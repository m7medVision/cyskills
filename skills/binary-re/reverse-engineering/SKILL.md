---
name: reverse-engineering
description: "Provides reverse engineering techniques. Use when the main job is to understand how a compiled, obfuscated, packed, or virtualized target works before exploiting or solving it, including binaries, APKs, WASM, firmware, custom VMs, bytecode, malware-like loaders, and anti-debug or anti-analysis logic. Do not use it when the vulnerability is already understood and the remaining task is exploitation; use pwn instead. Do not use it for pure web workflows, log or disk forensics, or standalone crypto problems unless reversing the implementation is the real blocker."
license: MIT
compatibility: Requires a filesystem-based code agent or CLI with shell access, Python 3, and internet access for tool installation.
allowed-tools: Bash Read Write Edit Glob Grep Task WebFetch WebSearch
---

# Reverse Engineering

## Workflow

1. Decision-framework entry hook
2. Default Sandbox Context
3. Prerequisites
4. Additional Resources
5. When to Pivot
6. Quick Wins (Try First!)
7. Initial Analysis
8. Memory Dumping Strategy
9. Decoy Flag Detection
10. GDB PIE Debugging
11. Comparison Direction (Critical!)
12. Common Encryption Patterns
13. Quick Tool Reference
14. Deep-Dive Notes

## References

- `references/ai-assisted-re.md`
- `references/analysis-decision-framework.md`
- `references/community-security-skills.md`
- `references/nonpe-format-cookbook.md`
- `references/ollvm-deobfuscation.md`
- `references/overview.md`
- `references/re-agent-workflow.md`
- `references/reverse-pwn.md`

## Before you start

- Confirm authorization scope via `step-cyskills` (`scope.md`); do not act outside it.
- Verify tools first; `step-cyskills` preflight reports missing tools with distro install commands.
