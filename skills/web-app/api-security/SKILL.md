---
name: api-security
description: "Use for authorized security assessment of REST, GraphQL, WebSocket, or SOAP APIs, including discovery, authentication, authorization, rate-limit, and CI/CD testing."
---

# API 安全测试

## Workflow

1. Phase 1: API 发现与侦察
2. Phase 2: 认证测试
3. Phase 3: 授权测试（BOLA/IDOR/BFLA）
4. Phase 4: GraphQL 专项
5. Phase 5: REST 输入验证
6. Phase 6: 业务逻辑与差分测试
7. Phase 7: WebSocket 测试
8. Phase 8: 限速与 DoS
9. Phase 9: 数据暴露
10. Phase 10: CI/CD 集成

## References

- `references/cookie-hmac-key-reuse-auth-bypass.md`
- `references/file-parser-chain.md`
- `references/graphql-rpc-drift.md`
- `references/jwt-oauth-testing.md`
- `references/overview.md`
- `references/queue-worker-drift.md`
- `references/race-condition-state-drift.md`
- `references/request-normalization-smuggling.md`
- `references/rest-graphql-testing.md`
- `references/runtime-routing.md`
- `references/ssrf-metadata-pivot.md`
- `references/template-render-path.md`
- `references/websocket-runtime.md`

## Before you start

- Confirm authorization scope via `step-cyskills` (`scope.md`); do not act outside it.
- Verify tools first; `step-cyskills` preflight reports missing tools with distro install commands.
