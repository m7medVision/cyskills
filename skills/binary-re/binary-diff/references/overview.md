
# Cross-Version Symbol Migration (Binary Diff)

## Applicability

Use this skill when a task matches one of the following scenarios:

1. **Kernel/driver missing PDB** — You have symbols for an old version of ntoskrnl.exe, the new PDB was pulled by Microsoft, and you need to deduce new-version non-exported function addresses from the old symbols.
2. **Symbol migration after a program update** — You once reverse-engineered a program, the program updated, you don't want to reverse it again, so you batch-migrate using the old results.
3. **Protection mechanism update** — The old version has complete reverse-engineering results; the new version needs the new offsets of the same functions located quickly.
4. **Any "old version has symbols + new version has none" binary comparison scenario.**

### Division of labor with other skills

| Scenario | What to use |
|------|--------|
| Reverse-engineer a binary from scratch | `ida-reverse/` or `radare2/` |
| Have old results, migrate to new version | **this skill** |
| Compare two completely different binaries | BinDiff / Diaphora (traditional tools) |

### Core advantages

Compared with traditional approaches:

| Approach | Cost for 200 functions | Time | Accuracy |
|------|--------------|------|--------|
| Manually compare two IDA windows | Free but life-draining | Hours | High |
| BinDiff automatic matching | Free | Fast | Medium (fails when structure changes a lot) |
| Fully hand over to an Agent (CC/Codex) | 50-100 yuan | Slow | High |
| **This skill (LLM batch comparison)** | **~1 yuan** | **~10 sec/function** | **High** |

## Core principle

```text
Old function (with symbols)          Same function in new version (no symbols)
    ↓                              ↓
Export disassembly + pseudocode      Export disassembly + pseudocode
    ↓                              ↓
    └──────── LLM structured comparison ────────┘
                    ↓
          Output YAML (symbol mapping table)
                    ↓
          Programmatic parsing → batch apply to new IDB
```

Key points:
- The prompt is a fixed template, filled programmatically
- Input/output format is deterministic, parsed programmatically
- The LLM only handles the step "look at two code fragments, find the correspondences"
- Time cost and token cost are extremely low

## Prompt template

### Standard comparison prompt

```text
I have disassembly outputs and procedure code of the same function.

This is the function for reference:

**Disassembly for Reference**
```c
{disasm_for_reference}
```

**Procedure code for Reference**
```c
{procedure_for_reference}
```

This is the function you need to reverse-engineering:

**Disassembly to reverse-engineering**
```c
{disasm_code}
```

**Procedure code to reverse-engineering**
```c
{procedure}
```

What you need to do is to collect all references to "{symbol_name_list}" in the function you need to reverse-engineering and output those references as YAML.

Example:
```yaml
found_vcall: # This is for indirect call to virtual function or virtual function pointer fetching.
  - insn_va: '0x180777700' # Always be the instruction with displacement offset
    insn_disasm: call [rax+68h] # Always be the instruction with displacement offset
    vfunc_offset: '0x68'
    func_name: ILoopMode_OnLoopActivate
  - insn_va: '0x180777778' # Always be the instruction with displacement offset
    insn_disasm: mov rax, [rax+80h] # Always be the instruction with displacement offset
    vfunc_offset: '0x80'
    func_name: INetworkMessages_GetNetworkGroupCount

found_call: # This is for direct call to non-virtual regular function.
  - insn_va: '0x180888800'
    insn_disasm: call sub_180999900
    func_name: CLoopMode_RegisterEventMapInternal
  - insn_va: '0x180888880'
    insn_disasm: call sub_180555500
    func_name: CLoopMode_SetSystemState

found_funcptr: # This is for non-virtual regular function pointer.
  - insn_va: '0x180666600' # Must load/reference the function pointer target address
    insn_disasm: lea rdx, sub_15BC910 # Must load/reference the function pointer target address
    funcptr_name: CLoopMode_OnClientPollNetworking

found_gv: # This is for reference to global variable.
  - insn_va: '0x180444400'
    insn_disasm: mov rcx, cs:qword_180666600 # Must load/reference the global variable
    gv_name: g_pNetworkMessages
  - insn_va: '0x180333300'
    insn_disasm: lea rax, unk_180222200 # Must load/reference the global variable
    gv_name: s_EventManager

found_struct_offset: # This is for reference to struct offset. NOTE THAT virtual function pointer should not be here! virtual function pointer should ALWAYS be in found_vcall !
  - insn_va: '0x1801BA12A' # Always be the instruction with displacement offset
    insn_disasm: mov rcx, [r14+58h] # Always be the instruction with displacement offset
    offset: '0x58'
    size: 8
    struct_name: CResourceService
    member_name: m_pEntitySystem
```

If nothing found, output an empty YAML. DO NOT output anything other than the desired YAML. DO NOT collect unrelated symbols.
```

### Variable descriptions

| Variable | Source | Description |
|------|------|------|
| `{disasm_for_reference}` | Old-version IDA export | Disassembly with symbols |
| `{procedure_for_reference}` | Old-version IDA export | Pseudocode with symbols |
| `{disasm_code}` | New-version IDA export | Disassembly without symbols |
| `{procedure}` | New-version IDA export | Pseudocode without symbols |
| `{symbol_name_list}` | Extracted from old version | List of symbols to locate in the new version |

## Workflow

### Full workflow

