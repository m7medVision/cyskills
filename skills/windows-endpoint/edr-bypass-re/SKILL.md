---
name: edr-bypass-re
description: "Reverse the defender's implementation → targeted red-team bypass. First reverse-engineer EDR / Defender / AV hook tables, ETW providers, and AMSI implementations, then write targeted unhook / indirect syscall / ETW patch / call stack spoof. Mapped to MITRE ATT&CK T1562 defense evasion. Trigger keywords: EDR bypass, AV bypass, AV evasion, unhook, direct syscall, indirect syscall, Hell's Gate, Halo's Gate, Tartarus Gate, ETW patch, AMSI patch, call stack spoofing, hardware breakpoint Blindside, MITRE T1562, ntdll unhook, kernel callback, CrowdStrike bypass, Defender bypass, Sentinel One bypass, Elastic Defend, Sysmon evasion, PPID spoof, sleep mask, process hollowing, reflective DLL."
---

# EDR Bypass: From Reversing Defender Implementations to Red Team Bypass

## Workflow

1. Step 1: Identify the target host's EDR
2. Step 2: Extract the hook table from the EDR DLL
3. Step 3: Choose the bypass technique combination
4. Step 4: Implement it in the implant
5. Step 5: Validate in a local sandbox
6. Step 6: Deliver

## References

- `references/hook-survey.md`
- `references/overview.md`
- `references/telemetry-blinding.md`
- `references/unhook-techniques.md`

## Before you start

- Confirm authorization scope via `step-cyskills` (`scope.md`); do not act outside it.
- Verify tools first; `step-cyskills` preflight reports missing tools with distro install commands.
