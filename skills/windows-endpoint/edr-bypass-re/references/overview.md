
# EDR Bypass: From Reversing Defender Implementations to Red Team Bypass

> For authorized red team / adversary emulation / testing your own products only; prohibited for unauthorized targets.

## Scope

Use this skill when a red team / adversary simulation delivers an implant to an authorized target host and needs to evade modern EDR.

1. **Red team / Purple team / adversary emulation** — the client wants to assess the real detection capability of their SOC and EDR
2. **In-house implant / C2 framework R&D** — develop payloads for testing your own products, needing to bypass your own or the target's EDR
3. **EDR product evaluation** — objectively evaluate a given EDR's detection coverage once compliance boundaries are confirmed
4. **CTF / red-vs-blue Windows-side breakthrough** — need stable execution on a hardened host in a competition

**Not applicable**:

- AV vendors doing a full RE of their own product to produce a commercial evaluation report for a customer (work with the vendor officially)
- AV-evasion against unauthorized targets (illegal)
- AV evasion for ordinary malware (this skill focuses on red-team OPSEC, not writing malicious code)

### Division of labor with other skills

| Scenario | What to use |
|------|--------|
| Full-chain attack (from external network to domain controller) | `attack-chain/` |
| Internal lateral movement / AD attacks | `windows-ad/references/network-attack-defense.md` |
| Need to bypass EDR on one specific host to deliver an implant | **this skill** |
| Pure static AV evasion (obfuscation / packing) | `malware-analysis/` (defensive perspective) |

`attack-chain` focuses on the full kill chain; this skill focuses only on the internal mechanisms of **EDR as a single adversary** and targeted ways around it.

## Core Principles

```text
EDR's four main monitoring surfaces       Red team countermeasures
─────────────────────                     ─────────────────────
User-mode ntdll hook       ◄──►   unhook (Peruns Fart / fresh ntdll)
                                  indirect syscall / Hell's Gate
                                  hardware breakpoint Blindside

kernel callback            ◄──►   call stack spoof
(Ps/Cm/Ob series)                 go through legitimate trigger chain (don't bypass directly; combine with upstream stealth)

ETW telemetry              ◄──►   EtwEventWrite patch
(Microsoft-Windows-Threat-        NtTraceControl to disable provider
 Intelligence, etc.)              AmsiContext synchronized handling

AMSI scanning              ◄──►   AmsiScanBuffer patch (mov eax,0x80070057; ret)
(amsi.dll)                        hardware breakpoint bypass
                                  reflective load of a copy of amsi.dll
```

Key insights:

- **EDR is not a black box** — the key hooks / callbacks / providers can all be reversed with IDA + windbg
- **Bypass techniques must be combined** — a single unhook does not solve ETW alerts, a single AMSI patch does not solve syscall hooks
- **Order matters** — ETW patch → AMSI patch → unhook; get the order wrong and the EDR receives the unhook alert first
- **Modern EDR has made ETW + kernel callback the main battlefield**, and pure user-mode unhook has long been insufficient

## Workflow

### Step 1: Identify the target host's EDR

```powershell
# List common EDR / AV drivers
Get-Service | Where-Object {$_.Name -match 'CSAgent|SentinelAgent|elasticendpoint|esets|ekrn|MsMpEng|wdsvc|cyserver|sysmon|aswbidsagent'}

# List loaded minifilters
fltmc filters

# List registered kernel callbacks (requires windbg + kernel debugging / or PChunter / DRVHV)
# !object \Callback
# !pnpcallback / Process / Thread / Image
```

See the top of `hook-survey.md` for the EDR fingerprint table.

### Step 2: Extract the hook table from the EDR DLL

1. attach to a process injected with an EDR user-mode component (any already-landed process)
2. in windbg, dump the `.text` section of the current `ntdll.dll`
3. diff it against the clean `C:\Windows\System32\ntdll.dll` on disk
4. wherever they differ is a hook point

Or use `pe-sieve` directly:

```powershell
pe-sieve64.exe /pid 1234 /shellc 3 /modules 3 /dir hooks_dump
```

See `hook-survey.md` for details.

### Step 3: Choose the bypass technique combination

