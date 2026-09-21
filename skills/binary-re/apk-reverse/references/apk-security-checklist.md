# APK Security Testing Checklist

> Based on OWASP MASTG (Mobile Application Security Testing Guide).
> Covers six dimensions: static analysis, dynamic analysis, network communication, data storage, authentication/authorization, and code protection.

---

## Static Analysis Checklist

### Manifest Audit

```text
□ android:debuggable="true" → debuggable (should not appear in production)
□ android:allowBackup="true" → data can be backed up and extracted
□ Components with android:exported="true" → exposed Activity/Service/Receiver/Provider
□ Custom permission protectionLevel → whether it is normal (should be signature)
□ scheme in intent-filter → whether a custom deeplink can be hijacked
□ android:usesCleartextTraffic="true" → cleartext HTTP allowed
□ minSdkVersion too low → may lack security features
```

### Code Audit Key Points

```text
□ Hardcoded keys/Token (search for "key", "secret", "password", "api_key")
□ Insecure random numbers (java.util.Random instead of SecureRandom)
□ Insecure crypto (ECB mode, DES, MD5 used for passwords)
□ WebView configuration (setJavaScriptEnabled + addJavascriptInterface = RCE risk)
□ SQL injection (rawQuery concatenating user input)
□ Path traversal (ContentProvider's openFile does not validate the path)
□ Log leakage (Log.d/Log.i outputting sensitive information)
□ Clipboard leakage (ClipboardManager storing sensitive data)
□ Implicit Intent leakage (sendBroadcast without specifying a package name)
```

### Third-party Library Audit

```text
□ Outdated OkHttp/Retrofit versions (known vulnerabilities)
□ Outdated WebView kernel
□ SDKs with known vulnerabilities (check CVE)
□ Data collection scope of ad SDKs
□ Push SDK configuration (whether it leaks tokens)
```

---

## Dynamic Analysis Checklist

### Frida Hook Priority Targets

| Target | Hook point | Purpose |
|------|---------|------|
| Login authentication | `LoginActivity.login()` | Observe credential handling |
| Signature generation | `*Sign*`, `*sign*`, `*encrypt*` | Recover the signature algorithm |
| SSL Pinning | `CertificatePinner.check` | Bypass for packet capture |
| Root detection | `*root*`, `*su*`, `*magisk*` | Bypass detection |
| Crypto operations | `javax.crypto.Cipher` | Extract key/IV |
| Token storage | `SharedPreferences.getString` | Observe token reads/writes |
| Network requests | `OkHttpClient.newCall` | Observe request construction |

### Common One-line Frida Commands

```bash
# Trace all crypto operations
frida-trace -U -f com.target.app -j '*Cipher*!*'

# Trace all HTTP requests
frida-trace -U -f com.target.app -j '*OkHttp*!*'

# Trace SharedPreferences reads/writes
frida-trace -U -f com.target.app -j '*SharedPreferences*!*'

# Trace all native function calls
frida-trace -U -f com.target.app -i 'Java_*'
```

### Objection Quick Commands

```bash
# Connect
objection -g com.target.app explore

# Common commands
android hooking list activities
android hooking list services
android sslpinning disable
android root disable
android clipboard monitor
env                              # View the app directory
sqlite connect <db_path>         # Connect to the database
```

---

## Network Communication Security

### Packet Capture Configuration

```text
Method 1: System proxy + Burp/mitmproxy
- Set the WiFi proxy → Burp listening address
- Install the CA certificate on the device
- Android 7+ requires network_security_config or a Frida bypass

Method 2: VPN mode (recommended)
- Use HttpCanary / Packet Capture
- No root required, no proxy configuration required
- But cannot decrypt traffic protected by SSL Pinning

Method 3: Frida + r2frida
- Intercept network calls directly inside the process
- Not limited by proxy/VPN
```

### Checklist

