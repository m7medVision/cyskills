---
name: js-reverse
description: "Use for front-end JavaScript reverse engineering: locating signing, crypto or risk-control code, observing page requests, runtime sampling, and rebuilding the logic locally in Node. Composes with the browser-automation skill (Playwright/Chromium) and the api-mitmproxy skill. Trigger keywords: JS 逆向, 签名链路, 加密参数, 补环境, js-reverse, CDP, sourcemap, AST deobfuscation."
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
