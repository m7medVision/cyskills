# EDR Hook Survey Quick Reference

> For authorized red team / adversary emulation / testing your own products only; prohibited for unauthorized targets.

This document summarizes the monitoring points of mainstream EDR / AV in user mode and kernel mode, to help the red team quickly locate "what needs handling" during the reconnaissance phase.

## 1. Mainstream EDR fingerprints and hook patterns quick reference

| Vendor / Product | User-mode component | Kernel driver | Main monitoring surface |
|------------|-----------|---------|-----------|
| CrowdStrike Falcon | `CSFalconService.exe`, `CSAgent.sys` injected into target process | `CSAgent.sys`, `CSBoot.sys` | Heavy kernel callback + ETW-TI; few user-mode hooks (cloud scanning) |
| Microsoft Defender for Endpoint (MDE) | `MsMpEng.exe`, `MpClient.dll` | `WdFilter.sys`, `WdBoot.sys`, `WdNisDrv.sys` | AMSI + ETW-TI + ntdll inline hook + kernel callback, comprehensive |
| SentinelOne | `SentinelAgent.exe`, `SentinelHelperService.exe` | `SentinelMonitor.sys`, `SentinelDeviceControl.sys` | Heavy ntdll user-mode hooks + kernel callback + own ETW provider |
| Elastic Defend (formerly Endpoint Security) | `elastic-endpoint.exe` | `elastic-endpoint-driver.sys` | Mainly ETW + a few ntdll hooks, uploads via Elastic Agent |
| ESET | `ekrn.exe`, `eamsi.dll` | `eamonm.sys`, `epfwwfp.sys` | Many user-mode hooks (NtCreateFile / NtOpenProcess, etc.) |
| Sophos Intercept X | `SophosFileScanner.exe`, `SophosNtpService.exe` | `SophosED.sys`, `hmpalert.sys` | ntdll hook + HMPA memory protection + kernel callback |
| Kaspersky | `avp.exe`, `klif.sys` | `klif.sys`, `klhk.sys` | Heavy user-mode hooks + KLIF proprietary minifilter + network filter driver |
| Trend Micro Apex One | `TmListen.exe`, `TmCCSF.dll` | `tmcomm.sys`, `tmactmon.sys` | User-mode hooks + behavior monitoring driver |
| Carbon Black | `RepMgr.exe`, `RepWAV.exe` | `ParityDriver.sys` | Leans kernel callback + ETW |

### Quick fingerprint script

```powershell
$edrSigs = @{
    'CSAgent'           = 'CrowdStrike Falcon'
    'SentinelAgent'     = 'SentinelOne'
    'elastic-endpoint'  = 'Elastic Defend'
    'ekrn'              = 'ESET'
    'MsMpEng'           = 'Microsoft Defender'
    'SophosFileScanner' = 'Sophos Intercept X'
    'avp'               = 'Kaspersky'
    'TmListen'          = 'Trend Micro Apex One'
    'cb'                = 'Carbon Black'
}

Get-Process | ForEach-Object {
    foreach ($k in $edrSigs.Keys) {
        if ($_.ProcessName -match $k) {
            "[+] $($edrSigs[$k]) detected: $($_.ProcessName) (PID $($_.Id))"
        }
    }
}

Get-ChildItem 'C:\Windows\System32\drivers\*.sys' |
    Where-Object { $_.Name -match 'CSAgent|Sentinel|elastic|eam|WdFilter|Sophos|klif|tmcomm|Parity' } |
    Select-Object Name, VersionInfo
```

## 2. Key user-mode ntdll hook functions

`ntdll.dll` exports that EDR almost certainly hooks (grouped by ATT&CK behavior):

