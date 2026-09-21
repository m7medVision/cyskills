# Workflows

Thin, declarative skills: each one is *just a workflow*. It names the modules to load (in order) and the tools to check — nothing else. The kernel (`step-cyskills`) resolves them: the user names a workflow, `workflow.sh` reads the bundle, and the agent injects every listed skill without asking.

| Workflow | Target | Modules |
| --- | --- | --- |
| [workflow-web-pentest](./workflow-web-pentest/SKILL.md) | website / HTTP API | pentest-core, recon, JS/source extraction, nuclei, mitmproxy, browser |
| [workflow-mobile-pentest](./workflow-mobile-pentest/SKILL.md) | Android app + backend | pentest-core, mitmproxy, APK/mobile RE, source-leak-hunt |
| [workflow-infra-pentest](./workflow-infra-pentest/SKILL.md) | CIDRs / hosts / services | pentest-core, nmap, recon, netexec, password-cracking, nuclei |

Each workflow ships `bundle.conf` (machine-readable: `name`, `title`, `track`, `skills`, `tools`) consumed by `step-cyskills/scripts/workflow.sh`. To add one, copy a directory and edit its `bundle.conf` plus the trigger description in `SKILL.md`.
