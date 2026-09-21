---
name: step-cyskills
description: Bootstrap a real-work cybersecurity engagement in a new project. Initializes the git workspace, builds CONTEXT.md, enforces the authorization scope gate, detects the Linux distro, audits required tools and wordlist resources, and resolves the user's chosen workflow into an ordered skill-injection plan. Run once per project before any security work; do not use for CTF challenges.
allowed-tools: Bash Read Write Edit Skill
---

# Step Cyskills

Run once per project, before any target action.

## Workflow

1. Confirm the project root. If it is not a git repo, ask the user, then `git init`; create `work/` and `.gitignore`.
2. Interview briefly (target, objective, constraints) and write `CONTEXT.md` in the project root; keep it updated during the engagement.
3. Authorization gate: `bash scripts/scope-init.sh --case <name> --target <target> --objective <goal> [--authorized --auth-basis <basis>]`, then `bash scripts/scope-guard.sh --case <name>`. Do not touch a target until the guard exits 0.
4. Distro and tool audit: run `bash scripts/preflight.sh`. Report missing tools and resources with the distro-specific install command. Ask for approval before installing anything; never install silently.
5. Workflow injection (preferred): when the user names a workflow or the task clearly matches one, run `bash scripts/workflow.sh <name>` (no name → `bash scripts/workflow.sh` lists them). Then load **every** listed skill with the Skill tool, in the printed order, without asking the user which skills to use. If modules are missing, say which to install and continue with the rest. If nothing matches, use step 6.
6. Ad-hoc tasks: `bash scripts/recommend.sh "<task>"` lists matching skills. Tell the user which to install before continuing; this skill never installs other skills itself.
7. Handoff: start with the workflow's track (or the recommended primary skill) and work strictly inside `scope.md`.

## References

- `references/preflight.md` — config format, workflow bundle format, distro matrix (Kali, BlackArch, Arch/AUR, git clone), environment overrides.