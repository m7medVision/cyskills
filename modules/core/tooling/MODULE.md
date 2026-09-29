---
name: tooling
description: Tool readiness and modern bootstrap for the module library. Checks which testing tools are present and prints fast install commands (uv, bun, go, prebuilt binaries) for the user to run — no apt, pip, npm, or AUR helpers. Use when a wrapper reports a missing binary, before a first engagement, or on setup/environment/install requests. Trigger keywords: tools, missing tool, install, setup, environment, uv, bun, prerequisites.
---

# Tooling

One script owns tool readiness: `scripts/check-tools.sh`. Read-only by default; never installs by itself.

## Workflow

1. `bash modules/core/tooling/scripts/check-tools.sh` — audit everything; or narrow with `--track web|infra|mobile|re|dfir|core` or tool names.
2. Show the user the output: `[ok]`/`[MISS]` per tool plus a copy-paste fast-path block batched per channel.
3. Prompt the user to run `check-tools.sh --install` (it asks `[y/N]` before acting) or to paste the printed commands. The install prompt belongs to the user, not the agent.
4. Never run `--install`, piped installers, or any package manager yourself; no silent installs.
5. Re-run the check after the user installs, then resume the track.

## Channels (fastest first)

- `uv tool install` — Python tools (sqlmap, netexec, mitmproxy, frida-tools, pwntools…); `uvx` for one-shot
- `bun install -g` — JS tools (playwright)
- `go install` — ProjectDiscovery and Go tools (compiles once)
- prebuilt — trufflehog, jadx, apktool, adb, ghidra, testssl.sh, bun, uv; symlink into `~/.local/bin`
- `system` — true system binaries only (nmap, hashcat, tshark…); one grouped `sudo pacman -S --needed` line

No apt, no pip, no npm, no AUR helpers, no distro detection. Elsewhere the kernel rule holds: tools are assumed present; this module is the only sanctioned way to surface missing ones.
