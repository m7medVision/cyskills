#!/usr/bin/env bash
# Cyskills preflight: detect distro, audit tools and wordlist resources, print install hints.
# Informational only: never installs or downloads anything.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/cyskills.conf"

# --- distro detection ---
DISTRO="unknown"; PM="none"; BLACKARCH=0; AUR=""
if [ -r /etc/os-release ]; then
  # shellcheck source=/dev/null
  . /etc/os-release
  DISTRO="${ID:-unknown}"
fi
if command -v apt-get >/dev/null 2>&1; then PM="apt"
elif command -v pacman >/dev/null 2>&1; then
  PM="pacman"
  if grep -q '^\[blackarch\]' /etc/pacman.conf 2>/dev/null || ls /etc/pacman.d/blackarch* >/dev/null 2>&1; then BLACKARCH=1; fi
  if command -v yay >/dev/null 2>&1; then AUR="yay -S"; elif command -v paru >/dev/null 2>&1; then AUR="paru -S"; else AUR="yay -S"; fi
fi

hint() { # $1=apt $2=pacman $3=aur $4=pip $5=git $6=name $7=purpose
  local apt="$1" pac="$2" aur="$3" pip="$4" git="$5" name="$6" purpose="$7"
  if [ "$PM" = "apt" ] && [ -n "$apt" ]; then echo "sudo apt install $apt"
  elif [ "$PM" = "pacman" ] && [ "$BLACKARCH" = "1" ] && [ -n "$pac" ]; then echo "sudo pacman -S $pac"
  elif [ "$PM" = "pacman" ] && [ -n "$aur" ]; then echo "$AUR $aur"
  elif [ -n "$pip" ]; then echo "uv tool install $pip   (no install needed: uvx runs it once)"
  elif [ -n "$git" ]; then echo "git clone --depth 1 $git $CYSKILLS_DATA/$name"
  else echo "manual install (see $purpose)"
  fi
}

printf 'distro: %s   package-manager: %s%s\n\n' "$DISTRO" "$PM" "$( [ "$BLACKARCH" = 1 ] && echo ' (blackarch)' )"

echo "TOOLS"
printf '  %-4s %-14s %s\n' "?" "tool" "install if missing"
while IFS='|' read -r name probe apt pac aur pip purpose; do
  [ -z "$name" ] && continue
  case "$name" in \#*) continue ;; esac
  if eval "$probe" </dev/null >/dev/null 2>&1; then
    printf '  %-4s %-14s %s\n' "ok" "$name" "$purpose"
  else
    printf '  %-4s %-14s %s\n' "MISS" "$name" "$(hint "$apt" "$pac" "$aur" "$pip" "" "$name" "$purpose")"
  fi
done < "$SCRIPT_DIR/tools.conf"

echo
echo "RESOURCES"
printf '  %-4s %-22s %s\n' "?" "resource" "path or install"
while IFS='|' read -r name paths sentinel apt pac aur git purpose; do
  [ -z "$name" ] && continue
  case "$name" in \#*) continue ;; esac
  found=""
  IFS=':' read -r -a cand <<< "$paths"
  for p in "${cand[@]}"; do
    p="${p//\$HOME/$HOME}"
    if [ -n "$sentinel" ]; then
      [ -e "$p/$sentinel" ] && { found="$p"; break; }
    else
      [ -e "$p" ] && { found="$p"; break; }
    fi
  done
  if [ -n "$found" ]; then
    printf '  %-4s %-22s %s\n' "ok" "$name" "$found"
  else
    printf '  %-4s %-22s %s\n' "MISS" "$name" "$(hint "$apt" "$pac" "$aur" "" "$git" "$name" "$purpose")"
  fi
done < "$SCRIPT_DIR/resources.conf"

echo
echo "Nothing was installed. Ask the user before running any install command."