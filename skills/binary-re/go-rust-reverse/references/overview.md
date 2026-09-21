
# Go / Rust Binary Reverse Engineering

## Applicable scenarios

- Symbol-stripped Go malware/tools
- Rust release binaries, panic-string-driven analysis
- Language-specific methods that complement generic ida/ghidra

## Workflow

### Go

```text
□ Identify go.buildid, leftover runtime symbols, pclntab
□ Recover function names with GoReSym / redress / IDA Go plugins
□ Note how interface, slice, and string structures appear in decompilation
□ Networking/crypto library paths: crypto/* net/http
```

### Rust

```text
□ panic strings, rust_begin_unwind, crate path hints
□ Code bloat from generic instantiation; locate string xrefs first
□ Async/tokio state machines require cross-referencing
```

### Dynamic

```text
□ Frida is still usable; mind the Go stack and scheduler
□ Prefer log and config strings to drive breakpoints
```

## Toolchain

| Tool | Purpose |
|------|------|
| GoReSym | Go metadata |
| IDA/Ghidra + Go/Rust plugins | Decompilation |
| radare2 | Quick string search |
| strings / rabin2 | Triage |

## References

- `go-rust-notes.md`
- `go-reverse.md` `the `ida-reverse` skill` `the `ghidra-reverse` skill`
- seed: `field-journal/seed-002_go-malware-stripped.md`

## Routing context

**Upstream**: MASTER R33  
**Downstream**: Malware sample workflow `malware-analysis`; generic RE `reverse-engineering`
