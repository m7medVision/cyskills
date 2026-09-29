#!/usr/bin/env bash
# check-tools.sh — tool readiness for the module library, modern channels only.
# Lists what is missing and prints fast install commands (uv / bun / go / prebuilt).
# Read-only by default. --install is meant to be run BY THE USER; it asks before acting.
# Usage:
#   check-tools.sh [--track web|infra|mobile|re|dfir|core] [name ...]
#   check-tools.sh --install [--track ...] [name ...]
set -uo pipefail

# name~channel~pkg~probe~purpose~tracks
# channels: uv = uv tool install · bun = bun install -g · go = go install · bin = full command · system = grouped pacman
REG="$(cat <<'EOF'
bun~bin~curl -fsSL https://bun.sh/install -o /tmp/bun-install.sh && bash /tmp/bun-install.sh~bun~JS runtime and package runner (fast)~core
uv~bin~curl -LsSf https://astral.sh/uv/install.sh -o /tmp/uv-install.sh && sh /tmp/uv-install.sh~uv~Fast Python tool manager~core
go~system~go~go~Go toolchain (compiles go-channel tools)~core
java~system~jdk-openjdk~java~Runtime for jadx, apktool, ghidra, ysoserial~core,mobile,re
playwright~bin~bun install -g playwright && bunx playwright install chromium~playwright~Browser automation (Chromium)~core,web
nmap~system~nmap~nmap~Port scanning and service detection~web,infra
masscan~system~masscan~masscan~Mass IP/port scanner~infra
nuclei~go~github.com/projectdiscovery/nuclei/v2/cmd/nuclei~nuclei~Template-based vulnerability scanning~web,infra
subfinder~go~github.com/projectdiscovery/subfinder/v2/cmd/subfinder~subfinder~Passive subdomain enumeration~web
httpx~go~github.com/projectdiscovery/httpx/cmd/httpx~httpx~HTTP probing and tech detection~web
katana~go~github.com/projectdiscovery/katana/cmd/katana~katana~Web crawler and endpoint discovery~web
ffuf~go~github.com/ffuf/ffuf/v2~ffuf~Web fuzzer~web
gobuster~go~github.com/OJ/gobuster/v3~gobuster~Directory, DNS and vhost brute force~web
interactsh-client~go~github.com/projectdiscovery/interactsh/cmd/interactsh-client~interactsh-client~OOB callback client~web
dalfox~go~github.com/hahwul/dalfox/v2~dalfox~XSS scanner~web
jsluice~go~github.com/BishopFox/jsluice/cmd/jsluice~jsluice~JS URL and secret extraction~web
gitleaks~go~github.com/zricethezav/gitleaks/v8~gitleaks~Secret scanning~web,mobile
sqlmap~uv~sqlmap~sqlmap~SQL injection automation~web
netexec~uv~netexec~nxc~AD/network exploitation (SMB, LDAP, WinRM)~infra
mitmproxy~uv~mitmproxy~mitmdump~HTTPS interception proxy~web,mobile
impacket~uv~impacket~secretsdump.py~Windows protocol toolkit~infra
certipy~uv~certipy-ad~certipy~AD CS abuse~infra
hashid~uv~hashid~hashid~Hash type identification~infra
arjun~uv~arjun~arjun~Hidden HTTP parameter discovery~web
corsy~uv~corsy~corsy~CORS misconfiguration scanner~web
sslyze~uv~sslyze~sslyze~TLS configuration scanner~web
binwalk~uv~binwalk~binwalk~Firmware and file extraction (v3)~re,dfir
pwntools~uv~pwntools~pwn~Exploit development CLI~re
ropgadget~uv~ropgadget~ROPgadget~ROP gadget search~re
ropper~uv~ropper~ropper~ROP gadget search (alternative)~re
ghidra~bin~curl -sL -o /tmp/ghidra.zip "$(curl -s https://api.github.com/repos/NationalSecurityAgency/ghidra/releases/latest | grep -oP '"browser_download_url": "\K[^"]*\.zip' | head -1)" && unzip -q -o /tmp/ghidra.zip -d "$HOME/tools" && mkdir -p "$HOME/.local/bin" && ln -sf "$HOME"/tools/ghidra_*/ghidraRun "$HOME/.local/bin/ghidraRun"~ghidraRun~Reverse engineering suite (needs java)~re
radare2~system~radare2~r2~Binary analysis CLI~re
yara~system~yara~yara~Malware rule scanning~re,dfir
volatility3~uv~volatility3~vol~Memory forensics~dfir
tshark~system~wireshark-cli~tshark~PCAP analysis~dfir
tcpdump~system~tcpdump~tcpdump~Traffic capture~dfir,infra
trufflehog~bin~curl -sSfL https://raw.githubusercontent.com/trufflesecurity/trufflehog/main/scripts/install.sh -o /tmp/th-install.sh && sh /tmp/th-install.sh -b "$HOME/.local/bin"~trufflehog~Secret scanning (prebuilt binary)~web,mobile
testssl.sh~bin~git clone --depth 1 https://github.com/drwetter/testssl.sh.git "$HOME/tools/testssl.sh" && mkdir -p "$HOME/.local/bin" && ln -sf "$HOME/tools/testssl.sh/testssl.sh" "$HOME/.local/bin/testssl.sh"~testssl.sh~TLS/SSL configuration scanner~web,infra
adb~bin~curl -sL -o /tmp/platform-tools.zip https://dl.google.com/android/repository/platform-tools-latest-linux.zip && unzip -q -o /tmp/platform-tools.zip -d "$HOME/tools" && mkdir -p "$HOME/.local/bin" && ln -sf "$HOME/tools/platform-tools/adb" "$HOME/.local/bin/adb"~adb~Android debug bridge~mobile
jadx~bin~curl -sL -o /tmp/jadx.zip "$(curl -s https://api.github.com/repos/skylot/jadx/releases/latest | grep -oP '"browser_download_url": "\K[^"]*jadx-[\d.]+\.zip' | head -1)" && unzip -q -o /tmp/jadx.zip -d "$HOME/tools/jadx" && mkdir -p "$HOME/.local/bin" && ln -sf "$HOME/tools/jadx/bin/jadx" "$HOME/.local/bin/jadx"~jadx~Java decompiler~mobile
apktool~bin~mkdir -p "$HOME/.local/bin" && curl -sL -o "$HOME/.local/bin/apktool" "$(curl -s https://api.github.com/repos/iBotPeaches/Apktool/releases/latest | grep -oP '"browser_download_url": "\K[^"]*apktool_[\d.]+\.jar' | head -1)" && chmod +x "$HOME/.local/bin/apktool"~apktool~APK decoding and rebuild (jar)~mobile
frida~uv~frida-tools~frida~Dynamic instrumentation~mobile,re
objection~uv~objection~objection~Frida-based runtime exploration~mobile
drozer~uv~drozer~drozer~Android attack-surface testing~mobile
apkleaks~uv~apkleaks~apkleaks~APK secret and endpoint scanner~mobile
reflutter~uv~reFlutter~reflutter~Flutter MITM patching~mobile
hermes-dec~uv~hermes-dec~hermes-dec~Hermes bytecode decompiler~mobile
hydra~system~hydra~hydra~Login brute force~infra
hashcat~system~hashcat~hashcat~GPU hash cracking~infra
john~system~john~john~CPU hash cracking~infra
searchsploit~system~exploitdb~searchsploit~Exploit-DB offline search~web,infra
aircrack-ng~system~aircrack-ng~aircrack-ng~Wireless assessment~infra
sslscan~system~sslscan~sslscan~TLS cipher/protocol scanner~web
nikto~system~nikto~nikto~Web server misconfiguration scanner~web
whatweb~system~whatweb~whatweb~Web technology fingerprinting~web
EOF
)"

INSTALL=0; TRACK=""; WANT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --install) INSTALL=1 ;;
    --track) TRACK="$2"; shift ;;
    -h|--help) sed -n '2,7p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) WANT="$WANT $1" ;;
  esac
  shift
