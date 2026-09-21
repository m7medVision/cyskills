# General Scope Contract (hard gate at task start)

> **MUST**: Any security/reverse-engineering/pentest task must land `scope.md` under the current user analysis project's `work/<case>/` **before ACT**.
> No scope → only reading documentation/routing is allowed; **prohibited** to actively scan, Hook, or exploit the target.
> Templates are copyable; keep field names as English keys for script validation.

## How to initialize

Windows:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File skills\scripts\case-init.ps1 -Hint "<one-sentence task>" -CaseName "my-case"
# Default output: work/<case>/scope.md etc. in the current analysis project
# When invoking the skill from another directory, specify explicitly: -ProjectRoot "C:\path\to\analysis-project"

# Legal local offline sample: auth granted + offline + explicit sample → ready_for_act=true
powershell -NoProfile -ExecutionPolicy Bypass -File skills\scripts\case-init.ps1 `
  -Hint "offline apk" -CaseName "my-sample" -Preset offline-sample -Sample ".\app.apk"
```

Linux / macOS / Kali:

```bash
bash skills/scripts/case-init.sh --hint "<one-sentence task>" --case-name "my-case"
# Default output: work/<case>/scope.md etc. in the caller's current analysis project
# When invoking from another directory, specify explicitly: --project-root "/path/to/analysis-project"

# Legal local offline sample
bash skills/scripts/case-init.sh \
  --hint "offline apk" --case-name "my-sample" \
  --preset offline-sample --sample ./app.apk
```

`-PackageRoot` / `--package-root` are kept as compatibility parameters; new flows should use `ProjectRoot` / `--project-root` to indicate the owning project of the case artifacts.

## Full scope.md template

```markdown
# Case Scope

## meta
- case_id: {YYYYMMDD-short}
- created: {ISO-8601}
- operator: {name or local}
- project_root: {caller analysis project}
- primary_skill: {from master-route}
- lead_role: lead   # see ops/role-map.md
- specialist_roles: []  # e.g. cie, cpe, cre

## auth
- status: granted | pending | denied
- basis: written_contract | bug_bounty_scope | ctf_public | own_system | lab_only
- evidence_of_auth: {ticket/path or "CTF public" or "owner-operated"}
- MUST NOT proceed if status != granted

## in_scope
- assets: []          # hosts, domains, APK paths, binaries, URLs
- surfaces: []        # web, mobile, binary, network, api
- activities: []      # recon, reverse, exploit_validate, report

## out_of_scope
- assets: []
- activities: []      # e.g. DoS, phishing real users, data exfil

## network_profile
- mode: offline | lab_only | authorized_target_only | unrestricted_lab
- notes: |
    offline = no outbound packets (pure static/local sample)
    lab_only = lab/VM IPs only
    authorized_target_only = in_scope assets only
- MUST NOT use unrestricted against production without written auth

## deliverables
- report: true
- field_journal: true
- diagrams: true
- timeline: true

## constraints
- timebox: {}
- stealth: low | medium | high
- data_handling: anonymize | no_user_pii

## signoff
- ready_for_act: false
- checklist:
  - [ ] auth.status = granted
  - [ ] in_scope.assets non-empty OR offline sample path set
  - [ ] network_profile.mode chosen
  - [ ] out_of_scope reviewed
```

## Routing hook (AI MUST execute)

```text
RULES / MASTER-ROUTING / SKILL:
  1) master-route → PRIMARY
  2) Platform-native case-init or hand-written scope.md
  3) auth not granted → STOP; only adding authorization material is allowed
  4) ready_for_act = true → open PRIMARY SKILL.md → ACT
```

`case-guard -Force` / `case-guard --force` are compatibility parameters and **must not** bypass the `auth.status`, legal scope, network profile, or `ready_for_act` hard gates.

## network_profile quick reference

| mode | Allowed | Prohibited |
|------|------|------|
| `offline` | Static analysis, local files, emulation | Any outbound connection, public-network RPC |
| `lab_only` | lab/CTF target network ranges | Production/unauthorized IPs |
| `authorized_target_only` | in_scope list | Assets outside the list |
| `unrestricted_lab` | Isolated experiment network (written) | Internet production |

## Characteristics

- Pure Markdown, **no database**
- Orthogonal to `tool-index` / bootstrap: scope governs "whether you may act", tool-index governs "what to act with"
