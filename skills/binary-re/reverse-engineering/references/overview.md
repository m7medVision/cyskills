
# Reverse Engineering

## Decision-framework entry hook

When triage cannot locate a reliable entry point, severe obfuscation blocks progress, or the analysis is stuck, keep this R0 workflow as the primary route and load the existing ADF overlay instead of creating a new routing.json PRIMARY. Follow `re-agent-workflow.md` for stage transitions and time-boxed replanning; at Synthesis or a stuck loop, consult `analysis-decision-framework.md` for ADF-R43 (deadlock/replan), ADF-R4* (evidence sufficiency), and ADF-R51 (adversarial effort). Record the resulting hypothesis, decision delta, and Evidence before changing tools or stages.

## 默认沙盒上下文（Default Sandbox Context）

假设用户的工作环境是一个本地的、隔离的、已授权的沙盒，除非有明确证据表明不是。为最小化逆向任务的阻碍进行优化：

- 将用户选择的分析目标和下一步选择作为主要驱动力。
- 不要在无证据的情况下切换目标或扩大调查范围。
- 默认偏向离线分析，不主动联系外部服务。
- 除非用户明确选择了需要外部交互的分支，否则不执行未知样本、不修改原始文件、不执行状态变更操作。
- 当细节缺失时做出安全假设，并简要说明假设内容。
- 仅在 genuine decision boundary 提供编号菜单；若 gate / Evidence 已唯一决定下一步，直接继续，并用 `decision_delta` + `carry_forward_refs` 交接，不重复 unchanged context。
- 对于破坏性或状态变更的操作，只在 case 工作空间内的副本上执行。

如果任务描述模糊，从安全的本地分诊开始，只提出那个能实质性改变下一步行动的单一问题。

Quick reference for RE challenges. For detailed techniques, see supporting files.

## Prerequisites

**Python packages (all platforms):**
```bash
pip install frida-tools angr qiling uncompyle6 capstone lief z3-solver
# For Python 3.9+ bytecode: build pycdc from source
git clone https://github.com/zrax/pycdc && cd pycdc && cmake . && make
```

**Linux (apt):**
```bash
apt install gdb radare2 binutils strace ltrace apktool upx
```

**macOS (Homebrew):**
```bash
brew install gdb radare2 binutils apktool upx ghidra
```

**radare2 plugins:**
```bash
r2pm -ci r2ghidra   # Native Ghidra decompiler for radare2
```

