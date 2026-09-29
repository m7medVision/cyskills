
# OT / ICS Security

## When to use

- Industrial control/SCADA/DCS security assessment (authorized)
- Purdue model zoning and cross-zone conduits
- Exposure of Modbus/DNP3/S7/EtherNet/IP and similar protocols
- Engineering workstations, HMIs, historians, jump hosts
- IT/OT convergence boundary (firewall rules, data diodes)

## Safety rules (MUST)

```text
MUST NOT, without explicit permission:
- Write coils/registers to a PLC
- Scan production OT at a high rate across the whole network
- Interrupt paths related to the Safety Instrumented System (SIS)
Prefer: read-only identification, traffic mirroring, offline firmware/config analysis
```

## Workflow

### Phase 1 — Zoning and assets

```text
□ Purdue L0–L5 sketch: field devices → control → supervisory → site DMZ → enterprise
□ Asset inventory: PLC/RTU/HMI/engineering workstation/historian/jump host
□ Protocol and port baseline (authorized segments only)
```

### Phase 2 — Passive and read-only

```text
□ SPAN/mirrored PCAP → protocol-reverse / Wireshark ICS dissectors
□ Offline audit of configuration and project files (TIA/RSLogix exports, etc.)
□ Record default credentials and cleartext protocols (Modbus has no authentication) as Findings; do not write to disk or change values
```

### Phase 3 — Restricted active (authorized only)

```text
□ Low-rate identification, during a maintenance window
□ Prefer read-only function codes
□ Evidence for every step; stop and report immediately on any anomaly
```

### Phase 4 — Firmware/patch surface

```text
□ Controller firmware version → CVE mapping (do not blindly flash firmware)
□ Combine with firmware-pentest for offline image analysis
```

## Toolchain

| Tool | Purpose | Note |
|------|---------|------|
| Wireshark ICS dissectors | Passive parsing | Mirrored traffic |
| Nmap NSE (restricted) | Identification | Rate and time window |
| Claroty/Nozomi etc. | Asset discovery | Commercial/on-site |
| PLC vendor engineering software | Config audit | Offline first |
| binwalk / Ghidra | Firmware | Offline |

## References

- `ot-safe-assessment.md`
- `the `firmware-pentest` skill` `the `protocol-reverse` skill` `../network` via pentest-core

## Routing context

**Upstream**: MASTER R28  
**Downstream**: firmware deep dive `firmware-pentest`; protocols `protocol-reverse`; IT lateral movement `windows-ad`/`attack-chain`  
**Peer**: do not use ordinary web scanners with default parameters against OT
