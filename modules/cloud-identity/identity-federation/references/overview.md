
# Identity Federation (SAML / OIDC / OAuth)

## Applicable scenarios

- SAML Response signature/assertion tampering surface (classic flaw patterns)
- OIDC implicit/authorization code + missing PKCE
- redirect_uri / state / nonce issues
- IdP and SP metadata, multi-tenant issuer confusion
- Complements `pentest-core` JWT attacks (this skill focuses on federation and SSO flows)

## Workflow

```text
□ Map it out: User → SP → IdP → Token → SP
□ Collect: /.well-known/openid-configuration, SAML metadata
□ Check: redirect_uri exact matching, state binding, PKCE
□ Check: SAML signature coverage, algorithm downgrade
□ Session fixation and logout failure
```

## Toolchain

| Tool | Purpose |
|------|---------|
| Burp + SAML Raider, etc. | Assertion editing (authorized) |
| jwt_tool | JWT segments |
| Browser DevTools | Redirect chain |
| IdP admin logs | Audit |

## References

- `sso-flow-checklist.md`
- `the `pentest-core` skill` `the `windows-ad` skill` (enterprise IdP)

## Routing context

**Upstream**: MASTER R37  
**Downstream**: pure API JWT → pentest-core; cloud IdP → cloud-k8s
