# Red-Team Sharp* Tool Analysis & Tool Install Matrix & dnSpy MCP

## Red-team Sharp* tool analysis

Red-team tools are written heavily in C# (the Sharp* series); reverse engineering them is a common scenario: understand detection logic, change signatures, extract embedded configuration.

### Common Sharp* tools quick reference

| Tool | Function | Reverse-engineering focus |
|------|------|-----------|
| **Rubeus** | Kerberos attacks (AS-REP roast / Kerberoast / S4U / pass-the-ticket) | Rubeus has a fixed project structure; find the `Interop.*` P/Invoke sections to see native calls |
| **SharpHound** | BloodHound data collector | LDAP query logic, the set of collected attributes |
| **SharpShell / SharpWS** | Remote execution, lateral movement | WMI / WinRM calls, command obfuscation |
| **Seatbelt** | Information gathering | collection item list, decision logic |
| **SharpRoast** | Kerberoasting | ticket request/parsing |
| **Inveigh / SharpSploit** | Man-in-the-middle / general exploitation framework | reflective loading, API call chain |

### General analysis approach

```text
1. Open in dnSpyEx (usually not obfuscated; a few teams add ConfuserEx)
2. Look at Program.Main or the entry command dispatch (Rubeus is structured as switch(command))
3. Find the implementation class/method of the target command
4. Look at the P/Invoke sections (the Interop.* namespace) — native API calls are here
5. Extract embedded resources (some tools embed config/templates)
6. If you need to change signatures (EDR evasion): change command strings, API calls, string constants
```

### Rubeus structure example

Rubeus uses command dispatch, one class per subcommand. To find the Kerberoasting logic:

```text
Entry: Rubeus.CommandLineParser → parse args
Dispatch: switch(command) → "kerberoast" → execute Ask.TGS(...)
P/Invoke: Rubeus.Interop.Lsa* / Native.cs → native Kerberos API
Key: LsaCallAuthenticationPackage (KERB_RETRIEVE_TKT_REQUEST)
```

Changing signatures (evasion): change the command string `"kerberoast"` to a custom name, change the `Rubeus` banner string, change the P/Invoke call order.

### Embedded configuration extraction

Many loaders/tools encrypt and embed the C2, keys, and certificates in resources or fields:

```powershell
# In dnSpyEx look at Resources (resource tree)
# or on the command line
powershell -c "[System.Reflection.Assembly]::LoadFile('target.exe').GetManifestResourceNames()"
# After finding the resource, right-click in dnSpyEx → Extract / Save
```

Config decrypted at runtime → dynamically break at the return point of the decrypt method and dump the plaintext (see `common-workflow.md`).

---

## Tool install matrix

### Windows (preferred, dnSpyEx is a GUI)

```powershell
# Option A: Chocolatey
choco install dnspy ilspy de4dot detect-it-easy

# Option B: manually download releases (recommended, version-controllable)
# dnSpyEx:    https://github.com/dnSpyEx/dnSpy/releases
# de4dot:     https://github.com/de4dot/de4dot/releases
# ILSpy:      https://github.com/icsharpcode/ILSpy/releases
# DIE:        https://github.com/horsicq/Detect-It-Easy/releases
# dnlib:      dotnet add package dnlib  (NuGet)
```

### Linux / macOS (no dnSpyEx GUI, use the CLI)

```bash
# ILSpy CLI decompile
dotnet tool install -g ilspycmd
ilspycmd target.exe -p -o outdir/         # decompile to a directory

# de4dot cross-platform (needs mono or dotnet)
# Download the de4dot artifact .dll from releases, run it with dotnet
dotnet de4dot.dll target.exe -o target-clean.exe

# dnlib (scripting, needs the dotnet SDK)
dotnet new console -o dnclean && cd dnclean
dotnet add package dnlib

# DIE CLI (diec)
# Linux: install from https://github.com/horsicq/Detect-It-Easy
diec target.exe
```

### .NET runtime prerequisite

```bash
# Linux
sudo apt install dotnet-runtime-8.0        # or 6.0/7.0 depending on the target
# macOS
brew install --cask dotnet-sdk
```

> dnSpyEx (with IL editor + debugger) only exists as a Windows GUI version. On Linux/macOS, .NET reverse engineering can only use `ilspycmd` decompilation + `dnlib` script patching; there is no equivalent interactive debugging GUI. Prefer Windows when you need to patch.

---

## dnSpy MCP integration

The community already has several dnSpy MCP projects that expose dnSpy's decompilation/IL inspection as MCP tools an AI can call directly — fully consistent with the MCP philosophy of reverse-skill.

### Mainstream dnSpy MCP projects

| Project | Features | Compatibility |
|------|------|------|
| **soufianetahiri/dnspy-mcp** | Core MCP server, exposes tools such as decompile, IL inspection | Claude Code / Cursor |
| **AgentSmithers/DnSpy-MCPserver-Extension** | Runs as a dnSpyEx extension, deeply integrates with the GUI | loaded inside dnSpyEx |
| **malwarecakefactory/dnspy-mcp-extension** | 33 tools covering the full triage → deobfuscation flow | full-flow automation |

### Registering with the Claude MCP config

After installing the dnSpyEx extension per the corresponding project README, register it in `~/.claude/mcp.json` (the exact command/args follow the project README):

```json
{
  "mcpServers": {
    "dnspy": {
      "command": "dotnet",
      "args": ["path/to/dnspy-mcp.dll"]
    }
  }
}
```

After registration, this skill's AI integration path: the user says "analyze this .NET" → route to `dotnet-reverse/` → prefer calling the `dnspy_decompile` / `dnspy_inspect_il` tool surface → fall back to the GUI if that fails.

> dnSpy MCP is not a built-in bootstrap capability of reverse-skill; the user must manually install and register the extension per the project README. It may be added to `bootstrap-manifest.json` later.

---

## Community resource index

### Highly recommended

- **Washi's blog** — .NET reverse engineering expert: https://blog.washi.dev/posts/misconceptions-about-dotnet/
  - Core point: **don't over-rely on dnSpy's C# decompiler; get familiar with the IL editor** (consistent with this project's IL-first principle)
- **dnSpyEx** — the actively maintained fork of dnSpy: https://github.com/dnSpyEx/dnSpy
- **de4dot** — .NET deobfuscation: https://github.com/de4dot/de4dot
- **dnlib** — metadata programming: https://github.com/dnlib/dnlib

### Hands-on tutorials

- Medium "De-obfuscating and reversing a .NET/C# spyware" — dnSpy + de4dot hands-on info-stealer deobfuscation
- YouTube "dnSpy Patch .NET EXEs & DLLs" — step-by-step patch + keygen
- Kanxue forum .NET reverse engineering board — search ".net reverse" / "dnSpy" / "ConfuserEx" for many hands-on posts, Nuitka reverse engineering, and AV-evasion discussion
- Guided Hacking "Top 5 .NET Reverse Engineering Tools" — dnSpy still ranks first
- StackExchange / Reverse Engineering — advanced questions such as `DynamicMethod` debugging

### Existing .NET resources in this repo (integration)

- `reverse-engineering/tools.md` `.NET Analysis` section — dnSpy/ILSpy tool quick reference + Codegate 2013 two-stage XOR+AES-CBC pattern
- `reverse-engineering` skill — .NET tooling notes
- `reverse-engineering/awesome-re-resources.md` — de4dot included
- `field-journal/seed-014_unity-il2cpp-reverse.md` — Unity IL2CPP (native side, complementary to the .NET managed layer)

Deep .NET reverse engineering content converges into this module; `reverse-engineering/` only needs to keep a quick-reference index.
