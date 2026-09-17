---
name: apk-reverse
description: "在 CLI 环境下做 Android APK 逆向时使用。适用于 APK 解包、Java 反编译、smali 修改、重打包、Frida 动态 Hook，以及按需切换到 so/native 分析。优先使用本机已安装的 jadx、apktool、frida、adb、ida-reverse、radare2。"
---

# APK 逆向 CLI 作业规范

## Workflow

1. Triage
2. Java 逻辑观察
3. Smali 与资源层确认
4. 重建与安装
5. 动态 Hook
6. Native .so 分流

## References

- `references/android-advanced.md`
- `references/android-hooking.md`
- `references/apk-security-checklist.md`
- `references/community-security-skills.md`
- `references/frida-bypass-kit.md`
- `references/frida-cookbook.md`
- `references/nonpe-format-cookbook.md`
- `references/overview.md`
- `references/skill-supply-chain.md`

## Before you start

- Confirm authorization scope via `step-cyskills` (`scope.md`); do not act outside it.
- Verify tools first; `step-cyskills` preflight reports missing tools with distro install commands.
