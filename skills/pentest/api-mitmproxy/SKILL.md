---
name: api-mitmproxy
description: "Use for authorized agent-driven API traffic interception with mitmproxy (mitmdump): scripted HTTPS interception, flow parsing to model the target (endpoints/auth/params), Python addon probes, replay, cert-pinning bypass, HAR export, and CI integration."
---

# mitmproxy API Traffic Interception (Agent-Driven)

Agent workflow: everything runs through `mitmdump` + Python addons — no interactive UI. The agent captures flows, parses them to understand the target, then scripts probes against it.

## Agent loop

1. Enforce scope: `--set allow_hosts='target\.com'` — out-of-scope hosts are never intercepted
2. Start capture in background: `mitmdump -q -w t.flow --listen-port 8080`; point the client at the proxy
3. Parse flows offline with `FlowReader` → build target model: endpoints, methods, auth headers, params, content types
4. Write an addon (`mitmdump -q -s probe.py`): module-level `def request(flow)` / `def response(flow)` hooks modify traffic live; addon `print`s JSON findings for the agent to parse; editing probe.py hot-reloads (~1s), iterate without restart
5. Replay: `mitmdump -C t.flow` (client replay) or re-run with a modifying addon
6. Mock/block: set `flow.response = http.Response.make(...)` in `request` to answer without the server
7. Bypass SSL pinning when needed: Frida (Android) or reverse mode + hosts redirect
8. Export evidence: `--set hardump=out.har`; delete or encrypt flow files after the engagement

## References

- `references/overview.md` — mitmdump flags, modes, CA cert, capture/replay/HAR, filter expressions, pinning bypass, troubleshooting
- `references/testing.md` — addon hooks, target-model extraction, probe patterns, OWASP API Top 10, CI, safety
- Browser client is `browser-automation`; `js-reverse` attaches to it.

## Before you start

- Confirm authorization scope via `step-cyskills` (`scope.md`); do not act outside it. Never intercept production traffic without explicit authorization.
- Captured traffic contains credentials/PII: store flow files encrypted, never commit them to git.
