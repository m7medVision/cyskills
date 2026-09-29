# RE Agent workflow gates (static↔dynamic)

> Source inspiration: binary-re stage division, community RE skills (Frida/r2/Ghidra/IDA loop), Cerberus three-headed loop (static/dynamic/instrumentation)  
> Issue #65 additions: IAT repair iron rule, six-stage mapping, .NET/DLL·SYS equivalent paths; user-instruction feasibility gate; bypass patches 6–10; anti-debug/obfuscation recipes A–T; non-PE multi-format recipes U–AV (2026-08-12)  
> Applies to: `reverse-engineering/`, `ida-reverse/`, `radare2/`, `malware-analysis/`, and handoff with the cre role

## 0. Startup

```text
□ scope.md: offline sample path or authorized device/target
□ tool-index: actual paths for file/strings/r2/ida/frida etc.
□ Role: cre (ops/role-map)
```

## 0.1 Transition handoff (decision delta)

Do not re-inject the full case context between stages. `scope.md` / `workitems.md` / Evidence remain authoritative; `timeline.md` only carries the transition delta:

1. At the end of a stage/turn, write only the `decision_delta` that truly changes subsequent actions; write `[]` when there is no change.
2. unchanged route/auth/scope/network profile/tool state/hypothesis go only in `carry_forward_refs`; the consumer reads them by reference, without re-serializing / re-emitting.
3. `decision_delta` is not the complete state; the consumer must first inherit the refs, then apply the delta.
4. Stop at the next-step menu only when two or more evidence-supported branches would lead to different next actions; deterministic gates advance directly.

Example: when Triage is complete and the only legitimate next step is Static, the transition only needs `decision_delta: [phase=triage->static]` + `carry_forward_refs: [scope.md, evidence/E-triage.md]`.

## 0.5 User-instruction feasibility gate (Issue #65)

**Principle**: obey the user's **goal**, not blindly the user's **step order**. Before skipping a step you must state the precondition and ask for confirmation; once confirmed, mandatory steps must be done, and Evidence quality must be labeled honestly.

| Situation | Agent MUST |
|------|------------|
| The user wants to do X, and the current state can yield **valid** Evidence | Execute X, update Evidence |
| The user wants to do X, but a **known blocking precondition** exists (e.g., it has been determined to be packed and the static IAT is unreadable) | **Forbidden** to pretend to complete a meaningful IAT; ① state the blocker in one sentence; ② give the recommended order (unpack/fix IAT first, or go straight to dynamic API capture); ③ **ask the user to confirm** whether to "still force viewing the current garbage table" or "follow the recommended order" |
| The user explicitly **forces** the current step (e.g., view the IAT even when unpacked) | Execute and record Evidence, MUST label `quality=unreadable` / `packed` (or equivalent); **forbidden** to draw conclusions such as "no network capability" from it |
| The user accepts the recommended order | Do the prerequisite steps first; after completion, do X automatically or on request; **forbidden** to use a prerequisite step (e.g., unpacking) to **pose as** "completed import table inspection" |

**Relation to "redo X"**: redoing X still = redoing the named step (or its confirmed legitimate prerequisite negotiation result); it is forbidden to substitute an unrelated step. Unpacking is a **precondition** of the import table, not a **replacement** for it.

Typical conflict: the user says "don't unpack first, look at the import table first" on a packed sample → packers often tamper with the import directory/encrypted descriptors, making the static table garbage and meaningless → follow the "blocking precondition" row of this table; do not silently unpack and pretend, and do not silently hand over the garbage table as done.

## 1. Triage (5–15 min · mandatory starting point)

