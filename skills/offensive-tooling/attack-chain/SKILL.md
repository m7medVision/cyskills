---
name: attack-chain
description: "Use for authorized multi-stage attack-path planning and orchestration when a task spans reconnaissance, initial access, privilege escalation, lateral movement, or impact assessment. Route single-stage tasks directly to their specialist skill."
---

# Attack Chain Orchestration Skill

## Workflow

1. 1 企业数字资产测绘
2. 2 敏感信息泄露狩猎
3. 3 员工信息画像
4. 4 技术栈指纹识别
5. 1 Web 漏洞利用（高频突破点）
6. 2 供应链攻击
7. 3 钓鱼攻击
8. 4 近源渗透（Physical Access）
9. 5 VPN/远程接入突破
10. 6 云服务突破
11. 1 Windows 提权
12. 2 Linux 提权
13. 3 数据库提权
14. 4 云权限提升
15. 1 凭据获取

## References

- `references/attack-playbooks.md`
- `references/evasion-cheatsheet.md`
- `references/lifecycle-checklist.md`
- `references/linux-credential-pivot.md`
- `references/overview.md`
- `references/role-map.md`
- `references/scope-contract.md`
- `references/timeline-workitem.md`

## Before you start

- Confirm authorization scope via `step-cyskills` (`scope.md`); do not act outside it.
- Verify tools first; `step-cyskills` preflight reports missing tools with distro install commands.
