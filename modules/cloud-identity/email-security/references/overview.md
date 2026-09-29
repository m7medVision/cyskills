
# Email Security & Phishing Analysis

## Applicable scenarios

- Phishing email dissection and IOCs
- SPF/DKIM/DMARC configuration assessment
- BEC business email compromise patterns
- OAuth app phishing / mailbox token abuse (combined with llm/cloud identity)
- Security awareness exercise design (authorized)

## Workflow

```text
□ Full raw headers: Received chain, From/Return-Path consistency
□ SPF/DKIM/DMARC alignment results
□ URL sandbox and attachment static analysis (combined with malware-analysis)
□ Brand impersonation and reply-to address discrepancies
□ Tenant: anti-phishing policy, external tagging, MFA, OAuth app consent
```

## Toolchain

| Tool | Purpose |
|------|---------|
| Email client "view source" | Headers |
| dig/nslookup | SPF/DMARC records |
| urlscan / sandbox | Links and attachments |
| Tenant admin center | Policies |

## References

- `email-auth-checklist.md`
- `the `malware-analysis` skill` `the `attack-chain` skill` (phishing stage) `the `windows-ad` skill` (tokens)

## Routing context

**Upstream**: MASTER R36  
**MUST NOT**: send mass phishing tests against third-party domains without authorization
