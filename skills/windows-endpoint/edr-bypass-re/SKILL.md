---
name: edr-bypass-re
description: "逆向防御方实现 → 红队针对性绕过。把 EDR / Defender / AV 的 hook 表、ETW provider、AMSI 实现先逆向出来， 再写针对性的 unhook / 间接 syscall / ETW patch / call stack spoof。对照 MITRE ATT&CK T1562 防御规避。 触发关键词：EDR 绕过、AV bypass、免杀、unhook、direct syscall、indirect syscall、Hell's Gate、Halo's Gate、 Tartarus Gate、ETW patch、AMSI patch、call stack spoofing、hardware breakpoint Blindside、MITRE T1562、 ntdll unhook、kernel callback、CrowdStrike 绕过、Defender 绕过、Sentinel One 绕过、Elastic Defend、 Sysmon 规避、PPID spoof、Sleep mask、Process Hollowing、Reflective DLL。"
---

# EDR 绕过：从防御方实现逆向到红队绕过

## Workflow

1. Step 1：识别目标主机的 EDR
2. Step 2：从 EDR DLL 提 hook 表
3. Step 3：选绕过技术组合
4. Step 4：在 implant 中实现
5. Step 5：本地 sandbox 验证
6. Step 6：投递

## References

- `references/hook-survey.md`
- `references/overview.md`
- `references/telemetry-blinding.md`
- `references/unhook-techniques.md`

## Before you start

- Confirm authorization scope via `step-cyskills` (`scope.md`); do not act outside it.
- Verify tools first; `step-cyskills` preflight reports missing tools with distro install commands.
