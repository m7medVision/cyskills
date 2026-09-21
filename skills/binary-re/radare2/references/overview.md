
# radare2

A binary analysis skill oriented around the `radare2` CLI. The focus is completing recon, analysis, locating, exporting, and lightweight modification directly from the command line, without relying on a GUI.

## Scope

Prefer this skill when the user has these intents:

- Wants to analyze `exe`, `dll`, `so`, `elf`, `apk`, `dex`, `wasm`, and similar files with `r2` / `radare2`
- Asks how to use `rabin2`, `rasm2`, `radiff2`, `rahash2`, `rax2`
- Needs command-line disassembly, viewing functions, viewing strings, viewing imports/exports, looking up cross-references, making patches
- Needs to write `radare2` batch commands, `-c` automation commands, or `r2pipe` scripts

If the user explicitly wants GUI reverse engineering, Hex-Rays-style pseudocode, or an IDA workflow, prefer `ida-reverse`. If it is web JS reverse engineering, prefer `reverse-engineering`.

## Confirm the environment first

Don't assume `r2` is available. Check first:

```powershell
r2 -v
rabin2 -v
```

If it is not installed, check common install locations or prompt for installation.

Common Windows executables:

- `radare2.exe`
- `rabin2.exe`
- `rasm2.exe`
- `radiff2.exe`
- `rahash2.exe`
- `rax2.exe`
- `r2pm.exe`

## Built-in resources

This skill ships two resources; reuse them first instead of assembling a duplicate set of temporary commands each time.

### `scripts/recon.ps1`

Standard recon script, good for a first-pass overview. It outputs:

- Basic info
- Sections
- Imports
- Exports
- Strings
- Optional `r2 -A` auto-analysis summary

Invocation:

```powershell
powershell -File "<skill-root>\radare2\scripts\recon.ps1" -TargetPath "C:\path\to\sample.exe"
```

If you need to include `r2` auto-analysis:

```powershell
powershell -File "<skill-root>\radare2\scripts\recon.ps1" -TargetPath "C:\path\to\sample.exe" -RunAnalysis
```

### `cheatsheet.md`

When you need more command details, common scenario templates, or a quick syntax refresher, read this cheatsheet rather than guessing from memory.

## Known issues

### Occasional `.sdb` missing warning on Windows

For some PE files, `rabin2` recon may emit a warning like the following:

```text
ERROR: Cannot find ...\share\format\dll\*.sdb
```

If the main output still returns normally, this usually does not affect the basic recon conclusions; just continue the analysis. Do not declare the analysis a failure solely because of this kind of incidental warning.

## Basic principles

### 1. Recon first, deep-dive later

Don't run full auto-analysis right away. First confirm the file type, architecture, entry point, strings, and import table with lightweight commands, then decide whether to run `aaa`, `aaaa`, or targeted analysis.

### 2. Prefer the minimal sufficient command

`radare2` has a huge number of commands; users usually need the shortest path:

- File info: `rabin2 -I`
- Strings: `rabin2 -z`
- Imports/exports: `rabin2 -i` / `rabin2 -E`
- Interactive analysis: `r2 <file>` then run local commands

### 3. Be cautious before modifying

If the user wants to patch a binary:

- Default to opening read-only: `r2 <file>`
- Only use write mode when modification is clearly required: `r2 -w <file>` or `oo+` in-session
- Warn about the risks before modifying, to avoid accidentally overwriting the original file

## Common workflows

## Workflow 1: quick recon

Suitable when you just received a binary file.

### Hard gate (MUST — you are forbidden from entering workflow 2 and beyond until it is satisfied)

For binaries with an import table such as PE/ELF/Mach-O, you **MUST** first complete the import-table check and record it as Evidence before proceeding to function-level analysis or dynamic steps:

1. Run `rabin2 -i <sample>` (or the imports section of the `recon.ps1` output); for DLL/SYS additionally you MUST run `rabin2 -E` and record `E-exports`
2. Write the complete/classified import-table result into Evidence (suggested id: `E-imports` or `E-triage-imports`), containing at least:
   - reproduction command (`repro_command`)
   - key-import classification summary: network / file / crypto / process injection / registry / other suspicious APIs
   - if the import table is empty, parsing fails, or the tool errors: you MUST still record the failure phenomenon and raw output as Evidence, **you must not silently skip**
   - import table "too clean" (only base DLLs): MUST note the suspicion of dynamic loading; SHOULD switch to dynamic API capture
3. .NET and others without a traditional IAT: MUST use equivalent anchors (dnSpy/IL/metadata summary) written into the same Evidence semantic slot; empty passes are forbidden
4. Packed sample IAT repair: use ImportREC (or equivalent) for x86, Scylla (or equivalent) for x64. If repair fails, MUST record `E-iat-repair-fail` then switch to dynamic API breakpoints; **forbidden** to grind endlessly on the static IAT (see `reverse-engineering/references/re-agent-workflow.md` §1.2)
5. When the user explicitly asks to "re-do the import-table check / re-check the import table / re-do the IAT": you MUST redo the named step itself (when blocked, first go through the feasibility gate: state the prerequisites + ask for confirmation; if forced, mark quality=unreadable), **forbidden to substitute an unrelated step and pass it off as done**

