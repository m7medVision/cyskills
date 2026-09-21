
# APK Reverse Engineering CLI Work Specification

## Scope

Use this skill first when the task matches any of the following scenarios:

- Analyze an APK's Java business logic
- Locate login, signing, risk control, certificate validation, root detection
- View and modify `AndroidManifest.xml`
- View and modify smali
- Repack the APK
- Use Frida for Java/native dynamic hooks
- Switch to native analysis when the APK contains `.so` files

## CLI Tools Verified Available on the Current Machine

- `jadx` `1.5.5`
- `apktool` `3.0.2`
- `frida-ps` `17.9.6`
- `adb`
- `java`

## Scenarios Where You Should Prefer the Scripts

The following flows are frequent and their arguments are error-prone; prefer the skill's bundled scripts:

- Complete `jadx + apktool` output to disk and produce a summary in one shot: `scripts/decode.ps1`
- Frida device check, process listing, spawn/attach injection: `scripts/frida-run.ps1`
- Rebuild, align, sign, and install the APK: `scripts/rebuild-sign-install.ps1`
- Quickly extract key Manifest components and permissions: `scripts/manifest-summary.ps1`

Keep the following one-liners as direct calls; do not wrap them separately:

- `adb devices`
- `adb logcat`
- `frida-ps -U`
- `jadx --version`
- `apktool --version`

## Bundled Scripts

### `scripts/decode.ps1`

Purpose:

- Run `jadx` and `apktool` in a unified way
- By default create the task output directory next to the original APK
- Output a summary of `package`, `java_files`, `smali_dirs`, `so_files`, etc.
- Tolerate cases where `jadx` partially fails to decompile but still produces usable artifacts

Example:

```powershell
pwsh -File "<skill-root>\apk-reverse\scripts\decode.ps1" -ApkPath "D:\DOWNLOAD\app.apk" -Clean
pwsh -File "<skill-root>\apk-reverse\scripts\decode.ps1" -ApkPath "D:\DOWNLOAD\app.apk" -Name demo -SkipJadx
```

### `scripts/frida-run.ps1`

Purpose:

- Unify Frida's device, process, and spawn/attach entry points
- Avoid confusing `-f`, `-n`, and `-U` when hand-writing arguments

Example:

```powershell
pwsh -File "<skill-root>\apk-reverse\scripts\frida-run.ps1" -ListDevices
pwsh -File "<skill-root>\apk-reverse\scripts\frida-run.ps1" -Usb -ListProcesses
pwsh -File "<skill-root>\apk-reverse\scripts\frida-run.ps1" -Usb -Spawn -Package com.example.app -ScriptPath "D:\hooks\test.js"
```

### `scripts/rebuild-sign-install.ps1`

Purpose:

- `apktool b` to rebuild the APK
- `zipalign` alignment
- `apksigner` signing and verification
- Optional direct `adb install`

Example:

```powershell
pwsh -File "<skill-root>\apk-reverse\scripts\rebuild-sign-install.ps1" -ProjectDir "C:\work\apktool_out" -Clean
pwsh -File "<skill-root>\apk-reverse\scripts\rebuild-sign-install.ps1" -ProjectDir "C:\work\apktool_out" -Install -Reinstall -DeviceSerial "127.0.0.1:7555"
```

Notes:

- Generate and reuse a debug keystore by default
- Output next to `ProjectDir` by default, convenient for keeping it with the original package and unpacked directory

### `scripts/manifest-summary.ps1`

Purpose:

- Extract the package name
- List permissions
- List activity/service/receiver/provider
- Mark the main launcher activity

Example:

```powershell
pwsh -File "<skill-root>\apk-reverse\scripts\manifest-summary.ps1" -ManifestPath "C:\work\apktool_out\AndroidManifest.xml"
```

If you need to analyze `.so`, `lib/arm64-v8a/*.so`, or `lib/armeabi-v7a/*.so`, also combine with:

- `ida-reverse`
- `radare2`

## Tool Responsibilities

### `jadx`

Used for:

- Reading Java decompilation
- Searching package names, class names, method names
- Understand the APK from high-level logic first

Common commands:

