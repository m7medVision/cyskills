# OLLVM Deobfuscation / Obfuscator-LLVM Deobfuscation

> An OLLVM deobfuscation workflow aimed at APK .so files, ELF binaries, and control-flow flattening scenarios.
> Tool and variant information is based on research into community-active projects in 2026, not on training memory.
> Applies to: Android NDK hardening, CTF reverse engineering, packed .so analysis, countering commercial obfuscators.

---

## 0. Quick decision: which tool should I use?

Based on your environment and your assessment of the target's obfuscation type, match yourself directly:

| Your situation | First choice | Alternative | Notes |
|---------|---------|------|------|
| IDA Pro 7.5-7.7 + Hex-Rays, want one-click deflattening | **obpo-plugin** | d810-ng | obpo uses microcode + dataflow + concolic execution, the strongest effect, but it is a cloud plugin (needs network, core closed source) |
| IDA Pro (any recent version), want a local all-in-one deobfuscator | **d810-ng** | Original D-810 | Local, open source, integrates Z3, supports OLLVM/Tigress/Hodur/Approov variants |
| Binary Ninja | **ollvm-breaker** | — | For Android .so in practice (hardened samples such as libvdog) |
| No IDA/BN, pure scripting, target x86/x64 | **ollvm-unflattener** (Miasm) | angr deflat | Based on Miasm symbolic execution, BFS multi-layer processing |
| No IDA/BN, pure scripting, target x86/x64 | **ollvm-unflattener** (Miasm) | angr deflat | Based on Miasm symbolic execution, BFS multi-layer processing |
| Pure Python symbolic execution, CTF scenario | **angr** Deobfuscator | Triton | No GUI dependency, scriptable |
| Target is ARM64 .so, no IDA | **deollvm** (Unicorn) | angr | Unicorn-based ARM64 deflat |
| Encounter BR obfuscation (indirect branches) | **DeObfBR** | Set the data segment read-only | Goron/Arkari-style BR obfuscation can be countered simply by making the data segment read-only |
| Encounter Tigress obfuscation | d810-ng `UnflattenerSwitchCase`/`UnflattenerTigressIndirect` | — | d810-ng has built-in Tigress-specific unflatteners |

> **Core recommendation:** prefer **d810-ng** (local, actively maintained, broad variant coverage). When a cloud service is available, **obpo-plugin** works best. If both fail, then use **angr/Miasm** symbolic execution for custom handling.

---

## 1. The modern OLLVM variant ecosystem (2026 community research)

OLLVM has long since ceased to be just the original 2017 repository. Below are the currently active obfuscator forks; **before deobfuscating you must first determine which variant the target is**, because countermeasures differ greatly between variants:

### 1.1 Obfuscator fork lineage

| Variant | Base LLVM | New features vs. original OLLVM | Countermeasure focus |
|------|----------|----------------------|---------|
| **Obfuscator** (original) | 3.3~4.0 | sub + bcf + fla (the three basic passes) | Standard tools can handle it |
| **Hikari** | 6~8 | Anti Class Dump, Function Call Obfuscate, Function Wrapper, Indirect Branching, Split BB, String Encryption | Need to decrypt strings first + repair indirect jumps |
| **Hikari-LLVM15** | 15~19 | + Anti Debugging, Anti Hook, Constant Encryption | Now closed source; Constant Encryption increases static analysis difficulty |
| **goron** | 7~10 | Indirect Branch/Call/GlobalVariable | ⚠️ Goron-style indirect obfuscation can be countered simply by "setting the data segment read-only" |
| **Arkari** (komimoe/Hikari) | 14~latest | Based on goron, actively maintained | Same as goron; making the data segment read-only partially counters it |
| **Pluto** | 14 | MBA Obfuscation, Random CF, Split BB, **Trap Angr** (specifically traps angr) | ⚠️ The Trap Angr pass breaks angr symbolic execution; switch tools or avoid the traps |
| **Polaris** (formerly Pluto) | 16 | Alias Access, Indirect Branch/Call, String Encryption, Merge Function, Linear MBA, Dirty Bytes Insertion, Function Splitting, Junk Insertion | Combines Hikari+Pluto, the trickiest; needs layered handling |
| **O-MVLL** | open-obfuscator | Python-driven pass manager; Anti Hooking, Arithmetic(MBA), BB Duplicate, CF Breaking, Function Outline, Indirect Branch/Call, Opaque Constants | Commonly used in modern Android hardening; Python configuration is easy to customize |
| **amice** (Rust) | Rust implementation | Full set + VM Flatten, Instruction Virtualization, Delayed Offset Loading, Parameter Aggregation | Includes VM-ization; needs VM handler recovery rather than plain deflat |
| **VMP family** (SmallVmp/VMPilot/xVMP/VMPacker) | — | Instruction virtualization | **Not in the OLLVM category**, requires VM reverse engineering; see VM-specific tools |