```text
□ Compute the sample hash (MD5/SHA256) → unique ID
□ Identify file type: EXE / DLL / SYS / ELF / Mach-O / .NET / script (bat/ps1/vba) / JS / APK etc.
□ Non-PE/script/APK/driver specialties: see §3.4 and `references/nonpe-format-cookbook.md` (U–AV)
□ file / DIE / entropy / packer signatures (PEiD / DIE / Exeinfo etc.)
□ Architecture: x86 / x64 / ARM; compiler language hints (VC++ / Delphi / .NET / Go / Rust)
□ Packer type hints: UPX / ASPack / VMProtect / Themida / unknown obfuscation
□ strings / rabin2 -z for low-hanging fruit
□ MUST import/export anchors (see "Import table hard gate and equivalent paths" below); if the user jumps ahead and it is packed → follow §0.5 first
□ Deliverable: E-triage (MUST include imports or an equivalent anchor classification summary, with quality labels where applicable) + hypothesis list
```

**Stage gate (Triage → Static/Dynamic)**: before E-triage records imports **or** a legitimate equivalent anchor summary, MUST NOT proceed to Dynamic (unless IAT repair failure has been recorded and a dynamic bypass chosen, see §1.2), and MUST NOT claim "basic triage complete". On parse failure, the failed output MUST still be written to Evidence and not skipped. When the user asks to "redo the import table check", MUST redo the imports/equivalent steps themselves (or first complete the prerequisite negotiated in §0.5), and it is forbidden to substitute other analysis steps.

### 1.1 Import table hard gate and equivalent paths

| Sample type | MUST anchor (Evidence) | Description |
|----------|----------------------|------|
| Native PE/ELF/Mach-O (IAT readable) | `E-imports` / `E-triage-imports`: import classification summary | `rabin2 -i` / IDA imports / equivalent |
| DLL / SYS / shared library | **Side-by-side** `E-imports` + `E-exports` (`rabin2 -i` + `rabin2 -E`) | Export table has priority equal to import table (external entry points) |
| .NET managed (no traditional IAT) | **Equivalent path**: dnSpy/IL/metadata/assembly references and sensitive API summary → still written to the `E-imports` or `E-triage-imports` semantic slot | **Forbidden** to leave the hard gate empty because "there is no IAT"; viewing in dnSpy = the native "check the import table" |
| Import table parse failure / empty / packed garbage table | Still record the failure or garbage-table output as Evidence, and mark `quality` | Do not silently skip; a garbage table must not support a capability-negation conclusion |

**Clean import table warning (MUST remind)**: if the import table is "too clean" (only base DLLs such as kernel32/ntdll, almost no business APIs), strongly suspect `LoadLibrary` + `GetProcAddress` dynamic loading → note the suspicion in Evidence, and **SHOULD** switch to Dynamic to capture in-memory APIs; do not declare "no network/no file capability" based only on the static IAT.

**High-risk API combinations (patch 8 · SHOULD)**: when the import table is too long, prioritize outputting **malicious combination clusters**, filtering out pure base system calls. Examples (non-exhaustive):

- High-risk cluster: `FindWindowA/W` + `WriteProcessMemory` + `CreateRemoteThread` (injection)
- High-risk cluster: `CryptEncrypt` / `CryptAcquireContext` + many `FindFirstFile` / `DeleteFile` (ransomware tendency)
- High-risk cluster: `InternetOpen` / `WinHttp` / `URLDownloadToFile` + persistence APIs (`RegSetValue` / `CreateService`)
- Standalone `CreateFile` / `ReadFile` etc. are mostly benign noise unless co-occurring with the clusters above

### 1.2 Unpacking and IAT handling (high-risk branch · Issue #65)

```text
Branch A: no packer / .NET managed
  → Go directly to §2 Static (.NET uses equivalent anchors)

Branch B: packed / strongly obfuscated
  Step 1: Try unpacking (automatic unpacker / manually find the OEP) — must be in an authorized and isolated environment
  Step 2: Try repairing the IAT
     Tools: x86 → ImportREC (or equivalent); x64 → Scylla (or equivalent). Forbidden to stubbornly use ImportREC on 64-bit samples.
     Case B1: repair succeeds and is parseable → record E-imports (post-repair) → §2 Static
     Case B2: ImportREC/Scylla errors, the repaired program won't run, or the IAT is all garbage (VMP/encrypted packer)
      → [IAT repair iron rule] immediately stop further static IAT repair
      → MUST record E-iat-repair-fail (command, tool, failure symptom, decision to switch to dynamic)
      → Go directly to §3 Dynamic: API breakpoints / hardware execution breakpoints / memory search to capture imports
      → This does not count as "skipping the import table": the import table path was attempted and Evidence recorded
     Case B3 (patch 6): after unpacking and fixing the IAT, double-clicking crashes / BSOD (suspected file CRC/size self-check)
      → Abandon further static file repair; record E-self-check-crash or merge into E-iat-repair-fail
      → Switch to §3 Dynamic: break on CreateFile / GetFileSize / hash-related APIs to locate the check-bypass point
```

