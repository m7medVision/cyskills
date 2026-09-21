---
name: dotnet-reverse
description: ".NET / C# binary reverse engineering. Use when the target is a .NET assembly (PE header containing CLR, managed .exe/.dll), C# compiled output (including NativeAOT), red-team Sharp* tools (Rubeus / SharpHound / SharpHound etc.), .NET obfuscated programs (ConfuserEx / SmartAssembly / Babel / Eazfuscator), or .NET loader / info-stealer / packed malware. Prefer dnSpyEx + de4dot; when an AI must operate directly, pair with the dnSpy MCP. Not for pure native binaries (use reverse-engineering / ida-reverse)."
license: MIT
compatibility: Requires a filesystem-based code agent or CLI with shell access, Windows host preferred (dnSpyEx is a Windows GUI); Linux/macOS can use the ILSpy/de4dot CLI + mono/dotnet runtime.
allowed-tools: Bash Read Write Edit Glob Grep Task WebFetch WebSearch
---

# .NET / C# Reverse Engineering Guidelines

## Workflow

1. Identify (identify .NET)
2. Detect (detect the obfuscator)
3. Deobfuscate
4. Static Analyze
5. Dynamic (dynamic debugging)
6. Patch (modify as needed)

## References

- `references/common-workflow.md`
- `references/obfuscators.md`
- `references/overview.md`
- `references/sharp-tools.md`

## Before you start

- Confirm authorization scope via `step-cyskills` (`scope.md`); do not act outside it.
- Verify tools first; `step-cyskills` preflight reports missing tools with distro install commands.
