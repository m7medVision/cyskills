
# Threat Hunting & Detection Engineering

## Use cases

- Threat hunting (hypothesis-driven)
- Sigma / YARA detection engineering
- Alert tuning, false-positive analysis
- With `malware-analysis/`: sample-side IOC → detection codified by this skill
- With `digital-forensics/`: case artifacts → lateral hunting

## Workflow

### 1. Form a hypothesis

```text
Example: attacker uses living-off-the-land for lateral movement
→ Data sources: Sysmon 1/3/10, Windows Security 4624/4648
→ Success criterion: discover anomalous parent processes or rare account log sources
```

### 2. Query and stack

```text
□ Baseline: normal administrator behavior by time window and host
□ Anomalies: new services, encoded PowerShell, anomalous outbound
□ Correlation: same account logging into multiple hosts in a short time
```

### 3. Codify as rules

```yaml
# See malware-analysis for the Sigma skeleton; this skill emphasizes:
# - false-positive surface
# - data source field mapping
# - response playbook links
```

### 4. Validate

```text
□ Atomic tests (Atomic Red Team) only in authorized labs
□ Replay historical logs to validate recall
```

## Toolchain

| Tool | Purpose |
|------|---------|
| Sigma CLI / sigmac | Rule conversion |
| YARA | File/memory |
| SIEM (ELK/Splunk etc.) | Query |
| osquery | Endpoint hunting |
| Atomic Red Team | Detection validation (lab) |

## References

- `hunting-loop.md`
- `yara-sigma-rules.md`
- `the `digital-forensics` skill`

## Routing context

**Upstream**: MASTER R27
**Downstream**: Confirmed intrusion → forensics; malicious sample → malware-analysis
**MUST NOT**: Run attack simulations in an unauthorized production environment
