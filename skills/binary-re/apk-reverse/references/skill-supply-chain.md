# Agent Skill Supply Chain Security (this package's specialty)

> Synthesized from: OWASP Agentic Skills Top 10 (AST10), Anthropic Agent Skills security recommendations, and public poisoning incidents (e.g. ClawHavoc, see the AST10 timeline)  
> Retrieval date: 2026-07-17  
> Applies to: installing/writing/merging **any** skill, MCP, or bootstrap script

Static audit of this package's **executable script surface** (backdoors / database deletion / pipe execution): [`docs/PACKAGE-SECURITY-AUDIT.md`](../../docs/PACKAGE-SECURITY-AUDIT.md).

## 1. Why reverse-skill Manages This Separately

This package will:

- Guide the AI to **execute commands and bootstrap downloads**
- Reach local and network resources via MCP  
- Write field-journal / reports  

Malicious skills can lead to: credential theft, prompt persistence, supply chain backdoors.  
We use **document gates + a tool source of truth**, rather than building another skill app store.

## 2. Threat Mapping (condensed AST10 approach)

| Risk class | Manifestation | Control in this package |
|--------|------|----------|
| Malicious/poisoned skills | Induce exfil, write memory/backdoors | Trust only this repo + external sources the user has authorized in writing; for external sources, first read SKILL.md and scripts manually |
| Excessive privileges | Indiscriminate `curl \| bash`, full-disk reads | Bootstrap limited to manifest capabilities; scope `network_profile` |
| Dependency poisoning | Malicious pip/npm packages | Prefer official releases; record versions in tool-index |
| Blind trust in MCP | Unaudited MCP servers | tool-index registration status + port probing; do not trust remote MCP by default |
| Poisoning via MCP/CLI auto-execution | Repo `.env` changing `CODEX_HOME`, etc., causing a malicious MCP to run on startup (HackTricks / CVE-type cases) | Do not trust default MCP configuration inside a repo; check env and the MCP list before starting the Agent |
| Prompt injection into skills | Hidden instructions in SKILL body text | Review diffs; forbid "execution instructions hidden in HTML comments" without user consent |
| Scope drift | Skills inducing broader scanning / "fully automatically pwn a whole domain" | ops/scope-contract: out_of_scope + auth; forbid indiscriminate scanning without in_scope |
| Skill stacking overload | Mounting too many skills at once causes missed findings (observed in public evaluations) | Load only PRIMARY + necessary secondary (MASTER-ROUTING) |

## 3. MUST Checklist for Installing External Skills

```text
□ Source: official org / audited list (e.g. ToB curated) / user-owned
□ Read all SKILL.md + scripts/* + package dependencies
□ No mysterious outbound connections, no default steps that read ~/.ssh / browser databases
□ On conflict with this package's routing: this package's MASTER-ROUTING + scope take precedence
□ Do not copy into the monorepo unless going through CONTRIBUTING and sanitization
□ Update skills/references/community-security-skills.md to record the source date
```

## 4. Boundaries with bootstrap / MCP

| Action | Allowed | Forbidden |
|------|------|------|
| `bootstrap-reverse.ps1 -Capability X` | X ∈ bootstrap-manifest.json | Arbitrary new name without changing the manifest |
| Register MCP | User confirmation + tool-index refresh | Silently writing a global MCP pointing at an unknown URL |
| Run community one-click Python pentest | Authorized lab + after reading the source | Directly against production targets + unknown scripts |

## 5. This Package's Authors/Contributors

- New skill: CONTRIBUTING + ACTION REQUIRED + completing self-checks  
- Citing community content: annotate URL + date (this file / community-security-skills.md)  
- On suspicious behavior: stop execution, inform the user, do not automatically "try to bypass"

## 6. Quick Self-check (before every merge of external material)

```powershell
# List the script extensions about to be introduced
Get-ChildItem -Recurse -Include *.ps1,*.sh,*.py,*.js | Select-Object FullName
# Rough search for dangerous patterns (manual review, not exhaustive)
# Run in the external directory: Select-String -Pattern 'Invoke-WebRequest|curl .\||wget .\||~/.ssh|exfil'
```

## 7. Related

- Identity: `IDENTITY.md`  
- External catalogue: `../references/community-security-skills.md`  
- Authorization: `scope-contract.md` + `field-journal/precedent-auth.md`  
