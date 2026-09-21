---
name: dsl-vm-reverse
description: "Reverse JavaScript-based custom DSL/VM interpreters, non-standard WASM-like runtimes, and risk-control engines. Use when analyzing IIFE or switch-based opcode dispatchers, extracting instruction tables, recovering bytecode semantics, capturing VM state at runtime, or reconstructing execution flow."
---

# 🔄 DSL Custom VM Reverse Engineering

## Workflow

1. Phase 1: File classification (5 min)
2. Phase 2: Variable mapping table extraction (10 min)
3. Phase 3: Opcode extraction and classification (15 min)
4. Phase 4: Constant table analysis (30 min)
5. Phase 5: Exported function tracing (1-2 hours)
6. Phase 6: Runtime injection (if pure static analysis is not enough)

## References

- `references/overview.md`

## Before you start

- Confirm authorization scope via `step-cyskills` (`scope.md`); do not act outside it.
- Verify tools first; `step-cyskills` preflight reports missing tools with distro install commands.
