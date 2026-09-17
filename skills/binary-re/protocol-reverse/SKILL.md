---
name: protocol-reverse
description: "Use for authorized reverse engineering of custom binary protocols, Protobuf/gRPC, WebSocket frames, and PCAP-driven protocol recovery."
---

# Protocol Reverse Engineering

## Workflow

1. Phase 1 — 采集与分诊
2. Phase 2 — 帧布局还原
3. Phase 3 — 序列化与加密
4. Phase 4 — 产物

## References

- `references/custom-protocol-replay.md`
- `references/overview.md`
- `references/protocol-workflow.md`

## Before you start

- Confirm authorization scope via `step-cyskills` (`scope.md`); do not act outside it.
- Verify tools first; `step-cyskills` preflight reports missing tools with distro install commands.
