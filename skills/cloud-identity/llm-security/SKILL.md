---
name: llm-security
description: "Use for authorized security assessment of LLM applications and AI agents, including prompt injection, tool abuse, RAG exposure, memory poisoning, and model supply-chain risks."
---

# LLM / AI Security Testing

## Workflow

1. Recon: map the AI attack surface
2. Prompt injection testing (OWASP LLM01 / ASI01)
3. Memory and context poisoning (OWASP ASI06)
4. Output handling testing (OWASP LLM05)
5. System prompt extraction (OWASP LLM07)

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
