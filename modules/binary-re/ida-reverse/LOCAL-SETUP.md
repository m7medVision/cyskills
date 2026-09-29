# IDA ↔ reverse-skill Integration (Portable)

This page contains generic steps and no machine-specific absolute paths. The local readiness report stays in the repo root `LOCAL-READINESS.md` (already gitignored).

## Target shape

| Item | Convention |
|----|------|
| IDA install directory | environment variable `IDADIR` (the directory contains `ida.exe` or `ida.dll`) |
| HTTP MCP | `http://127.0.0.1:13337/mcp` |
| Client server name | keep only **`idapro`** (do not also register `ida-pro-mcp`) |
| Startup | `scripts/start.ps1` (`--unsafe`, no `?ext=dbg`) |
| Opening a DB | for large files prefer `scripts/open.ps1`; do not call `idb_open` directly through some clients |

Pointing two MCP names at the same 13337 registers the tools twice and competes with the idalib worker for the port.

## Installation

```powershell
setx IDADIR "<your IDA install directory>"

# Must use mrexodia/ida-pro-mcp, do not install the PyPI ida-mcp
python -m pip install "git+https://github.com/mrexodia/ida-pro-mcp.git"

# Activate idalib (adjust the path to your local IDA)
python "<IDADIR>\idalib\python\py-activate-idalib.py" -d "<IDADIR>"

# Install the plugin + client config
python -m ida_pro_mcp --install --transport streamable-http --scope global
```

## Startup and keep-alive

An MCP entry with `type: http` will not spawn the process for you. When 13337 is not listening, all clients report error.

| Script | Purpose |
|------|------|
| `scripts/start.ps1` | If healthy, `OK:<n>:reuse` and refresh last-healthy; if the port is listening but RPC times out, treat it as busy and don't kill; only replace the managed supervisor when nobody is listening, `py_eval` is missing, or tools/list has failed continuously for more than 3 minutes (and there is no `opening.lock`); never kill `ida.exe` |
| `scripts/watchdog.ps1` | Patrols every minute; healthy reuse; GUI / `open.ps1` DB-open lock / last-healthy less than 3 minutes → reuse; only `-Force` after tools/list has failed continuously for more than 3 minutes |
| `scripts/recover.ps1` | Immediately `-Force` restart the supervisor (does not kill `ida.exe`). Use this when an HTTP client marks `idapro` as error |
| `scripts/install-autostart.ps1` | Register the scheduled task `reverse-skill-ida-mcp` (logon + every minute) |
| `scripts/start-gui.ps1` | Open the GUI plugin when the idalib license fails |
| `scripts/open.ps1` | Directly call `idb_open` over HTTP, bypassing some clients' schema validation |

Logs: `%LOCALAPPDATA%\reverse-skill\ida-mcp\supervisor.log` and `watchdog.log`.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "skills\ida-reverse\scripts\start.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File "skills\ida-reverse\scripts\open.ps1" -Path "C:\path\to\target.exe" -TimeoutSeconds 600
powershell -NoProfile -ExecutionPolicy Bypass -File "skills\ida-reverse\scripts\install-autostart.ps1"
```

When the GUI occupies 13337 but doesn't reply for a while, `start.ps1` outputs `WARN:gui_busy` and exits, to avoid killing an IDA that is mid-analysis.

## Client

All point to Streamable HTTP: `http://127.0.0.1:13337/mcp`, server name `idapro`.

After changing the config you must start a new session. If Cursor starts while the port is not listening, bringing the service up afterward will **not auto-reconnect**; you need to manually refresh in the MCP panel.

## Known caveats

1. System32 files: `open.ps1` copies to a temp path (output includes `(temp copy)`)
2. Do not call `idb_open` directly through some clients' MCP
3. `start.ps1` prefers `python -m ida_pro_mcp.idalib_supervisor`, which is more stable than the `.cmd` wrapper
4. When a formal install and a portable desktop package coexist, `IDADIR` is authoritative
5. Do not add `?ext=dbg` (the debugger tools are not exposed by default)
