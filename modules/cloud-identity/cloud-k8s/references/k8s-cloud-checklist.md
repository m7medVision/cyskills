# Cloud / K8s Checklist (condensed)

## IMDS
- [ ] Is SSRF able to reach 169.254.169.254
- [ ] Is IMDSv2 enforced
- [ ] Permission surface of the returned IAM role

## K8s high risk
- [ ] cluster-admin bound too broadly
- [ ] secrets exposed as plaintext environment variables
- [ ] privileged + hostPID/hostPath combination
- [ ] anonymous auth / insecure apiserver port

## Containers
- [ ] running as root
- [ ] can load kernel modules / docker.sock mounted