### 1.2 Key identification clues

- **Trap Angr** (Pluto/Polaris): if angr blows up or path-explodes while running, suspect the target uses the Trap Angr pass → switch to d810-ng or a Unicorn dynamic approach
- **Goron/Arkari indirect jumps**: if the dispatcher uses indirect jumps (BR x8 instead of switch), first try setting the relevant data segment read-only; indirect jump targets then often become statically solvable
- **Constant Encryption** (Hikari-LLVM15/Polaris/O-MVLL): constants are decrypted at runtime, so pure static analysis cannot see the real values → need Unicorn to dynamically execute the decryption stub
- **VM Flatten** (amice): the control flow becomes a VM dispatch loop; **do not treat it as ordinary fla**, you must first identify the VM handler table

---

## 2. OLLVM obfuscation type detection

Identification features of OLLVM's three core passes:

### 2.1 Control Flow Flattening (`fla`)

**IDA view features:**
- The function entry first jumps to a single dispatcher block
- The main logic is split into multiple basic blocks, each ending with a jump back to the dispatcher
- The dispatcher uses a **state variable** to decide which block to execute next
- A huge `switch` structure, with no logical connection between cases

```
Original:             OLLVM flattened:
  block_A               entry -> dispatcher
  block_B                 ↓
  block_C              state_machine:
                         switch(state):
                           0 → block_A
                           1 → block_B
                           2 → block_C
```

**Variant forms (the multiple dispatchers d810-ng recognizes):**
- O-LLVM: switch / if-chain + state variable
- Tigress: `m_jtbl` (switch-case) or `m_ijmp` (indirect jump, requires `goto_table_info` configuration)
- Hodur (PlugX): nested `while(1)` state machine, `jnz state, #CONST`, **no switch dispatcher**
- Approov: `while(v8 != C)`, state constants concentrated at `0xF6000–0xF6FFF`

### 2.2 Bogus Control Flow (`bcf`)

- Inserts **unreachable bogus branches** between real branches
- Bogus branches are protected by **opaque predicates** (conditions always true/false, but static analysis cannot directly prove it)
- Large amounts of dead code inflate the function size

```c
// Classic opaque predicate: x(x+1) must be even, the compiler cannot prove it
if (x * (x + 1) % 2 == 0) {
    // real logic
} else {
    // unreachable junk code
}
```

### 2.3 Instruction Substitution (`sub`) → MBA

- Replaces simple arithmetic/bitwise operations with equivalent complex expressions (MBA, Mixed Boolean-Arithmetic)

```
a + b  →  (a ^ b) + 2*(a & b)
a ^ b  →  (a | b) - (a & b)
a - b  →  a + (~b) + 1
```

### 2.4 Quick classification table

| Obfuscation type | IDA feature | Main countermeasure |
|---------|---------|------------|
| fla (flattening) | Huge switch + dispatcher | obpo / d810-ng / deflat |
| bcf (bogus control flow) | Unreachable branches + dead code | d810-ng opaque predicate removal / symbolic execution |
| sub/MBA | Complex arithmetic expressions | d810-ng MBA simplifier / SiMBA (Z3) |
| fla + bcf + sub | All of the above, massive inflation | **Layered deobfuscation (bcf first, then fla, then sub)** |

