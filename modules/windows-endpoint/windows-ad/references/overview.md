
# Windows / Active Directory Security

## Applicable Scenarios

- Domain penetration, Kerberoasting, AS-REP, delegation
- AD CS (ESC1–ESC8, etc.) certificate attacks
- BloodHound / SharpHound attack paths
- NTLM Relay / Coercer forced authentication
- Local privilege escalation to domain paths (Potato, etc. as a stepping stone)

## Relationship with attack-chain

- **Multi-stage from external network to domain controller** → PRIMARY can still be `attack-chain/`; this skill is the **AD specialty**
- **Already inside the domain, focused on identity** → PRIMARY = this skill

## Workflow

### 1. Enumeration

```bash
# Example Impacket / built-in (requires credentials and authorization)
nxc smb <range> -u user -p pass
bloodhound-python -d domain.local -u user -p pass -c All -ns <DC>
```

### 2. Common paths (map first, then exploit)

```text
□ Kerberoast / AS-REP → offline cracking
□ ACL abuse (GenericAll/WriteDacl)
□ Delegation (unconstrained/constrained/resource-based)
□ AD CS template misconfiguration → Certipy
□ Relay: LLMNR/NBT-NS + ntlmrelayx (confirm authorization)
```

### 3. Credentials and lateral movement

```text
□ secretsdump / lsassy / mimikatz (strict authorization and cleanup)
□ PtH / PtT / golden ticket only within authorized red-team scope
□ Write Evidence at every step; await user confirmation for high-risk actions
```

## Toolchain

| Tool | Purpose |
|------|------|
| BloodHound / SharpHound | Path graph |
| Certipy | AD CS |
| Impacket / NetExec | Lateral movement and enumeration |
| Rubeus / Mimikatz | Tickets and credentials (authorized) |
| Coercer / Responder | Forced authentication / poisoning |

## References

- `ad-attack-paths.md`
- `network-attack-defense.md`
- `the `attack-chain` skill`
- seeds: `field-journal/seed-005_ad-certipy-esc1.md` seed-007_ntlm-relay-coercer.md seed-013_kerberoasting-spn.md

## Routing Context

**Upstream**: MASTER R24
**Downstream**: report via `task-report`; for EDR research use `edr-bypass-re`
**MUST NOT**: DCSync / golden ticket against production without authorization
