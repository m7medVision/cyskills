# mitmdump: Intercept Setup (Agent-Driven)

Headless scriptable proxy for agents. :8080. HTTP/1-3+WS. `-q` quiet; addons print JSON to stdout.

## Flags

`-w f` flows · `-s a.py` addon, hot-reload ~1s · `-C f` client replay · `-nr f` saved flows · `--set hardump=out.har` · `--set allow_hosts='re'` scope gate (also `ignore_hosts`) · `--anticache` · `--listen-host 0.0.0.0` · `--set ssl_insecure=true` labs · `--mode regular|transparent` (iptables)`|reverse:URL` (impersonate server, `-p 443`)`|upstream:URL` (chain).

## CA cert

Headless: `HTTPS_PROXY=http://localhost:8080` + trust `~/.mitmproxy/mitmproxy-ca-cert.pem` (`REQUESTS_CA_BUNDLE`/curl `--cacert`). Android: `adb push` `.cer` + install; API 24+ ignores user CAs → Frida unpin or system store (root). Reset: `rm -rf ~/.mitmproxy/`.

## Parse saved flows

`FlowReader(open("f","rb")).stream()` from `mitmproxy.io`; `f.type == "http"` → `f.request`/`f.response`.

## Filters

Case-insensitive Python regexes, combine `! & | ( )`. `~d` domain · `~u` URL · `~m` method · `~c` status · `~b` body · `~h` header · `~q` no response · `~s` has response · `~e` error · `~websocket ~tcp ~dns`. For `--view-filter`, `--modify-*`, `flow.filter()`.

## Pinning bypass

Android: `frida -U -l universal-android-ssl-pinning-bypass.js -f pkg` · reverse mode + `/etc/hosts` · pinned QUIC: `ignore_hosts` pass-through.

## Troubleshooting

No traffic: proxy env, firewall, `--listen-host`; test `curl -x http://localhost:8080 http://example.com/`. docs.mitmproxy.org