---

## 3. Mainstream tools in detail (community-active projects)

### 3.1 obpo-plugin — strongest effect, cloud plugin

> [obpo-project/obpo-plugin](https://github.com/obpo-project/obpo-plugin) · 629⭐ · active 2026-06

A pseudocode optimizer based on Hex-Rays **microcode**, using **dataflow tracking + program slicing + concolic execution** to rebuild flattened control flow. Its effect is recognized by the community as one of the strongest.

**Key features:**
- Operates at the microcode layer, directly optimizing the decompiler output (not modifying ASM)
- Supports IDA 7.5.0 / 7.6.0 / 7.7.0 + Hex-Rays
- Architectures: ARM, ARM64, x86, x86_64, PowerPC, PowerPC64, MIPS (7.6/7.5)
- **Cloud plugin**: the target function's binary is uploaded to obpo-server for processing (core closed source, plugin free and open source)
- The server is maintained at the author's own expense, timeout 600s, **multi-threading/malicious calls forbidden**

**Installation and usage:**
```text
1. Download obpo_plugin.py and the obpoplugin directory
2. Copy to the IDA plugins path
3. Restart IDA, open the target binary
4. Locate the dispatcher block in the CFG, usually looking like this:
   [see the repository's assets/dispatchblock.png screenshot]
5. Right-click → OBPO → Mark and process function
6. Refresh the decompiler after processing
7. You can keep marking newly appearing dispatcher blocks based on the decompilation changes (iteratively handle nested fla)
```

**Applicability and limitations:**
- ✅ Standard and nested fla, good results
- ⚠️ Requires network; use with caution on sensitive samples (undisclosed internal vulnerabilities, trade secrets) — the binary is uploaded
- ⚠️ The server may be down; depends on the author's maintenance
- ❌ Cannot solve all obfuscation (the author explicitly states this)

### 3.2 d810-ng — local all-in-one first choice

> [w00tzenheimer/d810-ng](https://github.com/w00tzenheimer/d810-ng) · 223⭐ · updated 2026-06-26

The modern maintained/refactored version (Next Generation) of D-810. Runs locally, open source, integrates the **Z3 SMT** solver, with the broadest variant coverage.

**Core capabilities (organized from the d810-ng README):**

*Instruction-level optimizations:*
| Category | Description |
|------|------|
| MBA simplification | `(a+b)-2*(a&b) => a^b`, Z3-verified DSL rules |
| Hacker's Delight | Bitwise equivalences (from the book Hacker's Delight) |
| O-LLVM patterns | Obfuscator-LLVM-specific MBA patterns |
| Constant folding | 22 constant-simplification rules |
| Predicate simplification | Opaque predicate removal (setz/setnz/lnot/smod) |
| Z3 rules | Fall back to SMT solving when template matching fails |
| Hodur-specific | MBA patterns of the PlugX (Hodur) malware |

*Control-flow Unflatteners (classified by target obfuscation):*
| Unflattener | Target | Description |
|------------|------|------|
| `Unflattener` | O-LLVM | Standard switch/if-chain + state variable |
| `UnflattenerSwitchCase` | Tigress | Tigress switch-case dispatch (`m_jtbl`) |
| `UnflattenerTigressIndirect` | Tigress | Tigress indirect jump (`m_ijmp`), requires `goto_table_info` configuration |
| `HodurUnflattener` | Hodur (PlugX) | Nested `while(1)` + `jnz state, #CONST`, no switch |
| `BadWhileLoop` | Approov | `while(v8 != C)`, state constants at 0xF6000–0xF6FFF |
| `UnflattenerFakeJump` | Generic | Removes always-true/always-false conditional jumps |
| `SingleIterationLoopUnflattener` | Residual | Cleans up single-iteration loops where `INIT == CHECK` and `UPDATE != CHECK` |
| `UnflattenControlFlowRule` (experimental) | Generic | Path-emulation-based CFG unflattener |

**Installation and usage:**
```text
1. clone d810-ng
2. Install dependencies (including Z3)
3. Copy to the IDA plugins directory
4. In IDA press Ctrl-Shift-D to load the plugin
5. Check the rule sets to apply in the GUI
6. Apply to the target functions
```

**Why choose d810-ng over the original D-810:**
- The original D-810 is now less maintained
- d810-ng has CI tests, refactored code, and new Tigress/Hodur/Approov-specific unflatteners
- It integrates Z3 and falls back to SMT solving when template matching fails, with a higher success rate

### 3.3 ollvm-unflattener — Miasm symbolic execution, pure scripting

> [cdong1012/ollvm-unflattener](https://github.com/cdong1012/ollvm-unflattener) · 265⭐ · active 2026-06

Based on the **Miasm** symbolic execution engine, it does not depend on IDA/BN and is a pure Python CLI.

**Features:**
- Uses Miasm symbolic execution to recover the original control flow (different from MODeflattener's pure static method)
- **BFS multi-layer processing**: automatically follows calls from the target function and recursively deobfuscates
- Supports Windows/Linux x86/x64
- Outputs a new deobfuscated binary

**Installation and usage:**
```bash
git clone https://github.com/cdong1012/ollvm-unflattener.git
cd ollvm-unflattener
pip install -r requirements.txt   # miasm, graphviz, keystone-engine

# Basic usage
python unflattener -i <input.bin> -o <output.bin> -t <function_addr> -a
# -a: automatically follow calls for multi-layer processing
```

**Applies to:** no IDA, target x86/x64, batch/scripted processing needed.

### 3.4 ollvm-breaker — Binary Ninja in practice

> [amimo/ollvm-breaker](https://github.com/amimo/ollvm-breaker) · 441⭐

Uses **Binary Ninja** for deflattening; the repository ships with an Android-hardened sample `libvdog.so` as a test case, and has already fixed functions such as JNI_OnLoad, crazy::GetPackageName, and prevent_attach_one.

**Applies to:** Binary Ninja users, Android .so in practice.

### 3.5 deollvm — ARM64 Unicorn

> [GeT1t/deollvm](https://github.com/GeT1t/deollvm) · 34⭐ · 2026-04

Unicorn-based ARM64 OLLVM deflat. A fallback for handling ARM64 .so without IDA.

### 3.6 DeObfBR — BR obfuscation specialty

> [Mrack/DeObfBR](https://github.com/Mrack/DeObfBR) · 96⭐ · 2026-06-25

Specifically removes **BR obfuscation** (indirect branch obfuscation, Goron/Arkari style).

**⚠️ Simple countermeasure trick (from awesome-ollvm):** Goron/Arkari-style indirect-related obfuscation can be countered simply by **setting the data segment read-only** — indirect jump targets often depend on a runtime-writable data segment, and making it read-only turns them into statically solvable values.

### 3.7 angr — general symbolic execution framework

```python
import angr

proj = angr.Project("target.so", auto_load_libs=False)
cfg = proj.analyses.CFGFast()
func = proj.kb.functions[0x12345]

# Built-in Deobfuscator
deob = proj.analyses.Deobfuscator(func=func)
deob.normalize()
```

**⚠️ Pluto/Polaris's Trap Angr pass:** these two variants specifically wrote traps to sabotage angr symbolic execution. If angr path-explodes or errors out, suspect the target uses Trap Angr → switch to d810-ng or a Unicorn dynamic approach.

---

## 4. Complete deobfuscation workflow (by scenario)

### 4.1 General decision tree

```
Target binary
  ↓
1. Identify the OLLVM variant (see the clues in section 1.2)
  ├── Original OLLVM / Hikari / O-MVLL  → standard fla/bcf/sub
  ├── Pluto / Polaris                → watch for Trap Angr, avoid angr
  ├── Goron / Arkari                 → try read-only data segment first, then handle BR
  ├── Tigress                        → d810-ng Tigress unflattener
  ├── Hodur (PlugX)                  → d810-ng HodurUnflattener
  └── amice (with VM)                → not plain fla, needs VM handler recovery
  ↓
2. Choose a tool (see the decision table in section 0)
  ├── Has IDA + can go online + non-sensitive sample → obpo-plugin
  ├── Has IDA + local              → d810-ng
  ├── Has Binary Ninja            → ollvm-breaker
  ├── No GUI + x86/x64           → ollvm-unflattener (Miasm)
  ├── No GUI + ARM64             → deollvm (Unicorn) / angr
  └── Pure symbolic execution / CTF → angr
  ↓
3. Layered deobfuscation (order matters)
  a) First remove opaque predicates (bcf)   → d810-ng opaque predicate removal
  b) Then remove control-flow flattening (fla) → unflattener
  c) Finally simplify MBA (sub)       → d810-ng MBA simplifier / SiMBA
  ↓
4. Verify
  ├── Does the function size decrease significantly?
  ├── Has the CFG changed from star-shaped/radial to chain-shaped/tree-shaped?
  └── Does a Frida hook of key functions confirm the logic is correct?
```

### 4.2 Android NDK .so deobfuscation specialty

OLLVM-hardened .so files compiled by the Android NDK are the most common APK reverse engineering scenario.

**Step 1 — Extract the .so:**
```bash
adb pull /data/app/~~/lib/arm64/libnative.so
# Or extract directly from the APK: unzip target.apk -d out/ ; find out -name "*.so"
```

**Step 2 — Identify OLLVM and its variant:**
```bash
readelf -a libnative.so | grep -E "Size|text"   # Abnormally large .text but few functions → likely OLLVM
# Open in IDA and look at function features:
#   Huge switch → fla
#   Unreachable branches → bcf
#   Complex arithmetic → sub/MBA
#   Indirect jump BR x8 → Goron/Arkari, try read-only data segment
#   while(1) + jnz state → Hodur, use d810-ng HodurUnflattener
```

**Step 3 — Deobfuscate (layered):**
```
a) bcf: d810-ng opaque predicate removal  (or obpo handles it automatically)
b) fla: d810-ng Unflattener / obpo-plugin / deollvm(ARM64)
c) sub: d810-ng MBA simplifier
```

**Step 4 — Frida dynamic verification:**
```javascript
// Trace the OLLVM state variable, helping deflat determine the state variable address
const target = Module.findBaseAddress("libnative.so");
console.log("[+] libnative.so @", target);

// Hook at the dispatcher entry to observe the state change sequence
Interceptor.attach(target.add(0x1234), {  // dispatcher offset
    onEnter(args) {
        // Read the state variable (register/stack location must be determined from the decompilation)
        console.log("[state]", this.context.x8);  // Assume state is in x8
    }
});
```

### 4.3 CTF scenario quick deobfuscation

CTF is usually time-pressured, so prefer the fastest path:

```python
#!/usr/bin/env python3
"""CTF OLLVM quick deflat with angr"""
import angr

proj = angr.Project("challenge", auto_load_libs=False)
cfg = proj.analyses.CFGFast()

# Find the largest few functions (most likely to be obfuscated)
funcs = sorted(cfg.functions.values(), key=lambda f: f.size, reverse=True)[:5]
for func in funcs:
    print(f"[*] {func.name} @ {hex(func.addr)} size={hex(func.size)}")
    try:
        deob = proj.analyses.Deobfuscator(func=func)
        deob.normalize()
        print(f"    [+] deobfuscated")
    except Exception as e:
        print(f"    [-] failed: {e}")
        # angr fails → suspect Trap Angr → switch to d810-ng / Unicorn
```

---

## 5. MBA expression simplification

### 5.1 Common OLLVM MBA patterns

```python
# These equalities are the simplification targets of expressions generated by the OLLVM sub pass
"(a | b) + (a & b)"        # → a + b
"(a | b) - (a & b)"        # → a ^ b
"(a ^ b) + 2*(a & b)"      # → a + b
"(a | b) & ~(a & b)"       # → a ^ b
"~(~a & ~b)"               # → a | b (De Morgan)
```

### 5.2 Tool selection

| Tool | Method | Applies to |
|------|------|------|
| **d810-ng MBA simplifier** | Batch inside IDA, Z3-verified | First choice, integrated into the decompilation flow |
| **SiMBA** (`pip install simba-simplifier`) | CLI/library | Pure expression simplification, batch processing |
| **Arybo** | Symbolic bit-vectors | Large numbers of MBA expressions |
| **Direct Z3 solving** | SMT | Most general, when all template matching fails |

```python
# SiMBA example
from simba import simplify_mba
exprs = ["(a | b) + (a & b)", "(a ^ b) + 2*(a & b)"]
for e in exprs:
    print(f"{e}  →  {simplify_mba(e)}")
```

---

## 6. Complete deobfuscation case script

```bash
#!/bin/bash
# OLLVM deobfuscation pipeline (2026 community tools)
# Applies to ELF/.so hardened with standard OLLVM / Hikari / O-MVLL

BINARY=$1

echo "[*] Stage 0: basic analysis and variant identification"
file $BINARY
readelf -h $BINARY 2>/dev/null | head -5
echo "    → confirm the variant in IDA (see section 1)"

echo "[*] Stage 1: d810-ng local deobfuscation (first choice)"
echo "    IDA → Ctrl-Shift-D to load d810-ng"
echo "    Check: MBA + Opaque predicate + Unflattener"
echo "    Apply to target functions"
echo "    Save the IDB"

echo "[*] Stage 2: obpo-plugin (if d810-ng is insufficient and you can go online)"
echo "    IDA → right-click dispatcher → OBPO → Mark and process"
echo "    ⚠️ Do not use for sensitive samples (binary uploaded to a cloud service)"

echo "[*] Stage 3: fallback without IDA (x86/x64)"
echo "    python unflattener -i $BINARY -o deobf.bin -t <func_addr> -a"

echo "[*] Stage 4: fallback for ARM64 .so without IDA"
echo "    deollvm (Unicorn) or angr Deobfuscator"

echo "[+] Done. Re-analyze and verify in IDA."
```

---

## 7. Common pitfalls (community practical summary)

| Problem | Cause | Solution |
|------|------|---------|
| angr path explosion/abnormal exit | Pluto/Polaris's **Trap Angr** pass | Switch to d810-ng or a Unicorn dynamic approach |
| obpo-plugin cannot connect | The server is maintained at the author's own expense and may be down | Switch to local d810-ng; you can file an issue in the obpo repository |
| Goron/Arkari indirect jump deflat fails | The dispatcher uses BR x8 instead of switch | First make the data segment read-only, then use DeObfBR |
| Functions still messy after d810-ng | OLLVM customized the pass parameters/seed | First use symbolic execution to remove opaque predicates, then unflatten |
| Nested fla (multi-layer flattening) not cleaned in one pass | obpo/d810-ng only cleans one layer per pass | **Iterate**: mark each newly appearing dispatcher |
| Error when using deflat on an ARM64 .so | Old deflat scripts only support x86 | Use d810-ng / obpo (ARM64 support) / deollvm |
| Hikari strings not visible | String Encryption pass | Use Unicorn to emulate the decryption stub, dump the decrypted strings |
| amice target deflat completely ineffective | Contains VM Flatten / Instruction Virtualization | **Not OLLVM fla**, needs VM handler recovery (see VM reverse engineering) |
| Hodur(PugX) sample has no switch dispatcher | Nested while(1) + jnz state | Use d810-ng **HodurUnflattener**, not the ordinary Unflattener |
| Approov sample state constants show no pattern | Constants concentrated at 0xF6000–0xF6FFF | Use the d810-ng **BadWhileLoop** unflattener |
| Sensitive sample mistakenly using obpo | Binary uploaded to a cloud service | For classified/undisclosed-vulnerability samples **use only local tools** (d810-ng/angr) |
| Frida hook of an OLLVM function hangs | The state variable was modified, causing an infinite loop | Add a conditional breakpoint at the dispatcher entry to limit the iteration count |

---

## 8. Tool quick reference (2026 community activity)

| Tool | Platform | Method | Stars/Price | Last update | Open source | Notes |
|------|------|------|---------|---------|------|------|
| **obpo-plugin** | IDA | microcode+concolic (cloud) | 629 | 2026-06 | plugin OSS/core closed | Strongest effect, needs network |
| **ollvm-breaker** | Binary Ninja | BN API | 441 | 2026-06 | ✅ | Android .so in practice |
| **ollvm-unflattener** | CLI | Miasm symbolic execution | 265 | 2026-06 | ✅ | x86/x64, BFS multi-layer |
| **d810-ng** | IDA | microcode+Z3 | 223 | 2026-06 | ✅ | **Local first choice**, broad variant coverage |
| **DeObfBR** | — | BR obfuscation specialty | 96 | 2026-06 | ✅ | Goron/Arkari indirect branches |
| **IDA_Ollvm-unflattener** | IDA | Miasm plugin version | 90 | 2026-04 | ✅ | IDA plugin wrapper around ollvm-unflattener |
| **deollvm** | CLI | Unicorn | 34 | 2026-04 | ✅ | ARM64 specialty |
| **angr** | CLI | Symbolic execution | — | active | ✅ | General; countered by Trap Angr |
| **SiMBA** | CLI/library | MBA simplification | — | — | ✅ | Expression simplification |
| **Triton** | CLI | Symbolic execution+taint | — | active | ✅ | Dynamic symbolic execution |

---

## 9. Reference links

**Obfuscators (to understand the target of the countermeasures):**
- [obfuscator-llvm/obfuscator](https://github.com/obfuscator-llvm/obfuscator) — original OLLVM
- [HikariObfuscator/Hikari](https://github.com/HikariObfuscator/Hikari) — Hikari
- [komimoe/Hikari](https://github.com/komimoe/Hikari) — Arkari (based on goron, LLVM 14+)
- [amimo/goron](https://github.com/amimo/goron) — goron
- [bluesadi/Pluto](https://github.com/bluesadi/Pluto) — Pluto
- [za233/Polaris-Obfuscator](https://github.com/za233/Polaris-Obfuscator) — Polaris (formerly Pluto)
- [open-obfuscator/o-mvll](https://github.com/open-obfuscator/o-mvll) — O-MVLL
- [fuqiuluo/amice](https://github.com/fuqiuluo/amice) — Rust implementation of OLLVM passes
- [lich4/awesome-ollvm](https://github.com/lich4/awesome-ollvm) — **variant ecosystem overview (strongly recommended reading first)**

**Deobfuscation tools:**
- [obpo-project/obpo-plugin](https://github.com/obpo-project/obpo-plugin) — strongest cloud plugin
- [w00tzenheimer/d810-ng](https://github.com/w00tzenheimer/d810-ng) — local first choice
- [cdong1012/ollvm-unflattener](https://github.com/cdong1012/ollvm-unflattener) — Miasm pure scripting
- [amimo/ollvm-breaker](https://github.com/amimo/ollvm-breaker) — Binary Ninja
- [GeT1t/deollvm](https://github.com/GeT1t/deollvm) — ARM64 Unicorn
- [Mrack/DeObfBR](https://github.com/Mrack/DeObfBR) — BR obfuscation specialty
- [maskelihileci/IDA_Ollvm-unflattener](https://github.com/maskelihileci/IDA_Ollvm-unflattener) — IDA plugin version
- [angr](https://angr.io/) — symbolic execution framework
- [SiMBA](https://github.com/tech-srl/simba) — MBA simplification

**Academic/blogs:**
- [Quarkslab: Deobfuscation: Recovering an OLLVM-protected program](https://blog.quarkslab.com/deobfuscation-recovering-an-ollvm-protected-program.html) — classic deflat principles
- [MODeflattener](https://github.com/mrT4ntr4/MODeflattener) — static deflat (comparison for ollvm-unflattener)

> Related documents: [[anti-analysis.md]] (anti-debug/anti-analysis master table), [[tools-advanced.md]] (advanced toolset), [[elf-analysis.md]] (ELF file analysis), [[ai-assisted-re.md]] (AI-assisted reverse engineering)
