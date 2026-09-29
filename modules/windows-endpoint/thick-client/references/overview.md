
# Thick Client Security Testing

## Applicable Scenarios

- Client/server (C/S) desktop clients, Electron/Qt/.NET WinForms/WPF
- Local configuration/credential storage, IPC, named pipes
- Research on bypassing client-side enforcement (authorized)
- Auto-update channels and code-signature verification

## Workflow

### 1. Establish boundaries

```text
□ Process tree, child processes, drivers/services
□ Listening ports and outbound domains
□ Sensitive local paths: %APPDATA%, Keychain, registry
```

### 2. Local attack surface

```text
□ Plaintext config, hardcoded keys, debug switches
□ DLL hijacking/search order (Windows)
□ Database files (SQLite) permissions and encryption
□ IPC: who can connect? Is it authenticated?
```

### 3. Network surface

```text
□ System proxy / application custom TLS
□ Certificate pinning → combine mobile/js methodology or Frida
□ API privilege abuse: admin interfaces hidden by the client
```

### 4. Reverse-engineering validation

```text
□ .NET → dotnet-reverse; native → ida/ghidra; Electron → asar + js-reverse
```

## Toolchain

| Tool | Purpose |
|------|------|
| Process Monitor / API Monitor | Behavior |
| Burp / mitmproxy | Traffic |
| dnSpy / IDA / Ghidra | Reverse engineering |
| Sysinternals | Windows surface |
| asar / nexe detection | Electron |

## References

- `thick-client-checklist.md`
- `the `dotnet-reverse` skill` `the `ida-reverse` skill` `the `js-reverse` skill` `the `pentest-core` skill`

## Routing Context

**Upstream**: MASTER R32
**Downstream**: pure protocol `protocol-reverse`; supply-chain updates `task-supply-chain`