done

rows() {
  printf '%s\n' "$REG" | while IFS='~' read -r name channel pkg probe purpose tracks; do
    [ -z "$name" ] && continue
    if [ -n "$TRACK" ]; then case ",$tracks," in *",$TRACK,"*) ;; *) continue ;; esac; fi
    if [ -n "$WANT" ]; then case " $WANT " in *" $name "*) ;; *) continue ;; esac; fi
    printf '%s~%s~%s~%s~%s\n' "$name" "$channel" "$pkg" "$probe" "$purpose"
  done
}

miss_uv=""; miss_bun=""; miss_go=""; miss_bin=""; miss_sys=""; n_ok=0; n_miss=0

echo "tool readiness ($(date -u +%F))"
while IFS='~' read -r name channel pkg probe purpose; do
  [ -z "$name" ] && continue
  if command -v "$probe" >/dev/null 2>&1; then
    printf '  [%-4s] %-18s %s\n' ok "$name" "$purpose"; n_ok=$((n_ok+1))
  else
    printf '  [%-4s] %-18s %s\n' MISS "$name" "$purpose"; n_miss=$((n_miss+1))
    case "$channel" in
      uv) printf '       %s\n' "uv tool install $pkg   (one-shot: uvx $pkg)"; miss_uv="$miss_uv $pkg" ;;
      bun) printf '       %s\n' "bun install -g $pkg"; miss_bun="$miss_bun $pkg" ;;
      go) printf '       %s\n' "go install $pkg@latest"; miss_go="$miss_go $pkg" ;;
      bin) printf '       %s\n' "$pkg"; miss_bin="$miss_bin
$pkg" ;;
      system) printf '       %s\n' "system package (batched below)"; miss_sys="$miss_sys $pkg" ;;
    esac
  fi
done < <(rows)

if [ "$n_miss" -eq 0 ]; then
  echo "all $n_ok tools present."
  exit 0
fi

echo
echo "missing $n_miss of $((n_ok+n_miss)). fast path — paste these:"
[ -n "$miss_uv" ]  && echo "  uv tool install$miss_uv"
[ -n "$miss_bun" ] && echo "  bun install -g$miss_bun"
[ -n "$miss_go" ]  && echo "  for p in$miss_go; do go install \"\$p@latest\"; done"
[ -n "$miss_sys" ] && echo "  sudo pacman -S --needed$miss_sys"
[ -n "$miss_bin" ] && { echo "  # prebuilt/one-shot:"; printf '%s\n' "$miss_bin" | sed '/^$/d; s/^/  /'; }

if [ "$INSTALL" = 1 ]; then
  echo
  printf 'install the %s missing tool(s) now? [y/N] ' "$n_miss"
  read -r answer
  case "$answer" in
    y|Y)
      [ -n "$miss_uv" ]  && uv tool install$miss_uv
      [ -n "$miss_bun" ] && bun install -g$miss_bun
      [ -n "$miss_go" ]  && for p in $miss_go; do go install "$p@latest"; done
      [ -n "$miss_sys" ] && sudo pacman -S --needed$miss_sys
      [ -n "$miss_bin" ] && printf '%s\n' "$miss_bin" | sed '/^$/d' | while IFS= read -r cmd; do eval "$cmd"; done
      echo "done. re-run without --install to verify."
      ;;
    *) echo "aborted — nothing was installed." ;;
  esac
else
  echo
  echo "the agent never installs: run this script with --install yourself, or paste the commands above."
fi
