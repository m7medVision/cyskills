# cyskills

One cybersecurity skill for agents: a kernel that bootstraps the engagement, enforces the authorization scope gate, and routes any task to an ordered list of modules.

## Install

```bash
npx skills add m7medvision/cyskills
```

## Use

Name a preset — `web-pentest`, `mobile-pentest`, or `infra-pentest` — or just describe the task. The kernel writes `CONTEXT.md`, gates every target action behind `work/<case>/scope.md`, and the router prints which modules to read, in order:

```bash
scripts/router.sh --workflow web-pentest    # ordered preset bundle
scripts/router.sh "analyze malware sample"  # keyword match over all modules
scripts/router.sh --list                    # available presets
scripts/router.sh --check                   # validate bundles + frontmatter
```

Tools are assumed present on the machine; nothing is installed or downloaded, and no target is touched until the scope gate passes.

## Modules (52)

| Group | Count | Examples |
| --- | --- | --- |
| `modules/core/` | 1 | tooling — tool readiness check + modern bootstrap (uv, bun, go, prebuilt); hands install commands to the user |
| `modules/pentest/` | 21 | pentest-core (engine), attack-chain (orchestrator); tools: nmap, nuclei, ffuf, sqlmap, netexec, api-mitmproxy, browser-automation, metasploit; tasks: task-recon, task-js-api-extract, task-source-leak-hunt, task-credential-recovery, task-wifi-assessment, task-code-audit, task-db-post-access, task-supply-chain, task-report; deep dives: js-reverse, src-hunter |
| `modules/binary-re/` | 14 | reverse-engineering, ida-reverse, ghidra-reverse, radare2, dotnet-reverse, pwn-chain, apk-reverse, mobile-reverse (Android/iOS RE) |
| `modules/dfir-intel/` | 5 | digital-forensics, malware-analysis, threat-hunting, threat-intelligence, case-review |
| `modules/cloud-identity/` | 4 | cloud-k8s, identity-federation, email-security, llm-security |
| `modules/hardware-embedded/` | 4 | firmware-pentest, hardware-security, ot-ics, radio-sdr |
| `modules/windows-endpoint/` | 3 | windows-ad, edr-bypass-re, thick-client |

## Attribution

Based on [zhaoxuya520/reverse-skill](https://github.com/zhaoxuya520/reverse-skill) (MIT). Contains content adapted from [MyuriKanao/src-hunter](https://github.com/MyuriKanao) and references to [SecLists](https://github.com/danielmiessler/SecLists) and [PayloadsAllTheThings](https://github.com/swisskyrepo/PayloadsAllTheThings). The `api-mitmproxy` skill is adapted from [AgentSecOps/SecOpsAgentKit](https://github.com/AgentSecOps/SecOpsAgentKit) (CC-BY-SA 4.0). The `task-js-api-extract` and `task-source-leak-hunt` skills are adapted from [wgpsec/AboutSecurity](https://github.com/wgpsec/AboutSecurity), [elementalsouls/Claude-BugHunter](https://github.com/elementalsouls/Claude-BugHunter), [uphiago/recon-skills](https://github.com/uphiago/recon-skills), and [trailofbits/skills](https://github.com/trailofbits/skills). The mobile pentest content (folded into `pentest-core`) is adapted from [mukul975/Anthropic-Cybersecurity-Skills](https://github.com/mukul975/Anthropic-Cybersecurity-Skills), [BitterSecurity/Decepticon](https://github.com/BitterSecurity/Decepticon), and [jd-opensource/JoySafeter](https://github.com/jd-opensource/JoySafeter).
