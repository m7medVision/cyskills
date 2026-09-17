---
name: binary-diff
description: "跨版本符号迁移与二进制差分。当你有旧版本的符号/逆向结果，需要快速迁移到新版本时使用。 适用场景：内核缺 PDB 用旧版符号推导、程序更新后批量迁移函数名、应用更新后快速定位新偏移。 核心方法：用 LLM 做结构化差异比对，程序化输入输出，成本极低（200 函数 ~1 元）。 触发关键词：符号迁移、bindiff、跨版本、PDB 缺失、函数偏移迁移、symbol migration、binary diff、版本对比。"
---

# 跨版本符号迁移 (Binary Diff)

## Workflow

1. 完整流程
2. 锚点选择策略
3. 批量处理建议

## References

- `references/overview.md`
- `references/prompt-template.md`

## Before you start

- Confirm authorization scope via `step-cyskills` (`scope.md`); do not act outside it.
- Verify tools first; `step-cyskills` preflight reports missing tools with distro install commands.
