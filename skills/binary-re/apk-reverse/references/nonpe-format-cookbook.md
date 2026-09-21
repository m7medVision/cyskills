# Non-PE / Multi-format Agent Response Cookbook U–AV + AW–DN

> Parallel to the PE anti-analysis cookbook A–T (../anti-analysis.md): organized by **file type**, giving "trigger → one-line action → Evidence".  
> This is **not** a second main workflow. After Triage identifies the type, jump to the corresponding skill + this table.  
> Assumes an **authorized isolated lab / authorized samples and devices**. For wipers, BYOVD, reflective injection, etc., write **detection and forensics**, not unauthorized destruction/exploitation tutorials.  
> Bypass or deobfuscation failures MUST also be recorded as Evidence; never silently treat them as "harmless".
>
> §1–§8 / U–AV = original rules (Issue #65). §9–§23 / AW–DN = extended rules (Issue #87, after deduplication + semantic enhancements + edge-case patches).

## 0. Routing Quick Reference

| Type clue | Main skill | Section in this table |
|----------|----------|----------|
| .bat / .cmd / batch | malware-analysis | §1, §19 |
| .ps1 / PowerShell | malware-analysis | §2, §20 |
| Office macro / VBA / XLM / .docm/.xlsm | malware-analysis | §3 (includes DD OLE extraction, DJ XLM macros) |
| .docx/.xlsx/.pptx OOXML external links / DDE / .rtf OLE | malware-analysis | §10 (includes DK RTF) |
| Web/frontend JS obfuscation, JSVMP | js-reverse | §4, §21 (includes DE/DF) |
| .sys / kernel driver | reverse-engineering/kernel-driver-reverse.md + cre | §5 |
| .dll focus | malware-analysis / re-agent-workflow | §6 (deduplicated against A–T) |
| APK / Magisk / hidden icons | apk-reverse | §7–§8, §23 |
| .pdf / PDF document | malware-analysis | §9 |
| .wasm / WebAssembly | reverse-engineering | §11 |
| .jar/.class / Java bytecode | reverse-engineering | §12 |
| .exe(AutoIt) / .au3 | malware-analysis | §13 |
| .hta / HTML Application | malware-analysis | §14 |
| .wsf/.jse/.vbe | malware-analysis | §15 |
| .msi / Windows Installer | malware-analysis | §16 |
| .reg / registry script | malware-analysis | §17 |
| .vbs / VBScript | malware-analysis | §18 |
| Xposed/LSPosed modules | apk-reverse | §22 |
| ELF / Linux binary | reverse-engineering | → elf-analysis.md, anti-analysis.md |
| Mach-O / macOS/iOS | reverse-engineering | → platforms.md |
| Python bytecode | reverse-engineering | → languages.md |

## 1. BAT/CMD (U V W)

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **U** | Many SET single-character variables + %a%%b% concatenation, or ^ line continuation splitting commands | Expand SET line by line; produce a command list after deobfuscation; a batch deobfuscation tool may be used; **forbid** treating it as "no action" before deobfuscation | E-batch-deobf | P0 |
| **V** | Garbled when opened as text, HEX header FF FE (UTF-16 LE BOM) | Confirm the BOM → convert to UTF-8 then parse; or chcp 65001 + type | E-batch-encoding | P2 |
| **W** | Many REM/:: comments and redundant GOTO/labels drowning the real logic | Remove comments; trace the real GOTO path; execute in isolation and capture the actual cmd command log | E-batch-deadcode | P1 |

## 2. PowerShell (X Z)

> Numbering preserves the proposer's convention: **no patch Y**.

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **X** | Multiple layers of FromBase64String / Gzip / Compress / nested -replace | Decode **layer by layer**; record each layer's result separately; tools optional (PowerDecode, etc.), otherwise manual/scripted | E-ps-decode-layer-N | P0 |
| **Z** | Reversed strings, fragments + concatenation followed by Invoke-Expression/IEX | Recover the complete string; break on IEX or log script blocks; record the cleartext command as Evidence | E-ps-string-restore | P1 |

## 3. VBA Macros / XLM (AA AB AC DD DJ)

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **AA** | olevba/OLEDump shows only P-Code, source stream empty (VBA Stomping) | P-Code decompilation tools; if incomplete, observe via Word/Excel macro debugging; document the limitations | E-vba-pcode | P0 |
| **AB** | Many Chr() concatenations or Base64 strings, suspected shellcode/nested script | Recover the string in the Immediate window/via script; determine the type after decoding; dynamically watch CreateObject/Shell | E-vba-str-decode | P1 |
| **AC** | Meaningless If 1=2, or InsertLines/DeleteLines self-modification | Statically follow the real branch; dynamically breakpoint the self-modifying API and dump the modified macro | E-vba-selfmod | P2 |
| **DD** | olevba/oledump detects a VBA macro project (vbaProject.bin); extensions .docm/.xlsm/.pptm | Use oledump.py to inspect the OLE stream structure; use olevba to extract VBA source and detect suspicious APIs; check auto-executing macros such as AutoOpen/Workbook_Open | E-office-vba | P0 |
| **DJ** | .xls/.xlsm contains Excel 4.0/XLM macros (hidden in cell formulas, not a VBA stream); olevba detects XLM macro markers | Use olevba --xlm to extract XLM macro formulas; check the EXEC/CALL/REGISTER functions in hidden worksheets; use XLMMacroDeobfuscator for dynamic simulation and recovery | E-office-xlm | P0 |

## 4. JavaScript (AD AE AF) → main path js-reverse

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **AD** | Custom bytecode array + while/switch interpreter (JSVMP) | Find the VM entry and opcode dispatch; dynamic log tracing; dual-track AST + dynamic; see js-reverse DeepDive | E-js-vmp | P0 |
| **AE** | while(1){switch} + large string-array indexing | Reconstruct with AST/Babel; recover strings from array indexes; wakaru etc. optional; do **not** paste the whole PE ollvm-deobfuscation essay | E-js-deobf | P0 |
| **AF** | debugger, console hijacking, performance.now delta, DevTools detection | Disable breakpoints / fix the time source / use a headless browser; patch the detection points; authorized pages | E-js-anti-debug | P1 |

## 5. SYS Kernel Drivers (AG AH AI)

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **AG** | DriverEntry is very short and the logic is not at the entry point | Scan non-empty slots of MajorFunction[]; prioritize IRP_MJ_DEVICE_CONTROL/CREATE; record the address list as evidence | E-driver-irp-handlers | P0 |
| **AH** | DeviceIoControl / IOCTL dispatch present | Build a control-code→handler table; mark METHOD_* and buffer direction; the user-mode communication surface | E-driver-ioctl | P0 |
| **AI** | Sample loads/drops a known vulnerable driver or an anomalously signed driver (BYOVD pattern) | Compare against **public** lists such as LOLDrivers; record driver name/hash/signature; analyze the **invocation intent**; do **not** lay out exploit steps | E-driver-byovd | P1 |

See kernel-driver-reverse.md for the flow; this table only adds agent action anchors.

## 6. DLL (AJ–AQ) — deduplicated against A–T / #72

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **AJ** | DLL analysis only looked at exports/EP, ignoring TLS or DllMain | **Both TLS callbacks + DllMain must be examined**; the dynamic breakpoint order still follows the four-stage rocket (TLS→EP/DllMain→API→ExitProcess) | E-dll-tls-dllmain | P0 |
| **AK** | Export names look benign at first then malicious, are misspelled, or the exports do not match the behavior | Cross-reference the export table with actual calls; list anomalous exports | E-exports-anomaly | P0 |
| **AL** | No exports or very few exports, yet still loaded | Locate via entry point, strings, xrefs, and callers; do not give up because of "no exports" | E-dll-noexport | P0 |
| **AM** | Static IAT is missing a DLL, only used at runtime | **See A–T patch R** (Delay-Load / E-delay-import); do not duplicate the long text here | E-delay-import | P0 pointer |
| **AN** | Need to recover exported function arguments and calling convention | Cross-reference + dynamically inspect registers/stack; annotate stdcall/fastcall, etc. | E-dll-export-abi | P1 |
| **AO** | Suspected DLL hijacking/sideloading | Check the app directory for same-named DLLs, search paths, KnownDLLs; a legitimate program + anomalous DLL combination | E-dll-sideload | P1 |
| **AP** | Clues of fileless mapping/reflective loading | Memory characteristics, loader behavior, pathless modules; forensics in an authorized environment | E-dll-reflective | P1 |
| **AQ** | Lowering risk only because export names "do not look malicious" | **Forbidden** to judge safety from export names alone; combine section permissions, entry point, strings, and dynamic behavior | E-dll-export-priority | P1 |

The hard gate for DLL/SYS remains: E-imports + E-exports (see re-agent-workflow).

## 7. Android Wipers / Persistence (AR AS AT) → apk-reverse

> **Authorized samples, images, or test devices only.** Actions are detection and extraction of IOCs and persistence paths, not carrying out destruction.

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **AR** | Magisk module/script contains **wiper-pattern commands** such as wiping data, flashing, or bulk rm of system partitions | Pattern-command table + module paths; flag high-risk destructive capability; do not execute wiper commands | E-android-wiper-cmd | P0 |
| **AS** | Repeated curl|sh / remote script fetching, unusual C2 URLs | Extract the URL; analyze whether the downloaded body contains wiper commands; record temp paths | E-android-wiper-backdoor | P0 |
| **AT** | /data/adb/service.d, post-fs-data.d, suspicious /system/priv-app, etc. | List persistence scripts/APKs; record content summaries as evidence | E-android-persistence | P1 |

## 8. Android Transparent/Hidden Icons (AU AV) → apk-reverse

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **AU** | LAUNCHER icon fully transparent/empty label, Theme.NoDisplay, no LAUNCHER category, component disabled | aapt dump badging + manifest; decompile to inspect icon pixels; record anomalies as evidence | E-android-hidden-icon-manifest | P0 |
| **AV** | Installed but no desktop icon, with background traffic/auto-start/high-risk permissions/dynamically restored icon | pm list vs desktop; dumpsys package; broadcasts and device_admin; record behavior as evidence | E-android-hidden-icon-behavior | P1 |

---

> **The following §9–§23 are Issue #87 extended rules (AW–DC).**
> Duplicate ELF (→ elf-analysis.md), Mach-O (→ platforms.md), and Python (→ languages.md) sections have been removed.

## 9. Malicious PDF Documents (AW AX AY AZ)

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **AW** | pdfid detects /JS, /JavaScript, /OpenAction, /AA, /Launch counts > 0 (including counts for obfuscated hex-encoded names such as /4A#61#76#61...) | pdfid -e statistics (compare plain vs obfuscated counts); pdf-parser to extract suspicious objects; peepdf interactive analysis + JS simulation | E-pdf-autoaction | P0 |
| **AX** | pdfid detects /EmbeddedFile > 0; object streams contain FlateDecode/ASCIIHexDecode cascaded filter chains; or an encoded payload is hidden in an /Annot object | pdf-parser to extract stream data; peepdf to decode multi-level cascaded filters (including AES-encrypted streams with security handler r5/r6); check Annotation objects; file to identify the decoded result type | E-pdf-embedded | P0 |
| **AY** | Extracted PDF JS contains large amounts of eval, unescape, String.fromCharCode, atob | peepdf JS simulation execution tracing; decode Base64/Hex/ROT13 layer by layer; CyberChef as an aid | E-pdf-js-deobf | P1 |
| **AZ** | Anomalous PDF structure: /JBIG2Decode, manipulated XREF table, skipped object numbers | pdfid -d to rename suspicious keywords; check known CVE exploitation patterns; extract exploit trigger conditions | E-pdf-exploit | P1 |

## 10. Office OOXML / DDE / RTF (BA BB DK) → complements §3 VBA

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **BA** | After unzipping a docx/xlsx/pptx ZIP, word/_rels/ or xl/_rels/ contains suspicious external relationships (including remote template injection) | Check *.rels external links; check vbaData.xml; extract embedded OLE objects; check protocol handler abuse (ms-msdt: / search-ms: / ms-officecmd:) | E-office-ooxml | P0 |
| **BB** | Document contains DDEAUTO or DDEEXEC field codes that execute external commands via fields | olevba --dde scanning; extract DDE command arguments; check whether it points to PowerShell/an external exe | E-office-dde | P0 |
| **DK** | .rtf file contains an embedded OLE object (not OOXML, not a classic OLE compound document) | rtfobj to extract the embedded OLE object; oleobj to analyze the object type; check for Equation Editor exploitation (CVE-2017-11882, etc.); file to identify the extracted artifact type | E-rtf-ole | P0 |

## 11. WebAssembly (BC BD BE)

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **BC** | File starts with the \x00asm magic bytes; or JS code contains WebAssembly instantiation logic | wasm2wat to convert to text; inspect the import section to identify host-environment imported functions; wasm-decompile to generate pseudocode; check the Emscripten glue signature (__wasm_call_ctors) to determine whether it was compiled from JS | E-wasm-struct | P0 |
| **BD** | Many WASM functions but simple logic, with function bodies split into tiny functions; or meaningless nested block/loop | diswasm to assess the function-minimization level; JEB Pro / IDA WASM plugin for deep analysis; dynamic tracing of execution logs | E-wasm-obfuscation | P1 |
| **BE** | WASM module interacts with the browser via JS imported/exported functions, with WebSocket, fetch, and WebGL calls present | Analyze the JS glue code and WASM module together; use browser DevTools to trace data exchange; extract network communication URLs/domains | E-wasm-c2 | P1 |

## 12. Java JAR/Class (BF BG BH BI)

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **BF** | When JD-GUI/jadx opens a JAR, class/method names are meaningless short strings (a.a.a / _0x prefix / numeric class names); or there is heavy while/switch control-flow obfuscation | Identify the obfuscator type (ProGuard / Allatori / ZKM); Java Deobfuscator for static deobfuscation; for high strength, dynamic debugging to trace the key logic | E-java-obfuscation | P0 |
| **BG** | Many Class.forName(), Method.invoke(), Constructor.newInstance() calls; or a custom ClassLoader + defineClass() loading classes in memory from a byte array; the import table is benign but malicious classes are loaded dynamically at runtime | javap -c -v to inspect reflection call details; trace Class.forName argument strings; check the source of the defineClass() byte array; dynamically break on Method.invoke | E-java-reflection | P0 |
| **BH** | JAR contains .so (Linux/Android) or .dll (Windows); or System.loadLibrary() calls | Extract the native library files; file to identify the format; switch to the standalone ELF/PE analysis flow | E-java-native | P1 |
| **BI** | JAR/ZIP contains nested JAR/WAR/EAR after extraction; high-entropy .dat/.bin/.img files exist in /resources, /assets | Recursively extract all nested archives; entropy analysis to determine encryption/compression; check META-INF/MANIFEST.MF and pom.xml | E-java-nested | P1 |

## 13. AutoIt (BJ BK BL DM)

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **BJ** | PE strings contain AutoIt / AU3 / EA05 / EA06 signatures; or a resource section contains AutoIt script resources (note the distinction from AutoHotKey; both share MITRE T1059.010) | autoit-ripper to extract the compiled script; identify the encoding family (EA05 = AutoIt3.00 / EA06 = AutoIt3.26); extract the 8-byte decryption key after the EA06 header to decrypt the payload; recover the source | E-autoit-extract | P0 |
| **BK** | Extracted script contains many StringEncrypt/_StringEncrypt calls; or dynamic Execute + meaningless variable names | myAutToExe static decompilation; identify anti-debug techniques; analyze the control flow after deobfuscation | E-autoit-deobf | P1 |
| **BL** | Script contains RegWrite (registry persistence), FileInstall (file drop), InetGet (network download), Run/RunWait | Flag the sensitive API call sequence; analyze the InetGet URL; trace the FileInstall drop path | E-autoit-malicious | P0 |
| **DM** | AutoIt acts as a loader performing process hollowing: CallWindowProc/EnumWindows callbacks + shellcode + injection into a legitimate process (regsvcs.exe, etc.), dropping a .NET payload (DarkGate / Snake Keylogger / ArechClient2 patterns) | Check the DllCall/DllCallbackRegister call chain to kernel32 injection APIs; extract the shellcode data; identify the injected target process; extract the .NET payload for standalone analysis | E-autoit-hollowing | P0 |

## 14. HTA / HTML Application (BM BN BO)

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **BM** | HTML contains HTA:APPLICATION tags, window.execScript, or CreateObject calls | Check the HTA:APPLICATION attributes (Application, WindowState); extract the VBS/JS in script tags | E-hta-bypass | P0 |
| **BN** | HTA launched via mshta.exe then uses XMLHttpRequest / ActiveXObject to fetch and execute a remote payload | Extract network request URLs; trace ActiveXObject creation (ADODB.Stream, etc.); recover the complete download-and-execute chain | E-hta-download-chain | P0 |
| **BO** | HTA contains only a single extremely long obfuscated string, executed via eval / execScript | Extract the Base64/Hex encoded payload and decode it; CyberChef recursive encoding-type detection; recover the payload | E-hta-oneline | P1 |

## 15. WSF / JSE / VBE (BP BQ BR BS)

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **BP** | .wsf contains \<job\> + \<script language="..."\> tags, mixing JScript/VBScript/Python | Split code blocks by \<script language\>; analyze each according to its language rules | E-wsf-multi | P0 |
| **BQ** | .jse/.vbe starts with the #@~^ signature, encoded by Microsoft Script Encoder | screnc-decoder to decode; if no tool is available, execute dynamically + dump the decoded script | E-jse-decode | P0 |
| **BR** | WSF with multiple \<script\> blocks + \<package\> referencing external resources + \<component\> referencing COM components | Build a cross-block call graph; trace function calls between \<script\> blocks; recover the complete execution flow | E-wsf-call-chain | P1 |
| **BS** | WSF contains WshShell.SendKeys to bypass UAC, WshShell.Run with window style 0 for hiding, WScript.Sleep delay-based bypass | Check whether simulated user actions are used to bypass security prompts; record stealthy execution parameters | E-wsf-anti-detect | P1 |

## 16. MSI Installers (BT BU BV)

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **BT** | MSI file contains a CustomAction table (Binary / Script / DLL type custom actions) | msiexec /a or lessmsi to extract contents; inspect the CustomAction table; extract the custom action binaries | E-msi-custom-action | P0 |
| **BU** | MSI Binary table contains VBScript/JScript custom action scripts | Extract the script binary from the Binary table and decode it into a readable script; analyze per VBS/JS rules | E-msi-script | P1 |
| **BV** | MSI silently installs via /quiet /passive /qn; ALLUSERS=1 for privilege escalation | Record the installation command-line arguments; analyze the Property table permission settings; flag the silent + privilege-escalation combination | E-msi-privilege | P1 |

## 17. REG Registry Scripts (BW BX BY)

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **BW** | .reg writes to HKCU\...\Run or HKLM\...\Run and other auto-start paths | Extract all paths; flag Run-path entries as persistence; record the complete paths and values | E-reg-persistence | P0 |
| **BX** | .reg modifies HKCR\...\shell\open\command (file association) or HKCR\CLSID\{...}\InprocServer32 (DLL injection) | Check whether shell\open\command points to an unusual exe; check the InprocServer32 DLL path | E-reg-hijack | P0 |
| **BY** | .reg modifies HKLM\...\Policies\System (UAC level), EnableLUA, ConsentPromptBehaviorAdmin | Check the default security configuration before modification; analyze the impact on UAC; flag the downgrade behavior | E-reg-uac-bypass | P1 |

## 18. VBScript (BZ CA CB CC DN)

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **BZ** | .vbs/.js parsed by both VBScript and JScript; conditional compilation (@_win32) or cross-language execution | Separate the VBScript/JScript code blocks; analyze the syntax of each; identify the mixed execution logic | E-vbs-mixed | P1 |
| **CA** | Script contains CreateObject("WScript.Shell") / CreateObject("Shell.Application") / Scripting.FileSystemObject | Flag high-risk COM object calls; trace Run/Exec arguments; trace file paths created by FSO | E-vbs-com-abuse | P0 |
| **CB** | Script starts with the #@~^ signature, encoded by Microsoft Script Encoder (VBS-specific) | screnc-decoder to decode; if no tool is available, execute dynamically + dump the decoded script | E-vbs-encoded | P0 |
| **CC** | VBA/VBScript contains WScript.Shell.Run + cmd /c + PowerShell followed by process injection | Trace the CreateObject COM object chain; analyze injection characteristics in the Run arguments; record the complete process creation chain | E-vbs-inject-chain | P0 |
| **DN** | VBScript/JScript achieves fileless persistence via WMI ActiveScriptEventConsumer (no startup folder / registry Run key) | Check WMI event subscriptions (__EventFilter + __FilterToConsumerBinding + ActiveScriptEventConsumer); extract the bound script content; flag fileless persistence | E-vbs-wmi-persist | P0 |

## 19. Advanced BAT/CMD Obfuscation (CD–CI) → complements §1 U–W

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **CD** | setlocal enabledelayedexpansion + !var! + dynamic variable names (!var_%i%!) | Expand statement by statement after enabling delayed expansion; Batch-Dump --expand for automatic expansion | E-bat-delayed-expand | P0 |
| **CE** | Executes via type/more/findstr reading the :stream ADS alternate data stream of itself or a file | Check for : suffix references (file.bat:payload); dir /r to list ADS; type file:stream to extract | E-bat-ads-hidden | P0 |
| **CF** | Many echo lines write a .tmp/.cmd temp file that is then executed via call | Extract all echo redirections to recover the temp file content; monitor scripts generated in the temp directory | E-bat-temp-gen | P1 |
| **CG** | for %%i in (...) do set var=%%i accumulating variables; for /f parsing command output line by line | Expand the for loop statement by statement and record each iteration's assignment; serialize and recover the for /f result | E-bat-for-expand | P1 |
| **CH** | Main batch receives arguments via %1 %* and is passed obfuscated instructions by a parent process/downloader | Check the calling context and record the passed arguments; decode and recover Base64 arguments; recover the complete call chain | E-bat-param-call | P1 |
| **CI** | certutil -decode / powershell -Command / echo \| findstr combined decode-and-execute | Extract Base64/Hex strings and decode; check whether the decoded result is an executable script/PE | E-bat-encoded-exec | P0 |

## 20. Advanced PowerShell Bypasses (CJ–CO, DL) → complements §2 X–Z

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **CJ** | AMSI bypasses such as [Ref].Assembly.GetType('...AmsiUtils') / amsiInitFailed / GetTypes() (including hardware-breakpoint bypass: CPU debug registers, no memory writes/VirtualProtect) | Identify the bypass pattern (Patch / registry / environment variable / hardware breakpoint); dynamically confirm it takes effect; flag the bypass technique type | E-ps-amsi | P0 |
| **CK** | [PSConstraintLanguage] type manipulation or modifying session state via DefaultRunspace to bypass CLM | Identify the CLM bypass pattern; flag bypass-clm; analyze the execution context after the bypass | E-ps-clm-bypass | P0 |
| **CL** | [ScriptBlock]::Create / $ExecutionContext.InvokeCommand constructors; or overriding ScriptBlock logging settings | Check whether the script disables logging; dynamically verify whether logging is bypassed | E-ps-sb-log-bypass | P1 |
| **CM** | IEX (New-Object Net.WebClient).DownloadString(...) or [Reflection.Assembly]::Load(FromBase64...) fileless execution | Extract the download URL and check domain/IP reputation; capture the in-memory loading code via PS logs; simulate in an isolated network to extract the payload | E-ps-reflect-load | P0 |
| **CN** | Three or more nested encoding layers: outer Base64 → Gzip → XOR → cleartext (beyond the two-layer scope of §2 X) | Recursively decode until cleartext or no further progress; record each layer's intermediate state; PowerDecode automation; record each layer's result as evidence | E-ps-multi-decode | P0 |
| **CO** | Set-Alias maps IEX to a single-character alias; Get-ChildItem variable: dynamically obtains variable values | Expand all alias mappings and substitute back the original command names; AST analysis to recover variables | E-ps-alias-decode | P1 |
| **DL** | Script patches ntdll.dll EtwEventWrite (stomping) to silence telemetry; often combined with AMSI bypasses | Check whether EtwEventWrite address acquisition + memory patching (ret 0xC3) is present; check together with CJ AMSI bypasses; flag the dual-bypass combination | E-ps-etw-bypass | P0 |

## 21. Advanced JavaScript Obfuscation (CP CQ DE DF) → complements §4 AD–AF

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **CP** | JS uses Proxy objects to intercept property access + Reflect API to dynamically call methods, bypassing static analysis | Identify Proxy get/set/apply trap functions; trace the actual target of Reflect.get; flag the dynamic interception behavior | E-js-proxy | P1 |
| **CQ** | JS contains a _0x... hex string array + while(!![]) infinite loop + for+switch control flow (obfuscator.io characteristics) | Identify the obfuscator.io characteristics (string array + infinite loop); de4js / jsnice for automatic deobfuscation; record the recovered code as evidence | E-js-obfuscator | P0 |
| **DE** | The main body is a large bytecode array + a VM interpreter loop (multiple while/switch), with the entry pointing to an eval/Function constructor; the business logic is completely unreadable (a deepening of §4 AD) | Identify the VM entry function and track the opcode→handler mapping; dynamically execute in the browser and hook eval output; JSimplifier AST reconstruction; record the opcode mapping table | E-jsvmp-deep | P0 |
| **DF** | JS contains eval dynamically generating new code and executing it immediately, document.write rewriting the page, or the Function constructor dynamically building function bodies | Hook eval and the Function constructor to record generated code; dynamically execute in the browser and capture self-modifying content | E-js-selfmod | P1 |

## 22. Xposed/LSPosed Module Analysis (CR–CX) → apk-reverse

> Analyze an Xposed/LSPosed **module itself** as a reverse engineering target (not a tool-usage scenario).

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **CR** | AndroidManifest.xml has no android:name entry Activity; meta-data specifies xposedmodule=true | Check assets/xposed_init to determine the entry class; search for implementations of the IXposedHookLoadPackage/ZygoteInit/CmdInit interfaces | E-xp-entry | P0 |
| **CS** | Code contains XposedHelpers.findAndHookMethod / XposedBridge.hookMethod / findClass | Extract the first argument of findAndHookMethod (target class) + the second argument (target method); build a target-app inventory | E-xp-hook-targets | P0 |
| **CT** | Module contains DexClassLoader/PathClassLoader dynamic loading; or Runtime.exec / ProcessBuilder command execution | Trace the DexClassLoader constructor arguments; extract the dynamically loaded DEX for standalone analysis; check exec command arguments | E-xp-dynamic-load | P0 |
| **CU** | Hook targets involve sensitive APIs such as payment/biometrics/SMS/contacts/location/crypto keys | Classify the sensitivity of the hooked target classes/methods; flag payment/biometric/SMS-contact categories; summarize the threat level | E-xp-sensitive-hooks | P0 |
| **CV** | Code contains XposedBridge detection evasion / Zygote injection trace cleanup / custom network communication | Check for stacktrace modification / XposedBridge class reference removal; check for standalone network requests (OkHttp/Socket); identify C2 targets | E-xp-anti-detection | P1 |
| **CW** | Code contains dynamic Resources replacement / View drawing interception / AccessibilityService declarations | Check for AssetManager replacement / Resources.updateConfiguration; check the AccessibilityService configuration; identify UI hijacking | E-xp-ui-hijack | P1 |
| **CX** | AndroidManifest.xml declares lsposed xposedscope meta-data; or code contains package-name allowlist checks | Parse the xposedscope target-app scope; check for dynamic allowlist bypass (reflection modifying scope); identify global Hook privilege escalation | E-xp-scope-bypass | P1 |

## 23. In-depth Magisk Module Analysis (CY–DC, DG–DI) → complements §7 AR–AT

> §7 focuses on wiper/destructive behavior. This section covers non-destructive but suspicious module behavior: install-script analysis, file drops, Zygisk injection, anti-detection, persistence, privilege escalation, and lateral infection.

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **DG** | Magisk module ZIP root contains config.sh / install.sh; META-INF/com/google/android/update-binary is a non-standard installer | Extract the on_install/print_modname/set_permissions functions from config.sh/install.sh; check whether update-binary contains an extra payload; flag pm install / dd block device / mount -o remount,rw operations | E-mg-install-script | P0 |
| **DH** | ZIP contains system/ / vendor/ / data/ directory structures; or boot-time execution scripts such as post-fs-data.sh / service.sh | Extract dropped file paths to determine whether an APK is dropped into /system/priv-app/; inspect service.sh + post-fs-data.sh content to identify boot auto-start/background keep-alive/C2 communication; flag all writes to system partitions | E-mg-file-drop | P0 |
| **CY** | Module contains a zygisk/ directory (native libraries such as arm64-v8a.so); or config.sh declares IS_ZYGISK=true | Extract the zygisk/ native library and analyze the ZygiskModule callbacks (onLoad / preAppSpecialize / postAppSpecialize); check for JNI hooks | E-mg-zygisk | P0 |
| **DI** | Module script writes into /data/adb/service.d/ or /data/adb/post-fs-data.d/; or modifies crontab/init.rc (a deepening of §7 AT) | Extract the script content written into service.d + post-fs-data.d; check for logic that automatically infects other modules on uninstall (post-uninstall.sh / module directory monitoring); check for a magisk --remove-modules trigger protection mechanism | E-mg-persistence | P0 |
| **CZ** | Module script contains resetprop system property modification / magiskhide / DenyList; or integrates Shamiko (hides Zygisk itself) / TrickyStore (tampers with the certificate chain) / PlayIntegrityFork (forges the Play Integrity API) | Extract all resetprop calls to identify modified properties (ro.debuggable / ro.build.tags, etc.); check whether DenyList hides itself; identify module-level anti-detection via Shamiko/TrickyStore/PlayIntegrityFork | E-mg-anti-detect | P0 |
| **DA** | Module script contains setenforce 0 / mount -o rw,remount /system / chmod 777 on sensitive directories | Check SELinux operations (setenforce/chcon/restorecon); check system partition mounting + dm-verity disabling; flag high-risk privilege escalation | E-mg-privilege | P0 |
| **DB** | Dropped APK/script contains curl/wget/HTTP clients; or the dropped APK requests INTERNET + READ_CONTACTS/SMS and other sensitive permissions | Extract network request target URLs/IPs; analyze the dropped APK's permission declarations; identify data exfiltration logic | E-mg-c2 | P0 |
| **DC** | Script traverses the /data/adb/modules/ directory, modifies other modules' files, or writes copies of itself into other modules | Check module.prop for injected malicious instructions; check other modules' service.sh for appended malicious code; identify "parasitic" logic | E-mg-cross-infect | P0 |

---

## 24. Constraints (global)

1. **Not a parallel main workflow**: phase gates still follow re-agent-workflow / each skill.  
2. **Evidence must be recorded**: including failures, partial recovery, and quality= annotations.  
3. **Deduplicated against A–T**: no duplication of PE anti-debug; AM→R; AJ supplements the DLL perspective without overturning the TLS rocket.  
4. **Missing tools**: record n/a + manual equivalent; do not pretend a commercial suite was used.  
5. **Authorization**: destructive/injection/driver-vulnerability categories are limited to defensive analysis and forensic wording.  
6. **Extended-rule deduplication**: ELF → elf-analysis.md; Mach-O → platforms.md; Python → languages.md. This table does not repeat the rules for those formats.

## 25. P0 Minimum Checklist (when a type matches)

```text
□ bat/cmd → U (+ V/W when needed; advanced CD–CI)
□ ps1 → X (+ Z; advanced CJ–CO + DL ETW)
□ vba/xlm → AA + DD + DJ (+ AB/AC)
□ office ooxml/rtf → BA + DK (+ BB if DDE is suspected)
□ js strong obfuscation → AD or AE (+ AF; advanced CP/CQ/DE/DF)
□ sys → AG + AH (+ AI if BYOVD is suspected)
□ dll → AJ + AK/AL; Delay-Load goes to R
□ apk destructive/hidden → AR/AS or AU (+ AT/AV)
□ pdf → AW + AX (+ AY/AZ)
□ wasm → BC (+ BD/BE)
□ jar/class → BF + BG (+ BH/BI)
□ autoit → BJ + BL + DM (+ BK)
□ hta → BM + BN (+ BO)
□ wsf/jse/vbe → BP + BQ (+ BR/BS)
□ msi → BT (+ BU/BV)
□ reg → BW + BX (+ BY)
□ vbs → CA + CB + CC + DN (+ BZ)
□ xposed module → CR + CS + CT + CU (+ CV–CX)
□ magisk in-depth → DG + DH + CY + DI + CZ + DA (+ DB/DC)
```