**IAT repair iron rule (MUST)**: try automatic/semi-automatic repair first; once the repair tool errors or the repaired program won't run, **immediately stop** stubbornly working on the static import table, switch to dynamic debugging, and capture imported functions at runtime with API breakpoints (e.g. `bp CreateFile` / key network APIs).

## 2. Static (basic static anchors → deep dive)

| Tool | When |
|------|------|
| radare2 / rabin2 | Quick functions/imports/strings (imports already MUST-completed in Triage or already have a recorded failure bypass) |
| IDA / Ghidra (MCP or headless) | Deep dive, cross-references, types; re-check import classification during survey |
| jadx / dnSpy | Android / .NET |
| OLLVM docs | Suspected control-flow flattening |

```text
□ Confirm E-imports / E-triage already contains import table or equivalent anchor Evidence (if missing, fill it in first; forbidden to defer)
□ If DLL/SYS: confirm E-exports has been recorded
□ Sensitive API grouping + high-risk combination clustering (patch 8)
□ Hardcoded domain/IP/URL strings; whether the resource section hides a Payload
□ Locate key functions (crypto/validation/network/authorization) → write addresses/symbols to Evidence
□ If one path is blocked → switch tools (IDA↔r2↔Ghidra)
□ Time box (patch 9 · SHOULD default): if ~15 minutes of static deep-diving still finds no key path → force switch to §3 Dynamic (user/task may override the duration)
```

**Without MCP**: you can export decompiled text and analyze it afterward (benchmarking P4nda0s reverse-skills / IDA-NO-MCP), still writing the Evidence path.

## 3. Dynamic (cross-validation loop zone)

Core idea: **static provides clues → dynamic validates → validation stalls → return to static for review** (no fixed unique order).

### 3.0 Breakpoint starter (patch 7 + 10 · MUST order)

Before launching the sample in a user-mode debugger (x64dbg etc.), preset breakpoints per the "four-stage rocket" (names may differ slightly by architecture/tool, order unchanged):

1. **TLS callback** breakpoint (may already have run before the debugger EP)
2. **Entry point EP** breakpoint
3. **Sensitive API** breakpoints (e.g. `CreateRemoteThread` / network / file write)
4. **Fallback**: `ExitProcess` / process-exit path breakpoint (patch 10) — if it exits immediately due to anti-debugging, **do not rush to restart**; immediately dump memory, and write the pre-crash image path to Evidence for string/data recovery

```text
□ Frida / x64dbg / gdb / emulator: validate static hypotheses
□ Preset breakpoints per §3.0 before running; single-step trace the stack/registers (white box)
□ Behavior monitoring: sandbox / Procmon / RegShot (black box)
□ Samples with IAT repair failure / self-check crash: hardware execution breakpoints or memory search to forcibly capture APIs; CreateFile/GetFileSize to check CRC
□ Anti-debug/anti-Frida → reverse-engineering/anti-analysis
□ Android: generate root-detection / SSL pinning bypass scripts as needed, **must be on an authorized device**
□ Crash logs drive the next hook round (adaptive loop)
□ Time box (patch 9 · SHOULD default): if ~200 instructions of single-stepping still yield no malicious-behavior clue → force return to static to search strings/switch anchors (overridable)
```

### 3.1 Sandbox / no-behavior dynamic contingency branch (MUST)