```text
□ Whether HTTPS is used (all API calls)
□ Whether SSL Pinning (certificate pinning) is present
□ Whether certificate validation is correct (does not accept self-signed)
□ Whether certificate transparency (CT) checks are present
□ Whether API keys are transmitted in cleartext in requests
□ Whether tokens have an expiration mechanism
□ Whether requests are signed to prevent tampering
□ Whether replay attack protection is present (nonce/timestamp)
□ Whether WebSocket is encrypted
□ Whether sensitive data is in URL parameters (it will be logged)
```

---

## Data Storage Security

### Locations to Check

| Location | Risk | Check command |
|------|------|---------|
| SharedPreferences | Cleartext storage of token/password | `adb shell cat /data/data/pkg/shared_prefs/*.xml` |
| SQLite database | Unencrypted sensitive data | `adb pull /data/data/pkg/databases/` |
| External storage | Readable by any app | `adb shell ls /sdcard/Android/data/pkg/` |
| App logs | Leaks debug information | `adb logcat \| grep pkg` |
| Backup files | allowBackup=true | `adb backup -f backup.ab pkg` |
| Keyboard cache | Input history | Check whether `inputType` is `textPassword` |
| Screenshot protection | Sensitive pages can be screenshotted | Check `FLAG_SECURE` |

### Encrypted Storage Options Compared

| Option | Security | Notes |
|------|--------|------|
| SharedPreferences cleartext | ❌ | Read directly after root |
| EncryptedSharedPreferences | ✓ | AndroidX Security library |
| SQLCipher | ✓ | Encrypted SQLite |
| Android Keystore | ✓✓ | Hardware-level key protection |
| Custom AES encryption | ⚠️ | Depends on key management |

---

## Authentication and Authorization

### Common Vulnerabilities

| Vulnerability | Test method |
|------|---------|
| Weak password policy | Try 123456, password, etc. |
| No lockout mechanism | Brute-force the login endpoint |
| Token does not expire | Replay an old token after logout |
| Broken access control | Modify user_id in the request |
| SMS verification code brute-forceable | 4/6-digit code with no rate limit |
| OAuth misconfiguration | redirect_uri can be tampered with |
| Biometric authentication bypass | Hook BiometricPrompt |
| Device binding bypass | Modify device_id |

### Test Payloads

```bash
# Broken access control test
curl -H "Authorization: Bearer USER_A_TOKEN" \
     "https://api.target.com/users/USER_B_ID/profile"

# Token replay
# 1. Log in normally to obtain a token
# 2. Log out
# 3. Request with the old token → should return 401

# SMS verification code brute-force
for code in $(seq 0000 9999); do
    curl -X POST "https://api.target.com/verify" \
         -d "phone=13800138000&code=$code"
done
```

---

## Code Protection Assessment

| Protection measure | Detection method | Bypass difficulty |
|---------|---------|---------|
| ProGuard obfuscation | Use jadx to see whether class names are a/b/c | Low (only renaming) |
| String encryption | Search for the decryption function, Hook to get cleartext | Medium |
| Anti-debug | Try to attach a debugger | Medium (Frida can bypass) |
| Root detection | Run on a rooted device | Medium (generic scripts bypass) |
| Emulator detection | Run on an emulator | Low-Medium |
| Integrity check | Modify the APK and install | Medium (patch the check function) |
| Packer/shell | Inspect the entry class and .so | Medium-High (unpacking required) |
| Native protection | Core logic in .so | High (IDA analysis required) |
| VMP virtualization | Code executed virtualized | Very high |

---

## Quick Test Flow (30 minutes)

```text
1. [5min] Unpack + Manifest audit
   apktool d app.apk
   Check debuggable/allowBackup/exported/cleartext

2. [10min] Quick code audit
   jadx -d out app.apk
   Search: password, key, secret, token, http://

3. [5min] Network testing
   Configure a proxy → operate the APP → check for cleartext/weak crypto

4. [5min] Storage check
   adb shell → check shared_prefs and databases

5. [5min] Dynamic verification
   Frida hook key functions → confirm findings
```
