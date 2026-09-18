# Automation Entry

Page driving is owned by the `browser-automation` skill (Playwright + Chromium); HTTP capture is owned by the `api-mitmproxy` skill (mitmdump). This skill attaches to that browser over CDP and correlates its runtime evidence with the captured flows — it does not launch or own a browser.

## Composed setup

1. Start the proxy (api-mitmproxy skill):
   `mitmdump -q --listen-port 8080 --set allow_hosts='target\.com' --set hardump=out.har`
2. Launch the browser (browser-automation skill) with proxy + CDP:
   `--proxy-server=http://127.0.0.1:8080 --remote-debugging-port=9222 --ignore-certificate-errors`
   (add `--proxy-bypass-list=<-loopback>` for localhost targets)
3. Point this MCP at that browser: `npx js-reverse-mcp --browserUrl http://127.0.0.1:9222`
4. Observe: `js-reverse_list_network_requests` → `js-reverse_get_request_initiator` → `js-reverse_list_scripts` / `js-reverse_search_in_sources`
5. Capture: `js-reverse_break_on_xhr`, then `js-reverse_get_paused_info`; use `js-reverse_set_breakpoint_on_text` when compressed code needs it
6. Correlate the same request against the mitmproxy HAR/flows
7. Rebuild locally: `local-rebuild.md` / `node-env-rebuild.md`

## Rules

- Attach to the browser-automation instance; do not launch a second browser.
- Run any Playwright `connectOverCDP` helper under Node, not Bun.
- Do not guess `window` / `document` / `navigator`; back every environment patch with page evidence (`env-patching.md`).