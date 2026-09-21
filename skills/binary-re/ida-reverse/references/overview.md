
# IDA Pro Reverse Engineering Skill

## Known issues and lessons learned (required reading)

### Pitfalls encountered

1. **Do not call `idb_open` (formerly `idalib_open`) directly through some AI clients' MCP**
   - Some code AI clients' MCP clients have a BUG in the output schema validation for open-type tools
   - Error: `Structured content does not match the tool's output schema`
   - **Workaround**: use the `scripts/open.ps1` script to call directly over the HTTP API, bypassing the MCP validation layer
   - In current ida-pro-mcp 2.x the tool names are `idb_open` / `idb_list` / `idb_save` (no longer `idalib_*`)
   - After a file is opened it returns a `session_id` (database); subsequent tool calls must carry that session

2. **Files under `C:\Windows\System32\` cannot be opened due to permissions**
   - idalib cannot read files inside the System32 directory directly
   - **Workaround**: `open.ps1` automatically detects this and copies to a `temp directory` before opening

3. **The server-start command blocks the conversation**
   - `idalib-mcp` continuously outputs INFO logs to the console after starting
   - **Workaround**: use `scripts/start.ps1` (`-WindowStyle Hidden` silent background start)
   - The script waits for the service to be ready then exits automatically, without blocking the conversation

4. **The MCP server name must not contain a hyphen**
   - Previously `ida-pro-mcp` was used as the server name, which may cause tool registration problems
   - **Current config**: server name `idapro`, tool prefix `idapro_*`

5. **Remote HTTP vs Local Stdio**
   - `type:"local"` (stdio) mode: `idalib_open` has the same schema validation problem
   - `type:"remote"` (HTTP) mode: you can open the file directly with the script first, then use MCP tools
   - **Current approach**: Remote HTTP mode

6. **PR #389 fixed some schema issues**
   - After issue #388, author mrexodia merged the fix via PR #389
   - Fixed the structuredContent schema in HTTP mode, but some code AI clients still have validation problems on their side
   - The latest `main` branch version is installed

7. **idalib timeout leaves orphan worker process lock files**
   - After the first `open.ps1` timeout, idalib's python worker child process may become orphaned, holding onto `.id0`/`.id1`/`.nam`
   - Any subsequent tool or manually dragging into the IDA GUI reports "insufficient privileges"
   - **Forbidden** to use `taskkill /F /T` to kill the process tree — `/T` also kills the GUI `ida.exe` child process
   - **Workaround**: `start.ps1` only replaces the managed supervisor when no one is listening on the port, or `tools/list` returns quickly but `py_eval` is missing (old supervisor); an RPC timeout while 13337 is still listening is treated as busy, and it is not killed. When opening a DB, `open.ps1` writes `opening.lock`, and the watchdog must not `-Force`
   - **Deadlock exception**: only when `tools/list` has **failed continuously for more than 3 minutes** (by last-healthy timestamp, not process creation time), there is no in-flight `opening.lock`, and the port is not occupied by the GUI, does it `-Force` replace the supervisor, still without killing `ida.exe`
   - **Fallback**: when `open.ps1` detects the old DB is locked, it automatically copies it to Temp with a GUID prefix

8. **Opening with auto-analysis looks like a hang**
   - `idalib_open(run_auto_analysis=true)` may not reply for a long time, but the backend is actually still continuing to open and analyze
   - Previously what the user saw was "PowerShell produces no output forever", easily mistaken for the script hanging
   - **Current workaround**: `open.ps1` adds `-TimeoutSeconds`, and switches to background request + foreground polling + periodic progress output
   - When polling finds the session is ready it returns `OK:filename:session_id` early; on timeout it returns `ERR:open_timeout_xxs`

9. **The HTTP MCP silently exits after logon**
   - Cursor/Claude's `type: http` will not spawn the process for you; the old scheduled task only ran once at logon
   - `pythonw` has no console, so even the Application log is empty when it crashes
   - **Workaround**: `start.ps1` reuses if healthy by default; `watchdog.ps1` patrols every minute; logs are in `%LOCALAPPDATA%\reverse-skill\ida-mcp\`
   - Installation: `scripts/install-autostart.ps1`. If the HTTP client starts before the port is up, you still need to manually refresh once in the MCP panel

10. **Streamable HTTP GET `/mcp` can hang the single-threaded supervisor**
    - Some HTTP MCP clients send a long-lived GET (SSE) to `/mcp`. The stock `idalib_supervisor` uses a `background=False` `HTTPServer`, handling only one request at a time
    - Result: `tools/list` times out, and the client marks `idapro` as error
    - **Workaround**: `run-supervisor.py` swaps HTTP for `ThreadingHTTPServer` and accepts GET `/mcp`; if patching fails it skips and still starts the supervisor. When stuck, use `scripts/recover.ps1` (immediately `-Force`)

### Workflow principles

| Step | What to do | What to use |
|------|--------|--------|
| 1 | Make sure the HTTP server is running | `scripts/start.ps1` (no arguments) |
| 2 | Open the target binary file | `scripts/open.ps1 -Path "xxx.exe"` |
| 3 | Use the MCP analysis tools | call `idapro_*` / HTTP tools directly (about 65, depending on the version) |
| 4 | Analysis done | tools are automatically available |

## Script resources

### start.ps1 — start the MCP HTTP server

Path: `scripts/start.ps1`

- Automatically resolves `IDADIR` (environment variable / portable desktop path / common install paths)
- Prefer IDA's bundled `Python314\python.exe -m ida_pro_mcp.idalib_supervisor`
- By default probes `http://127.0.0.1:13337/mcp` first; if healthy, outputs `OK:<n>:reuse` and exits
- If 13337 is listening but `tools/list` times out → `WARN:busy` / `OK:busy:reuse`, **does not kill** (cannot reply while opening a DB or when the GUI occupies it)
- If `tools/list` has **failed continuously for more than 3 minutes** (last-healthy timestamp) and there is no `opening.lock` → treat as deadlock, output `INFO:deadlock` and `-Force` replace the supervisor. An in-progress `idb_open` and the GUI do not take this path
- Replaces the managed supervisor only when nobody is listening on the port, `py_eval` is missing, or the deadlock above occurs; **never kills `ida.exe`, never uses `taskkill /T`**
- When the GUI occupies 13337, outputs `WARN:gui_busy` and exits without starting another supervisor
- On success outputs `OK:<tool count>` (currently about 66), on failure outputs `ERR:timeout`
- supervisor log: `%LOCALAPPDATA%\reverse-skill\ida-mcp\supervisor.log`
- The server runs in the background and does not block the conversation

