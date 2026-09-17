---
name: js-reverse
description: "在使用 js-reverse-mcp 做前端 JavaScript 逆向时使用，适用于签名链路定位、页面观察取证、运行时采样、本地补环境复现与证据化输出。优先适配当前环境里的 js-reverse_* 工具，需要更强的浏览器/CDP/Hook 面时联动 jshookmcp。"
---

# MCP 前端 JS 逆向作业规范

## Workflow

1. Observe
2. Capture
3. Rebuild
4. Patch
5. DeepDive

## References

- `references/ast-deobfuscation.md`
- `references/automation-entry.md`
- `references/bundle-sourcemap-recovery.md`
- `references/env-patching.md`
- `references/fallbacks.md`
- `references/instrumentation.md`
- `references/local-rebuild.md`
- `references/mcp-task-template.md`
- `references/node-env-rebuild.md`
- `references/nonpe-format-cookbook.md`
- `references/output-contract.md`
- `references/overview.md`
- `references/task-artifacts.md`
- `references/task-input-template.md`
- `references/tool-defaults.md`

## Before you start

- Confirm authorization scope via `step-cyskills` (`scope.md`); do not act outside it.
- Verify tools first; `step-cyskills` preflight reports missing tools with distro install commands.
