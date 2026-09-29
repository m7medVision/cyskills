# Go Binary Reverse Engineering Guide

> Go-compiled binaries present unique challenges: static linking makes them huge, function counts reach tens of thousands, the string format is unusual, and recovery is difficult once symbols are stripped.
> This document covers the toolchain, recovery techniques, and practical workflows.

---

## Identifying Go binaries

Quickly determine whether a binary is Go-compiled:

```bash
# String characteristics
strings binary | grep -E "runtime\.|go\.buildid|GOROOT"

# rabin2 reconnaissance
rabin2 -z binary | grep -i "runtime"

# Abnormally large file size (statically linked runtime)
# Typical Hello World: C ~20KB, Go ~2MB
```

Common characteristics:
- A large number of functions with the `runtime.` prefix
- Contains a `go.buildid` section
- Contains `GOROOT`, `GOPATH` path strings
- Function count of 5000-50000+ (includes the entire runtime and standard library)

---

## Core toolchain

### Symbol recovery

| Tool | Purpose | Link |
|------|------|------|
| **GoReSym** | By Mandiant, parses Go symbol information (pclntab/moduledata) | https://github.com/mandiant/GoReSym |
| **GoResolver** | By Volexity, uses CFG similarity to automatically deobfuscate Garble binaries | https://github.com/volexity/GoResolver |
| **redress** | Analyzes stripped Go binaries, recovers types/interfaces/package structure | https://github.com/goretk/redress |
| **GoStringUngarbler** | By Google, specifically recovers Garble-obfuscated strings | https://github.com/mandiant/GoStringUngarbler |

### IDA plugins

| Tool | Purpose | Link |
|------|------|------|
| **go_parser** | IDA plugin, parses moduledata/pclntab/type information | https://github.com/0xjiayu/go_parser |
| **IDAGolangHelper** | IDA script collection, parses Go type information | https://github.com/sibears/IDAGolangHelper |
| **AlphaGolang** | SentinelLabs' IDAPython script collection | https://github.com/SentineLabs/AlphaGolang |
| **IDA 9.2+ native support** | Hex-Rays official Go decompilation improvements | https://hex-rays.com/blog/stop-guessing-and-start-going |

### Ghidra plugins

| Tool | Purpose | Link |
|------|------|------|
| **Ghidra + GoReSym output** | Export symbols with GoReSym then import into Ghidra | Used together |
| **golang_loader_assist** | Ghidra Go loading assistant | Community script |

### Standalone analysis tools

| Tool | Purpose | Link |
|------|------|------|
| **gore** | Go reverse engineering library (the foundation of redress) | https://github.com/goretk/gore |
| **garble** | Go obfuscation tool (know it to fight it) | https://github.com/burrowers/garble |

---

## Key structures of Go binaries

### pclntab (PC Line Table)

The most important structure in a Go binary, containing:
- All function name and address mappings
- Source file paths
- Line number information
- Stack frame sizes

Even when symbols are stripped, pclntab usually still exists (the Go runtime depends on it).

```text
Locating it:
1. Search for magic bytes: 0xFFFFFFF0 (Go 1.16+) or 0xFFFFFFFB (Go 1.18+)
2. Locate automatically with GoReSym
3. Parse automatically with the go_parser IDA plugin
```

### moduledata

Contains:
- pclntab pointer
- Type information table
- itab (interface table)
- Global variable information

### String format

Go strings are not C-style null-terminated; they use a `(pointer, length)` structure:

```text
C string:   "hello\0"
Go string:  struct { ptr *byte; len int } → ptr points to "hello" (no \0)
```

This causes IDA/Ghidra's default string recognition to miss a large number of Go strings.

**Solutions**:
- Use `go_parser` to automatically identify Go strings
- Use GoReSym to export the string list
- Manually: find `runtime.stringtable` or locate via cross-references

---

## Practical workflows

### Scenario 1: Unstripped Go binary

