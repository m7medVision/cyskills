
# Cloud / Container / Kubernetes Security

## Applicable scenarios

- Cloud metadata SSRF (169.254.169.254 / IMDS)
- IAM excessive permissions, public storage buckets, misconfigured security groups
- Docker/containerd escape path assessment
- Kubernetes RBAC, Secrets, Admission, supply-chain images
- Container image vulnerabilities (can integrate with `task-supply-chain/`)

## Workflow

### Phase 1 — Identity and boundaries

```text
□ Current identity: cloud AK/SK, K8s SA, node SSH?
□ Scope: single account / single cluster / single namespace
□ Network profile: authorized_target_only
```

### Phase 2 — Cloud control plane

```bash
# Example (replace per vendor; MUST stay within the authorized account)
aws sts get-caller-identity
aws s3 ls
# Corresponding identity commands for Azure / GCP
```

```text
□ Public buckets / wrong ACLs
□ Metadata: IMDSv1 vs v2; SSRF chain
□ Roles assumable (PassRole) and lateral movement
```

### Phase 3 — Containers

```text
□ privileged / hostPath / hostNetwork?
□ capabilities (SYS_ADMIN, etc.)
□ Writable host paths → escape candidates
□ Image history and known CVEs → Trivy
```

### Phase 4 — Kubernetes

```bash
kubectl auth can-i --list
kubectl get pods,secrets,svc -A
kubectl get clusterrolebindings
```

```text
□ SA token mounting and permissions
□ Missing dangerous admission webhooks
□ etcd / dashboard exposure
□ Whether network policies default to allow
```

## Toolchain

| Tool | Purpose | Bootstrap |
|------|---------|-----------|
| kubectl | Cluster interaction | Manual |
| trivy | Images/IaC | bootstrap `trivy` if available |
| kube-bench / kubeaudit | CIS/configuration | Manual |
| pacu / scoutsuite | Cloud audit (authorized) | Manual |
| nuclei | Known cloud vulnerability templates | bootstrap nmap/nuclei ecosystem |

## References

- `k8s-cloud-checklist.md`
- `the `task-supply-chain` skill` `the `pentest-core` skill`

## Routing context

**Upstream**: MASTER R23  
**Downstream**: get a node shell → `attack-chain` / `windows-ad`; image vulnerabilities → supply-chain  
**MUST NOT**: scan other tenants of a public cloud without authorization
