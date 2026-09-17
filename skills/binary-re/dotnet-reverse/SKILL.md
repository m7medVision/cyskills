---
name: dotnet-reverse
description: ".NET / C# 二进制逆向。当目标是 .NET assembly（PE 头含 CLR、.exe/.dll 托管程序）、C# 编译产物（含 NativeAOT）、红队 Sharp* 工具（Rubeus / SharpHound / SharpHound 等）、.NET 混淆程序（ConfuserEx / SmartAssembly / Babel / Eazfuscator）、.NET loader / info-stealer / 套壳 malware 时使用。优先用 dnSpyEx + de4dot，需要 AI 直接操作时联动 dnSpy MCP。不用于纯 native 二进制（走 reverse-engineering / ida-reverse）。"
license: MIT
compatibility: Requires a filesystem-based code agent or CLI with shell access, Windows host preferred (dnSpyEx 是 Windows GUI)；Linux/macOS 可用 ILSpy/de4dot CLI + mono/dotnet runtime。
allowed-tools: Bash Read Write Edit Glob Grep Task WebFetch WebSearch
---

# .NET / C# 逆向作业规范

## Workflow

1. Identify（识别 .NET）
2. Detect（检测混淆器）
3. Deobfuscate（脱混淆）
4. Static Analyze（静态分析）
5. Dynamic（动态调试）
6. Patch（按需修改）

## References

- `references/common-workflow.md`
- `references/obfuscators.md`
- `references/overview.md`
- `references/sharp-tools.md`

## Before you start

- Confirm authorization scope via `step-cyskills` (`scope.md`); do not act outside it.
- Verify tools first; `step-cyskills` preflight reports missing tools with distro install commands.
