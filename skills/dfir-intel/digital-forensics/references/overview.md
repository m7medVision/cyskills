
# Digital Forensics & IR Artifacts

## Use cases

- Memory dump analysis (Volatility 2/3)
- Disk / E01 / dropped-file timelines
- PCAP tracing and protocol reconstruction (can combine with `protocol-reverse/`)
- Host artifacts: Prefetch, Shimcache, Event Log, browser history
- Incident response IOC extraction (combine with `malware-analysis/` / `threat-hunting/`)

## Workflow

### 1. Preservation

```text
□ Compute SHA256; record timezone and acquisition command
□ Work on copies; keep originals read-only
□ Write chain of custody notes into the timeline
```

### 2. Memory

```bash
vol -f mem.dmp windows.info
vol -f mem.dmp windows.pslist
vol -f mem.dmp windows.netscan
vol -f mem.dmp windows.cmdline
```

### 3. Host artifacts

```text
□ Event logs: Security / PowerShell / Sysmon
□ Persistence: Run keys, services, scheduled tasks, WMI
□ Execution traces: Amcache, Prefetch, BAM
```

### 4. Network

```text
□ tshark session and DNS statistics
□ Export suspicious streams → protocol-reverse or malware C2 analysis
```

## Toolchain

| Tool | Purpose |
|------|---------|
| Volatility 3 | Memory |
| Timeline Explorer / Plaso | Super timeline |
| tshark | PCAP |
| Eric Zimmerman tools | Windows artifacts |
| Autopsy / FTK Imager | Disk |

## References

- `forensics-triage.md`
- `the `malware-analysis` skill` `the `threat-hunting` skill` `the `protocol-reverse` skill`

## Routing context

**Upstream**: MASTER R25
**Downstream**: Malware deep dive → malware-analysis; rules → threat-hunting