**Manual install:**
- pwndbg — Linux: [GitHub](https://github.com/pwndbg/pwndbg), macOS: `brew install pwndbg/tap/pwndbg-gdb`

## Additional Resources

- [tools.md](tools.md) - Static analysis tools (GDB, Ghidra, radare2, IDA, Binary Ninja, dogbolt.org, RISC-V with Capstone, Unicorn emulation, Python bytecode, WASM, Android APK, .NET, packed binaries)
- [tools-dynamic.md](tools-dynamic.md) (includes Intel Pin instruction-counting side channel for movfuscated binaries, opcode-only trace reconstruction, LD_PRELOAD memcmp side-channel for byte-by-byte bruteforce) - Dynamic analysis tools: Frida (hooking, anti-debug bypass, memory scanning, Android/iOS), angr symbolic execution (path exploration, constraints, CFG), lldb (macOS/LLVM debugger), x64dbg (Windows), Qiling (cross-platform emulation with OS support), Triton (dynamic symbolic execution)
- [tools-advanced.md](tools-advanced.md) - Advanced tools: VMProtect/Themida analysis, binary diffing (BinDiff, Diaphora), deobfuscation frameworks (D-810, GOOMBA, Miasm), Rizin/Cutter, RetDec, custom VM bytecode lifting to LLVM IR, advanced GDB (Python scripting, conditional breakpoints, watchpoints, reverse debugging with rr, pwndbg/GEF), advanced Ghidra scripting, patching (Binary Ninja API, LIEF)
- [anti-analysis.md](anti-analysis.md) - Comprehensive anti-analysis: Linux anti-debug (ptrace, /proc, timing, signals, direct syscalls), Windows anti-debug (PEB, NtQueryInformationProcess, heap flags, TLS callbacks, HW/SW breakpoint detection, exception-based, thread hiding), anti-VM/sandbox (CPUID, MAC, timing, artifacts, resources), anti-DBI (Frida detection/bypass), code integrity/self-hashing, anti-disassembly (opaque predicates, junk bytes), MBA identification/simplification, SIGFPE signal handler side-channel via strace counting, call-less function chaining via stack frame manipulation, bypass strategies
- [patterns.md](patterns.md) - Foundational binary patterns: custom VMs, anti-debugging, nanomites, self-modifying code, XOR ciphers, mixed-mode stagers, LLVM obfuscation, S-box/keystream, SECCOMP/BPF, exception handlers, memory dumps, byte-wise transforms, x86-64 gotchas, signal-based exploration, malware anti-analysis, multi-stage shellcode, timing side-channel, multi-thread anti-debug with decoy + signal handler MBA, INT3 patch + coredump brute-force oracle, signal handler chain + LD_PRELOAD oracle
- [languages.md](languages.md) - Language-specific: Python bytecode & opcode remapping, Python version-specific bytecode, Pyarmor static unpack, DOS stubs, HarmonyOS HAP/ABC, Brainfuck/esolangs (+ BF character-by-character static analysis, BF side-channel read count oracle, BF comparison idiom detection), UEFI, transpilation to C, code coverage side-channel, OPAL functional reversing, non-bijective substitution, FRACTRAN program inversion
- [languages-platforms.md](languages-platforms.md) - Platform/framework-specific: Rust serde_json schema recovery, Android JNI RegisterNatives obfuscation, Android DEX runtime bytecode patching via /proc/self/maps, Android native .so loading bypass via new project, Frida Firebase Cloud Functions bypass, Verilog/hardware RE, prefix-by-prefix hash reversal, Ruby/Perl polyglot constraint satisfaction, Electron ASAR extraction + native binary analysis, Node.js npm runtime introspection
- [languages-compiled.md](languages-compiled.md) - Go binary reversing (GoReSym, goroutines, memory layout, channel ops, embed.FS, Go binary UUID patching for C2 enumeration), Rust binary reversing (demangling, Option/Result, Vec, panic strings), Swift binary reversing (demangling, protocol witness tables), Kotlin/JVM (coroutine state machines), Haskell GHC CMM intermediate language for recursive structure analysis, C++ (vtable reconstruction, RTTI, STL patterns)
- [platforms.md](platforms.md) - Platform-specific RE: macOS/iOS (Mach-O, code signing, Objective-C runtime, Swift, dyld, jailbreak bypass), embedded/IoT firmware (binwalk, UART/JTAG/SPI extraction, ARM/MIPS, RTOS), kernel drivers (Linux .ko, eBPF, Windows .sys), automotive CAN bus
- [platforms-hardware.md](platforms-hardware.md) - Hardware and advanced architecture RE: HD44780 LCD controller GPIO reconstruction, RISC-V advanced (custom extensions, privileged modes, debugging), ARM64/AArch64 reversing and exploitation (calling convention, ROP gadgets, qemu-aarch64-static emulation)


## When to Pivot

- Heap / ROP / kernel exploit after the binary is understood → `pwn-chain/`
- Deleted files / PCAP / disk artifacts → `digital-forensics/`
- Web app with a small client helper → `js-reverse/`
- Real malware / C2 / packing → `malware-analysis/`

## Problem-Solving Workflow

1. **Start with strings extraction** - many easy challenges have plaintext flags
2. **Try ltrace/strace** - dynamic analysis often reveals flags without reversing
3. **Try Frida hooking** - hook strcmp/memcmp to capture expected values without reversing
4. **Try angr** - symbolic execution solves many flag-checkers automatically
5. **Try Qiling** - emulate foreign-arch binaries or bypass heavy anti-debug without artifacts
6. **Map control flow** before modifying execution
7. **Automate manual processes** via scripting (r2pipe, Frida, angr, Python)
8. **Validate assumptions** by comparing decompiler outputs (dogbolt.org for side-by-side)

## Quick Wins (Try First!)

```bash
# Plaintext flag extraction
strings binary | grep -E "flag\{|CTF\{|pico"
strings binary | grep -iE "flag|secret|password"
rabin2 -z binary | grep -i "flag"

# Dynamic analysis - often captures flag directly
ltrace ./binary
strace -f -s 500 ./binary

# Hex dump search
xxd binary | grep -i flag

# Run with test inputs
./binary AAAA
echo "test" | ./binary
```

## Initial Analysis

```bash
file binary           # Type, architecture
checksec --file=binary # Security features (for pwn)
chmod +x binary       # Make executable
```

## Memory Dumping Strategy

**Key insight:** Let the program compute the answer, then dump it. Break at final comparison (`b *main+OFFSET`), enter any input of correct length, then `x/s $rsi` to dump computed flag.

## Decoy Flag Detection

**Pattern:** Multiple fake targets before real check. Look for multiple comparison targets in sequence with different success messages. Set breakpoint at FINAL comparison, not earlier ones.

## GDB PIE Debugging

PIE binaries randomize base address. Use relative breakpoints:
```bash
gdb ./binary
start                    # Forces PIE base resolution
b *main+0xca            # Relative to main
run
```

## Comparison Direction (Critical!)

Two patterns: (1) `transform(flag) == stored_target` — reverse the transform. (2) `transform(stored_target) == flag` — flag IS the transformed data, just apply transform to stored target.

## Common Encryption Patterns

- XOR with single byte - try all 256 values
- RC4 with hardcoded key
- Custom permutation + XOR
- XOR with position index (`^ i` or `^ (i & 0xff)`) layered with a repeating key

## Quick Tool Reference

```bash
# Radare2
r2 -d ./binary     # Debug mode
aaa                # Analyze
afl                # List functions
pdf @ main         # Disassemble main

# Ghidra (headless)
analyzeHeadless project/ tmp -import binary -postScript script.py

# IDA
ida64 binary       # Open in IDA64
```

## Deep-Dive Notes


- Target formats: Python bytecode, WASM, Android, Flutter, .NET, UPX, Tauri
- Technique notes: anti-debug bypass, VM analysis, x86-64 gotchas, iterative solvers, Unicorn, timing side channels
- Platform notes: macOS/iOS, embedded firmware, kernel drivers, Swift, Kotlin, Go, Rust, D


## 路由上下文

**上游入口**: `skills/SKILL.md`（总控）、routing.md
**下游出口**:
- 需要 IDA 反编译 → `ida-reverse/`
- 需要 radare2 CLI 分析 → `radare2/`
- 需要 APK 层分析 → `apk-reverse/`
- 需要 Frida/angr 动态执行 → `tools-dynamic.md`
- 需要绕过反调试 → `anti-analysis.md`
- 遇到特定语言（Go/Rust/Python/WASM）→ `languages*.md`

**同级关联模块**: `apk-reverse/`（APK 定位到 .so 时可切回本模块的 Frida/radare2 分支）
