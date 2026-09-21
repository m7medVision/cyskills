
# RF / SDR Security Research

## When to use

- Non-Wi-Fi RF such as wireless remotes/sensors (authorized)
- Protocol research such as ADS-B/remote control (lawful reception)
- Division of labor with task-wifi-assessment: this skill covers **SDR general RF**; Wi-Fi offense/defense goes to R29

## Workflow

```text
□ Confirm regulations and licensing
□ Receive only: identify center frequency and modulation
□ GNU Radio / URH analysis
□ Replay only in a shielded room and with written permission
□ Conclusion focuses on: whether unauthorized control is possible / hardening recommendations
```

## Toolchain

| Tool | Purpose |
|------|---------|
| RTL-SDR / HackRF (compliant) | Transmit/receive hardware |
| URH / GNU Radio | Analysis |
| Inspectrum | Signals |

## References

- `sdr-lab-rules.md`
- `the `task-wifi-assessment` skill` `the `ot-ics` skill` `the `hardware-security` skill`

## Routing context

**Upstream**: MASTER R38  
**MUST NOT**: interfere with public communications, transmit without authorization
