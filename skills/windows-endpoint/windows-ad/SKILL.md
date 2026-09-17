---
name: windows-ad
description: "Use for authorized Active Directory and Windows identity attacks including Kerberos, AD CS, BloodHound paths, NTLM relay, and domain privilege escalation research."
---

# Windows / Active Directory Security

## Workflow

1. 枚举
2. 常见路径（先图后枪）
3. 凭证与横向

## References

- `references/ad-attack-paths.md`
- `references/ad-certificate-abuse.md`
- `references/dpapi-credential-chain.md`
- `references/identity-windows.md`
- `references/kerberos-delegation.md`
- `references/lsass-ticket-material.md`
- `references/network-attack-defense.md`
- `references/overview.md`
- `references/relay-coercion-chain.md`
- `references/windows-pivot.md`

## Before you start

- Confirm authorization scope via `step-cyskills` (`scope.md`); do not act outside it.
- Verify tools first; `step-cyskills` preflight reports missing tools with distro install commands.
