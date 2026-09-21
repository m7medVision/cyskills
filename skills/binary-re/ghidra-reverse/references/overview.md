
# Ghidra Reverse Engineering

## Use cases

- Primary reverse-engineering entry point when you have no IDA license
- Batch headless analysis / decompilation in CI
- Ghidra scripting (Java/Python Jython/PyGhidra) automation
- ghidriff integration with `binary-diff` / `patch-diff-exploit`

## Division of labor with IDA

| Need | Preferred |
|------|------|
| Existing IDA MCP deep-dive | `ida-reverse/` |
| Open-source / batch / teaching | **this skill** |
| CLI-only quick recon | `radare2/` |

## Workflow

### 1. Project and auto-analysis

```text
□ New Project → Import file → Analyze (default analyzers)
□ Record the language/compiler identification result and base address
□ Mark entry point, export table, string xrefs
```

### 2. Key functions

```text
□ Trace back from strings / imported APIs
□ Recover the algorithm in the Decompile window
□ Rename functions/variables; write Plate comments
□ Hand off to Frida/GDB when dynamic analysis is needed (reverse-engineering dynamic chapter)
```

### 3. Headless (batch)

```bash
# Example: the analyzeHeadless path varies by installation; you MUST take it from the tool-index
analyzeHeadless /path/to/project Proj -import sample.bin -postScript ExportDecomp.py
```

### 4. MCP (if configured)

```text
□ Confirm the ghidra MCP port (commonly 8765; the tool-index is authoritative)
□ Use MCP tools to pull decompilation / xrefs; do not guess the port
```

## Toolchain

| Tool | Purpose | Bootstrap |
|------|------|------|
| Ghidra | Main decompilation tool | manual release / package manager |
| ghidra-mcp | AI bridge | bootstrap capability name `ghidra-mcp` |
| ghidriff | patch diffing | see `patch-diff-exploit` |

## References

- `ghidra-cheatsheet.md`
- `the `ida-reverse` skill` `the `radare2` skill` `the `binary-diff` skill`

## Routing context

**Upstream**: MASTER R22  
**Downstream**: dynamic verification → Frida/GDB; exploitation → `pwn-chain`  
**Peer**: `ida-reverse` (commercial deep-dive)
