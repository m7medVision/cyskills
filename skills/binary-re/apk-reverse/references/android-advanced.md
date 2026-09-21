# Android Advanced Reverse Engineering Reference

> Covers Native SO analysis, advanced Frida usage, SSL Pinning bypass, Root detection countermeasures, packer unpacking, and Flutter/React Native reverse engineering.

---

## Native SO Reverse Engineering

### Analysis Workflow

```text
1. Extract the .so file from the APK
   unzip app.apk lib/arm64-v8a/*.so -d extracted/

2. Confirm architecture and basic info
   file libxxx.so
   rabin2 -I libxxx.so

3. Find the JNI entry point
   - Search for JNI_OnLoad (dynamic registration)
   - Search for Java_com_xxx_yyy (static registration)
   - nm -D libxxx.so | grep -i java

4. Load into IDA/Ghidra for analysis
   - Import the JNI header (jni.h types)
   - Annotate the JNIEnv* parameter
   - Find the RegisterNatives call (function table for dynamic registration)

5. Locate the key logic
   - Trace from the Java-layer native method name
   - Cross-reference from strings (keys, URLs, error messages)
   - Trace from crypto library function calls (AES/MD5/SHA)
```

### JNI Function Registration

```c
// Static registration: function name = Java_package_class_method
JNIEXPORT jstring JNICALL Java_com_example_app_Security_getSign(
    JNIEnv *env, jobject thiz, jstring input) { ... }

// Dynamic registration: call RegisterNatives inside JNI_OnLoad
static JNINativeMethod methods[] = {
    {"getSign", "(Ljava/lang/String;)Ljava/lang/String;", (void*)native_getSign},
};

JNIEXPORT jint JNI_OnLoad(JavaVM *vm, void *reserved) {
    JNIEnv *env;
    vm->GetEnv((void**)&env, JNI_VERSION_1_6);
    jclass clazz = env->FindClass("com/example/app/Security");
    env->RegisterNatives(clazz, methods, sizeof(methods)/sizeof(methods[0]));
    return JNI_VERSION_1_6;
}
```

### Tips for Analyzing JNI in IDA

```text
1. Import the JNI type library
   File → Load File → Parse C Header → jni.h

2. Annotate the first parameter as JNIEnv*
   Right-click the parameter → Set type → JNIEnv*
   This way calls like env->FindClass / env->GetMethodID are recognized automatically

3. Find RegisterNatives
   Search for calls to JNIEnv vtable offset 0x35C (ARM64)
   → the third argument is the JNINativeMethod array
   → extract all native function addresses from the array
```

---

## Advanced Frida Usage

### Hook Native Functions

```javascript
// Hook a libc function
Interceptor.attach(Module.findExportByName("libc.so", "open"), {
    onEnter: function(args) {
        this.path = args[0].readUtf8String();
        console.log("[open] " + this.path);
    },
    onLeave: function(retval) {
        if (this.path.includes("su") || this.path.includes("magisk")) {
            console.log("[open] Blocked root check: " + this.path);
            retval.replace(-1);  // return failure
        }
    }
});

// Hook a function in a custom SO
var base = Module.findBaseAddress("libsecurity.so");
var targetFunc = base.add(0x1234);  // offset address
Interceptor.attach(targetFunc, {
    onEnter: function(args) {
        console.log("arg0: " + args[0].readUtf8String());
    },
    onLeave: function(retval) {
        console.log("return: " + retval.readUtf8String());
    }
});
```

### Hook Java Methods

```javascript
Java.perform(function() {
    // Hook an instance method
    var Security = Java.use("com.example.app.Security");
    Security.getSign.implementation = function(input) {
        console.log("[getSign] input: " + input);
        var result = this.getSign(input);  // call the original method
        console.log("[getSign] output: " + result);
        return result;
    };

    // Hook a constructor
    Security.$init.overload('java.lang.String').implementation = function(key) {
        console.log("[Security.<init>] key: " + key);
        this.$init(key);
    };

    // Hook an overloaded method
    Security.encrypt.overload('java.lang.String', 'int').implementation = function(data, mode) {
        console.log("[encrypt] data=" + data + " mode=" + mode);
        return this.encrypt(data, mode);
    };
});
```