| Function | Behavior monitored | ATT&CK |
|------|-----------|--------|
| `NtCreateThreadEx` | Remote thread injection, QueueUserAPC injection | T1055.002 / T1055.004 |
| `NtAllocateVirtualMemory` | shellcode allocating RWX memory | T1055 |
| `NtAllocateVirtualMemoryEx` | Cross-process memory allocation (new Win10+ API) | T1055 |
| `NtProtectVirtualMemory` | Changing page permissions RW→RX | T1055 |
| `NtWriteVirtualMemory` | Cross-process shellcode write | T1055.012 |
| `NtMapViewOfSection` | section-based injection (Process Doppelganging / Ghosting) | T1055.013 |
| `NtCreateSection` | used together with MapViewOfSection | T1055.013 |
| `NtOpenProcess` | open target process to obtain handle | T1057 |
| `NtQueueApcThread` / `NtQueueApcThreadEx` | APC injection | T1055.004 |
| `NtCreateProcess` / `NtCreateProcessEx` / `NtCreateUserProcess` | create child process (including PPID spoof) | T1106 |
| `NtSetContextThread` | modify thread context (thread hijacking injection) | T1055.003 |
| `NtResumeThread` | resume thread after injection | T1055 |
| `NtQuerySystemInformation` | enumerate processes / drivers / handles | T1057 / T1082 |
| `NtAdjustPrivilegesToken` | privilege escalation to obtain SeDebugPrivilege, etc. | T1134 |
| `NtLoadDriver` | load kernel driver (BYOVD) | T1543.003 |

### Verify whether a hook exists

```powershell
# Simple: disassemble-diff the on-disk ntdll against the current process's ntdll
# 1. Grab the on-disk ntdll
copy C:\Windows\System32\ntdll.dll C:\temp\ntdll_clean.dll

# 2. In windbg, attach to any process and dump the current ntdll's .text section
# .writemem c:\temp\ntdll_live.bin ntdll!.text L?<size>

# 3. Disassemble NtAllocateVirtualMemory with IDA / radare2; normally it should be:
#    mov r10, rcx
#    mov eax, <SSN>
#    test byte ptr [...]
#    jne ...
#    syscall
#    ret
# If the first instruction becomes jmp <some address>, that's a hook
```

## 3. Kernel callback monitoring points

Common kernel callbacks registered by EDR (all can be unregistered via the BYOVD route in `attack-chain`, but at high cost):

| API | When the callback fires | Defender's use |
|-----|--------------|-----------|
| `PsSetCreateProcessNotifyRoutineEx` | Process creation / exit | Intercept suspicious child processes |
| `PsSetCreateThreadNotifyRoutine` | Thread creation / exit | Detect remote thread injection |
| `PsSetLoadImageNotifyRoutine` | DLL / EXE loaded into any process | Module integrity / unsigned blocking |
| `CmRegisterCallback` / `CmRegisterCallbackEx` | Registry operations | Persistence detection |
| `ObRegisterCallbacks` | `OpenProcess` / `OpenThread` handle requests | Prevent LSASS handle acquisition (T1003.001) |
| `MmRegisterPhysicalMemoryCallback` | Physical memory mapping | Prevent DMA / memory forensics |
| `IoRegisterFsRegistrationChange` | File system registration | Minifilter coordination |
| `KeRegisterNmiCallback` | NMI (rarely used by EDR) | Exception monitoring |
| `EtwRegister` (kernel side) | Kernel ETW reporting | Symbiotic with ETW-TI |

### Enumerate registered callbacks with windbg

```text
0: kd> dx -r1 nt!PspCreateProcessNotifyRoutine
0: kd> dx -r1 nt!PspCreateThreadNotifyRoutine
0: kd> dx -r1 nt!PspLoadImageNotifyRoutine

0: kd> !object \Callback
0: kd> !object \Callback\ProcessObject
```

Or use tools like PChunter / DRVHV to visually inspect the callback list as a normal user.

## 4. Statically dumping the hook table (IDA + windbg process)

### Process A: single-process comparison

```text
1. Find a process already injected with an EDR user-mode component (any live process)
2. windbg attach (-pn target.exe)
3. lm m ntdll  → get the module base address
4. .writemem c:\temp\ntdll_live.bin ntdll+0x0 L?<image size>
5. Copy C:\Windows\System32\ntdll.dll to c:\temp\ntdll_disk.dll
6. Load both files in IDA and jump to NtAllocateVirtualMemory:
     - disk: standard prologue
     - live: first instruction is jmp <0x7FFE000000xx>
7. Follow the jmp target address → that's the EDR's trampoline; dump it
8. Enter the trampoline and see which DLL it ultimately lands in, confirming the EDR module name
```