```bash
jadx -d jadx_out app.apk
jadx --single-class com.example.LoginActivity -d jadx_out app.apk
jadx --deobf -d jadx_out app.apk
```

### `JEB Pro` (optional commercial tool)

Used for:

- Cross-validation and deep decompilation of Android DEX / APK / ARM
- Supplement static analysis when JADX output is incomplete or heavily obfuscated
- Perform second-toolchain validation of classes, methods, and call relationships for the same target

Boundaries:

- JEB Pro is commercial software; the user must obtain it and install a valid license themselves. This package will not download, crack, or circumvent licensing.
- Only invoke it when `tool-index` has confirmed JEB is available locally; otherwise continue using `jadx`, `apktool`, Ghidra, IDA, or radare2.
- The third-party JEB MCP bridge is not a dependency of this package. Before installing, you must review its source, permissions, network behavior, and version per `skill-supply-chain.md`, and the user must explicitly confirm registration.

### `apktool`

Used for:

- Unpack the APK
- View and modify `AndroidManifest.xml`
- View and modify smali
- Rebuild the APK

Common commands:

```bash
apktool d app.apk -o apktool_out
apktool b apktool_out -o rebuilt.apk
```

### `frida`

Used for:

- Dynamically observe Java method calls
- Hook native exported functions
- Bypass root detection, certificate validation, debug detection

Common commands:

```bash
frida-ps -U
frida -U -f com.example.app -l hook.js
frida-trace -U -f com.example.app -j '*!*certificate*'
```

### `adb`

Used for:

- Device connection
- Install APK
- View logs
- Pull files

Common commands:

```bash
adb devices
adb install -r app.apk
adb shell pm list packages
adb logcat
adb pull /data/local/tmp/file .
```

## Recommended Workflow

### 1. Triage

First determine the APK's rough composition; do not rush to modify the package or hook.

Suggested actions:

1. Export Java code with `jadx -d jadx_out app.apk`
2. Export smali and resources with `apktool d app.apk -o apktool_out`
3. First look at:
   - `AndroidManifest.xml`
   - the main `package`
   - `application`, `activity`, `service`, `receiver`
   - whether there are `.so` files in the `lib/` directory
4. Issue #65 threat-pattern quick reference (authorized samples/devices; see `nonpe-format-cookbook.md` §7–8):
   - Transparent/hidden icons (AU): `aapt dump badging` + manifest theme/label/icon → `E-android-hidden-icon-manifest`
   - Magisk/script wiper patterns and remote curl|sh (AR/AS) → record patterns and URLs as evidence; do **not execute** destructive commands
   - Persistence paths (AT): `service.d` / `priv-app`, etc. → `E-android-persistence`

### 2. Observe Java Logic

Read from `jadx_out` first:

- `MainActivity`
- `Application`
- Login, network, crypto, risk control related classes
- Third-party SDK initialization classes

Common keywords:

- `login`
- `sign`
- `encrypt`
- `cipher`
- `token`
- `root`
- `certificate`
- `trust`
- `okhttp`
- `retrofit`
- `webview`

If the Java code is readable, locate the business logic here first.

### 3. Confirm at the Smali and Resource Layer

When `jadx` results are incomplete, heavily obfuscated, or you need to actually patch, switch to `apktool_out`:

- Look at `smali*/`
- Look at `res/values/strings.xml`
- Look at `AndroidManifest.xml`

Prefer patching:

- `android:exported`
- Debug flags
- Root detection return values
- Login verification logic
- Certificate validation branches

### 4. Rebuild and Install

After modifying:

```bash
apktool b apktool_out -o rebuilt.apk
```

Or close the loop directly with the script:

```powershell
pwsh -File "<skill-root>\apk-reverse\scripts\rebuild-sign-install.ps1" -ProjectDir "apktool_out" -Install -Reinstall -DeviceSerial "127.0.0.1:7555"
```

Notes:

- This skill only guarantees the `apktool` rebuild chain
- If you later need to formally install to a device, a signing flow is usually also required
- If the task moves into signing/alignment, add `apksigner` / `zipalign`

### 5. Dynamic Hooks

When static analysis is insufficient, use Frida:

