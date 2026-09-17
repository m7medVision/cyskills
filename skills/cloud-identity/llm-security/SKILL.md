---
name: llm-security
description: "Use for authorized security assessment of LLM applications and AI agents, including prompt injection, tool abuse, RAG exposure, memory poisoning, and model supply-chain risks."
---

# LLM / AI 安全测试

## Workflow

1. 侦察：映射 AI 攻击面
2. Prompt 注入测试（OWASP LLM01 / ASI01）
3. 记忆与上下文投毒（OWASP ASI06）
4. 输出安全测试（OWASP LLM05）
5. 系统提示词提取（OWASP LLM07）

## References

- `references/agent-cloud.md`
- `references/agent-obedience-engineering.md`
- `references/agent-security-testing.md`
- `references/community-security-skills.md`
- `references/overview.md`
- `references/owasp-llm-top10.md`
- `references/prompt-injection.md`
- `references/prompt-injection-methodology.md`
- `references/skill-supply-chain.md`

## Before you start

- Confirm authorization scope via `step-cyskills` (`scope.md`); do not act outside it.
- Verify tools first; `step-cyskills` preflight reports missing tools with distro install commands.