### Process B: batch hook table generation

Use `HookHunter` or a custom script:

```powershell
# pseudo workflow; see the scripts mentioned in references
$disk = Get-Content C:\Windows\System32\ntdll.dll -Encoding Byte
$live = # obtained via OpenProcess + ReadProcessMemory
# compare the first 16 bytes of each export in the .text section
```

## 5. pe-sieve automated detection

`pe-sieve` is the first choice for surveying EDR hooks and for implant self-checks:

```powershell
# Basic scan
pe-sieve64.exe /pid 1234

# Recommended combination (includes shellcode and hook detection)
pe-sieve64.exe /pid 1234 /shellc 3 /modules 3 /imp 3 /data 3 /dir hooks_dump

# Key parameters:
#   /shellc N    shellcode scan level (0-3)
#   /modules N   module integrity check (0-3)
#   /imp N       IAT hook check
#   /data N      data section scan
#   /dir <path>  dump output directory
```

The output produces `*.tag` files under `hooks_dump/<pid>.<name>/`, listing hook addresses:

```text
modified_modules.tag example:
71f10000;ntdll.dll
71f1a3b0;hook;jmp_far
71f1c020;hook;jmp_near
```

It can be fed directly to IDA to jump to the corresponding RVA for further analysis.

### Embedding pe-sieve in the implant (self-check)

In practice, `pe-sieve` is often compiled as a lib (`libpe-sieve`) so the implant self-checks at startup: if ntdll has hooks, trigger the unhook routine; if you find yourself hooked, be careful — you may be in a sandbox.

## 6. API Monitor v2 dynamic observation

API Monitor v2 (Rohitab) is good for watching when and where the EDR inserts hooks in the lab:

```text
1. Launch API Monitor v2 (as administrator)
2. Under API Filter, check:
     - NT Native API → Memory Management
     - NT Native API → Process and Thread
     - Windows Defender / AMSI (if visible)
3. Monitor New Process → select the implant test sample
4. Observe:
     - the call order of NtAllocateVirtualMemory
     - whether it is relayed through an EDR DLL
5. On the Modules tab, see which EDR DLLs were injected via LoadLibrary
```

## 7. Common EDR DLLs (user mode) quick reference

| DLL | Vendor | Notes |
|-----|------|------|
| `umppc*.dll` | Microsoft Defender | MpClient userland |
| `mpoav.dll` | Microsoft Defender | AMSI provider |
| `aswAMSI.dll` | Avast | AMSI provider |
| `eamsi.dll` | ESET | AMSI provider |
| `IDPMServiceClient.dll` | Sophos | HMPA injection |
| `klsihk64.dll` | Kaspersky | injected into target process |
| `CrowdStrike.Sensor.dll` | CrowdStrike | older version; newer versions rely mainly on the kernel |
| `SentinelInjection64.dll` | SentinelOne | user-mode injection |
| `TmUmEvt64.dll` | Trend Micro | behavior monitoring |

After confirming the target EDR, decide which DLL to reverse to extract the hook table.

## Reference links

- pe-sieve: <https://github.com/hasherezade/pe-sieve>
- HollowsHunter: <https://github.com/hasherezade/hollows_hunter>
- API Monitor v2: <http://www.rohitab.com/apimonitor>
- MITRE ATT&CK T1562: <https://attack.mitre.org/techniques/T1562/>
- MITRE ATT&CK T1055: <https://attack.mitre.org/techniques/T1055/>
- ired.team EDR notes: <https://www.ired.team/offensive-security/defense-evasion>

## Routing callback

After completing the hook survey, return to Step 3 in `SKILL.md` to choose the bypass technique combination, then execute according to `references/unhook-techniques.md` and `references/telemetry-blinding.md`.
