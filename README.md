# cyskills

Cybersecurity skills for coding agents, packaged for the [`skills`](https://skills.sh) CLI.

Built for real engagements (pentest, red team, reverse engineering, DFIR, reporting) — not CTF.

## Install the core

```bash
npx skills add <owner>/cyskills -s step-cyskills
```

Then run the `step-cyskills` skill once per project. It:

1. initializes the git workspace and writes `CONTEXT.md`;
2. enforces the authorization scope gate (`work/<case>/scope.md`);
3. detects your distro (Kali, BlackArch, Arch/AUR) and audits required tools and wordlist resources;
4. prints the exact `npx skills add` command for the skills your task needs.

Nothing is installed or downloaded without your approval, and no target is touched until `scripts/scope-guard.sh` passes.

## Skills (43)

| Group | Count | Examples |
| --- | --- | --- |
| `skills/core/` | 1 | step-cyskills — project bootstrap and preflight, install first |
| `skills/web-app/` | 7 | api-security, code-audit, js-reverse, browser-automation, supply-chain-security |
| `skills/cloud-identity/` | 4 | cloud-k8s, identity-federation, email-security, llm-security |
| `skills/windows-endpoint/` | 3 | windows-ad, edr-bypass-re, thick-client |
| `skills/binary-re/` | 12 | reverse-engineering, ida-reverse, ghidra-reverse, radare2, dotnet-reverse, pwn-chain |
| `skills/mobile/` | 2 | apk-reverse, mobile-reverse |
| `skills/hardware-embedded/` | 4 | firmware-pentest, hardware-security, ot-ics, radio-sdr |
| `skills/dfir-intel/` | 5 | digital-forensics, malware-analysis, threat-hunting, threat-intelligence |
| `skills/offensive-tooling/` | 5 | pentest-tools, attack-chain, wifi-wireless, docs-generator |

## Resources

Wordlists and payloads are **not** bundled. `step-cyskills` reports the distro-specific install command for SecLists, rockyou, dirb, dirbuster, wfuzz and PayloadsAllTheThings, and only if a task needs them.

## Format

Every skill follows the [Agent Skills](https://agentskills.io) spec: `skills/<name>/SKILL.md` plus optional `references/`, `scripts/`, `assets/`. Frontmatter is limited to `name`, `description`, `license`, `compatibility`, `metadata`, `allowed-tools`. Each `SKILL.md` is under 500 tokens and points to `references/` for depth. Validated with `agentskills validate`.

## Attribution

Based on [zhaoxuya520/reverse-skill](https://github.com/zhaoxuya520/reverse-skill) (MIT). Contains content adapted from [MyuriKanao/src-hunter](https://github.com/MyuriKanao) and references to [SecLists](https://github.com/danielmiessler/SecLists) and [PayloadsAllTheThings](https://github.com/swisskyrepo/PayloadsAllTheThings), which are installed separately and never redistributed here. MIT licensed — see `LICENSE`.