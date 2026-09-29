# Agent Skill Supply-Chain Security (a feature of this package)

> Source synthesis: OWASP Agentic Skills Top 10 (AST10), Anthropic Agent Skills security guidance, public poisoning incidents (e.g. ClawHavoc, see the AST10 timeline)  
> Retrieval date: 2026-07-17  
> Applies to: installing/writing/merging **any** skill, MCP, or bootstrap script

Static audit of this package's **executable script surface** (backdoors / data wipes / pipe execution): [`docs/PACKAGE-SECURITY-AUDIT.md`](../../docs/PACKAGE-SECURITY-AUDIT.md).

## 1. Why reverse-skill manages this separately

This package will:

- Direct the AI to **execute commands and bootstrap downloads**
- Touch local and network resources through MCP  
- Write field-journal / reports  

A malicious skill can cause: credential theft, persistent prompts, supply-chain backdoors.  
We use a **documentation gate + tool source of truth** instead of building yet another skill app store.

## 2. Threat mapping (a condensed AST10 view)

| Risk class | Manifestation | Controls in this package |
|--------|------|----------|
| Malicious/poisoned skill | Induces exfil, writes memory/backdoors | Trust only this repo + external sources with written user authorization; for external sources, first manually read SKILL.md and scripts |
| Excessive permissions | Indiscriminate `curl \| bash`, full-disk reads | bootstrap only manifest capabilities; scope `network_profile` |
| Dependency poisoning | Malicious pip/npm packages | Prefer official releases; record versions in tool-index |
| Blind MCP trust | Unaudited MCP servers | tool-index registration status + port probing; do not trust remote MCP by default |
| MCP/CLI auto-execution poisoning | A repo `.env` changing `CODEX_HOME` etc. causing a malicious MCP to run at startup (HackTricks / CVE-class cases) | Do not trust in-repo default MCP config; inspect env and the MCP list before starting the Agent |
| Prompt injection into a skill | Hidden instructions in SKILL body | Review the diff; forbid "execution instructions hidden in HTML comments" without user awareness |
| Scope drift | Skill induces a broader scan / "auto-pwn a whole domain" | ops/scope-contract: out_of_scope + auth; forbid aggressive scanning without in_scope |
| Skill stacking overload | Mounting too many skills at once causes missed findings (observed in public evaluations) | Load only PRIMARY + necessary secondary (MASTER-ROUTING) |

## 3. MUST checklist for installing an external skill

```text
□ Source: official org / audited list (e.g. ToB curated) / user-owned
□ Read all SKILL.md + scripts/* + package dependencies
□ No mysterious outbound connections, no default step that reads ~/.ssh / browser stores
□ When conflicting with this package's routing: this package's MASTER-ROUTING + scope prevail
□ Do not copy into the monorepo unless it goes through CONTRIBUTING and sanitization
□ Update skills/references/community-security-skills.md with source and date
```

## 4. Boundaries with bootstrap / MCP

| Action | Allowed | Forbidden |
|------|------|------|
| `bootstrap-reverse.ps1 -Capability X` | X ∈ bootstrap-manifest.json | Any new name without changing the manifest |
| Registering MCP | User confirmation + tool-index refresh | Silently writing a global MCP pointing to an unknown URL |
| Running community one-click Python pentest | Authorized lab + after reading the source | Directly against production targets + unknown scripts |

## 5. Package authors/contributors

- New skill: CONTRIBUTING + ACTION REQUIRED + completed self-check  
- Citing community content: annotate URL + date (this file / community-security-skills.md)  
- Discovering suspicious behavior: stop execution, inform the user, do not automatically "try to bypass"

## 6. Quick self-check (before each merge of external material)

```powershell
# List the script extensions that will be introduced
Get-ChildItem -Recurse -Include *.ps1,*.sh,*.py,*.js | Select-Object FullName
# Rough search for dangerous patterns (manual review, not exhaustive)
# Run in the external directory: Select-String -Pattern 'Invoke-WebRequest|curl .\||wget .\||~/.ssh|exfil'
```

## 7. Related

- Identity: `IDENTITY.md`  
- External directory: `../references/community-security-skills.md`  
- Authorization: `scope-contract.md` + `field-journal/precedent-auth.md`  
