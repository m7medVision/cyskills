
# Evidence Graph Review

Use this skill when a reverse engineering, forensics, CTF, or authorized security case needs a defensible handoff. It audits the existing `work/<case>/` package without changing the case or touching a target.

## Scope

This skill covers:

- Scope metadata and target-activity readiness
- Evidence record structure and reproducibility fields
- References from work items and timeline entries to Evidence
- Structured Findings and Paths in report Markdown
- Optional SHA-256 verification for case-local artifacts
- A Markdown or JSON review result for a report handoff

It MUST NOT perform reconnaissance, exploitation, dynamic instrumentation, or target changes. Those actions belong to the routed analysis skill and require the case scope gate.

## Tool dependencies

| Tool | Required | Purpose | Auto-bootstrap |
|------|----------|---------|---------------|
| Python 3.9+ | Yes | Runs the read-only case review script | No, use the platform Python installation |

No network access or third-party package is required.

## Workflow

### Phase 1: Intake

Run the review against the existing case directory:

```bash
python3 skills/case-review/scripts/review_case.py work/<case> --format markdown
```

Confirm that scope.md, timeline.md, workitems.md, and `evidence/` are present. A non-strict review reports scope warnings while a strict review treats warnings as handoff blockers.

## Suggested next steps (pick one number)

1. Fix the authorization, scope, or network_profile fields in scope.md
2. Continue checking the reproducible command and source of Evidence records
3. Export the current review result and attach it to a progress report
4. Switch to JSON output for CI or another review tool
5. Pause and first confirm the review scope

### Phase 2: Traceability

Review the checks for:

- Evidence IDs that do not exist
- Findings without `evidence_ids`
- Paths without an allowed `path_type` or Evidence reference
- Work items and timeline entries pointing to unknown Evidence
- Unlinked Evidence records
- Validated Findings with low confidence

An offline observation may use `repro_command: n/a` only when its `notes` field explicitly documents the offline limitation.

Use JSON when another tool needs stable fields:

```bash
python3 skills/case-review/scripts/review_case.py work/<case> --format json
```

## Suggested next steps (pick one number)

1. Write the missing Evidence and keep the original command
2. Bind candidate Findings to Evidence and re-review
3. Add P-id and Path steps for the call chain or attack chain
4. Generate a Markdown handoff summary
5. Switch back to the PRIMARY skill to continue analysis

### Phase 3: Fixity verification

When an Evidence record contains both `content_hash` and `artifact_path`, verify the case-local artifact:

```bash
python3 skills/case-review/scripts/review_case.py work/<case> --verify-hashes --strict
```

The script accepts `sha256:<64 hex characters>` and checks that the artifact remains inside the case root. A hash mismatch is a hard failure.

The PowerShell Evidence helper can record a hash while appending a record:

```powershell
powershell -File skills/scripts/append-evidence.ps1 -CaseRoot work\<case> -Id E-001 -Title "Sample hash" -ReproCommand "sha256sum evidence/sample.bin" -ArtifactPath "evidence\sample.bin"
```

## Suggested next steps (pick one number)

1. Fix the hash mismatch or replace the tainted working copy
2. Add SHA-256 and artifact_path for un-fixated original files
3. Continue into the report generation phase
4. Export the JSON result for CI storage
5. Pause and request manual review

### Phase 4: Handoff

Use strict mode before a final report or specialist handoff:

```bash
python3 skills/case-review/scripts/review_case.py work/<case> --strict --format markdown > work/<case>/report/case-review.md
```

The command is read-only with respect to the case unless shell redirection is explicitly used to save its output. The review is not legal advice and does not replace organizational evidence handling procedures.

## Suggested next steps (pick one number)

1. Hand the passing review result to `task-report/` to generate a formal report
2. Return to the PRIMARY skill to fill in new analysis evidence
3. Archive the Markdown and JSON review results
4. Pause and request manual review

## Language behavior contract

- Internal reasoning, tool selection, and phase control: English.
- User-visible messages, section labels, reports, and next-step menus: Chinese unless the user requests another language.
- Default bilingual labels place Chinese first and English second, separated by `/`.

## Bootstrap boundary

This skill has no third-party dependency. If Python 3 is unavailable, the only allowed recovery action is the repository bootstrap path when a Python capability is registered for the current platform. If no such capability is registered, stop and report the missing runtime. Do not guess executable paths, download packages, or perform a manual install from inside this skill.

## Routing context

**Upstream entry**: any reverse, forensics, CTF, or authorized security skill that has produced a case package.

**Downstream exit**: `task-report/` for a formal report, or the original PRIMARY skill when the graph is incomplete.

**Related modules**: `ops/evidence-finding-path.md`, `ops/timeline-workitem.md`, `digital-forensics/`, `reverse-engineering/`, and `task-report/`.

## References

- [NIST SP 800-86: Guide to Integrating Forensic Techniques into Incident Response](https://csrc.nist.gov/pubs/sp/800/86/final)
- [SWGDE Best Practices for Computer Forensic Acquisitions](https://www.swgde.org/documents/published-complete-listing/17-f-002-2-1/)
- [SWGDE Best Practices for Archiving Digital and Multimedia Evidence](https://www.swgde.org/documents/published-complete-listing/19-f-003-best-practices-for-archiving-digital-and-multimedia-evidence/)
