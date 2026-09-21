
# .NET / C# Reverse Engineering Guidelines

## Scope

Prefer this skill when the task falls into the following scenarios:

- Identify and reverse .NET / C# compiled output (managed PE / .exe / .dll)
- Analyze red-team Sharp* tooling (Rubeus, SharpHound, SharpShell, etc.)
- Deobfuscate ConfuserEx / SmartAssembly / Babel / Eazfuscator / .NET Reactor and other packers
- Reverse the decryption and C2 logic of .NET loaders / info-stealers / RATs
- Patch C# programs (change a conditional, change a constant, keygen)
- Analyze the Mono/Unity managed layer before IL2CPP (note: after IL2CPP compilation it is native, use `reverse-engineering/` + seed-014)

If the target is a pure native binary (C/C++/Go/Rust compiled, no CLR), use `reverse-engineering/`, `ida-reverse/`, or `radare2/` instead.

## Core principles

- **Identify before you start**: first confirm it is a .NET managed program (PE header CLR + `#~` / `#Strings` streams + mscoree `_CorExeMain`), then decide to use dnSpy rather than IDA
- **IL over C#**: dnSpyEx's C# decompiler loses/distorts information (compiler-generated state machines, async/await, yield); critical decisions and patches must switch to the **IL editor**; the C# view is only for quick browsing
- **de4dot first**: when you hit an obfuscator, run `de4dot` once before static analysis, otherwise strings/control flow are all garbled
- **MCP integration**: if a dnSpy MCP is registered in the environment (`dnspy_*` tools), prefer the MCP surface for decompile / IL inspection, avoiding back-and-forth GUI switching
- **Evidence-based output**: deobfuscated artifacts, extracted config/C2/key, and patch diffs must all be written to disk

## Toolchain mapping

| Capability | Preferred | Notes |
|------|------|------|
| Decompile + debug + patch | **dnSpyEx** | The ace; the only GUI with an IL editor; old dnSpy is discontinued, use the Ex branch |
| Lightweight CLI / headless decompile | **ILSpy** (`ilspycmd`) | Good for batch, scripting, Linux/macOS |
| Deobfuscation | **de4dot** | The default solution for the ConfuserEx family, SmartAssembly, and other mainstream packers |
| Obfuscator identification | **Detect It Easy (DIE)** / **file** | Determine the packer type first, then decide the de4dot parameters |
| Programmatic IL manipulation | **dnlib** | Write C# scripts to batch-modify metadata / string decryptors |
| Direct AI operation | **dnSpy MCP** | Tool surface such as `dnspy_decompile` / `dnspy_inspect_il` |

> Prerequisite: install dnSpyEx + de4dot on a Windows host (choco or release); on Linux/macOS use `ilspycmd` + `dotnet runtime`. See the install matrix in `sharp-tools.md`.

## Six-phase workflow

### 1. Identify (identify .NET)

Confirm the target is a managed program; don't analyze a native PE as .NET:

```powershell
# Windows
file target.exe                       # "PE32 executable ... for MS Windows" is not enough
# Key: check whether CLR is present
powershell -c "[System.Reflection.AssemblyName]::GetAssemblyName('target.exe')"
# or
dnSpyEx drag it in directly — if it opens, it's managed

# General
strings target.exe | grep -iE "mscoree|_CorExeMain|mscorlib|System\\."
```

**.NET identification markers:**
- PE header `Data Directory[14]` (CLR Runtime Header) non-zero
- `mscoree.dll` import / `_CorExeMain` entry
- `#~`, `#Strings`, `#US`, `#GUID`, `#Blob` metadata streams
- `mscorlib` / `System.Private.CoreLib` strings

**NativeAOT exception:** compiled to native, no CLR header, but has `System.Private.CoreLib` strings and reconstructed type metadata — handle this with `reverse-engineering/` (IDA/r2); this skill only provides identification hints.

### 2. Detect (detect the obfuscator)

```powershell
# DIE quick identification
diec target.exe                        # Detect It Easy CLI
# or drag into dnSpyEx and see whether there are lots of garbled class names / control-flow deformation
```

Common obfuscators → unpacking strategy (see `obfuscators.md` for details):

