# mitmdump Addons: Security Testing Patterns

## Basics

Module-level hook functions = an addon (classes: `addons = [T()]`). `-s a.py` hot-reloads; handler errors logged, addon survives. Findings: `print` JSON to stdout.

Hooks: `request` (modify before send) · `response` · `error` (XOR `response`) · `websocket_message` (`flow.messages[-1]`, modifiable) · `tls_clienthello` (`data.ignore = True` = pass-through) · `done` (summary).

## Target-model extraction

```python
# mitmdump -q -s model.py -w t.flow; parse MODEL JSON from stdout
import json
from mitmproxy import http
seen = {}
def response(flow: http.HTTPFlow):
    r = flow.request
    seen[r.method + " " + r.path] = {
        "status": flow.response.status_code,
        "auth": bool(r.headers.get("authorization")),
        "params": sorted({k for k, _ in r.query.items(multi=True)}),
    }
def done():
    print("MODEL " + json.dumps(seen))
```

## Probes (request hook)

- Auth bypass: pop `authorization` header → diff response
- BOLA/BFLA: rewrite object IDs, `X-User-ID`, roles
- Mass assignment: inject fields via `set_content(json.dumps(body).encode())`
- Mock: `flow.response = http.Response.make(200, b'{"ok":1}')`
- GraphQL: parse body JSON `query`; probe `{__schema{types{name}}}`
- `response` hook: regex secrets/`admin`/stack traces on `flow.response.text`

## OWASP API Top 10 / CI

Map probes to API1–10: IDs, token strip/replay, extra JSON fields, burst (`-C` loop), roles/paths, bulk flows, SSRF, CORS, shadow endpoints (MODEL vs docs), outbound. Methodology: `api-security` skill. CI: `mitmdump -q -s tests.py --anticache -w r.flow & export HTTPS_PROXY=http://localhost:8080; pytest; kill %1`

## Safety

Scope-gate with `allow_hosts`; flows hold creds/PII — encrypt, never commit, delete after.
