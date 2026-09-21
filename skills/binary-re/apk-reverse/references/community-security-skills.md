# Community Security Skill Ecosystem Comparison (2026-07)

> Source retrieval date: **2026-07-17**  
> Purpose: let reverse-skill **know what is out there**, borrow on demand, and **not** merge entire external giant repositories into this package.  
> Package identity: routing + tool bootstrap + evidence/scope contracts + field-journal (see `ops/IDENTITY.md`).

## 1. External High-value Repositories (worth learning from, do not install blindly)

| Repository | Scale/positioning | Value to this package | Risk |
|------|-----------|------------|------|
| [trailofbits/skills](https://github.com/trailofbits/skills) | ToB security research Claude plugin marketplace | Quality benchmark for audit/vuln analysis/RE plugins | Install via the ToB marketplace; do not trust non-curated copies by default |
| [trailofbits/skills-curated](https://github.com/trailofbits/skills-curated) | Reviewed plugin list | Prefer over arbitrary community skills | Same as above |
| [Orizon-eu/claude-code-pentest](https://github.com/Orizon-eu/claude-code-pentest) | 6 pentest lifecycle skills + pure Python scripts | Recon→exploit→report pipeline comparable to our `attack-chain`+`pentest-core` | Verify authorization boundaries yourself; scripts need sandboxing |
| [trilwu/secskills](https://github.com/trilwu/secskills) | 16 skills + 6 expert subagents | Multi-role division of labor comparable to `ops/role-map.md` | Plugin form, unlike this package's monorepo |
| [Masriyan/Claude-Code-CyberSecurity-Skill](https://github.com/Masriyan/Claude-Code-CyberSecurity-Skill) | ~15–19 domain skills (including RE/OT/CSOC) | Domain coverage checklist | Less depth than this package's single-domain skills |
| [mukul975/Anthropic-Cybersecurity-Skills](https://github.com/mukul975/Anthropic-Cybersecurity-Skills) | **800+** skills · ATT&CK/NIST mapping | **Framework mapping** and domain catalogue are worth referencing, but not as a whole-repo dependency | Too large; huge maintenance and poisoning surface |
| [Eyadkelleh/awesome-skills-security](https://github.com/Eyadkelleh/awesome-claude-skills-security) | SecLists packaged as agent skills | Wordlist/payload entry point | Overlaps with seclists bootstrap |
| [securityfortech/awesome-security-skills](https://github.com/securityfortech/awesome-security-skills) | Curated list of security skills | An index for discovering new skills | List-type; must audit one by one |
| [VoltAgent/awesome-agent-skills](https://github.com/VoltAgent/awesome-agent-skills) | 1000+ cross-vendor skill index | Discover official/community skills | Not security-specific |
| [anthropics/claude-code-security-review](https://github.com/anthropics/claude-code-security-review) | PR security review GitHub Action | Comparable to our docs/report-side "change audit" scenario | A CI product, not RE routing |
| [agentskills.io](https://agentskills.io) | Agent Skills open standard | Alignment on frontmatter/directory conventions | The standard itself has no offensive/defensive content |

### 1.1 Second-round Search Additions (searched again on 2026-07-17)

| Repository / Resource | Positioning | Where it lands in this package |
|-------------|------|----------|
| [trailofbits/skills](https://github.com/trailofbits/skills) plugins: `audit-context-building` `differential-review` `semgrep-rule-creator` `sharp-edges` `dwarf-expert` `burpsuite-project-parser` | Audit context, differential security review, dangerous APIs, DWARF, Burp project parsing | Compare with `ida-reverse`/`task-report`/audit workflow; do **not** merge the whole repo |
| [HexRaysSA/ida-claude-code-plugins](https://github.com/HexRaysSA/ida-claude-code-plugins) | Official IDA Claude plugins (including domain automation, marked unsafe) | Compare with the `ida-reverse` MCP path; unsafe plugins are disabled by default |
| [P4nda0s/reverse-skills](https://github.com/P4nda0s/reverse-skills) | IDA-NO-MCP: export decompilation then analyze; rev-frida/dex-dump/u3d | Complements "offline export when MCP is unavailable" |
| [2389-research/binary-re](https://github.com/2389-research/binary-re) | triage→static(r2/Ghidra)→dynamic(QEMU/GDB/Frida)→synthesis | See `re-agent-workflow.md` for the `reverse-engineering` phase gate |
| [incogbyte/android-reverse-engineering-claude-skill](https://github.com/incogbyte/android-reverse-engineering-claude-skill) | APK unpacking, endpoint extraction, adaptive Frida bypass | Compare with `apk-reverse`; dynamic scripts need scope |
| [OwenPawl/cerberus-re-skill](https://github.com/OwenPawl/cerberus-re-skill) | Apple-oriented Ghidra+LLDB+Frida triple loop | Can reference for the macOS/iOS dynamic loop |
| [ljagiello/ctf-skills](https://github.com/ljagiello/ctf-skills) | CTF reverse/pwn; install tools on demand | Compare with CTF-Sandbox + `pwn-chain` |
| [shuvonsec/claude-bug-bounty](https://github.com/shuvonsec/claude-bug-bounty) | /recon→/hunt→/validate→/report | Compare with `task-recon/SKILL.md` + scope gate |
| [PayloadsAllTheThings](https://github.com/swisskyrepo/PayloadsAllTheThings) | Web payload + Prompt Injection chapter | Prefer `src-hunter/references/payloader`; for LLM see `llm-security` |
| [HackTricks](https://hacktricks.wiki/) | Pentest methodology + **AI/MCP abuse** | See the MCP section of skill-supply-chain |
| [appsecsanta AI pentesting agents 2026](https://appsecsanta.com/research/ai-pentesting-agents-2026) | 39+ open-source AI pentest agent architecture classification | Multi-agent ≠ mandatory; we use role-map |
| Snyk evaluation "more skills ≠ better" | Skill stacking may lower audit quality | Reinforces the "deep skills + routing" strategy |

## 2. Security Standards and Threats (2025–2026)

| Source | Key points | Where it lands in this package |
|------|------|----------|
| [OWASP Agentic Skills Top 10](https://owasp.org/www-project-agentic-skills-top-10/) | Malicious skills, supply chain, privilege abuse, memory poisoning, etc. | `ops/skill-supply-chain.md` |
| [Anthropic Agent Skills engineering article](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills) | Install only from trusted sources; review scripts and dependencies | Same as above + bootstrap must not guess paths |
| ClawHavoc and other poisoning campaigns (recorded in AST10) | Batch malicious skills in a registry | Forbid one-click installation from unknown registries into this package |

## 3. What This Package Already Has vs External "Broad" Coverage

| Domain | reverse-skill | Why external repos often have it and we do not merge the whole repo |
|------|---------------|--------------------------------|
| APK/JS/IDA/r2/firmware/pwn | **Deep** skills + scripts | Preserves depth and tool-index binding |
| Penetration/attack chain/SRC | pentest-core + attack-chain + src-hunter | Orizon-like projects serve as methodology references |
| LLM/Agent security | llm-security | AST10 enhances skill self-security |
| Evidence/scope/roles | **ops/** (distinctive) | Most skill packages have no case contracts |
| OT/ICS / pure GRC / fraud F3 | No standalone skill | Routing miss → propose a new one or link out, do not force-fit |
| 800+ micro skills | Do not copy | Use MASTER routing + domain skills instead of fragmentation |

## 4. Borrowing Rules (MUST)

```text
1. Do not use git submodule to pull an entire repo of 800+ skills as a runtime dependency
2. When borrowing: extract "phase/checklist/command patterns" and write them into this package's references or existing skills
3. External scripts: first inspect dependencies and network behavior in an isolated environment, then consider bootstrap-manifest
4. New scenarios: add a skill via CONTRIBUTING and update routing + RULES keywords
5. Annotate the source URL + retrieval date (this file's format)
6. Follow the ops/skill-supply-chain.md checklist before installing/merging
7. At runtime load only the PRIMARY from MASTER-ROUTING (+ necessary secondary) to avoid skill-stacking overload
```

## 4.1 "Borrowed Artifacts" Already Distilled in This Package (not external dependencies)

| Artifact | Path |
|------|------|
| RE four phases | `reverse-engineering/references/re-agent-workflow.md` |
| Authorized reconnaissance | `task-recon/SKILL.md` |
| Attack chain gate | `attack-chain/references/lifecycle-checklist.md` |
| Skill supply chain | `ops/skill-supply-chain.md` |
| Domain coverage | `references/domain-coverage-map.md` |

## 5. Suggested Priorities (future iterations)

| Priority | Action |
|--------|------|
| P0 done | ops contracts, MASTER routing, skill supply chain security docs |
| P1 | Add pentest phase checklists to attack-chain references, referencing Orizon/ToB |
| P2 | Optional "external skill allowlist" configuration, not in the default path |
