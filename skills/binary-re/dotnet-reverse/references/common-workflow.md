# .NET Reverse Engineering Common Workflow

Full workflow details, IL patch reliability, string decryptor extraction, state machine identification, dnlib scripting.

## Full workflow (end to end)

```text
1. Identify  → confirm it is a .NET managed program (not native)
2. Detect    → DIE / de4dot --detect identify the obfuscator
3. Deobf     → de4dot deobfuscation (keep the original sample)
4. Static    → browse the C# view in dnSpyEx to locate, read key logic in the IL view
5. Dynamic   → break at key methods with the dnSpyEx debugger, see runtime plaintext
6. Patch     → edit with the IL editor, Save Module
```

Each step's artifact must be written to disk: original sample `target.exe` → unpacked `target-clean.exe` → patched `target-patched.exe`.

## IL patch vs C# patch reliability

**Core conclusion: use the IL editor for critical modifications, not the C# editor.**

| Dimension | C# editor (Edit Method C#) | IL editor (Edit IL) |
|------|---------------------------|---------------------|
| Compilation failure risk | High (missing references, syntax, lambda rewrite failure) | Nearly zero |
| Information fidelity | The compiler regenerates IL, which may differ from the original | Replaced as-is, instruction by instruction |
| Suitable for | changing a string, changing a constant, simple logic | changing conditionals, removing validation, changing control flow |
| async/await/state machine | often fails to compile or gets distorted | directly modify state machine fields, reliable |

dnSpyEx's C# decompiler is based on read-only decompilation plus attempted recompilation; recompiling compiler-generated code (state machines, closures, `yield`) fails easily. The IL editor edits instruction by instruction, WYSIWYG.

### Typical IL patch patterns

```text
Change a conditional (if (check) → always true):
  Original: call bool Foo::Check()
      brfalse.s SKIP
  Change: ldc.i4.1            ; push true
      brfalse.s SKIP      ; now never jumps, SKIP not executed
  Or more directly:
      ldc.i4.1
      ret                 ; method returns true directly

Change a conditional (if (check) → always false):
  ldc.i4.0
  ret

Remove an entire validation block:
  nop everything, or change to ret + the correct return value

Change a string constant:
  The C# editor usually handles string changes fine (ldstr swaps the token directly), but if the string is in resources/encrypted you must change the decryption logic

Change a numeric constant:
  Change the operand directly in the ldarg / ldc instruction
```

## State machine identification (async/await / yield)

C#'s `async/await` and `IEnumerator` yield compile into a **state machine**: the compiler generates a nested class whose `MoveNext()` uses a `state` field for switch dispatch. The dnSpyEx C# view restores it as async, but decompilation may be distorted; the `MoveNext` in the IL view is the most accurate.

```text
The MoveNext structure of async/await:
  switch(this.<>1__state) {
    case 0: ... logic before await; this.<>1__state = 1; await MoveNext;
    case 1: ... logic after await;
  }

To patch async logic: change the state transitions in MoveNext or the conditionals in specific cases.
The C# editor almost always fails at changing async → you must use IL.
```

## String decryptor extraction

See `obfuscators.md` for details. Here we add dnlib scripting to batch-decrypt strings:

```csharp
// dnlib script: scan all string decryptor calls, restore at runtime, and write back
// Usage: dotnet script decrypt.csproj target.exe 0x06000012
using System;
using System.Reflection;
using dnlib.DotNet;
using dnlib.DotNet.Writer;
using dnlib.DotNet.Emit;

var module = ModuleDefMD.Load(args[0]);
var decryptorToken = uint.Parse(args[1], System.Globalization.NumberStyles.HexNumber);

// Find the decrypt method and call it via reflection (need to load the assembly into the AppDomain)
// Iterate all methods, replace call Decryptor(token) with ldstr "decryption result"
foreach (var type in module.GetTypes())
    foreach (var method in type.Methods)
    {
        if (!method.HasBody) continue;
        var instrs = method.Body.Instructions;
        for (int i = 0; i < instrs.Count; i++)
        {
            // Recognize the call decryptor pattern, call the decryptor to get plaintext, replace with ldstr
            // (the reflection boilerplate to call the decryptor is omitted here; idea: load the original assembly →
            //   MethodInfo.Invoke to get plaintext → instrs[i] = OpCodes.Ldstr + operand=plaintext)
        }
    }

var opts = new ModuleWriterOptions(module);
module.Write("target-decrypted.exe", opts);
```

dnlib is the de facto standard for .NET metadata programming; de4dot uses it internally. The first choice when writing custom deobfuscation scripts.

## Dynamic debugging essentials

The dnSpyEx debugger is far friendlier to .NET programs than native:

- **Breakpoints at method entry**: right-click method → Add Breakpoint
- **View object values**: after breaking, the Locals / Watch windows show object fields and string contents directly
- **Memory writes**: you can directly change runtime variable values (Edit Value)
- **Exception breakpoints**: Debug → Exceptions, check the exception types to break on — obfuscators often use exception-driven control flow; breaking on exceptions reveals the real path

### Exception-driven control flow

Some obfuscators stuff normal logic into `try` and use `throw` + `catch` for jumps. Statically the IL looks like exception handling, but it is actually control flow:

```text
try { throw new CustomException(0x42); }
catch (CustomException e) {
    switch(e.Code) {
        case 0x42: real logic A; break;
        case 0x43: real logic B; break;
    }
}
```

Set an exception breakpoint (break on `CustomException`) and trace the flow of the `Code` value; faster than grinding through the IL.

## Module initializer (Module .cctor)

A `.NET` module's static constructor (`<module>`'s `.cctor`) executes first when the assembly loads; obfuscators often put anti-tamper / decryption initialization here. Analysis order:

```text
1. First look at <module>.cctor (Module .cctor) — decryption/anti-debug initialization
2. Then look at Program.Main / Startup
3. If anti-tamper is in .cctor → patch .cctor first, then unpack
```

## Common pattern for extracting config / C2 / key

Red-team tools and loaders often encrypt and embed config in resources or fields, decrypting at runtime:

```text
Locating flow:
1. Use strings to see if there is a plaintext URL/IP (usually none after obfuscation)
2. Find the byte[] field + decrypt method (AES/XOR)
3. Dynamically break at the return point of the decrypt method and dump the decrypted plaintext
4. Common: AES-256-CBC with Key==IV (Codegate 2013 pattern, see the .NET section of reverse-engineering/tools.md)
```

Refer to `references/sharp-tools.md` for the specific configuration structures of red-team tools.

## Boundary with reverse-engineering

- **IL2CPP / NativeAOT** → compiled to native, no CLR metadata → use `reverse-engineering/` (IDA/r2); this skill only handles identification
- **Managed .NET** (standard C# exe/dll, Mono/Unity managed layer, Xamarin) → this skill
- **Hybrid (native loader + .NET payload)** → the loader part goes to `reverse-engineering/`; after dumping the .NET payload, switch to this skill

## Artifact checklist

Each .NET reverse engineering task is recommended to produce:
- `target-original.exe` (original sample, untouched)
- `target-clean.exe` (after de4dot unpacking)
- `notes.md` (identified obfuscator, decryptor token, key method addresses, config/C2/key)
- `target-patched.exe` (after patching, if needed)
- `il-diff.txt` (IL before/after patch, if a patch was made)
