# Community Security Skill Ecosystem Comparison (2026-07)

> Source retrieval date: **2026-07-17**  
> Purpose: let reverse-skill **know what exists out there**, borrow as needed, and **not** pull entire giant external libraries into this package.  
> This package's identity: routing + tool bootstrap + evidence/scope contract + field-journal (see `ops/IDENTITY.md`).

## 1. High-value external repositories (learnable, do not install blindly)

| Repository | Scale/positioning | Value to this package | Risk |
|------|-----------|------------|------|
| [trailofbits/skills](https://github.com/trailofbits/skills) | ToB security research Claude plugin marketplace | Quality benchmark for audit/vulnerability analysis/RE plugins | Must install via the ToB marketplace; do not trust non-curated copies by default |
| [trailofbits/skills-curated](https://github.com/trailofbits/skills-curated) | Reviewed plugin list | Prefer over arbitrary community skills | Same as above |
| [Orizon-eu/claude-code-pentest](https://github.com/Orizon-eu/claude-code-pentest) | 6 pentest lifecycle skills + pure Python scripts | Recon→exploit→report pipeline can be benchmarked against our `attack-chain`+`pentest-core` | Verify authorization boundaries yourself; scripts need a sandbox |
| [trilwu/secskills](https://github.com/trilwu/secskills) | 16 skills + 6 expert subagents | Multi-role division can be benchmarked against `ops/role-map.md` | Plugin form, different from this package's monorepo |
| [Masriyan/Claude-Code-CyberSecurity-Skill](https://github.com/Masriyan/Claude-Code-CyberSecurity-Skill) | ~15–19 domain skills (including RE/OT/CSOC) | Domain coverage checklist | Less depth than this package's per-domain skills |
| [mukul975/Anthropic-Cybersecurity-Skills](https://github.com/mukul975/Anthropic-Cybersecurity-Skills) | **800+** skills · ATT&CK/NIST mapping | **Framework mapping** and domain catalog are useful references, but not as a whole-library dependency | Too large; huge maintenance and poisoning surface |
| [Eyadkelleh/awesome-skills-security](https://github.com/Eyadkelleh/awesome-claude-skills-security) | SecLists packaged as agent skills | Wordlist/payload entry point | Overlaps with the seclists bootstrap |
| [securityfortech/awesome-security-skills](https://github.com/securityfortech/awesome-security-skills) | Curated list of security skills | Index for discovering new skills | List-type; needs per-item auditing |
| [VoltAgent/awesome-agent-skills](https://github.com/VoltAgent/awesome-agent-skills) | 1000+ cross-vendor skill index | Discover official/community skills | Not security-specific |
| [anthropics/claude-code-security-review](https://github.com/anthropics/claude-code-security-review) | PR security review GitHub Action | Can be benchmarked against our docs/report-side "change audit" scenario | A CI product, not RE routing |
| [agentskills.io](https://agentskills.io) | Agent Skills open standard | Align frontmatter/directory conventions | The standard itself has no offensive/defensive content |

### 1.1 Second-round search additions (2026-07-17 re-search)

| Repository / resource | Positioning | Placement in this package |
|-------------|------|----------|
| [trailofbits/skills](https://github.com/trailofbits/skills) plugins: `audit-context-building` `differential-review` `semgrep-rule-creator` `sharp-edges` `dwarf-expert` `burpsuite-project-parser` | Audit context, differential security review, dangerous APIs, DWARF, Burp project parsing | Compare with `ida-reverse`/`task-report`/audit workflows; do **not** merge the whole library |
| [HexRaysSA/ida-claude-code-plugins](https://github.com/HexRaysSA/ida-claude-code-plugins) | Official IDA Claude plugins (including domain automation, marked unsafe) | Compare with the `ida-reverse` MCP path; unsafe plugins are disabled by default |
| [P4nda0s/reverse-skills](https://github.com/P4nda0s/reverse-skills) | IDA-NO-MCP: export decompilation then analyze; rev-frida/dex-dump/u3d | Complements "offline export when MCP is unavailable" |
| [2389-research/binary-re](https://github.com/2389-research/binary-re) | triage→static(r2/Ghidra)→dynamic(QEMU/GDB/Frida)→synthesis | `reverse-engineering` phase gate, see `re-agent-workflow.md` |
| [incogbyte/android-reverse-engineering-claude-skill](https://github.com/incogbyte/android-reverse-engineering-claude-skill) | APK unpacking, endpoint extraction, adaptive Frida bypass | Compare with `apk-reverse`; dynamic scripts require scope |
| [OwenPawl/cerberus-re-skill](https://github.com/OwenPawl/cerberus-re-skill) | Apple-oriented Ghidra+LLDB+Frida three-loop | Can reference the macOS/iOS dynamic loop |
| [ljagiello/ctf-skills](https://github.com/ljagiello/ctf-skills) | CTF reverse/pwn; tools installed on demand | Compare with CTF-Sandbox + `pwn-chain` |
| [shuvonsec/claude-bug-bounty](https://github.com/shuvonsec/claude-bug-bounty) | /recon→/hunt→/validate→/report | Compare with `task-recon/SKILL.md` + scope gate |
| [PayloadsAllTheThings](https://github.com/swisskyrepo/PayloadsAllTheThings) | Web payloads + Prompt Injection chapter | Prefer `src-hunter/references/payloader`; for LLM see `llm-security` |
| [HackTricks](https://hacktricks.wiki/) | Pentest methodology + **AI/MCP abuse** | See the MCP section of skill-supply-chain |
| [appsecsanta AI pentesting agents 2026](https://appsecsanta.com/research/ai-pentesting-agents-2026) | Architecture classification of 39+ open-source AI pentest agents | Multiple agents ≠ mandatory; we use role-map |
| Snyk's evaluation "more skills ≠ better" | Skill stacking may reduce audit quality | Reinforces the "deep skill + routing" strategy |

## 2. Security standards and threats (2025–2026)

| Source | Key points | Placement in this package |
|------|------|----------|
| [OWASP Agentic Skills Top 10](https://owasp.org/www-project-agentic-skills-top-10/) | Malicious skills, supply chain, privilege abuse, memory poisoning, etc. | `ops/skill-supply-chain.md` |
| [Anthropic Agent Skills engineering article](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills) | Install only trusted sources; review scripts and dependencies | Same as above + bootstrap forbids guessing paths |
| ClawHavoc and other poisoning campaigns (documented in AST10) | Batch malicious skills in registries | Forbid one-click installation into this package from an unknown registry |

## 3. This package's existing vs. external "broad" coverage

| Domain | reverse-skill | Why external packages often have it but we don't merge the whole library |
|------|---------------|--------------------------------|
| APK/JS/IDA/r2/firmware/pwn | **Deep** skill + scripts | Maintain depth and tool-index binding |
| Pentest/attack chain/SRC | pentest-core + attack-chain + src-hunter | Orizon-like projects can serve as methodology references |
| LLM/Agent security | llm-security | AST10 enhances the skill's own security |
| Evidence/scope/roles | **ops/** (a feature) | Most skill packages have no case contract |
| OT/ICS / pure GRC / fraud F3 | No standalone skill | If routing finds no match → propose a new one or link externally; do not force-fit |
| 800+ micro-skills | Not copied | Replace fragmentation with MASTER routing + domain skills |

## 4. Borrowing rules (MUST)

```text
1. Forbid pulling an entire 800+ skill library via git submodule as a runtime dependency
2. When borrowing: extract "phase/checklist/command patterns" into this package's references or existing skills
3. External scripts: first inspect dependencies and network behavior in an isolated environment, then consider bootstrap-manifest
4. New scenario: add a skill via CONTRIBUTING, and update routing + RULES keywords
5. Annotate source URL + retrieval date (this file's format)
6. Before installing/merging, go through the ops/skill-supply-chain.md checklist
7. At runtime load only MASTER-ROUTING's PRIMARY (+ necessary secondary) to avoid skill stacking overload
```

## 4.1 "Borrowing outputs" already settled in this package (not external library dependencies)

| Output | Path |
|------|------|
| Four RE phases | `reverse-engineering/references/re-agent-workflow.md` |
| Authorized recon | `task-recon/SKILL.md` |
| Attack chain gate | `attack-chain/references/lifecycle-checklist.md` |
| Skill supply chain | `ops/skill-supply-chain.md` |
| Domain coverage | `references/domain-coverage-map.md` |

## 5. Suggested priorities (future iterations)

| Priority | Action |
|--------|------|
| P0 done | ops contract, MASTER routing, skill supply-chain security documentation |
| P1 | Compare against Orizon/ToB to add pentest phase checklists to attack-chain references |
| P2 | Optional "external skill allowlist" configuration, not on the default path |
