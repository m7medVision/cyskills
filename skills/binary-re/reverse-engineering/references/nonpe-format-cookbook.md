# Non-PE / multi-format Agent response recipes U–AV + AW–DN

> Parallel to the PE anti-debug recipes A–T (../anti-analysis.md): organized by **file type**, giving "trigger → one-line action → Evidence".  
> This is **not** a second master flow. After Triage identifies the type, jump to the corresponding skill + this table.  
> Default is an **authorized isolated lab / authorized samples and devices**. For bricking, BYOVD, reflective injection, etc., write **detection and forensics**, not unauthorized sabotage/exploitation tutorials.  
> Failure to bypass or recover MUST still record Evidence; forbidden to silently treat it as "harmless".
>
> §1–§8 / U–AV = original rules (Issue #65). §9–§23 / AW–DN = extended rules (Issue #87, after dedup + semantic enhancement + edge-case patches).

## 0. Routing quick reference

| Type clue | Main skill | Sections in this table |
|----------|----------|----------|
| .bat / .cmd / batch | malware-analysis | §1, §19 |
| .ps1 / PowerShell | malware-analysis | §2, §20 |
| Office macro / VBA / XLM / .docm/.xlsm | malware-analysis | §3 (incl. DD OLE extraction, DJ XLM macro) |
| .docx/.xlsx/.pptx OOXML external link / DDE / .rtf OLE | malware-analysis | §10 (incl. DK RTF) |
| Web/front-end JS obfuscation, JSVMP | js-reverse | §4, §21 (incl. DE/DF) |
| .sys / kernel driver | reverse-engineering/kernel-driver-reverse.md + cre | §5 |
| .dll focus | malware-analysis / re-agent-workflow | §6 (deduped with A–T) |
| APK / Magisk / hidden icon | apk-reverse | §7–§8, §23 |
| .pdf / PDF document | malware-analysis | §9 |
| .wasm / WebAssembly | reverse-engineering | §11 |
| .jar/.class / Java bytecode | reverse-engineering | §12 |
| .exe(AutoIt) / .au3 | malware-analysis | §13 |
| .hta / HTML Application | malware-analysis | §14 |
| .wsf/.jse/.vbe | malware-analysis | §15 |
| .msi / Windows Installer | malware-analysis | §16 |
| .reg / registry script | malware-analysis | §17 |
| .vbs / VBScript | malware-analysis | §18 |
| Xposed/LSPosed module | apk-reverse | §22 |
| ELF / Linux binary | reverse-engineering | → elf-analysis.md, anti-analysis.md |
| Mach-O / macOS/iOS | reverse-engineering | → platforms.md |
| Python bytecode | reverse-engineering | → languages.md |

## 1. BAT/CMD (U V W)

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **U** | Many single-character SET variables + %a%%b% concatenation, or ^ line-continuation splitting commands | Expand SET line by line; produce a command list after recovery; batch deobfuscation tools may be used; **forbidden** to treat it as "no action" before recovery | E-batch-deobf | P0 |
| **V** | Garbled when opened as text, HEX header FF FE (UTF-16 LE BOM) | Confirm the BOM → convert to UTF-8 before parsing; or chcp 65001 + type | E-batch-encoding | P2 |
| **W** | Large amounts of REM/::, redundant GOTO/labels drowning the real logic | Strip comments; sort out the real GOTO path; isolate execution to capture the actual cmd command log | E-batch-deadcode | P1 |

## 2. PowerShell (X Z)

> Numbering preserves the submitter's convention: **there is no patch Y**.

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **X** | Multi-layer FromBase64String / Gzip / Compress / nested -replace | Decode **layer by layer**; record each layer's result separately; tools optional (PowerDecode etc.), or manual/scripted without tools | E-ps-decode-layer-N | P0 |
| **Z** | Reversed strings, fragments + concatenation then Invoke-Expression/IEX | Restore the full string; break on IEX or script-block logging; put the plaintext command in Evidence | E-ps-string-restore | P1 |

## 3. VBA macro / XLM (AA AB AC DD DJ)

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **AA** | olevba/OLEDump sees only P-Code, source stream empty (VBA Stomping) | P-Code decompilation tools; if incomplete, observe via Word/Excel macro debugging; state the limitations clearly | E-vba-pcode | P0 |
| **AB** | Large amounts of Chr() concatenation or Base64 strings, suspected shellcode/nested script | Restore the string in the immediate window/script; determine the type after decoding; dynamically watch CreateObject/Shell | E-vba-str-decode | P1 |
| **AC** | Meaningless If 1=2, or self-modification via InsertLines/DeleteLines | Statically follow the real branch; dynamically bp the self-modification API and dump the modified macro | E-vba-selfmod | P2 |
| **DD** | olevba/oledump detects a VBA macro project (vbaProject.bin); extension .docm/.xlsm/.pptm | Use oledump.py to inspect the OLE stream structure; olevba to extract VBA source and detect suspicious APIs; check auto-execution macros such as AutoOpen/Workbook_Open | E-office-vba | P0 |
| **DJ** | .xls/.xlsm contains Excel 4.0/XLM macros (hidden in cell formulas, not a VBA stream); olevba detects XLM macro markers | olevba --xlm to extract XLM macro formulas; check hidden worksheets for EXEC/CALL/REGISTER functions; XLMMacroDeobfuscator dynamic emulation recovery | E-office-xlm | P0 |

## 4. JavaScript (AD AE AF) → main path js-reverse

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **AD** | Custom bytecode array + while/switch interpreter (JSVMP) | Find the VM entry and opcode dispatch; dynamic log traces; AST + dynamic dual-track; see js-reverse DeepDive | E-js-vmp | P0 |
| **AE** | while(1){switch} + large string array indexing | AST/Babel reconstruction; recover strings by array index; wakaru etc. optional; **do not** paste the entire PE ollvm-deobfuscation long text | E-js-deobf | P0 |
| **AF** | debugger, hijacked console, performance.now differences, DevTools detection | Disable breakpoints/fix the time source/headless browser; patch detection points; authorized page | E-js-anti-debug | P1 |

## 5. SYS kernel driver (AG AH AI)

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **AG** | DriverEntry is very short, logic is not in the entry | Scan MajorFunction[] non-empty slots; prioritize IRP_MJ_DEVICE_CONTROL/CREATE; put the address list in Evidence | E-driver-irp-handlers | P0 |
| **AH** | DeviceIoControl / IOCTL dispatch exists | Build a control-code→handler table; mark METHOD_* and buffer direction; user-mode communication surface | E-driver-ioctl | P0 |
| **AI** | The sample loads/drops a known vulnerable driver or an abnormally signed driver (BYOVD pattern) | Compare against **public** lists such as LOLDrivers; record driver name/hash/signature; analyze the **call intent**; do **not** elaborate exploit steps | E-driver-byovd | P1 |

See kernel-driver-reverse.md for the process; this table only adds agent action anchors.

## 6. DLL (AJ–AQ) — deduped with A–T / #72

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **AJ** | DLL analysis only looked at exports/EP, ignoring TLS or DllMain | **Both TLS callbacks + DllMain must be examined**; the dynamic breakpoint order still follows the four-stage rocket (TLS→EP/DllMain→API→ExitProcess) | E-dll-tls-dllmain | P0 |
| **AK** | Export names good then malicious, wrong names, or exports inconsistent with behavior | Cross-check the export table against actual calls; anomalous export list | E-exports-anomaly | P0 |
| **AL** | No exports or very few exports, yet still loaded | Locate from the entry, strings, xrefs, caller; do not give up because of "no exports" | E-dll-noexport | P0 |
| **AM** | Static IAT lacks a DLL, used only at runtime | **See A–T patch R** (Delay-Load / E-delay-import), do not duplicate the long text here | E-delay-import | P0 pointer |
| **AN** | Need to recover exported function parameters and calling convention | Cross-references + dynamically watch registers/stack; annotate stdcall/fastcall etc. | E-dll-export-abi | P1 |
| **AO** | Suspected DLL hijacking/sideloading | Check for same-named DLLs in the application directory, search paths, KnownDLLs; legitimate program + anomalous DLL combination | E-dll-sideload | P1 |
| **AP** | Clues of fileless mapping/reflective loading | Memory characteristics, loader behavior, pathless modules; authorized-environment forensics | E-dll-reflective | P1 |
| **AQ** | Lowering risk just because export names "don't look malicious" | **Forbidden** to judge safety by export name alone; combine section permissions, entry, strings, dynamic behavior | E-dll-export-priority | P1 |

DLL/SYS hard gate still: E-imports + E-exports (see re-agent-workflow).

## 7. Android bricking / persistence (AR AS AT) → apk-reverse

> **Authorized samples, images, or test devices only.** The actions are detection, extracting IOCs and persistence paths, not carrying out sabotage.

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **AR** | Magisk module/script contains **bricking-signature commands** such as deleting the database, flashing, batch rm of system partitions | Signature command table + module path; flag high-risk destructive capability; do not execute the bricking commands | E-android-wiper-cmd | P0 |
| **AS** | Looped curl|sh / remote script pulling, abnormal C2 URLs | Extract the URL; analyze whether the downloaded body contains bricking commands; record temp paths | E-android-wiper-backdoor | P0 |
| **AT** | /data/adb/service.d, post-fs-data.d, suspicious /system/priv-app, etc. | List persistence scripts/APKs; content summary in Evidence | E-android-persistence | P1 |

## 8. Android transparent/hidden icon (AU AV) → apk-reverse

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **AU** | LAUNCHER icon fully transparent/empty label, Theme.NoDisplay, no LAUNCHER category, component disabled | aapt dump badging + manifest; decompile to inspect icon pixels; anomalous items in Evidence | E-android-hidden-icon-manifest | P0 |
| **AV** | Installed but no icon on the desktop, background traffic/autostart/high-risk permissions/dynamically restored icon | pm list vs desktop; dumpsys package; broadcasts and device_admin; behavior in Evidence | E-android-hidden-icon-behavior | P1 |

---

> **The following §9–§23 are Issue #87 extended rules (AW–DC).**
> Sections already duplicated in existing files have been removed: ELF (→ elf-analysis.md), Mach-O (→ platforms.md), Python (→ languages.md).

## 9. PDF malicious documents (AW AX AY AZ)

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **AW** | pdfid detects /JS, /JavaScript, /OpenAction, /AA, /Launch counts >0 (including obfuscated counts of hex-encoded names like /4A#61#76#61...) | pdfid -e statistics (compare plain vs obfuscated counts); pdf-parser to extract suspicious objects; peepdf interactive analysis + JS emulation | E-pdf-autoaction | P0 |
| **AX** | pdfid detects /EmbeddedFile >0; object streams contain FlateDecode/ASCIIHexDecode cascaded filter chains; or encoded payloads hidden in /Annot objects | pdf-parser to extract stream data; peepdf to decode multi-level cascaded filters (including AES-encrypted streams with security handler r5/r6); check Annotation objects; file to identify the decoded result type | E-pdf-embedded | P0 |
| **AY** | Extracted PDF JS contains lots of eval, unescape, String.fromCharCode, atob | peepdf JS emulation environment execution tracing; decode Base64/Hex/ROT13 layer by layer; CyberChef as an aid | E-pdf-js-deobf | P1 |
| **AZ** | PDF structure anomalies: /JBIG2Decode, manipulated XREF table, skipped object numbers | pdfid -d to rename suspicious keywords; check known CVE exploitation patterns; extract exploit trigger conditions | E-pdf-exploit | P1 |

## 10. Office OOXML / DDE / RTF (BA BB DK) → complements §3 VBA

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **BA** | After unzipping docx/xlsx/pptx ZIP, word/_rels/ or xl/_rels/ contains suspicious external relationships (including remote template injection) | Check *.rels external links; check vbaData.xml; extract embedded OLE objects; check protocol handler abuse (ms-msdt: / search-ms: / ms-officecmd:) | E-office-ooxml | P0 |
| **BB** | Document contains DDEAUTO or DDEEXEC field codes, executing external commands via fields | olevba --dde scan; extract DDE command parameters; check whether they point to PowerShell/external exe | E-office-dde | P0 |
| **DK** | .rtf file contains an embedded OLE object (not OOXML, not a classic OLE compound document) | rtfobj to extract the embedded OLE object; oleobj to analyze the object type; check Equation Editor vulnerability exploitation (CVE-2017-11882 etc.); file to identify the extracted artifact type | E-rtf-ole | P0 |

## 11. WebAssembly (BC BD BE)

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **BC** | File starts with the \x00asm magic bytes; or JS code contains WebAssembly instantiation logic | wasm2wat to text; inspect the import section to identify host-environment imported functions; wasm-decompile to generate pseudocode; check for the Emscripten glue signature (__wasm_call_ctors) to determine whether it was compiled from JS | E-wasm-struct | P0 |
| **BD** | Many WASM functions but simple logic, function bodies split into tiny functions; or meaningless nested block/loop | diswasm to assess the function-minimization level; JEB Pro / IDA WASM plugin for deep analysis; dynamically trace the execution log | E-wasm-obfuscation | P1 |
| **BE** | WASM module interacts with the browser via JS import/export functions, with WebSocket, fetch, WebGL calls | Analyze the JS glue code and the WASM module together; browser DevTools to trace data exchange; extract network communication URLs/domains | E-wasm-c2 | P1 |

## 12. Java JAR/Class (BF BG BH BI)

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **BF** | When JD-GUI/jadx opens the JAR, class/method names are meaningless short strings (a.a.a / _0x prefix / numeric class names); or lots of while/switch control-flow obfuscation | Identify the obfuscator type (ProGuard / Allatori / ZKM); Java Deobfuscator static deobfuscation; for high strength, dynamically debug and trace the key logic | E-java-obfuscation | P0 |
| **BG** | Lots of Class.forName(), Method.invoke(), Constructor.newInstance(); or a custom ClassLoader + defineClass() loading classes from a byte array in memory; harmless import table but dynamically loading malicious classes at runtime | javap -c -v to inspect reflection call details; trace the Class.forName parameter strings; check the source of the defineClass() byte array; dynamically break on Method.invoke | E-java-reflection | P0 |
| **BH** | JAR contains .so (Linux/Android) or .dll (Windows); or System.loadLibrary() calls | Extract the native library files; file to identify the format; switch to the standalone ELF/PE analysis flow | E-java-native | P1 |
| **BI** | After unzipping JAR/ZIP, contains nested JAR/WAR/EAR; high-entropy .dat/.bin/.img files in /resources, /assets | Recursively unzip all nested archives; entropy analysis to determine encryption/compression; check META-INF/MANIFEST.MF and pom.xml | E-java-nested | P1 |

## 13. AutoIt (BJ BK BL DM)

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **BJ** | PE strings contain AutoIt / AU3 / EA05 / EA06 signatures; or the resource section contains an AutoIt script resource (note the distinction from AutoHotKey; MITRE T1059.010 shares both) | autoit-ripper to extract the compiled script; identify the encoding family (EA05 = AutoIt3.00 / EA06 = AutoIt3.26); after the EA06 header, extract the 8-byte decryption key to decrypt the payload; recover the source | E-autoit-extract | P0 |
| **BK** | Extracted script contains lots of StringEncrypt/_StringEncrypt; or Execute dynamic execution + meaningless variable names | myAutToExe static decompilation; identify anti-debugging techniques; analyze the obfuscated control flow | E-autoit-deobf | P1 |
| **BL** | Script contains RegWrite (registry persistence), FileInstall (file drop), InetGet (network download), Run/RunWait | Flag the sensitive API call sequence; analyze the InetGet URL; trace the FileInstall drop path | E-autoit-malicious | P0 |
| **DM** | AutoIt used as a loader to perform process hollowing: CallWindowProc/EnumWindows callbacks + shellcode + injection into legitimate processes (regsvcs.exe etc.), dropping a .NET payload (DarkGate / Snake Keylogger / ArechClient2 pattern) | Check the DllCall/DllCallbackRegister call chain to kernel32 injection APIs; extract the shellcode data; identify the injected target process; extract the .NET payload for standalone analysis | E-autoit-hollowing | P0 |

## 14. HTA / HTML Application (BM BN BO)

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **BM** | HTML contains an HTA:APPLICATION tag, window.execScript or CreateObject calls | Check HTA:APPLICATION attributes (Application, WindowState); extract VBS/JS from script tags | E-hta-bypass | P0 |
| **BN** | HTA launched via mshta.exe then XMLHttpRequest / ActiveXObject remotely pulls a Payload to execute | Extract the network request URL; trace ActiveXObject creation (ADODB.Stream etc.); recover the full download-and-execute chain | E-hta-download-chain | P0 |
| **BO** | HTA contains only a single extremely long obfuscated string line, executed via eval / execScript | Extract Base64/Hex encoded payload and decode; CyberChef recursively detects the encoding type; recover the payload | E-hta-oneline | P1 |

## 15. WSF / JSE / VBE (BP BQ BR BS)

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **BP** | .wsf contains \<job\> + \<script language="..."\> tags, mixing JScript/VBScript/Python | Split code blocks by \<script language\>; analyze each according to the corresponding language rules | E-wsf-multi | P0 |
| **BQ** | .jse/.vbe starts with the #@~^ signature, Microsoft Script Encoder encoded | screnc-decoder to decode; without tools, dynamically execute + dump the decoded script | E-jse-decode | P0 |
| **BR** | WSF multiple \<script\> blocks + \<package\> referencing external resources + \<component\> referencing COM components | Build a cross-block call graph; trace function calls between \<script\> blocks; recover the full execution flow | E-wsf-call-chain | P1 |
| **BS** | WSF contains WshShell.SendKeys to bypass UAC, WshShell.Run with window 0 hiding, WScript.Sleep delay bypass | Check whether user-simulation operations are used to bypass security prompts; record stealthy execution parameters | E-wsf-anti-detect | P1 |

## 16. MSI installer (BT BU BV)

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **BT** | MSI file contains a CustomAction table (Binary / Script / DLL type custom actions) | msiexec /a or lessmsi to extract contents; check the CustomAction table; extract custom action binaries | E-msi-custom-action | P0 |
| **BU** | MSI Binary table contains VBScript/JScript custom action scripts | Extract the script binary from the Binary table and decode it into a readable script; analyze per VBS/JS rules | E-msi-script | P1 |
| **BV** | MSI silently installs via /quiet /passive /qn; ALLUSERS=1 for privilege escalation | Record the install command-line parameters; analyze the Property table privilege settings; flag the silent+privilege combination | E-msi-privilege | P1 |

## 17. REG registry scripts (BW BX BY)

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **BW** | .reg writes to autostart paths such as HKCU\...\Run or HKLM\...\Run | Extract all paths; flag Run-path entries as persistence; record full paths and values | E-reg-persistence | P0 |
| **BX** | .reg modifies HKCR\...\shell\open\command (file association) or HKCR\CLSID\{...}\InprocServer32 (DLL injection) | Check whether shell\open\command is an abnormal exe; check the InprocServer32 DLL path | E-reg-hijack | P0 |
| **BY** | .reg modifies HKLM\...\Policies\System (UAC level), EnableLUA, ConsentPromptBehaviorAdmin | Check the default security configuration before modification; analyze the impact on UAC; flag the downgrade behavior | E-reg-uac-bypass | P1 |

## 18. VBScript (BZ CA CB CC DN)

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **BZ** | .vbs/.js is parsed by both VBScript and JScript; conditional compilation (@_win32) or cross-language feature execution | Separate VBScript/JScript code blocks; parse each separately; identify mixed-execution logic | E-vbs-mixed | P1 |
| **CA** | Script contains CreateObject("WScript.Shell") / CreateObject("Shell.Application") / Scripting.FileSystemObject | Flag high-risk COM object calls; trace Run/Exec parameters; trace file paths created by FSO | E-vbs-com-abuse | P0 |
| **CB** | Script starts with the #@~^ signature, Microsoft Script Encoder encoded (VBS-specific) | screnc-decoder to decode; without tools, dynamically execute + dump the decoded script | E-vbs-encoded | P0 |
| **CC** | VBA/VBScript contains WScript.Shell.Run + cmd /c + PowerShell, followed by process injection | Trace the CreateObject COM object chain; analyze injection signatures in the Run parameters; record the full process-creation chain | E-vbs-inject-chain | P0 |
| **DN** | VBScript/JScript achieves fileless persistence via WMI ActiveScriptEventConsumer (no startup folder/registry Run key) | Check WMI event subscriptions (__EventFilter + __FilterToConsumerBinding + ActiveScriptEventConsumer); extract the bound script content; flag fileless persistence | E-vbs-wmi-persist | P0 |

## 19. BAT/CMD advanced obfuscation (CD–CI) → complements §1 U–W

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **CD** | setlocal enabledelayedexpansion + !var! + dynamic variable names (!var_%i%!) | After enabling delayed expansion, expand line by line; Batch-Dump --expand for automatic expansion | E-bat-delayed-expand | P0 |
| **CE** | Reading its own or a file's :stream ADS alternate data stream via type/more/findstr to execute | Check : suffix references (file.bat:payload); dir /r to list ADS; type file:stream to extract | E-bat-ads-hidden | P0 |
| **CF** | Large amounts of echo writing line by line into .tmp/.cmd temp files then call to execute | Extract all echo redirections to recover temp file contents; monitor scripts generated in the temp directory | E-bat-temp-gen | P1 |
| **CG** | for %%i in (...) do set var=%%i accumulating variables; for /f parsing command output line by line | Expand the for loop entry by entry and record each iteration's assignment; serialize and recover the for /f result | E-bat-for-expand | P1 |
| **CH** | The main batch receives arguments via %1 %* passed by a parent process/downloader with obfuscated instructions | Check the calling context and record the passed parameters; decode and recover Base64 parameters; recover the full call chain | E-bat-param-call | P1 |
| **CI** | certutil -decode / powershell -Command / echo \| findstr combined decode-and-execute | Extract Base64/Hex strings and decode; check whether the decoded result is an executable script/PE | E-bat-encoded-exec | P0 |

## 20. PowerShell advanced bypass (CJ–CO, DL) → complements §2 X–Z

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **CJ** | AMSI bypass such as [Ref].Assembly.GetType('...AmsiUtils') / amsiInitFailed / GetTypes() (including hardware-breakpoint bypass: CPU debug registers, no memory writes/VirtualProtect) | Identify the bypass pattern (Patch / registry / environment variable / hardware breakpoint); dynamically confirm it takes effect; flag the bypass technique type | E-ps-amsi | P0 |
| **CK** | [PSConstraintLanguage] type manipulation or modifying session state via DefaultRunspace to bypass CLM | Identify the CLM bypass pattern; flag bypass-clm; analyze the post-bypass execution context | E-ps-clm-bypass | P0 |
| **CL** | [ScriptBlock]::Create / $ExecutionContext.InvokeCommand constructors; or overriding ScriptBlock logging settings | Check whether the script disables logging; dynamically verify whether logging is bypassed | E-ps-sb-log-bypass | P1 |
| **CM** | IEX (New-Object Net.WebClient).DownloadString(...) or [Reflection.Assembly]::Load(FromBase64...) fileless execution | Extract the download URL and check domain/IP reputation; PS logging captures the in-memory loaded code; isolated network simulation to extract the payload | E-ps-reflect-load | P0 |
| **CN** | More than three layers of encoding nesting: outer Base64 → Gzip → XOR → plaintext (beyond §2 X's two-layer scope) | Recursively decode to plaintext or until it cannot continue; record the intermediate state of each layer; PowerDecode automation; each layer's result in Evidence | E-ps-multi-decode | P0 |
| **CO** | Set-Alias maps IEX to a single-character alias; Get-ChildItem variable: dynamically obtains variable values | Expand all alias mappings back to the original command names; AST analysis to recover variables | E-ps-alias-decode | P1 |
| **DL** | Script contains an ntdll.dll EtwEventWrite patch (stomping) to silence telemetry; often combined with an AMSI bypass | Check whether there is an EtwEventWrite address fetch + memory patch (ret 0xC3); check together with CJ AMSI bypass; flag the double-bypass combination | E-ps-etw-bypass | P0 |

## 21. JavaScript advanced obfuscation (CP CQ DE DF) → complements §4 AD–AF

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **CP** | JS uses Proxy objects to intercept property access + Reflect API to dynamically call methods, bypassing static analysis | Identify Proxy get/set/apply trap functions; trace the actual targets of Reflect.get; flag dynamic interception behavior | E-js-proxy | P1 |
| **CQ** | JS contains an _0x... hex string array + while(!![]) infinite loop + for+switch control flow (obfuscator.io signature) | Identify the obfuscator.io signature (string array + infinite loop); de4js / jsnice automatic deobfuscation; the recovered code in Evidence | E-js-obfuscator | P0 |
| **DE** | The JS body is a large bytecode array + VM interpreter loop (multiple while/switch), with the entry pointing to eval/Function constructors; business logic completely unreadable (deepening §4 AD) | Identify the VM entry function and trace the opcode→handler mapping; browser dynamic execution with Hooked eval output; JSimplifier AST reconstruction; record the opcode mapping table | E-jsvmp-deep | P0 |
| **DF** | JS contains eval dynamically generating new code and immediately executing it, document.write rewriting the page, or Function constructors dynamically building function bodies | Hook eval and Function constructors to record generated code; browser dynamic execution to capture self-modifying content | E-js-selfmod | P1 |

## 22. Xposed/LSPosed module analysis (CR–CX) → apk-reverse

> Analyze the Xposed/LSPosed **module itself** as the reverse-engineering target (not a tool-usage scenario).

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **CR** | AndroidManifest.xml has no android:name entry Activity; meta-data specifies xposedmodule=true | Check assets/xposed_init to determine the entry class; search for IXposedHookLoadPackage/ZygoteInit/CmdInit interface implementations | E-xp-entry | P0 |
| **CS** | Code contains XposedHelpers.findAndHookMethod / XposedBridge.hookMethod / findClass | Extract findAndHookMethod's first parameter (target class) + second parameter (target method); build the target application inventory | E-xp-hook-targets | P0 |
| **CT** | Module contains DexClassLoader/PathClassLoader dynamic loading; or Runtime.exec / ProcessBuilder executing commands | Trace DexClassLoader constructor parameters; extract dynamically loaded DEX for standalone analysis; check exec command parameters | E-xp-dynamic-load | P0 |
| **CU** | Hook targets involve sensitive APIs such as payment/biometrics/SMS/contacts/location/crypto keys | Classify the sensitivity of Hook target classes/methods; flag payment/biometrics/SMS-contacts categories; summarize the threat level | E-xp-sensitive-hooks | P0 |
| **CV** | Code contains XposedBridge detection evasion / Zygote injection trace cleanup / custom network communication | Check stacktrace modification / XposedBridge class reference cleanup; check standalone network requests (OkHttp/Socket); identify C2 targets | E-xp-anti-detection | P1 |
| **CW** | Code contains Resources dynamic replacement / View drawing interception / AccessibilityService declaration | Check AssetManager replacement / Resources.updateConfiguration; check AccessibilityService configuration; identify UI hijacking | E-xp-ui-hijack | P1 |
| **CX** | AndroidManifest.xml declares lsposed xposedscope meta-data; or code contains package-name whitelist checks | Parse the xposedscope target application scope; check dynamic whitelist bypass (reflectively modifying scope); identify global Hook privilege escalation | E-xp-scope-bypass | P1 |

## 23. Magisk module deep analysis (CY–DC, DG–DI) → complements §7 AR–AT

> §7 focuses on bricking/destructive behavior. This section covers non-destructive but suspicious module behavior: install script analysis, file drops, Zygisk injection, anti-detection, persistence, privilege escalation, lateral infection.

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **DG** | Magisk module ZIP root contains config.sh / install.sh; META-INF/com/google/android/update-binary is a non-standard installer | Extract the on_install/print_modname/set_permissions functions from config.sh/install.sh; check whether update-binary contains an extra payload; flag pm install / dd block device / mount -o remount,rw operations | E-mg-install-script | P0 |
| **DH** | ZIP contains system/ / vendor/ / data/ directory structure; or boot-time scripts such as post-fs-data.sh / service.sh | Extract dropped file paths to identify whether an APK is dropped to /system/priv-app/; check service.sh + post-fs-data.sh contents to identify boot autostart/background keep-alive/C2 communication; flag all writes to the system partition | E-mg-file-drop | P0 |
| **CY** | Module contains a zygisk/ directory (arm64-v8a.so etc. native libraries); or config.sh declares IS_ZYGISK=true | Extract the zygisk/ native libraries and analyze ZygiskModule callbacks (onLoad / preAppSpecialize / postAppSpecialize); check JNI Hooks | E-mg-zygisk | P0 |
| **DI** | Module scripts write to /data/adb/service.d/ or /data/adb/post-fs-data.d/; or modify crontab/init.rc (deepening §7 AT) | Extract the contents of scripts written to service.d + post-fs-data.d; check logic that automatically infects other modules on uninstall (post-uninstall.sh / module directory monitoring); check protection mechanisms triggered by magisk --remove-modules | E-mg-persistence | P0 |
| **CZ** | Module scripts contain resetprop to modify system properties / magiskhide / DenyList; or integrate Shamiko (hiding Zygisk itself) / TrickyStore (tampering with the certificate chain) / PlayIntegrityFork (forging the Play Integrity API) | Extract all resetprop calls to identify modified properties (ro.debuggable / ro.build.tags etc.); check DenyList hiding itself; identify module-level anti-detection such as Shamiko/TrickyStore/PlayIntegrityFork | E-mg-anti-detect | P0 |
| **DA** | Module scripts contain setenforce 0 / mount -o rw,remount /system / chmod 777 on sensitive directories | Check SELinux operations (setenforce/chcon/restorecon); check system partition mounting + dm-verity disabling; flag high-risk privilege escalation | E-mg-privilege | P0 |
| **DB** | Dropped APK/scripts contain curl/wget/HTTP clients; or the dropped APK requests sensitive permissions such as INTERNET + READ_CONTACTS/SMS | Extract the network request target URL/IP; analyze the dropped APK's permission declarations; identify data exfiltration logic | E-mg-c2 | P0 |
| **DC** | Scripts traverse the /data/adb/modules/ directory, modify other modules' files, or write a copy of themselves into other modules | Check module.prop for injected malicious instructions; check other modules' service.sh for appended malicious code; identify "parasitic" logic | E-mg-cross-infect | P0 |

---

## 24. Constraints (global)

1. **Not a parallel master flow**: stage gates still follow re-agent-workflow / each skill.  
2. **Evidence must be recorded**: including failures, partial recovery, quality= annotations.  
3. **Deduped with A–T**: PE anti-debug is not repeated; AM→R; AJ's DLL perspective does not overturn the TLS rocket.  
4. **Missing tools**: record n/a + manual equivalent; do not pretend a commercial suite was used.  
5. **Authorization**: destructive/injection/driver-vulnerability categories are limited to defensive analysis and forensic phrasing.
6. **Extended-rule dedup**: ELF → elf-analysis.md; Mach-O → platforms.md; Python → languages.md. This table does not repeat rules for those formats.

## 25. P0 minimum checklist (when a type matches)

```text
□ bat/cmd → U (+ V/W when needed; advanced CD–CI)
□ ps1 → X (+ Z; advanced CJ–CO + DL ETW)
□ vba/xlm → AA + DD + DJ (+ AB/AC)
□ office ooxml/rtf → BA + DK (+ BB if DDE suspected)
□ heavily obfuscated js → AD or AE (+ AF; advanced CP/CQ/DE/DF)
□ sys → AG + AH (+ AI if BYOVD suspected)
□ dll → AJ + AK/AL; Delay-Load goes through R
□ apk destruction/hiding → AR/AS or AU (+ AT/AV)
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
□ magisk deep → DG + DH + CY + DI + CZ + DA (+ DB/DC)
```