**Invocation**:
```
powershell -File "<skill-root>\ida-reverse\scripts\start.ps1"
```

### watchdog.ps1 / recover.ps1 / install-autostart.ps1 — keep-alive

- `watchdog.ps1`: probes 13337; healthy reuse (and refresh last-healthy); GUI / `open.ps1` DB-open lock / busy with last-healthy less than 3 minutes → reuse; only `start.ps1 -Force` after tools/list has failed continuously for more than 3 minutes
- `recover.ps1`: immediately `start.ps1 -Force` (does not kill `ida.exe`). Use this when an HTTP client marks `idapro` as error
- `install-autostart.ps1`: register the scheduled task `reverse-skill-ida-mcp` (logon + every minute)
- Logs: `%LOCALAPPDATA%\reverse-skill\ida-mcp\watchdog.log`

### open.ps1 — open a binary file

Path: `scripts/open.ps1`

- Directly calls `idb_open` over the HTTP API, bypassing MCP schema validation
- Automatically detects System32 paths and copies to a temp directory
- Automatically cleans up old same-named database files (`.id0`/`.id1`/`.nam`/`.til`/`.i64`)
- When the old DB is locked, degrades automatically: copies to Temp with a GUID prefix and opens that, without erroring
- Runs the open request in the background, avoiding a long synchronous wait that makes the script unresponsive
- Supports `-TimeoutSeconds`; after timeout returns `ERR:open_timeout_xxs` and will not hang forever
- Outputs `INFO:opening:elapsed/timeout seconds` every 10 seconds, to help judge that analysis is still in progress
- On success outputs `OK:filename:session_id`; on degradation adds a `(temp copy)` marker
- On failure automatically retries via the Temp copy

