# .NET Obfuscator Deobfuscation in Detail

Identification, unpacking, and anti-tamper bypass for mainstream .NET obfuscators. Core tools: **de4dot** (auto-detects most packers) + **dnSpyEx** (manual patch) + **dnlib** (scripting).

## Master decision table

| Obfuscator | de4dot type | Typical characteristics | Auto unpack | Manual notes |
|--------|-------------|---------|---------|---------|
| ConfuserEx 1.x/2.x | `cfze` | anti-tamper, control-flow deformation, string encryption, anti-debug | ✅ mostly automatic | newer versions need anti-tamper patched first |
| ConfuserEx 3.x / private mods | `cfze` | same as above + custom protector | ⚠️ partial | runtime dump / dnlib |
| SmartAssembly | `sa` | string encoding, resource compression, method-call hiding | ✅ automatic | resource decompression |
| Babel.NET | `babel` | method body encryption, control flow, strings | ✅ automatic | — |
| Eazfuscator.NET | `eaz` | string/resource encryption, expression obfuscation | ⚠️ partial | string decryptor |
| .NET Reactor | `reactor` | necrobit (code segment encryption) + anti-tamper | ⚠️ hard for new versions | dump + rebuild metadata |
| Themida .NET | — | outer shell + virtualization | ❌ de4dot won't work | dump memory, take the native approach |
| Agile.NET / CliSecure | `agile` | method body encryption | ✅ automatic | — |

## Standard de4dot usage

```powershell
# Auto-detect (sufficient in most cases)
de4dot target.exe -o target-clean.exe

# Explicitly specify type (when auto-detection fails)
de4dot --type cfze target.exe -o target-clean.exe

# Probe the packer type first
de4dot --detect target.exe

# Batch
de4dot *.exe

# Decrypt only strings, leave control flow alone (minimal intervention)
de4dot --strtyp delegate --strtok METHOD_TOKEN target.exe
```

de4dot's `--strtyp` / `strtok` mode: decrypt only the string decryptor (with a specified decrypt method token), keeping the original control flow. Suitable for the scenario of "just wanting to see the plaintext strings without touching anti-tamper".

---

## ConfuserEx (most common)

### Characteristic identification

- Entry module `<module>` class has an anti-tamper check with `[MethodImpl(NoInlining)]`
- Lots of `Dictionary<string, T>` string-decryptor calls
- Control-flow flattening (switch dispatch + state variable)
- `.cmp` compressed resources embedded in resources
- dnSpyEx C# view: garbled class/method names (`\uXXXX` or meaningless characters), method bodies full of `int num = ...; switch(num)`

### Unpacking flow

```powershell
# 1. Standard unpack
de4dot target.exe -o target-clean.exe

# 2. If de4dot reports "unknown" or the unpacked file won't open → new/private-mod ConfuserEx
#    Confirm anti-tamper first:
dnSpyEx open → find the integrity check in Module .cctor or Main
```

### anti-tamper bypass (common in new ConfuserEx)

ConfuserEx's `anti tamper` verifies method body hashes at runtime; if modified, it crashes. de4dot usually handles old versions; new versions need manual work:

```text
Method A — patch the verification function directly with dnSpyEx:
  1. Find the anti-tamper verification method (usually called from the static constructor of <module>)
  2. IL edit: change the verification method body to ret (return directly)
  3. Save → then feed to de4dot

Method B — runtime dump:
  1. Use MegaDumper / ExtremeDumper to run it and dump the assembly from memory
  2. The dump is already decrypted, then clean up the residue with de4dot
```

### After control-flow restoration

de4dot restores the flattened switch dispatch into normal if/while. If not fully restored (you still see a residual state machine), run de4dot again or follow the IL manually.

---

## SmartAssembly

```powershell
de4dot --type sa target.exe -o target-clean.exe
```

Characteristics:
- Strings encoded with the `SmartAssembly.Runtime.Strong` family
- Resource compression (`{assembly}.Resources`)
- Method-call hiding (`ProcessCaller` / indirect call)

de4dot has the best compatibility with SmartAssembly; basically one-click.

---

## .NET Reactor (necrobit)

`.NET Reactor`'s **necrobit** encrypts the real method bodies into resources and injects them after decryption at runtime; the original method bodies are empty shells. de4dot works on old versions but often fails on new versions (4.x+).

```text
When de4dot fails:
1. Get the program running (dotnet target.exe or just double-click)
2. MegaDumper / ExtremeDumper dump process memory → export the decrypted assembly
3. Use de4dot to clean up residual obfuscation in the dump
4. If metadata is corrupted, rebuild it with dnlib (see common-workflow.md)
```

---

## Manual string decryptor extraction

Obfuscators encrypt strings and call a decrypt method at runtime to restore them. de4dot auto-detects the decryptor most of the time; when it fails, do it manually:

```text
1. Find the decrypt method in dnSpyEx (usually a fixed signature: static string Decrypt(int) or Decrypt(string, int))
   - Characteristics: called in bulk, arguments are numeric constants, returns string
2. Note the method token (e.g. 0x06000012)
3. Specify the decryptor to de4dot:
   de4dot --strtyp delegate --strtok 0x06000012 target.exe -o target-clean.exe
```

If even the decrypt method itself is obfuscated (control-flow flattening), you need to deobfuscate the control flow before locating the decryptor.

## Common anti-debug techniques

| Technique | Location | Bypass |
|------|------|------|
| `Debugger.IsAttached` check | any method | IL change to `ldc.i4.0; ret` or patch the getter |
| `Debugger.IsLogging` | — | same as above |
| Timing check (`DateTime.Now` delta) | method entry | patch out the delta comparison |
| `CheckRemoteDebuggerPresent` P/Invoke | — | nop out the call |
| Exception-driven control flow (try/catch path selection) | main logic | cannot simply nop; analyze the real path in the catch block |

> .NET anti-debug is simpler than native — most are managed API calls, a one-line dnSpyEx IL edit suffices.

## Fallbacks when de4dot fails

1. **de4dot --detect** to see the result, compare with the table above
2. **Runtime dump** (MegaDumper / ExtremeDumper / Process Hacker export module)
3. **dnlib script** manual decryption (see the dnlib section of common-workflow.md)
4. **Dynamic first**: run it and break at the decryption point to see the plaintext directly; you can get intel without unpacking

Community references: Washi's blog "misconceptions-about-dotnet" (common misconceptions about IL analysis), the Kanxue .NET reverse engineering board, Guided Hacking's "Top 5 .NET RE Tools".
