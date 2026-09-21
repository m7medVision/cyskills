
# macOS / Mach-O Reverse Engineering

## Use cases

- Mach-O executables / dylib / framework
- .app bundles, LaunchAgent/Daemon
- Objective-C / Swift symbols and runtime
- Notarization/signing, Hardened Runtime, and TCC-related behavior analysis
- macOS malware static/dynamic analysis (together with malware-analysis)

## Workflow

### 1. Bundle and signing

```bash
file target
codesign -dv --verbose=4 target
spctl -a -vv target 2>&1
otool -L target
```

### 2. Static

```text
□ class-dump / swift-demangle / Hopper / Ghidra / IDA
□ Strings, XPC service names, TCC-sensitive APIs
□ LC_LOAD_dylib dependencies and rpath
```

### 3. Dynamic

```text
□ lldb / Frida
□ fs_usage / log stream observation
□ Network: together with protocol-reverse or a proxy
```

## Toolchain

| Tool | Purpose |
|------|---------|
| otool / nm / codesign | Built into the system |
| Hopper / Ghidra / IDA | Decompilation |
| class-dump / dsdump | ObjC |
| Frida / lldb | Dynamic |
| jtool2 | Mach-O |

## References

- `macho-triage.md`
- `the `mobile-reverse` skill` (iOS) `the `ghidra-reverse` skill` `the `malware-analysis` skill`

## Routing context

**Upstream**: MASTER R31  
**Downstream**: iOS → mobile-reverse; general samples → malware-analysis
