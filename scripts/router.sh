#!/usr/bin/env bash
# router.sh — route a task or a workflow preset to an ordered module list.
# The index is derived at runtime from modules/*/*/MODULE.md frontmatter.
# Usage:
#   router.sh "<task description>"    keyword-match modules for the task
#   router.sh --workflow <name>       resolve a preset bundle (scripts/bundles/)
#   router.sh --list                  list preset bundles
#   router.sh --check                 validate bundles and module frontmatter
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODULES="$ROOT/modules"
BUNDLES="$ROOT/scripts/bundles"

# index: name|category|path|description  (path relative to repo root)
index() {
  local f name desc
  for f in "$MODULES"/*/*/MODULE.md; do
    [ -f "$f" ] || continue
    name="$(sed -n 's/^name:[[:space:]]*//p' "$f" | head -1 | tr -d '"')"
    desc="$(sed -n 's/^description:[[:space:]]*//p' "$f" | head -1 | tr -d '"')"
    [ -n "$name" ] || continue
    printf '%s|%s|%s|%s\n' "$name" "$(basename "$(dirname "$(dirname "$f")")")" "${f#"$ROOT"/}" "$desc"
  done
}

usage() { sed -n '2,7p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

list() {
  echo "presets:"
  local f name title
  for f in "$BUNDLES"/*.conf; do
    [ -f "$f" ] || continue
    name="$(sed -n 's/^name=//p' "$f" | head -1)"
    title="$(sed -n 's/^title=//p' "$f" | head -1)"
    printf '  %-14s %s\n' "${name:-$(basename "$f" .conf)}" "$title"
  done
}

# $1 = skill name → prints its module path (relative to root), empty if unknown
resolve() {
  index | awk -F'|' -v s="$1" '$1==s{print $3; exit}'
}

workflow() {
  local want="$1" f="" name title track skills s path
  for f in "$BUNDLES"/*.conf; do
    [ "$(sed -n 's/^name=//p' "$f" | head -1)" = "$want" ] && break
    f=""
  done
  if [ -z "$f" ]; then
    echo "[-] unknown preset: $want" >&2
    list >&2
    return 1
  fi
  name="$(sed -n 's/^name=//p' "$f" | head -1)"
  title="$(sed -n 's/^title=//p' "$f" | head -1)"
  track="$(sed -n 's/^track=//p' "$f" | head -1)"
  skills="$(sed -n 's/^skills=//p' "$f" | head -1)"
  echo "workflow: $name — $title"
  [ -n "$track" ] && echo "case track: $track"
  echo "read (Read tool, in order; the engine owns case, matrix, and report):"
  local i=0 bad=0
  for s in $skills; do
    i=$((i+1))
    path="$(resolve "$s")"
    if [ -n "$path" ]; then
      printf '  %2d  %s\n' "$i" "$path"
    else
      printf '  %2d  %-16s UNRESOLVED — fix scripts/bundles/%s.conf\n' "$i" "$s" "$name"
      bad=$((bad+1))
    fi
  done
  return "$bad"
}

match() {
  [ -n "$1" ] || { usage; exit 1; }
  local hits
  hits=$(index | awk -F'|' -v task="$*" '
    BEGIN{ n=split(tolower(task), tw, /[^a-z0-9]+/) }
    {
      hay=tolower($2 " " $3 " " $4)
      s=0
      for(i=1;i<=n;i++){ w=tw[i]; if(length(w)>=4 && index(hay,w)>0) s++ }
      if(s>0) printf "%d|%s|%s\n", s, $1, $3
    }' | sort -t'|' -k1,1rn | head -8)
  if [ -z "$hits" ]; then
    echo "no confident match. available categories:"
    index | awk -F'|' '{print "  "$2}' | sort -u
    echo "name a preset (--workflow web-pentest|mobile-pentest|infra-pentest) or rephrase the task."
    return 1
  fi
  echo "route: $*"
  echo "read (Read tool, in order):"
  echo "$hits" | awk -F'|' '{printf "  %2d  %s\n", NR, $3}'
}

check() {
  local err=0 n=0 f name desc s
  echo "== modules =="
  while IFS='|' read -r name _ path desc; do
    n=$((n+1))
    if [ -z "$desc" ]; then
      echo "  [!] $path: empty description"; err=$((err+1))
    fi
  done < <(index)
  for f in "$MODULES"/*/*/MODULE.md; do
    [ -f "$f" ] || continue
    grep -q '^name:' "$f" || { echo "  [!] ${f#"$ROOT"/}: no frontmatter name"; err=$((err+1)); }
  done
  echo "  $n modules indexed"
  echo "== bundles =="
  for f in "$BUNDLES"/*.conf; do
    [ -f "$f" ] || continue
    printf '  %s: ' "$(basename "$f")"
    bad=0
    for s in $(sed -n 's/^skills=//p' "$f" | head -1); do
      [ -n "$(resolve "$s")" ] || { printf '[%s] ' "$s"; bad=1; err=$((err+1)); }
    done
    [ "$bad" = 0 ] && echo "ok" || echo "UNRESOLVED"
  done
  return "$err"
}

case "${1:-}" in
  --workflow) shift; workflow "${1:?usage: router.sh --workflow <name>}" ;;
  --list) list ;;
  --check) check ;;
  -h|--help|"") usage ;;
  *) match "$*" ;;
esac