**Invocation**:
```
powershell -File "<skill-root>\ida-reverse\scripts\open.ps1" -Path "C:\path\to\file.exe"
```

**Optional parameters**:
```
# Specify SessionId
powershell -File "scripts\open.ps1" -Path "file.exe" -SessionId "my_session"

# Skip auto-analysis (recommended for large files)
powershell -File "scripts\open.ps1" -Path "large.exe" -NoAutoAnalysis

# Set a timeout to avoid a long no-return when using auto-analysis
powershell -File "scripts\open.ps1" -Path "file.exe" -TimeoutSeconds 600
```

**Output conventions**:
```
# Analysis in progress (output every 10 seconds)
INFO:opening:11/600s

# Opened successfully
OK:sample.exe:abcd1234

# Opened successfully, but degraded to a Temp copy because of lock files
OK:1234abcd-sample.exe:abcd1234 (temp copy)

# Reached the timeout limit
ERR:open_timeout_600s
```

**Measured notes**:
- `Snipaste.exe` with auto-analysis took about `324s` to return success, which is "analysis takes a long time" rather than "the script is deadlocked"
- Therefore for GUI programs or more complex samples, it is recommended to explicitly set `-TimeoutSeconds 600` first

## Core tool list

### Survey analysis (first step)
- `idapro_survey_binary(detail_level="minimal")` — quick survey: function count, strings, segments, entry point, import classification (crypto/network/file IO)
- `idapro_list_funcs(queries)` — list functions (paging, filter by name)
- `idapro_list_globals(queries)` — list globals
- `idapro_entity_query(kind, filter)` — unified query: functions/globals/imports/strings/names

### Decompilation and disassembly
- `idapro_decompile(addr)` — decompile to pseudocode
- `idapro_disasm(addr, max_instructions=N)` — disassemble
- `idapro_analyze_function(addr, include_asm=false)` — comprehensive analysis (pseudocode + strings + constants + callers + callees + blocks)
- `idapro_func_profile(queries)` — function summary metrics

### Cross-references and data flow
- `idapro_xrefs_to(addrs)` — find who references the target address
- `idapro_xref_query(addr, direction)` — advanced xref query (direction/type filter)
- `idapro_callees(addrs)` — callee list
- `idapro_callgraph(roots, max_depth)` — call graph
- `idapro_trace_data_flow(addr, direction, max_depth)` — data-flow tracing (forward/backward)

### Search
- `idapro_find_regex(pattern, limit)` — regex string search
- `idapro_search_text(pattern)` — search text in the disassembly listing
- `idapro_find_bytes(patterns, limit)` — byte pattern search (supports ?? wildcards)
- `idapro_find(type, targets)` — advanced search (immediates/strings/references)

### Memory and data
- `idapro_get_bytes(addrs)` — read raw bytes
- `idapro_get_string(addrs)` — read strings
- `idapro_get_int(queries)` — read integer values
- `idapro_get_global_value(queries)` — read global values
- `idapro_read_struct(queries)` — read struct field values
- `idapro_search_structs(filter)` — search structs

### Modification operations
- `idapro_set_comments(items)` — add comments (bidirectional sync between disassembly + decompilation)
- `idapro_append_comments(items)` — append comments
- `idapro_rename(batch)` — batch rename (functions/globals/locals/stack variables)
- `idapro_patch_asm(items)` — patch assembly instructions
- `idapro_patch(patches)` — patch bytes
- `idapro_define_func(items)` — define functions
- `idapro_undefine(items)` — undefine
- `idapro_define_code(items)` — convert bytes to code

### Type system
- `idapro_declare_type(decls)` — declare C structs/enums/unions
- `idapro_set_type(edits)` — apply types to functions/globals/locals
- `idapro_infer_types(addrs)` — infer types
- `idapro_type_query(queries)` — query declared types
- `idapro_type_inspect(queries)` — inspect type details

### Stack frame
- `idapro_stack_frame(addrs)` — view stack frame variables
- `idapro_declare_stack(items)` — declare stack variables
- `idapro_delete_stack(items)` — delete stack variables

