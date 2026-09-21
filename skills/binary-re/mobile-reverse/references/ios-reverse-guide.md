# iOS Reverse Engineering Deep Dive

## IPA Acquisition and Decryption

```bash
# Download from the App Store
ipatool search "Target App"
ipatool purchase -b com.target.app
ipatool download -b com.target.app -o app.ipa

# Extract an installed app from the device
# Jailbroken device
scp root@device:/private/var/containers/Bundle/Application/*/Target.app .

# Decryption (the App Store binary is an encrypted FAT format)
# frida-ios-dump (recommended)
python3 dump.py com.target.app -o decrypted.ipa

# Clutch
Clutch -i  # List installed apps
Clutch -d 1  # Decrypt the first one

# dumpdecrypted
DYLD_INSERT_LIBRARIES=dumpdecrypted.dylib /path/to/App
```

## Mach-O Analysis

```bash
# Basic info
otool -l TargetBinary | grep crypt    # Encryption status
otool -L TargetBinary                 # Dynamic library dependencies
otool -hv TargetBinary                # Header info
jtool2 --pages TargetBinary           # Memory page info

# Fat Binary thinning
lipo -info TargetBinary
lipo TargetBinary -thin arm64 -output TargetBinary_arm64

# Symbol analysis
nm -g TargetBinary                    # Exported symbols
nm -a TargetBinary                    # All symbols
swift-demangle <mangled_name>         # Swift symbol demangling

# class-dump
class-dump -H TargetBinary -o headers/
# Export ObjC class and method declarations to the headers/ directory
```

## Objective-C Runtime Analysis

```text
Message-passing mechanism:
objc_msgSend(id self, SEL op, ...)  →  dynamic method dispatch
  ↓
Runtime lookup:
1. Class method list cache
2. Class method list
3. Walk up the superclass chain
4. +resolveInstanceMethod / +resolveClassMethod
5. forwardingTargetForSelector
6. methodSignatureForSelector + forwardInvocation
```

### Frida ObjC Hook

```javascript
// Hook an instance method
var hook = ObjC.classes.ClassName["- instanceMethod:"];
Interceptor.attach(hook.implementation, {
    onEnter: function(args) {
        // args[0] = self, args[1] = selector, args[2+] = method args
        console.log("self: " + new ObjC.Object(args[0]));
        console.log("arg: " + args[2].toInt32());
    }
});

// Hook a class method
var hook = ObjC.classes.ClassName["+ classMethod:"];
Interceptor.attach(hook.implementation, { ... });

// Call an ObjC method
var NSString = ObjC.classes.NSString;
var str = NSString.stringWithString_("test");
console.log(str.UTF8String());
```

## Swift Reverse Engineering

```text
Swift name mangling:
$s10ModuleName5ClassC6method3argSi_tF
  │ │         │     │ │      │  │   └─ parameter type
  │ │         │     │ │      │  └───── return type  
  │ │         │     │ │      └──────── parameter name
  │ │         │     │ └─────────────── method name
  │ │         │     └──────────────── class name (length + name)
  │ │         └────────────────────── module name
  │ └──────────────────────────────── identifier marker
  └────────────────────────────────── global marker

Tools: swift-demangle, Hopper (automatic demangling)
```

## Jailbreak Detection Bypass

```text
Detection method categories:

1. File system checks:
   □ /Applications/Cydia.app
   □ /var/lib/apt/
   □ /bin/bash
   □ /usr/sbin/sshd
   → Hook NSFileManager.fileExistsAtPath:

2. Sandbox escape detection:
   □ Whether fork() succeeds (forbidden inside the sandbox)
   □ system() call
   → Hook fork → return -1

3. Dyld injection detection:
   □ _dyld_get_image_count > limit
   → Clamp the return value to a reasonable range

4. Scheme detection:
   □ cydia:// URL Scheme
   → Hook UIApplication.canOpenURL:

5. sysctl detection:
   □ CTL_KERN/KERN_PROC/KERN_PROC_PID → kinfo_proc
   → Hook sysctl → clear the p_flag P_TRACED bit
```

### Unified Frida Bypass Script

```javascript
// File detection bypass
var NSFileManager = ObjC.classes.NSFileManager;
var defaultManager = NSFileManager.defaultManager();
Interceptor.attach(defaultManager["- fileExistsAtPath:"].implementation, {
    onLeave: function(retval) {
        var path = ObjC.Object(args[2]).toString();
        if (path.includes("Cydia") || path.includes("apt") || 
            path.includes("sshd") || path.includes("bash")) {
            retval.replace(0); // false
        }
    }
});

// fork bypass
Interceptor.replace(Module.findExportByName(null, "fork"), 
    new NativeCallback(function() { return -1; }, 'int', []));

// dyld bypass
var _dyld_get_image_count = Module.findExportByName(null, "_dyld_get_image_count");
Interceptor.attach(_dyld_get_image_count, {
    onLeave: function(retval) {
        if (retval.toInt32() > 200) retval.replace(200);
    }
});
```

## Key Protection Bypass Checklist

| Protection | iOS bypass method |
|------|-------------|
| App Store encryption | frida-ios-dump / Clutch |
| SSL Pinning | Objection `ios sslpinning disable` / SSL Kill Switch 2 |
| Jailbreak detection | Objection `ios jailbreak disable` / custom Frida Hook |
| Anti-debug (PT_DENY_ATTACH) | Frida post-launch injection / debugserver |
| Integrity check | Hook MAC check / code signature verification |
| Anti-injection | Modify the Mach-O to remove the __RESTRICT segment |
| Swift obfuscation | swift-demangle + LLM-assisted semantic recovery |
| Screenshot protection | Hook UIScreen.mainScreen.snapshotViewAfterScreenUpdates |

Source: OWASP MSTG, frida-ios-dump, The iPhone Wiki
