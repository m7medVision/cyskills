---
name: ida-reverse
description: "IDA Pro reverse engineering assistant skill. Whenever the user mentions reverse engineering, decompilation, analyzing binaries/PE/ELF/APK/DLL/SO, cracking, finding passwords, vulnerability analysis, malware analysis, or firmware analysis, or needs to analyze files such as exe/dll/so/elf/macho/sys, be sure to use this skill."
---

# IDA Pro Reverse Engineering Skill

## Workflow

1. Step 1: start the server
2. Step 2: open a file
3. Step 3: global survey (including the import-table hard gate)
4. Step 4: deep-dive key functions
5. Step 5: data flow and cross-references
6. Step 6: record and refine
7. Step 7: output the report

## References

- `references/ida-mcp-cheatsheet.md`
- `references/overview.md`

## Before you start

- Confirm authorization scope via `step-cyskills` (`scope.md`); do not act outside it.
- Verify tools first; `step-cyskills` preflight reports missing tools with distro install commands.
