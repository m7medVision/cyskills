---
name: dsl-vm-reverse
description: "Reverse JavaScript-based custom DSL/VM interpreters, non-standard WASM-like runtimes, and risk-control engines. Use when analyzing IIFE or switch-based opcode dispatchers, extracting instruction tables, recovering bytecode semantics, capturing VM state at runtime, or reconstructing execution flow."
---

# 🔄 DSL 自定义虚拟机逆向（DSL VM Reverse Engineering）

## Workflow

1. Phase 1: 文件分类（5 分钟）
2. Phase 2: 变量映射表提取（10 分钟）
3. Phase 3: Opcode 提取与分类（15 分钟）
4. Phase 4: 常量表分析（30 分钟）
5. Phase 5: 导出函数追踪（1-2 小时）
6. Phase 6: 运行时注入（若纯静态分析不够）

## References

- `references/overview.md`

## Before you start

- Confirm authorization scope via `step-cyskills` (`scope.md`); do not act outside it.
- Verify tools first; `step-cyskills` preflight reports missing tools with distro install commands.