### Memory Search and Modification

```javascript
// Search for a string in memory
Process.enumerateModules().forEach(function(module) {
    if (module.name === "libtarget.so") {
        Memory.scan(module.base, module.size, "48 65 6C 6C 6F", {  // "Hello"
            onMatch: function(address, size) {
                console.log("Found at: " + address);
            }
        });
    }
});

// Modify memory (patch instructions)
var addr = Module.findBaseAddress("libsecurity.so").add(0x5678);
Memory.patchCode(addr, 4, function(code) {
    var writer = new Arm64Writer(code, {pc: addr});
    writer.putNop();  // replace with NOP
    writer.flush();
});
```

---

## SSL Pinning Bypass

### Generic Approach (recommended)

```javascript
// Generic Frida SSL Pinning bypass
// Source: https://github.com/0xCD4/SSL-bypass
Java.perform(function() {
    // 1. TrustManager bypass
    var TrustManager = Java.registerClass({
        name: 'com.custom.TrustManager',
        implements: [Java.use('javax.net.ssl.X509TrustManager')],
        methods: {
            checkClientTrusted: function(chain, authType) {},
            checkServerTrusted: function(chain, authType) {},
            getAcceptedIssuers: function() { return []; }
        }
    });

    // 2. SSLContext replacement
    var SSLContext = Java.use('javax.net.ssl.SSLContext');
    var sslContext = SSLContext.getInstance("TLS");
    sslContext.init(null, [TrustManager.$new()], null);

    // 3. OkHttp CertificatePinner bypass
    try {
        var CertificatePinner = Java.use('okhttp3.CertificatePinner');
        CertificatePinner.check.overload('java.lang.String', 'java.util.List').implementation = function() {};
    } catch(e) {}
});
```

### Bypass per Framework

| Framework | Bypass method |
|------|---------|
| OkHttp3 | Hook `CertificatePinner.check` to return empty |
| Retrofit | Same as OkHttp (uses OkHttp underneath) |
| Volley | Hook the SSL factory of `HurlStack` |
| Flutter | Hook `dart:io`'s `SecurityContext` (requires a special script) |
| React Native | Hook `OkHttpClientProvider` |
| WebView | Hook `WebViewClient.onReceivedSslError` |

### Flutter Deep Dive

```javascript
// Flutter SSL Pinning bypass (need to find the ssl_verify_peer_cert function)
var flutter_lib = Module.findBaseAddress("libflutter.so");
// Search for the signature of ssl_verify_peer_cert
var pattern = "FF 03 05 D1 FD 7B 0F A9";  // ARM64 signature
Memory.scan(flutter_lib, Module.findModuleByName("libflutter.so").size, pattern, {
    onMatch: function(address) {
        Interceptor.replace(address, new NativeCallback(function() {
            return 0;  // return success
        }, 'int', []));
    }
});
```

---

## Root Detection Bypass

### Common Detection Methods

| Detection method | Bypass method |
|---------|---------|
| Check for `/system/app/Superuser.apk` | Hook `File.exists()` to return false |
| Check for the `su` command | Hook `Runtime.exec()` to intercept su calls |
| Check `/proc/self/mounts` | Hook file reads and filter out magisk-related entries |
| SafetyNet/Play Integrity | Magisk Hide / Zygisk + Shamiko |
| Check the Magisk package name | Randomize the Magisk package name |
| Check `/data/adb/` | Hook `opendir`/`access` |

### Generic Frida Root Bypass

```javascript
Java.perform(function() {
    // Hook File.exists
    var File = Java.use("java.io.File");
    File.exists.implementation = function() {
        var path = this.getAbsolutePath();
        var blacklist = ["su", "Superuser", "magisk", "busybox", "xposed"];
        for (var i = 0; i < blacklist.length; i++) {
            if (path.toLowerCase().includes(blacklist[i])) {
                return false;
            }
        }
        return this.exists();
    };

    // Hook System.getProperty
    var System = Java.use("java.lang.System");
    System.getProperty.overload('java.lang.String').implementation = function(key) {
        if (key === "ro.debuggable" || key === "ro.secure") {
            return "1";
        }
        return this.getProperty(key);
    };
});
```

