---
name: cloud-k8s
description: "Use for authorized cloud, container, and Kubernetes security assessment including metadata SSRF, IAM misconfig, container escape paths, and cluster RBAC review."
---

# Cloud / Container / Kubernetes Security

## Workflow

1. Phase 1 — Identity and boundaries
2. Phase 2 — Cloud control plane
3. Phase 3 — Containers
4. Phase 4 — Kubernetes

## References

- `references/cloud-metadata-path.md`
- `references/container-runtime.md`
- `references/k8s-cloud-checklist.md`
- `references/k8s-control-plane.md`
- `references/kernel-container-escape.md`
- `references/overview.md`

## Before you start

- Confirm authorization scope via `step-cyskills` (`scope.md`); do not act outside it.
- Verify tools first; `step-cyskills` preflight reports missing tools with distro install commands.