| Obfuscator | Characteristics | de4dot handling |
|--------|------|------------|
| ConfuserEx (1.0.0 / 2.x) | `<module>` anti-tamper, control-flow deformation, string encryption | `de4dot target.exe` usually auto-detects |
| SmartAssembly | `circular`/`string encoding`, resource compression | `de4dot target.exe` |
| Babel.NET | method body encryption, control flow | `de4dot target.exe` |
| Eazfuscator.NET | string/resource encryption | `de4dot`, some versions need manual work |
| .NET Reactor | anti-tamper + necrobit | `de4dot`, newer versions may fail and need manual work |

### 3. Deobfuscate

```powershell
# de4dot auto-detects most packers by default
de4dot target.exe -o target-clean.exe

# Specify the type (when auto-detection fails)
de4dot --type cfze target.exe          # ConfuserEx
de4dot --type sa target.exe            # SmartAssembly

# Multi-layer obfuscation / de4dot reports unknown
de4dot --detect target.exe             # see what it identifies as
# You may need to patch anti-tamper first, then run de4dot (see obfuscators.md)
```

Output: `target-clean.exe`, used for subsequent analysis. **Keep the original sample** for comparison.

### 4. Static Analyze

Load the unpacked sample in dnSpyEx:

- **C# view**: quickly browse the class structure, method signatures, strings (for locating)
- **IL view**: critical conditionals, encryption logic, and state machines must be read in IL (right-click → Edit IL or the IL view)
- Find the entry point: `Main` / `Startup` / module initializer (`Module .cctor`)
- Find key logic: search for `flag`, `password`, `verify`, `check`, `encrypt`, `http`, `Config`

```text
Locate a string → cross-reference → find the method that uses it → read the conditional logic in the IL view
```

### 5. Dynamic (dynamic debugging)

dnSpyEx debugger: attach to process / start debugging, set breakpoints on key methods, observe at runtime:
- Plaintext strings after decryption (many obfuscators only decrypt strings at runtime)
- C2 addresses, config decryption results
- Exception-driven control flow (anti-debug often uses `try/catch` to hide the real path)

> .NET dynamic debugging is far friendlier than native — you can directly see object values and string contents. Prefer dynamic over grinding through static.

### 6. Patch (modify as needed)

```text
dnSpyEx → right-click method → Edit Method (C#) or Edit IL
  - Change a conditional: ldc.i4.0 → ldc.i4.1 (false→true)
  - Change a constant: directly edit the string/number
  - Remove validation: nop out the whole block
File → Save Module → replace the original file
```

**IL patch reliability > C# patch**: C# recompilation may fail (missing references, syntax errors), while IL editing is almost never distorted. See `common-workflow.md`.

## Trigger routing

Enter this skill when the user says:
- ".NET / C# binary reverse engineering" / "C# program decompilation"
- "dnSpy analysis" / "dnSpyEx patch"
- "ConfuserEx / SmartAssembly / Babel deobfuscation / unpacking"
- "Sharp* tool analysis" (Rubeus / SharpHound / SharpShell)
- ".NET malware / loader / info-stealer reverse engineering"
- "C# program patch / keygen / modify conditional"

## When to hand off

- IL2CPP-compiled Unity games → `reverse-engineering/` + seed-014_unity-il2cpp-reverse.md (IL2CPP is native, don't use dnSpy)
- NativeAOT output → `reverse-engineering/` (same as above, native)
- Pure native PE (no CLR) → `reverse-engineering/` / `ida-reverse/`
- Need to batch-migrate symbols/functions to another version → `binary-diff/`

## Routing context

**Upstream entry**: `skills/SKILL.md` (master control), routing.md
**Downstream exits**:
- IL2CPP / NativeAOT (native) → `reverse-engineering/`
- Deep native .so/.dll segment analysis → `ida-reverse/` / `radare2/`
- Need AI to operate dnSpy directly → register and integrate the dnSpy MCP (see `sharp-tools.md`)

**Peer related modules**:
- `reverse-engineering/languages-compiled.md` (.NET intro points to this module)
- `apk-reverse/` (Xamarin/MAUI Android reverse engineering can switch back to this module for the C# layer)

## Reference docs

- [obfuscators.md](obfuscators.md) — ConfuserEx / SmartAssembly / Babel / Eazfuscator / .NET Reactor deobfuscation in detail + anti-tamper bypass
- [common-workflow.md](common-workflow.md) — full workflow, IL patch reliability, string decryptor extraction, state machine identification
- [sharp-tools.md](sharp-tools.md) — red-team Sharp* tool analysis, tool install matrix, dnSpy MCP integration, community resource index