Before recording the import-table (or legitimate equivalent anchor / IAT-failure bypass) Evidence: you MUST NOT claim "basic recon complete", and MUST NOT proceed to the deep-dive conclusions of workflow 2+.

Prefer running the built-in script directly:

```powershell
powershell -File "<skill-root>\radare2\scripts\recon.ps1" -TargetPath "sample.exe"
```

If you only need the manual minimal commands, use:

```powershell
rabin2 -I sample.exe
rabin2 -z sample.exe
rabin2 -i sample.exe
rabin2 -E sample.exe
```

Focus points:

- File format, bitness, architecture, platform
- Entry point address
- Suspicious strings: URLs, paths, errors, registry, command-line arguments
- Imported functions: network, file, crypto, process injection, registry operations (**MUST record Evidence, see the hard gate above**)

## Workflow 2: interactive function analysis

```powershell
r2 sample.exe
```

Once inside, commonly used:

```text
aaa          # regular auto-analysis
afl          # list functions
iz           # list strings
iS           # list sections
is           # list symbols
s entry0     # jump to the entry point
pdf          # disassemble the current function
VV           # enter visual mode (if the terminal suits it)
q            # quit
```

Notes:

- Default to `aaa` first; don't use the heavier `aaaa` from the start
- If the sample is large or analysis is slow, you can analyze only near the entry point and expand manually

## Workflow 3: locate main / key logic

```text
afl~main
afl~sym.
iz~http
iz~error
axt <addr>
```

Approach:

- Start from `main`, the entry point, or string references
- Use `axt` to find who references a string or address
- After finding the reference point, `s <addr>` and `pdf`

## Workflow 4: hex and memory viewing

```text
px 64        # 64 bytes of hex from the current address
pd 20        # disassemble 20 instructions
psz          # read the string at the current address
pxa          # friendlier hex view
```

## Workflow 5: binary patch

Only use when the user explicitly asks to modify the file:

```powershell
r2 -w sample.exe
```

Once inside, for example:

```text
s 0x401000
wa nop
wa jmp 0x401050
wq
```

Common write operations:

- `wa <asm>`: write assembly
- `wx <hex>`: write raw bytes
- `wq`: write and quit

Back up the original file before modifying. If the user did not mention a backup, at least remind them once.

## Workflow 6: non-interactive automation

Suitable for one-shot output:

```powershell
r2 -A -q -c "afl;iz;ii;q" sample.exe
```

Common parameters:

- `-A`: auto-analyze at startup
- `-q`: quiet mode
- `-c`: execute a command string

If there are many commands, prefer organizing them into a readable order rather than cramming them into a hard-to-maintain giant string.

It is better to lay a foundation with the built-in recon script first, then decide whether to add custom commands.

## Common sub-tools

### `rabin2`

Good for static information extraction:

```powershell
rabin2 -I sample.exe   # basic info
rabin2 -S sample.exe   # sections
rabin2 -s sample.exe   # symbols
rabin2 -i sample.exe   # imports
rabin2 -E sample.exe   # exports
rabin2 -z sample.exe   # strings
rabin2 -zz sample.exe  # more verbose strings
```

### `rasm2`

Good for quick assembly/disassembly:

```powershell
rasm2 -d "9090"
rasm2 -a x86 -b 64 "xor eax, eax"
```

### `radiff2`

Good for comparing two binaries:

```powershell
radiff2 old.exe new.exe
radiff2 -C old.exe new.exe
```

### `rahash2`

Good for computing hashes:

```powershell
rahash2 -a md5 sample.exe
rahash2 -a sha256 sample.exe
```

### `rax2`

Good for base and encoding conversion:

```powershell
rax2 0x401000
rax2 4198400
rax2 -s hello
```

## Recommended analysis order

For an unknown sample, follow this order:

1. `rabin2 -I` for format, architecture, entry point
2. `rabin2 -z` for strings
3. `rabin2 -i` for imported functions — **MUST + Evidence (hard gate, see workflow 1)**
4. If interactive analysis is needed, then enter `r2` (only once the Evidence from step 3 is on disk)
5. `aaa` first, then `afl` / `iz` / `pdf`
6. Gradually locate key functions through string references, import calls, and the entry flow

The benefit of this order is low noise and quickly building a sense of direction. Step 3 is not an optional optimization; it is a hard gate before deep-diving.

## Windows notes

- When a path contains spaces, the command must be quoted correctly
- If the current terminal cannot find `r2`, it may be that `PATH` was just updated; open a new terminal and retry
- Some samples require administrator privileges to read, but by default do not proactively elevate privileges unless the user explicitly needs it
- Before dynamic debugging of a suspicious sample, confirm the user's intent first to avoid misoperation