```text
No behavior or immediate exit / infinite sleep
  → Check anti-debug / anti-VM routines (CPUID, high-precision timing, sandbox artifacts, etc.)
  → Try hardware breakpoint bypass, patch detection points, or switch to a physical machine / higher-fidelity environment
  → Write "no behavior + suspected anti-VM" to Evidence; forbidden to write "sample harmless" without conditions
```

### 3.2 Time-box strategy (patch 9 · SHOULD)

| Stage | Default threshold (overridable by user/task) | Action |
|------|------------------------------|------|
| Static deep-dive finds no key path | ~15 minutes | Switch to Dynamic |
| Dynamic single-step makes no progress | ~200 instructions | Return to Static for string/cross-reference re-anchoring |
| Any path fails repeatedly | Record Evidence, then switch tools or bypass | Forbidden to idle on the same failing technique |


### 3.3 Anti-debug / obfuscation bypass quick reference (Issue #65 patches A–T · high frequency)

For the full index and action details see `reverse-engineering/anti-analysis.md` "Agent response recipes A–T". Here we list only **P0 must-check + common transitions**. Default is an **authorized isolated lab**; patching/changing flags is not an unauthorized production action.

| Trigger feature | Preferred action (summary) | Evidence |
|----------|------------------|----------|
| jz/jnz after `cpuid` (A) | lab: change the flag or patch to take the real branch; record the detection point address | `E-anti-debug-cpuid` |
| `rdtsc` + sub/cmp (B) | bp rdtsc or hook the time source; forbidden to treat infinite spinning waiting for sandbox timeout as "harmless" | `E-anti-debug-rdtsc` |
| PEB BeingDebugged / NtGlobalFlag (K) | ScyllaHide or manually modify the PEB; patch the conditional jump | `E-anti-debug-peb` |
| `NtQueryInformationProcess` DebugPort/Flags/Object (P) | ScyllaHide / hook the return value; record the class parameter | `E-anti-debug-ntqip` |
| Few imports but rich behavior → API hashing (N) | bp GetProcAddress; reverse-lookup the hash and re-inject into IDA | `E-api-hash` |
| strings empty but network/file behavior → string encryption (I) | find the decode routine xref; dump after decryption and re-inject | `E-string-decrypt` |
| Signed but suspicious origin (F) | SigCheck: valid/revoked/timestamp; **invalid does not downgrade** the threat level | `E-sig-forge` |
| No IOC with standard strings → try wide chars (T) | `strings -el` / UTF-16LE; Alt+A unicode | `E-wide-strings` |
| Debugger-name strings / Toolhelp scan (C) | bp the CreateToolhelp32Snapshot chain | `E-anti-debug-procscan` |
| AddVectoredExceptionHandler + deliberate exception (D) | bp VEH registration; analyze the handler | `E-anti-debug-veh` |
| int3 / DR0–DR7 (M) | patch int3; software breakpoints or ScyllaHide to hide hardware BPs | `E-anti-debug-bp` |
| Multiple PE headers/overlapping sections (G) | Section table's real mapping + entropy; don't trust section names | `E-pe-anomaly` |
| File tail > sum of sections Overlay (J) | Extract the overlay; file/entropy; find the load-offset xref | `E-overlay` |
| Abnormally large/high-entropy .rsrc RT_RCDATA (Q) | Extract the resource; FindResource chain + decrypt dump | `E-rsrc-payload` |
| DLL loaded only at runtime (R) | Check Delay Import; bp the delay-load helper | `E-delay-import` |
| while+switch star-shaped CFG (H) | **See** `ollvm-deobfuscation.md`; if plugins fail, use the dynamic path | `E-cff` |
| Always-true/always-false branches (S) | **See** ollvm / symbolic execution; dynamic is authoritative | `E-opaque-pred` |
| `/proc/self/status` TracerPid (L) | **Linux/ELF**; hook or patch; not mandatory on the main Windows path | `E-anti-debug-tracerpid` |