---

## Packer/Shell Detection and Unpacking

### Common Packer Vendors

| Packer | Identifying signature | Unpacking method |
|------|---------|---------|
| 360 packer | `libjiagu.so`, `com.stub.StubApp` | FART / Frida dump dex |
| Tencent Legu | `libshell*.so`, `com.tencent.StubShell` | FART / BlackDex |
| Bangcle | `libDexHelper.so`, `com.secneo.apkwrapper` | FART |
| IJiami | `libexec.so`, `s.h.e.l.l` | Frida dump |
| NetEase Yidun | `libnesec.so` | Frida dump |
| Naga | `libnaga.so` | Frida dump |

### Generic Unpacking Methods

```text
Method 1: FART (ART environment unpacking)
- Flash a FART ROM or use the Frida version of FART
- Automatically dump all dex files loaded by every ClassLoader

Method 2: Frida DEX Dump
- frida -U -f com.target.app -l dex_dump.js
- Hook at DexFile::OpenMemory and dump the dex from memory

Method 3: BlackDex
- Root-free unpacking tool
- Just install the BlackDex APK and select the target app to unpack

Method 4: Manual dump
- Use Frida to enumerate all ClassLoaders
- Find the app's ClassLoader → get the DexFile object
- Read the dex memory region and save it
```

### Frida DEX Dump Script

```javascript
Java.perform(function() {
    Java.enumerateClassLoaders({
        onMatch: function(loader) {
            try {
                var dexFiles = loader.getDexFileList();
                console.log("ClassLoader: " + loader);
                console.log("  DEX files: " + dexFiles);
            } catch(e) {}
        },
        onComplete: function() {}
    });
});
```

---

## React Native / Flutter Reverse Engineering

### React Native

```text
1. Unzip the APK → assets/index.android.bundle (JS code)
2. Format the JS → search for API endpoints, keys, signature logic
3. If there is Hermes bytecode (.hbc files) → decompile with hermes-dec
4. Hook: use Frida to hook the Java-layer ReactBridge
```

### Flutter

```text
1. Flutter code is compiled into libapp.so (Dart AOT)
2. Cannot be decompiled directly into Dart source
3. Analysis methods:
   - reFlutter tool: patch libflutter.so to obtain a snapshot
   - Doldrums: parse the Dart snapshot to recover class/function information
   - Use Frida to hook key functions in libflutter.so
4. Network analysis: Flutter does not use the system proxy, so SSL must be handled specially
```

---

## Tool Reference

| Tool | Purpose | Installation |
|------|------|------|
| jadx | Java decompilation | Included in bootstrap |
| apktool | Unpack/repack | Included in bootstrap |
| Frida | Dynamic Hook | `pip install frida-tools` |
| Objection | Frida wrapper (easier to use) | `pip install objection` |
| MobSF | Automated mobile security analysis | Docker deployment |
| BlackDex | Root-free unpacking | APK install |
| FART | ART unpacking | Flash a ROM or use the Frida version |
| hermes-dec | Hermes bytecode decompilation | npm install |
| reFlutter | Flutter reverse engineering helper | pip install |
| Magisk + Shamiko | Root hiding | Flash |

---

## Reference Resources

| Resource | Description | Link |
|------|------|------|
| OWASP MASTG | Mobile security testing guide | https://mas.owasp.org/ |
| FridaBypassKit | Generic bypass framework | https://github.com/okankurtuluss/FridaBypassKit |
| SSL-bypass | Generic SSL Pinning bypass | https://github.com/0xCD4/SSL-bypass |
| awesome-frida | Frida resource collection | https://github.com/dweinstein/awesome-frida |
| Android Security Awesome | Android security resources | https://github.com/ashishb/android-security-awesome |
