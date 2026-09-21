# cyskills

Cybersecurity skills for agents.

## Install the core

```bash
npx skills add m7medvision/cyskills
```

The install ships the kernel (`step-cyskills`) and every workflow entrypoint. Then just **name the workflow you want** — `workflow-web-pentest`, `workflow-mobile-pentest`, or `workflow-infra-pentest` triggers and injects the right modules in order, no skill-picking needed. `step-cyskills`:

1. initializes the git workspace and writes `CONTEXT.md`;
2. enforces the authorization scope gate (`work/<case>/scope.md`);
3. detects your distro (Kali, BlackArch, Arch/AUR) and audits the bundle's tools and wordlist resources;
4. resolves your workflow into an ordered skill list and loads them automatically.

Nothing is installed or downloaded without your approval, and no target is touched until `scripts/scope-guard.sh` passes.

## Skills (55)

| Group | Count | Examples |
| --- | --- | --- |
| `skills/core/` | 1 | step-cyskills — project bootstrap, preflight and workflow resolver, install first |
| `skills/workflows/` | 3 | workflow-web-pentest, workflow-mobile-pentest, workflow-infra-pentest — declarative entrypoints |
| `skills/cloud-identity/` | 4 | cloud-k8s, identity-federation, email-security, llm-security |
| `skills/windows-endpoint/` | 3 | windows-ad, edr-bypass-re, thick-client |
| `skills/binary-re/` | 14 | reverse-engineering, ida-reverse, ghidra-reverse, radare2, dotnet-reverse, pwn-chain, apk-reverse, mobile-reverse (Android/iOS RE; Android workflow → workflow-mobile-pentest) |
| `skills/hardware-embedded/` | 4 | firmware-pentest, hardware-security, ot-ics, radio-sdr |
| `skills/dfir-intel/` | 5 | digital-forensics, malware-analysis, threat-hunting, threat-intelligence |
| `skills/pentest/` | 21 | pentest-core (engine), attack-chain (orchestrator); tools: nmap, nuclei, ffuf, sqlmap, netexec, api-mitmproxy, browser-automation, metasploit; tasks: task-recon, task-js-api-extract, task-source-leak-hunt, task-credential-recovery, task-wifi-assessment, task-code-audit, task-db-post-access, task-supply-chain, task-report; deep dives: js-reverse, src-hunter |

## Attribution

Based on [zhaoxuya520/reverse-skill](https://github.com/zhaoxuya520/reverse-skill) (MIT). Contains content adapted from [MyuriKanao/src-hunter](https://github.com/MyuriKanao) and references to [SecLists](https://github.com/danielmiessler/SecLists) and [PayloadsAllTheThings](https://github.com/swisskyrepo/PayloadsAllTheThings). The `api-mitmproxy` skill is adapted from [AgentSecOps/SecOpsAgentKit](https://github.com/AgentSecOps/SecOpsAgentKit) (CC-BY-SA 4.0). The `task-js-api-extract` and `task-source-leak-hunt` skills are adapted from [wgpsec/AboutSecurity](https://github.com/wgpsec/AboutSecurity), [elementalsouls/Claude-BugHunter](https://github.com/elementalsouls/Claude-BugHunter), [uphiago/recon-skills](https://github.com/uphiago/recon-skills), and [trailofbits/skills](https://github.com/trailofbits/skills). The mobile pentest content (folded into `pentest-core`) is adapted from [mukul975/Anthropic-Cybersecurity-Skills](https://github.com/mukul975/Anthropic-Cybersecurity-Skills), [BitterSecurity/Decepticon](https://github.com/BitterSecurity/Decepticon), and [jd-opensource/JoySafeter](https://github.com/jd-opensource/JoySafeter).
