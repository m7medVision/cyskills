---
name: cyskills
description: Cybersecurity engagement kernel for real work: web/mobile/network penetration testing, binary and mobile reverse engineering, DFIR and malware analysis, cloud and identity attacks, hardware and firmware. Bootstraps the project workspace, enforces the authorization scope gate, routes the task to an ordered module list, and drives the case to a report. Use for any authorized security task — name a preset (web-pentest, mobile-pentest, infra-pentest) or describe the task. Not for CTF challenges.
allowed-tools: Bash Read Write Edit
---

# Cyskills

One kernel; the module library lives in `modules/`. Tools are assumed present on the machine — never install, download, or bootstrap anything.

## Workflow

1. Confirm the project root. If it is not a git repo, ask the user, then `git init`; create `work/` and `.gitignore`.
2. Interview briefly (target, objective, constraints) and write `CONTEXT.md` in the project root; keep it updated during the engagement.
3. Authorization gate: `bash scripts/scope-init.sh --case <name> --target <target> --objective <goal> [--authorized --auth-basis <basis>]`, then `bash scripts/scope-guard.sh --case <name>`. Do not touch a target until the guard exits 0.
4. Route: named engagement → `bash scripts/router.sh --workflow web-pentest|mobile-pentest|infra-pentest`; anything else → `bash scripts/router.sh "<task>"`. The router prints ordered module paths.
5. Read each printed module file with the Read tool, in order. The track engine (`modules/pentest/pentest-core`) owns the case, scope, per-asset matrix, and report; support modules add specialist depth.
6. Missing tools? Load `modules/core/tooling` — it prints fast install commands (uv, bun, go, prebuilt) for the user to run; never install anything yourself.
7. Work strictly inside `work/<case>/scope.md`; finish with the track's report module.
