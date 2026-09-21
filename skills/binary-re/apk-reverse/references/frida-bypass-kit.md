# Frida Bypass Kit — Android Generic Security Bypass Framework

> Source: [FridaBypassKit](https://github.com/okankurtuluss/FridaBypassKit) (2025)
> Use cases: when APK dynamic analysis requires bypassing root detection, SSL pinning, emulator detection, and anti-debug

## Overview

FridaBypassKit is a Frida script that integrates four major bypass capabilities. It requires no app-specific customization and works out of the box.

## The Four Bypass Capabilities

### 1. Root Detection Bypass

- Hook `File.exists()` to hide the su binary
- Intercept root-check calls to `Runtime.exec()`
- Hide root-related packages from PackageManager (Magisk, SuperSU, etc.)
- Modify system properties so the device appears unrooted

### 2. SSL Pinning Bypass

- Hook `TrustManagerImpl.verifyChain()`
- Hook `TrustManagerImpl.checkTrustedRecursive()`
- Bypass certificate chain validation
- Return an empty certificate chain to avoid validation
- Compatible with OkHttp, Retrofit, and custom implementations

### 3. Emulator Detection Bypass

- Forge TelephonyManager return values
- Return a fake phone number and carrier name
- Modify Build properties

### 4. Anti-Debug Bypass

- Hook `Debug.isDebuggerConnected()`
- Block debugger detection
- Bypass anti-debug checks

## Usage

```bash
# Prerequisites
pip install frida-tools
adb push frida-server /data/local/tmp/
adb shell chmod 755 /data/local/tmp/frida-server
adb shell su -c /data/local/tmp/frida-server &

# Inject into the target APP
frida -U -f com.example.app -l FridaBypassKit.js
```

## Other Recommended Frida Bypass Scripts

| Project | Feature | Link |
|------|------|------|
| httptoolkit/frida-interception-and-unpinning | MitM all HTTPS traffic directly | [GitHub](https://github.com/httptoolkit/frida-interception-and-unpinning) |
| 0xCD4/SSL-bypass | Generic, non-custom SSL bypass | [GitHub](https://github.com/0xCD4/SSL-bypass) |
| incogbyte/ssl-bypass gist | Bypasses common SSL pinning methods | [Gist](https://gist.github.com/incogbyte/1e0e2f38b5602e72b1380f21ba04b15e) |
| Zero3141/Frida-OkHttp-Bypass | Specifically targets OkHttp CertificatePinner | [GitHub](https://github.com/Zero3141/Frida-OkHttp-Bypass) |

## Integration with This Package

In the `apk-reverse` workflow, use this when you encounter the following:

1. The APP detects root and refuses to run → enable Root Detection Bypass
2. HTTPS requests show no cleartext during packet capture → enable SSL Pinning Bypass
3. The APP detects an emulator and refuses to run → enable Emulator Detection Bypass
4. The APP crashes after attaching Frida → enable Debug Detection Bypass

Recommended: run the full FridaBypassKit first, then adjust as needed.
