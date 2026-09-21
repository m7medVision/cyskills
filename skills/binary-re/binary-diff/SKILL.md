---
name: binary-diff
description: "Cross-version symbol migration and binary diffing. Use when you have symbols/reverse-engineering results from an old version and need to migrate them quickly to a new version. Scenarios: deduce kernel symbols from an old version when PDB is missing, batch-migrate function names after a program update, quickly locate new offsets after an application update. Core method: structured diffing with an LLM, programmatic input/output, extremely low cost (200 functions ~1 yuan). Trigger keywords: symbol migration, bindiff, cross-version, PDB missing, function offset migration, symbol migration, binary diff, version comparison."
---

# Cross-Version Symbol Migration (Binary Diff)

## Workflow

1. Full workflow
2. Anchor selection strategy
3. Batch processing recommendations

## References

- `references/overview.md`
- `references/prompt-template.md`

## Before you start

- Confirm authorization scope via `step-cyskills` (`scope.md`); do not act outside it.
- Verify tools first; `step-cyskills` preflight reports missing tools with distro install commands.
