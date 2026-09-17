---
name: step-cyskills
description: Bootstrap a real-work cybersecurity engagement in a new project. Initializes the git workspace, builds CONTEXT.md, enforces the authorization scope gate, detects the Linux distro, audits required tools and wordlist resources, and prints the exact command to install the skills this task needs. Run once per project before any security work; do not use for CTF challenges.
allowed-tools: Bash Read Write Edit
---

# Step Cyskills

Run once per project, before any target action.

## Workflow

1. Confirm the project root. If it is not a git repo, ask the user, then `git init`; create `work/` and `.gitignore`.
2. Interview briefly (target, objective, constraints) and write `CONTEXT.md` in the project root; keep it updated during the engagement.
3. Authorization gate: `bash scripts/scope-init.sh --case <name> --target <target> --objective <goal> [--authorized --auth-basis <basis>]`, then `bash scripts/scope-guard.sh --case <name>`. Do not touch a target until the guard exits 0.
4. Distro and tool audit: run `bash scripts/preflight.sh`. Report missing tools and resources with the distro-specific install command. Ask for approval before installing anything; never install silently.
5. Skill selection: `bash scripts/recommend.sh "<task>"` prints the `npx skills add` command for this task. Show it to the user to run; this skill never installs other skills itself.
6. Handoff: start with the recommended primary skill and work strictly inside `scope.md`.

## References

- `references/preflight.md` — config format, distro matrix (Kali, BlackArch, Arch/AUR, git clone), environment overrides.