## Output style

When the user does not just want commands but wants you to actually analyze a file:

- First give a recon result summary
- Then list the key evidence: strings, imports, functions, addresses
- Finally give next-step suggestions or continue deeper analysis

Don't just list commands without explaining why you are doing it.

## Typical request examples

### Example 1: analyze an exe

User: `help me see what this exe does, radare2 is fine`

How to handle:

1. First use `rabin2 -I/-z/-i`
2. Decide whether to enter `r2`
3. Use `aaa`, `afl`, `pdf` to deep-dive the entry and key string references

### Example 2: find where a string is called

User: `which function triggers this error string`

How to handle:

1. Use `iz~keyword` to find the string address
2. Use `axt <addr>` to find references
3. Jump to the reference point `s <addr>` then `pdf`

### Example 3: change a jump

User: `change this jne to je`

How to handle:

1. Confirm the target address first
2. Clearly state you will enter write mode
3. Use `wa je <target>` or directly `wx`
4. Disassemble again afterward to verify

## Practices to avoid

- Don't treat `radare2` as a tool with only the `aaa` command
- Don't open the user's file in write mode without stating the risks
- Don't draw conclusions before doing basic recon
- **Forbidden to skip the import-table check** (`rabin2 -i` / recon imports): without Evidence written, you may not proceed to the next step; when the user asks to redo the import table, you are forbidden to do other steps instead
- **Forbidden to grind statically after IAT repair fails**: record `E-iat-repair-fail` then switch to dynamic; forbidden to use only ImportREC for 64-bit samples
- Don't misroute web JS reverse engineering to this skill; that is the scope of `reverse-engineering`

## References

- Command cheatsheet: `cheatsheet.md`
- Standard recon script: `scripts/recon.ps1`

## radare2-skills ecosystem

The radare2-skills project (radareorg/radare2-skills) provides a more complete ecosystem of tools and workflows:

- **r2xsql**: SQL queries over binary imports / strings / functions
- **r2mcp / r2http**: MCP tools and an HTTP stateful command channel
- **radius2**: symbolic execution, symbolic dynamic analysis
- **r2pm**: plugin management, extensions
- **decompiler plugins**: radare2 plugin mechanism

**Usage strategy**:
- When the user mentions `r2xsql`, `r2mcp`, `r2http`, `radius2`, `r2pm`, `rabin2`, `rasm2`, `radiff2`, `rahash2`, `rax2`, prefer routing to this skill (radare2/SKILL.md)
- These tools are only ecosystem accelerators and **cannot bypass**: the authorization gate, `tool-index` validation, Evidence import, write-mode confirmation
- Give minimal reproducible command examples:
  - `r2xsql -s <file> -q "SELECT ..."`
  - `curl.exe -sS --data-binary 'aaa' http://127.0.0.1:9393/cmd`
  - `radius2 -p <binary> ...`
  - `r2pm -ci <plugin>`

This skill preserves the original hard gates and evidence-chain integrity, and does not allow skipping any authorization or Evidence step.


## Routing context

**Upstream entry**: `skills/SKILL.md` (master control), routing.md
**Upstream alternative**: `ida-reverse/` (upgrade to IDA when decompilation/pseudocode is needed)
**Downstream exits**:
- Need dynamic analysis → `reverse-engineering/tools-dynamic.md` (Frida/GDB)
- Need deep decompilation → `ida-reverse/`
- After PAT finds an interesting string and cross-referencing is needed → `ida-reverse/` (IDA's xref is more powerful)

**Peer related module**: `ida-reverse/` (complementary: r2 recon is fast, IDA decompilation is deep)

## On-Demand Bootstrap

This skill's entry script is connected to the unified bootstrap system. When radare2 is missing it does not error out directly, but attempts to install automatically.

### Automation capability boundaries

| Tool | Auto-installable | Install method | Notes |
|------|-----------|---------|------|
| r2 | ✓ | GitHub Release ZIP (w64) | auto-download and extract to `%USERPROFILE%\Tools\radare2\` |
| rabin2 | ✓ | same as above (included in the radare2 release package) | — |
| rasm2 | ✓ | same as above | — |
| radiff2 | ✓ | same as above | — |
| rahash2 | ✓ | same as above | — |
| rax2 | ✓ | same as above | — |

### Bootstrap trigger points

- `scripts/recon.ps1`: automatically calls bootstrap-reverse.ps1 when `rabin2` or `r2` is missing

### When bootstrap fails

If auto-install fails (no network, GitHub API rate limiting, etc.), the script throws a clear error with a manual installation link.

Manual install: download `radare2-*-w64.zip` from https://github.com/radareorg/radare2/releases, extract it to `%USERPROFILE%\Tools\radare2\`, and make sure the `bin\` directory is in PATH.
