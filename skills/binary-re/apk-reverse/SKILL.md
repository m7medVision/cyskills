---
name: apk-reverse
description: "Android APK reverse engineering in the CLI: unpack, Java decompilation, smali edits, repack, Frida dynamic hooks, and switching to so/native analysis when needed. Prefer the locally installed jadx, apktool, frida, adb, ida-reverse and radare2. Trigger keywords: APK, Android, jadx, apktool, smali, frida, repack, native so."
---

# APK Reverse Engineering (CLI)

## Workflow

1. Triage
2. Observe Java logic
3. Confirm at the smali and resource layer
4. Rebuild and install
5. Dynamic hooks
6. Route to native `.so`

## References

- `references/overview.md`
- `references/android-advanced.md`
- `references/android-hooking.md`
- `references/apk-security-checklist.md`
- `references/frida-cookbook.md`
- `references/frida-bypass-kit.md`
- `references/nonpe-format-cookbook.md`
- `references/skill-supply-chain.md`
- `references/community-security-skills.md`

## Before you start

- Confirm authorization scope via `step-cyskills` (`scope.md`); do not act outside it.
- Verify tools first; `step-cyskills` preflight reports missing tools with distro install commands.