- Hook the login function
- Hook key points of `OkHttp` / `Retrofit` / `WebView`
- Hook `javax.crypto`, `MessageDigest`
- Hook the root detection function
- Hook the SSL pinning logic

Principles:

- Hook the Java layer first, then decide whether native hooks are needed
- Print arguments and return values first, then decide whether to actively modify return values

Suggestions:

- Use `frida-*` directly for simple one-off commands
- Prefer `scripts/frida-run.ps1` for stable, reusable injection flows

### 6. Native `.so` Triage

If the APK contains critical `.so` files:

- Use `apktool` or `jadx` to find `lib/**/*.so`
- If you only need exported symbols, strings, or quick triage, use `radare2`
- For long-term in-depth analysis, decompilation, renaming, and type recovery, use `ida-reverse`

Switch to native as soon as you see these signals:

- The Java layer is only a JNI wrapper
- The core signing logic is not in Java
- The key logic disappears after `System.loadLibrary()`
- Certificate validation/risk control is in the `.so`

## Output Requirements

At the end, at minimum explain:

- Entry components and key classes
- Whether the key logic is in Java, smali, or `.so`
- Confirmed sensitive points: login, signing, root, SSL, WebView, JNI
- If you patched anything, explain what you changed
- If you hooked anything, explain which class/method/exported function you hooked

## Prohibitions

- Do not blindly modify smali from the start
- Do not write hooks before looking at the manifest and main entry point
- Do not equate incomplete Java decompilation with "unanalyzable logic"
- Do not keep grinding on the Java layer when the `.so` clearly carries the core logic

## Quick Command Cheat Sheet

```bash
# Decompile Java
jadx -d jadx_out app.apk

# Unpack the APK
apktool d app.apk -o apktool_out

# Rebuild the APK
apktool b apktool_out -o rebuilt.apk

# Devices and processes
adb devices
frida-ps -U

# Launch and inject
frida -U -f com.example.app -l hook.js
```


## Routing context

**Upstream entry**: `skills/SKILL.md` (master control), routing.md
**Downstream exits**:
- Core logic in `.so` → `ida-reverse/` or `radare2/`
- Need dynamic Hook/verification → `reverse-engineering/tools-dynamic.md` (Frida chapter)
- General reverse engineering methodology → `reverse-engineering/SKILL.md`

**Sibling modules**: `reverse-engineering/` (.so analysis and advanced Frida usage)


## On-Demand Bootstrap

This skill's entry scripts are integrated with the unified bootstrap system. When a tool is missing, it will not fail outright but will automatically attempt installation.

### Automation Capability Boundaries

| Tool | Auto-installable | Installation method | Notes |
|------|-----------|---------|------|
| jadx | ✓ | GitHub Release ZIP | Automatically download and extract to `%USERPROFILE%\Tools\jadx\` |
| apktool | ✓ | GitHub Release JAR + wrapper | Automatically download the jar and generate a bat into `%USERPROFILE%\Tools\apktool\` |
| JEB Pro | ✗ | Manual user install with a valid license | Optional Android / ARM cross-validation tool; the third-party MCP bridge requires separate auditing |
| frida / frida-ps | ✓ | pip install frida-tools | Requires Python to be installed |
| adb | ✓ | winget / fallback path | Automatically install Android Platform-Tools |
| zipalign | ✗ | Requires manual installation of Android Build-Tools | `sdkmanager "build-tools;35.0.0"` |
| apksigner | ✗ | Requires manual installation of Android Build-Tools | Same as above |

### Bootstrap Trigger Points

- `scripts/decode.ps1`: automatically invokes bootstrap-reverse.ps1 when jadx or apktool is missing
- `scripts/rebuild-sign-install.ps1`: automatically invokes bootstrap when adb or apktool is missing
- `scripts/frida-run.ps1`: currently still a manual check (frida is usually already installed via pip)

### When Bootstrap Fails

If auto-install fails, the script throws a clear error with a manual installation link. Common causes:
- Network unavailable (GitHub API / PyPI unreachable)
- winget unavailable (Windows version too old)
- Java not installed (apktool depends on the JDK)