**Constraint**: record Evidence even when the bypass fails; forbidden to write "anti-debug triggered exit" as "sample harmless". The full A–T and P2 (E compilation time, O junk instructions) are in the anti-analysis recipes section.

### 3.4 Non-PE / multi-format bypass (Issue #65 patches U–AV · routing)

Full index: `reverse-engineering/references/nonpe-format-cookbook.md`. Here we list only **type → entry**; action details are in the cookbook / corresponding skill.

| Type | Jump | P0 Evidence anchor (example) |
|------|------|---------------------------|
| BAT/CMD | cookbook §1 + malware | `E-batch-deobf` |
| PowerShell | cookbook §2 + malware | `E-ps-decode-layer-N` |
| VBA macro | cookbook §3 + malware | `E-vba-pcode` |
| Heavily obfuscated JS / JSVMP | **js-reverse** + cookbook §4 | `E-js-vmp` / `E-js-deobf` |
| SYS driver | kernel-driver-reverse + cookbook §5 | `E-driver-irp-handlers` / `E-driver-ioctl` |
| DLL focus | cookbook §6 (AM≡A–T **R**) | `E-dll-tls-dllmain` / `E-exports` |
| Android bricking/hidden icon | **apk-reverse** + cookbook §7–8 | `E-android-wiper-*` / `E-android-hidden-icon-*` |

**Constraint**: do not start a separate "non-PE six stages"; divide labor with §3.3 A–T (PE anti-debug vs multi-format). Authorized lab; bricking/BYOVD/reflection = detection-and-forensics phrasing.


## 4. Synthesis (IOC / attack chain / report)

### Decision quality overlay (Issue #77)

Before closing Synthesis, apply [analysis-decision-framework.md](../../ops/analysis-decision-framework.md) **P0 checklist**: R41 grounded claims, R4* validated sufficiency, R1 confidence->dynamic, R2 hypothesis exit, R43 deadlock replan (under feasibility gate), R8/R23 no default malice/IOC. Multi-module -> R50; anti-analysis effort -> R51 + A-T cookbook.

Blindspots (Rust/Go/VMP/injection/OLE/PDF/agent-meta): [analysis-blindspot-cookbook.md](../../ops/analysis-blindspot-cookbook.md) R52-R81 — detection-oriented; not a parallel master flow.



```text
□ Finding: algorithm/validation logic/exploitable point / behavior conclusion
□ Path: callflow or solve steps linked to E-*
□ IOC: network fingerprint + host fingerprint (table if present; n/a + reason if not)
□ Report task-report (malware/apt/null/vuln overlay chosen by task) + optional diagram
□ Optional: YARA / Snort·Suricata rule codification
□ field-journal redaction
```

## 5. Six-stage practical mapping (Issue #65 mind map → this file)

| Practical stage | This file's sections | Hard gate / iron rule |
|----------|------------|-------------|
| 1 Initial rapid assessment | §0–§1 Triage | Hash, architecture, file type, packer check; imports/equivalent anchors; §0.5 instruction gate |
| 2 Unpacking and IAT | §1.2 | IAT iron rule; failure/self-check crash → Evidence → Dynamic |
| 3 Basic static anchors | §2 Static | High-risk API combinations; time box SHOULD |
| 4 Deep cross-validation | §3 Dynamic | Four-stage breakpoint rocket; no-behavior contingency; time box; §3.3 A–T; §3.4 U–AV type routing |
| 5 Extract IoCs and attack chain | §4 Synthesis | IOC + Kill Chain / Path |
| 6 Archiving and codification | §4 + task-report / YARA | Structured report; rules optional |

## 6. Differences from "stacking RE skill plugins"

- This package uses **stage gates + tool-index**, and does not enable Hex-Rays "unsafe fully-automatic execution" plugins by default  
- Dynamic instrumentation defaults to an **offline/lab** network_profile  
- IAT/import table: **attempt + record** takes priority over "infinite static stubbornness" or "silent skipping"  
- User instructions: **goal first + precondition negotiation**; forbidden to pass off an unrelated step as the named step