```text
1. GoReSym -t -d -p binary > symbols.json
   → Export all function names, types, source file paths
2. Load into IDA/Ghidra
3. Import GoReSym's symbol information
4. Filter out runtime.* and standard library functions, focus on user code
5. Start analysis from main.main
```

### Scenario 2: Stripped Go binary

```text
1. GoReSym -t -d -p binary > symbols.json
   → Even after stripping, pclntab is usually still there
2. If GoReSym fails → use redress
   redress -src binary    # Recover source file paths
   redress -pkg binary    # Recover package structure
   redress -type binary   # Recover type information
3. Load into IDA + go_parser plugin
4. Run go_parser for automatic recovery
5. Start from the recovered main.main
```

### Scenario 3: Garble-obfuscated Go binary

```text
Garble will:
- Randomize function names (main.main → main.a3f2b1c)
- Encrypt strings
- Remove file path information
- Obfuscate package names

Countermeasures:
1. GoResolver (CFG signature matching)
   → Recover standard library function names via control-flow graph similarity
2. GoStringUngarbler (string decryption)
   → Automatically identify and decrypt Garble's string encryption patterns
3. Dynamic analysis (Frida/dlv)
   → Hook runtime functions to observe actual behavior
4. Comparative analysis
   → Compile a Hello World with the same Go version, use binary-diff to compare the runtime portion
```

### Scenario 4: CGo mixed compilation

```text
1. Identify the CGo boundary (_cgo_* functions)
2. Recover the Go part with go_parser
3. Analyze the C part with regular IDA
4. Watch for bridging functions like _cgo_topofstack, crosscall2
```

---

## Common command quick reference

```bash
# GoReSym: export symbols
GoReSym -t -d -p binary > symbols.json
GoReSym -t -d -p binary -o ida_script.py  # Generate an IDA script

# redress: analyze a stripped binary
redress -src binary          # Source file paths
redress -pkg binary          # Package structure
redress -type binary         # Type information
redress -interface binary    # Interface information
redress -filepath binary     # Full file paths

# GoResolver: deobfuscate Garble
GoResolver -binary binary -output resolved.json

# GoStringUngarbler: decrypt Garble strings
GoStringUngarbler -i binary -o deobfuscated_binary

# Quickly determine the Go version
strings binary | grep "go1\."
GoReSym -p binary | grep "Version"
```

---

## Go analysis workflow in IDA

```text
1. Load the binary (select the correct architecture)
2. Wait for auto-analysis to finish
3. Run the go_parser plugin:
   - File → Script File → go_parser.py
   - Or Edit → Plugins → Go Parser
4. The plugin will automatically:
   - Parse pclntab
   - Recover function names
   - Mark Go strings
   - Parse type information
5. Filter the view:
   - Hide runtime.* functions
   - Focus on main.* and third-party packages
6. Start reverse engineering from main.main
```

---

## Common pitfalls

| Pitfall | Description | Solution |
|------|------|------|
| Too many functions to review | Go static linking yields 5000-50000 functions | Filter by package name, look only at main.* and business packages |
| Incomplete string recognition | Go strings are not null-terminated | Recover with go_parser or GoReSym |
| Decompiled output hard to read | Go's defer/goroutine/interface make pseudocode complex | IDA 9.2+ has improvements, or use dynamic analysis as an aid |
| Garble obfuscation | Function names/strings all randomized | GoResolver + GoStringUngarbler |
| Version differences | pclntab format differs across Go versions | GoReSym supports Go 1.2-1.23+ |
| CGo boundary | Go and C code mixed | Identify _cgo_* functions as the dividing line |

---

## Coordination with other skills

| Need | What to use |
|------|--------|
| Deep IDA analysis of Go binaries | `ida-reverse/` + go_parser plugin |
| Ghidra analysis (free) | Ghidra + GoReSym symbol import |
| Quick reconnaissance | `radare2/` — `rabin2 -z` to view strings |
| Dynamic hooking | Frida (hook runtime functions) or dlv (Go native debugger) |
| Cross-version comparison | `binary-diff/` — migrate old-version symbols to the new version |
| Garble deobfuscation | GoResolver + GoStringUngarbler |