```text
Step 1: Prepare data
  - Load the old-version binary into IDA (with PDB/symbols)
  - Load the new-version binary into IDA (no symbols)
  - Find anchor functions that are identical in both versions (exported functions, string references, etc.)

Step 2: Batch export
  - Export from old version: disassembly + pseudocode of the anchor function (including symbol names)
  - Export from new version: disassembly + pseudocode of the same anchor function (no symbol names)

Step 3: LLM comparison
  - Fill the prompt template with data
  - Call the LLM API (recommended: deepseek for high volume and low cost, switch to gpt for very large functions)
  - Parse the returned YAML

Step 4: Apply results
  - Batch-apply the symbol mappings from the YAML to the new IDB
  - Batch-rename with idapro_rename or an IDAPython script

Step 5: Iterate
  - Functions migrated in the first round become new anchors
  - Enter these functions and continue comparing internal calls
  - Repeat until all target functions are covered
```

### Anchor selection strategy

| Anchor type | Reliability | Description |
|---------|--------|------|
| Exported function | Highest | Name unchanged, address may change |
| String reference | High | String content unchanged, reference location may change |
| Constant/magic value | Medium | Feature value unchanged |
| Code pattern | Medium | Function structure similar but all addresses change |

### Batch processing recommendations

- Compare 1 function at a time (avoid context explosion)
- Use deepseek for medium functions (<200 lines)
- Switch to gpt-4o or claude for very large functions (>500 lines)
- Use concurrency to speed up (10-20 concurrent)
- Cache results to avoid repeated calls

## Output format

### The 5 symbol types of YAML output

| Type | Meaning | Key fields |
|------|------|---------|
| `found_vcall` | Virtual function call (indirect call) | `vfunc_offset`, `func_name` |
| `found_call` | Direct function call | `insn_va`, `func_name` |
| `found_funcptr` | Function pointer reference | `insn_va`, `funcptr_name` |
| `found_gv` | Global variable reference | `insn_va`, `gv_name` |
| `found_struct_offset` | Struct offset reference | `offset`, `struct_name`, `member_name` |

### Apply actions after parsing

```text
found_call → idapro_rename(addr=call_target, name=func_name)
found_vcall → idapro_set_comments(addr=insn_va, comment="vcall: {func_name} @ +{offset}")
found_funcptr → idapro_rename(addr=funcptr_target, name=funcptr_name)
found_gv → idapro_rename(addr=gv_addr, name=gv_name)
found_struct_offset → idapro_set_comments(addr=insn_va, comment="{struct_name}.{member_name}")
```

## Typical scenarios

### Scenario 1: ntoskrnl.exe missing PDB

```text
Have: ntoskrnl.exe 10.0.26100.2000 + full PDB
Target: ntoskrnl.exe 10.0.26100.2605 (PDB pulled)
Need: locate the new address of PspSetCreateProcessNotifyRoutine

Steps:
1. Load both versions into IDA
2. Find exported function PsSetCreateProcessNotifyRoutine (present in both versions)
3. In the old version it calls PspSetCreateProcessNotifyRoutine (with symbols)
4. In the new version it calls sub_140822108 (no symbols)
5. The LLM sees at a glance: sub_140822108 = PspSetCreateProcessNotifyRoutine
6. Batch apply
```

### Scenario 2: Migration after an application update

```text
Have: complete reverse-engineering results for target.exe v1.0 (200+ functions named)
Target: target.exe v1.1 (all symbols lost)
Need: batch-migrate 200 function names

Steps:
1. Export disassembly+pseudocode of all named functions from the old version
2. In the new version, find corresponding anchors via exported functions/strings
3. Batch-call the LLM for comparison
4. Parse YAML, batch rename
5. Iterate deeper
```

## LLM selection recommendations

| Model | Suitable scenario | Cost | Speed |
|------|---------|------|------|
| DeepSeek V3 | Small/medium functions (<200 lines), batch processing | Very low | Fast |
| GPT-4o | Very large functions, complex control flow | Medium | Fast |
| Claude Sonnet | Medium/large functions, needs reasoning | Medium | Fast |
| Claude Opus | Extremely complex functions, needs deep understanding | High | Slow |

Recommended strategy: DeepSeek by default; automatically upgrade when context is exceeded or results are inaccurate.

## Notes

- **Do not throw the whole binary at the LLM** — compare only one function at a time
- **Anchors must be reliable** — if an anchor itself is wrong, everything downstream is wasted
- **Results need manual spot checks** — the LLM is not 100% accurate; key symbols must be verified
- **Cache intermediate results** — avoid wasting tokens on repeated calls
- **Mind context limits** — very large functions (>1000 lines of disassembly) need splitting or a large-context model


## On-Demand Bootstrap

### Tool dependencies

| Tool | Purpose | Auto-installable |
|------|------|-----------|
| IDA Pro | Export disassembly/pseudocode | ✗ (commercial software) |
| Python | Script execution, API calls | ✓ |
| PyYAML | Parse the YAML returned by the LLM | ✓ (pip install pyyaml) |
| LLM API | Perform comparison | Requires an API key |

### Notes

The core of this skill does not depend on heavy tool installation, it mainly depends on:
- IDA Pro already present (managed with the `ida-reverse/` skill)
- Python + requests/httpx (to call the API)
- An LLM API endpoint


## Routing context

**Upstream entry**: `skills/SKILL.md` (master control), routing.md
**Trigger condition**: You have old-version symbols/reverse-engineering results and need to migrate to a new version
**Downstream exit**:
- Need to open the binary first → `ida-reverse/`
- Need quick reconnaissance to confirm version differences → `radare2/`

**Sibling associated modules**: `ida-reverse/` (data export and symbol application both go through IDA)
