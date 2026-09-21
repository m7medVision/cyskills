# Community security skill ecosystem comparison (2026-07)

> Source retrieval date: **2026-07-17**  
> Purpose: let reverse-skill **know what exists out there**, borrow as needed, and **not** merge external giant libraries wholesale into this package.  
> This package's identity: routing + tool bootstrap + evidence/scope contract + field-journal (see `ops/IDENTITY.md`).

## 1. External high-value repositories (learn from, don't blindly install)

| Repository | Scale/positioning | Value to this package | Risk |
|------|-----------|------------|------|
| [trailofbits/skills](https://github.com/trailofbits/skills) | ToB security research Claude plugin marketplace | Quality benchmark for audit/vulnerability analysis/RE plugins | Install via the ToB marketplace; do not trust non-curated copies by default |
| [trailofbits/skills-curated](https://github.com/trailofbits/skills-curated) | Reviewed plugin list | Prefer over arbitrary community skills | Same as above |
| [Orizon-eu/claude-code-pentest](https://github.com/Orizon-eu/claude-code-pentest) | 6 pentest lifecycle skills + pure Python scripts | Recon→exploit→report pipeline can benchmark our `attack-chain`+`pentest-core` | Verify authorization boundaries yourself; scripts need a sandbox |
| [trilwu/secskills](https://github.com/trilwu/secskills) | 16 skills + 6 expert subagents | Multi-role division can benchmark `ops/role-map.md` | Plugin form, differs from this package's monorepo |
| [Masriyan/Claude-Code-CyberSecurity-Skill](https://github.com/Masriyan/Claude-Code-CyberSecurity-Skill) | ~15-19 domain skills (including RE/OT/CSOC) | Domain coverage checklists | Less depth than this package's single-domain skills |
| [mukul975/Anthropic-Cybersecurity-Skills](https://github.com/mukul975/Anthropic-Cybersecurity-Skills) | **800+** skills · ATT&CK/NIST mapping | **Framework mapping** and domain catalogs are worth referencing; not suitable as a whole-library dependency | Too large, huge maintenance and poisoning surface |
| [Eyadkelleh/awesome-skills-security](https://github.com/Eyadkelleh/awesome-claude-skills-security) | SecLists packaged as agent skills | Wordlist/payload entry point | Overlaps with seclists bootstrap |
| [securityfortech/awesome-security-skills](https://github.com/securityfortech/awesome-security-skills) | Curated list of security skills | Index for discovering new skills | List type, needs auditing one by one |
| [VoltAgent/awesome-agent-skills](https://github.com/VoltAgent/awesome-agent-skills) | 1000+ cross-vendor skill index | Discover official/community skills | Not security-specific |
| [anthropics/claude-code-security-review](https://github.com/anthropics/claude-code-security-review) | PR security review GitHub Action | Can benchmark our docs/report-side "change audit" scenario | A CI product, not RE routing |
| [agentskills.io](https://agentskills.io) | Agent Skills open standard | Align frontmatter/directory conventions | The standard itself has no offensive/defensive content |

### 1.1 Second-round retrieval additions (searched again 2026-07-17)

| Repository / resource | Positioning | Landing point in this package |
|-------------|------|----------|
| [trailofbits/skills](https://github.com/trailofbits/skills) plugins: `audit-context-building` `differential-review` `semgrep-rule-creator` `sharp-edges` `dwarf-expert` `burpsuite-project-parser` | Audit context, differential security review, dangerous APIs, DWARF, Burp project parsing | Benchmark against `ida-reverse`/`task-report`/audit workflows; do **not** merge the whole library |
| [HexRaysSA/ida-claude-code-plugins](https://github.com/HexRaysSA/ida-claude-code-plugins) | Official IDA Claude plugins (including domain automation, marked unsafe) | Benchmark `ida-reverse` MCP path; unsafe plugins are disabled by default |
| [P4nda0s/reverse-skills](https://github.com/P4nda0s/reverse-skills) | IDA-NO-MCP: export decompilation then analyze; rev-frida/dex-dump/u3d | Complements "offline export when MCP is unavailable" |
| [2389-research/binary-re](https://github.com/2389-research/binary-re) | triage→static(r2/Ghidra)→dynamic(QEMU/GDB/Frida)→synthesis | See `re-agent-workflow.md` for the `reverse-engineering` stage gates |
| [incogbyte/android-reverse-engineering-claude-skill](https://github.com/incogbyte/android-reverse-engineering-claude-skill) | APK unpacking, endpoint extraction, adaptive Frida bypass | Benchmark against `apk-reverse`; dynamic scripts need scope |
| [OwenPawl/cerberus-re-skill](https://github.com/OwenPawl/cerberus-re-skill) | Apple-oriented Ghidra+LLDB+Frida triple loop | Reference for the macOS/iOS dynamic loop |
| [ljagiello/ctf-skills](https://github.com/ljagiello/ctf-skills) | CTF reverse/pwn; install tools as needed | Benchmark against CTF-Sandbox + `pwn-chain` |
| [shuvonsec/claude-bug-bounty](https://github.com/shuvonsec/claude-bug-bounty) | /recon→/hunt→/validate→/report | Benchmark against `task-recon/SKILL.md` + scope gate |
| [PayloadsAllTheThings](https://github.com/swisskyrepo/PayloadsAllTheThings) | Web payload + Prompt Injection chapters | Prefer `src-hunter/references/payloader`; for LLM see `llm-security` |
| [HackTricks](https://hacktricks.wiki/) | Pentest methodology + **AI/MCP abuse** | See the MCP section of skill-supply-chain |
| [appsecsanta AI pentesting agents 2026](https://appsecsanta.com/research/ai-pentesting-agents-2026) | Architecture taxonomy of 39+ open-source AI pentest agents | Multiple agents ≠ mandatory; we use role-map |
| Snyk evaluation "more skills ≠ better" | Skill stacking can degrade audit quality | Reinforce the "deep skill + routing" strategy |

## 2. Security standards and threats (2025–2026)

| Source | Key points | Landing point in this package |
|------|------|----------|
| [OWASP Agentic Skills Top 10](https://owasp.org/www-project-agentic-skills-top-10/) | Malicious skills, supply chain, privilege abuse, memory poisoning, etc. | `ops/skill-supply-chain.md` |
| [Anthropic Agent Skills engineering article](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills) | Only install trusted sources; audit scripts and dependencies | Same as above + bootstrap forbids guessing paths |
| Poisoning campaigns such as ClawHavoc (recorded in AST10) | Batch malicious skills in registries | Forbid one-click installation from unknown registries into this package |

## 3. What this package has vs external "broad" coverage

| Domain | reverse-skill | Why external packages often have it but we don't merge the whole library |
|------|---------------|--------------------------------|
| APK/JS/IDA/r2/firmware/pwn | **Deep** skills + scripts | Maintain depth and tool-index binding |
| Pentest/attack chain/SRC | pentest-core + attack-chain + src-hunter | Orizon-like packages can serve as methodology comparisons |
| LLM/Agent security | llm-security | AST10 enhances the security of the skills themselves |
| Evidence/scope/roles | **ops/** (distinctive) | Most skill packages have no case contract |
| OT/ICS / pure GRC / fraud F3 | No dedicated skill | Routing miss → propose a new one or link externally, don't force it in |
| 800+ micro-skills | Not copied | Use MASTER routing + domain skills instead of fragmentation |

## 4. Borrowing rules (MUST)

```text
1. Forbidden to pull a whole library of 800+ skills via git submodule as a runtime dependency
2. When borrowing: extract "stage/checklist/command patterns" into this package's references or existing skills
3. External scripts: inspect dependencies and network behavior in an isolated environment first, then consider bootstrap-manifest
4. New scenarios: add a skill via CONTRIBUTING, and update routing + RULES keywords
5. Cite the source URL + retrieval date (this file's format)
6. Run the ops/skill-supply-chain.md checklist before install/merge
7. At runtime load only MASTER-ROUTING's PRIMARY (+ necessary secondary), to avoid skill stacking overload
```

## 4.1 "Borrowed artifacts" already distilled in this package (not external dependencies)

| Artifact | Path |
|------|------|
| RE four stages | `reverse-engineering/references/re-agent-workflow.md` |
| Authorized reconnaissance | `task-recon/SKILL.md` |
| Attack chain gates | `attack-chain/references/lifecycle-checklist.md` |
| Skill supply chain | `ops/skill-supply-chain.md` |
| Domain coverage | `references/domain-coverage-map.md` |

## 5. Suggested priorities (future iterations)

| Priority | Action |
|--------|------|
| P0 done | ops contract, MASTER routing, skill supply chain security doc |
| P1 | Add pentest stage checklists to attack-chain references, benchmarking Orizon/ToB |
| P2 | Optional "external skill whitelist" configuration, not on the default path |