### Signatures
- `idapro_make_signature(addrs)` — generate a unique byte signature for an address
- `idapro_make_signature_for_function(addrs)` — generate a signature for a function
- `idapro_find_xref_signatures(addrs)` — generate signatures for code referencing an address

### Debugger (requires ?ext=dbg)
- `idapro_open_file(file_path)` — open a file in a GUI IDA instance
- Debugger tools are hidden by default and can be enabled via the URL parameter `?ext=dbg`

### Session management (ida-pro-mcp 2.x)
- `idapro_idb_open` / HTTP `idb_open` — ⚠️ recommend opening with `open.ps1`
- `idapro_idb_list` / HTTP `idb_list` — list all sessions
- `idapro_idb_save` / HTTP `idb_save` — save the database
- Most analysis tools need the `database=<session_id>` parameter (the session output by open.ps1)

### Other
- `idapro_int_convert(inputs)` — base conversion (**you must use this, don't compute bases yourself!**)
- `idapro_export_funcs(addrs, format)` — export functions (json/c_header/prototypes)
- `idapro_py_eval(code)` — run Python in the IDA context
- `idapro_server_health()` — server health check
- `idapro_server_warmup()` — warm up subsystems (string cache, Hex-Rays, etc.)

## Complete reverse-engineering workflow

### Step 1: start the server

**Path A — Headless idalib (requires a valid license)**
```
powershell -File "scripts/start.ps1"
```
Output `OK:<tool count>` (currently about 65) means ready.

**Path B — GUI + plugin (when the idalib license fails or interactive analysis is needed)**
```
powershell -File "scripts/start-gui.ps1" -Path "C:\target.exe"
```
Or double-click the portable `Launch-IDA-Pro.cmd` and open the sample in IDA.

After confirming the Output window shows `[MCP] ... port=13337`, the MCP tools are available.

See `LOCAL-SETUP.md` for the generic integration steps.

### Step 2: open a file

Headless:
```
powershell -File "scripts/open.ps1" -Path "C:\target.exe" -TimeoutSeconds 600
```
Output `OK:filename:session_id` means success (a trailing `(temp copy)` means it automatically degraded to a temp copy).

If `ERR:idalib_license:...` appears, switch to path B (GUI mode); do not repeatedly retry open.ps1.

GUI mode: just Open the sample inside IDA; no open.ps1 needed.

### Step 3: global survey (including the import-table hard gate)
```
idapro_survey_binary(detail_level="minimal")
```
Focus on:
- Architecture (x86/x64/ARM)
- Entry point (main/WinMain/DllMain)
- Interesting strings (URLs, paths, error messages)
- **Import classification (MUST)**: crypto functions / network APIs / file operations / process injection / registry — must be recorded as Evidence (suggested id: `E-imports`), using `idapro_entity_query(kind="imports")` or the imports section of the survey output
- **DLL/SYS**: export table alongside the import table (Evidence `E-exports`)
- **.NET**: when there is no traditional IAT, use a module/metadata/managed-reference summary as an equivalent anchor written into the E-imports semantic slot
- **Clean import table**: note the suspicion of dynamic loading, and push for dynamic API breakpoint verification
- Hot functions (functions with high xref counts are usually key logic)

**Hard gate**: Before the imports view/classification summary (or a legitimate equivalent anchor) is written into Evidence, you MUST NOT proceed to the Step 4 deep-dive conclusions, and MUST NOT claim the survey is complete. When the import table is empty or the query fails, you MUST still record the failure phenomenon. When packed-IAT repair fails, you MUST record `E-iat-repair-fail` and switch to dynamic debugging to capture APIs; grinding statically is forbidden. When the user asks to redo the import-table/IAT check, you MUST redo the named step (when blocked, the feasibility gate: explain + confirm; if forced, mark quality=unreadable); substituting an unrelated step is forbidden.

### Step 4: deep-dive key functions
```
idapro_analyze_function(addr="key function name")
```
Or:
```
idapro_decompile(addr="function name")
idapro_disasm(addr="function name", max_instructions=50)
```

### Step 5: data flow and cross-references
```
idapro_xrefs_to(addrs="key address/string")
idapro_callgraph(roots=["key function"], max_depth=3)
idapro_trace_data_flow(addr="key address", direction="backward", max_depth=5)
```

### Step 6: record and refine
```
idapro_set_comments(items=[{"addr": "0x140001000", "comment": "your understanding"}])
idapro_rename(batch={"func": [{"addr": "function address", "name": "meaningful name"}]})
```

### Step 7: output the report
After analysis is complete, generate report.md recording the findings and steps.

## Prompt engineering guidelines

1. **Don't compute bases manually** — whenever you need to convert a number, use `idapro_int_convert`
2. **Survey before deep-diving** — look at the overview first, then do targeted analysis
3. **Keep adding comments and renames** — continuously update function and variable names during analysis to improve the accuracy of later analysis
4. **Follow cross-references** — when you find interesting data/strings, use `xrefs_to` to see who references it
5. **When you hit obfuscated code** — do preprocessing first such as string decryption, import hash removal, control-flow unflattening
6. **C++ STL code** — after identifying library functions with FLIRT/Lumina, analyze the business logic
7. **Don't brute-force** — analysis should derive the solution from the disassembly, using simple Python to assist computation
8. **When you see "No database bound"** — no binary file has been opened yet; run `open.ps1` first
9. **When you see "Failed to open database"** — the old database file may be locked; `open.ps1` will automatically degrade to a Temp copy (output contains a `(temp copy)` marker)
10. **When opening a GUI/complex sample with auto-analysis** — add `-TimeoutSeconds 600` by default; don't misjudge a long `INFO:opening:...` as the script hanging


## Routing context

**Upstream entry**: `skills/SKILL.md` (master control), routing.md
**Upstream alternative**: `radare2/` (if you don't want to start IDA, you can do a quick r2 recon first)
**Downstream exits**:
- Need Frida dynamic verification → `reverse-engineering/tools-dynamic.md`
- Need symbolic execution/angr → `reverse-engineering/tools-dynamic.md`
- Need general reverse-engineering methodology → `reverse-engineering/SKILL.md`

**Peer related module**: `radare2/` (fallback when IDA is unavailable)


## On-Demand Bootstrap

This skill's entry script is connected to the unified bootstrap system.

### Automation capability boundaries

| Tool | Auto-installable | Install method | Notes |
|------|-----------|---------|------|
| idalib-mcp | ✓ | pip install (from GitHub) | auto-install when `start.ps1` is missing |
| IDA Pro itself | ✗ | commercial software, manual install required | set the `IDADIR` environment variable to point at the install directory |

### Installation steps (verified)

```cmd
# 1. Set the IDA path (replace with your actual IDA install directory)
setx IDADIR "<your IDA install directory>"

# 2. Install ida-pro-mcp from GitHub (ida-mcp on PyPI is a different project, don't install the wrong one!)
pip install git+https://github.com/mrexodia/ida-pro-mcp.git

# 3. Install the IDA plugin (choose Streamable HTTP + Global + select all clients)
ida-pro-mcp --install

# 4. Restart IDA Pro and open the target file
# The plugin automatically listens on 127.0.0.1:13337

# 5. Verify
ida-pro-mcp --config
```

> ⚠️ **Note**: the `ida-mcp` package on PyPI (author jtsylve) is a different project, not what we need.
> You must install `mrexodia/ida-pro-mcp` from GitHub.

### Bootstrap trigger points

- `scripts/start.ps1`: automatically calls bootstrap-reverse.ps1 when `idalib-mcp` is missing
- MCP registration: bootstrap automatically writes `idapro` into the Claude MCP config

### Prerequisites

- IDA Pro is installed and the `IDADIR` environment variable is set (or the default path in the script is correct)
- Recommended to use `ida-pro-mcp` from IDA's bundled Python314 (already bundled in the portable version)
- Common local configuration:
  - User env `IDADIR` → IDA install directory (containing `ida.exe`)
  - Optional `~\Tools\bin\idalib-mcp.cmd` / `ida-pro-mcp.cmd` wrappers
  - Client MCP server name keeps only `idapro` → `http://127.0.0.1:13337/mcp`