| Defense point | Recommended bypass |
|--------|---------|
| ntdll inline hook | indirect syscall + dynamic SSN (Halo's Gate) |
| ETW-TI provider | EtwEventWrite head patch |
| AMSI (PowerShell / .NET) | AmsiScanBuffer patch or HWBP |
| kernel callback | call stack spoof + go through legit gadget |
| Sysmon ProcessCreate | PPID spoof + unbacked memory |

### Step 4: Implement it in the implant

See `unhook-techniques.md` and `telemetry-blinding.md` for code skeletons.

### Step 5: Validate in a local sandbox

```powershell
# Deploy a trial version of the target EDR in an isolated environment (Defender default is enough to start)
# Enable Sysmon + olaf-config
sysmon64.exe -i sysmonconfig.xml

# Run the implant and see whether it triggers any of these alert sources:
#   - Defender AMSI
#   - ETW-TI
#   - Sysmon Event ID 1/7/8/10
#   - EDR console
```

### Step 6: Delivery

- Use legitimate software directories for file landing paths
- PPID spoof to explorer.exe
- Combine with the initial access section in `attack-chain`

## Typical Scenarios

### Scenario 1: Deliver a cobalt-strike-alike beacon past Defender + Sysmon

```text
Target: Windows 11 Enterprise + Defender (cloud scanning on) + Sysmon (olaf config)
Requirement: beacon can call back after landing and triggers no alerts

Combination:
  1. shellcode stored encrypted, decrypted at runtime
  2. AMSI patch (if delivering via PowerShell)
  3. EtwEventWrite patch (kill ETW-TI)
  4. indirect syscall + Halo's Gate (kill ntdll hook alerts)
  5. PPID spoof to explorer.exe
  6. encrypt own memory with Ekko / Foliage during sleep
```

### Scenario 2: EDR sleep mask on an already-landed low-privilege shell

```text
Precondition: already obtained a medium IL shell via phishing, EDR is monitoring
Risk: long-term residency is easily discovered by memory scanning for beacon signatures

Solution:
  1. stop allocating new RWX memory
  2. during sleep use Ekko:
       - WaitForSingleObjectEx + CreateTimerQueueTimer
       - in the timer encrypt own .text + zero out the stack
  3. restore via ROP on wake
  4. combine with call stack spoof so RtlCaptureStackBackTrace cannot see the beacon address
```

## On-Demand Bootstrap

### Tool dependencies

| Tool | Purpose | Auto-installable |
|------|------|-----------|
| pe-sieve | Detect hooks / injection in a process | ✓ |
| API Monitor v2 | Dynamically observe API calls and hooks | Semi-auto (manual download) |
| SysWhispers3 | Generate direct / indirect syscall stubs | ✓ (git clone + python) |
| Hell's Gate POC | Reference implementation of dynamic SSN resolution | ✓ (git clone) |
| windbg + IDA | Statically reverse EDR DLL / kernel callback | ✗ (install yourself) |
| Sysmon + olaf config | Local validation environment | ✓ |

### Bootstrap command

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "&lt;SKILL_ROOT&gt;\skills\scripts\bootstrap-reverse.ps1" -Capability @('pe-sieve','syswhispers3','sysmon') -StartServices
```

## Routing Context

**Upstream entry**:

- `reverse-engineering/` — need to first understand the EDR DLL / driver implementation
- `attack-chain/` — decide at which stage of the kill chain to introduce this skill

**Peer associations**:

- `windows-ad/references/network-attack-defense.md` — how to combine with this skill during internal lateral movement
- `malware-analysis/` — defensive perspective, see how defenders write rules
- `field-journal/` — write back lessons after each engagement

**Downstream deliverables**:

- When generating reports, cite MITRE ATT&CK **T1562 (Impair Defenses)**, T1562.001 (Disable or Modify Tools), T1562.006 (Indicator Blocking), T1055 (Process Injection), T1027 (Obfuscated Files or Information)

## Legal Boundary Statement

- Authorized red team / adversary emulation / testing your own products only
- Written authorization must be obtained before operations (SoW / test contract / SRC scope statement)
- Must not be used against unauthorized targets, must not exceed the authorized scope
- Report high-risk findings to the customer immediately, follow responsible disclosure
- Real target information in all reports must be redacted (IP / hostname / domain / credential placeholders)

## References

- Detailed hook survey: `hook-survey.md`
- unhook / syscall techniques: `unhook-techniques.md`
- ETW / AMSI / anti-forensics: `telemetry-blinding.md`
- MITRE ATT&CK T1562: <https://attack.mitre.org/techniques/T1562/>
