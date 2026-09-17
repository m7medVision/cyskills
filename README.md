# cyskills

Cybersecurity skills for agents.

## Install the core

```bash
npx skills add m7medvision/cyskills
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
| `skills/web-app/` | 7 | api-security, api-mitmproxy, code-audit, js-reverse, browser-automation (single browser entry), supply-chain-security |
| `skills/cloud-identity/` | 4 | cloud-k8s, identity-federation, email-security, llm-security |
| `skills/windows-endpoint/` | 3 | windows-ad, edr-bypass-re, thick-client |
| `skills/binary-re/` | 12 | reverse-engineering, ida-reverse, ghidra-reverse, radare2, dotnet-reverse, pwn-chain |
| `skills/mobile/` | 2 | apk-reverse, mobile-reverse |
| `skills/hardware-embedded/` | 4 | firmware-pentest, hardware-security, ot-ics, radio-sdr |
| `skills/dfir-intel/` | 5 | digital-forensics, malware-analysis, threat-hunting, threat-intelligence |
| `skills/offensive-tooling/` | 5 | pentest-tools, attack-chain, wifi-wireless, docs-generator |

## Attribution

Based on [zhaoxuya520/reverse-skill](https://github.com/zhaoxuya520/reverse-skill) (MIT). Contains content adapted from [MyuriKanao/src-hunter](https://github.com/MyuriKanao) and references to [SecLists](https://github.com/danielmiessler/SecLists) and [PayloadsAllTheThings](https://github.com/swisskyrepo/PayloadsAllTheThings). The `api-mitmproxy` skill is adapted from [AgentSecOps/SecOpsAgentKit](https://github.com/AgentSecOps/SecOpsAgentKit) (CC-BY-SA 4.0).
