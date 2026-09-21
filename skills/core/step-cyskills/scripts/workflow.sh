#!/usr/bin/env bash
# Resolve a cyskills workflow into an ordered skill-injection plan (kernel of step-cyskills).
# Usage:
#   workflow.sh                 list workflows
#   workflow.sh <name>          resolve: ordered skills, presence check, tool readiness
# Manifests: skills/workflows/workflow-*/bundle.conf (name, title, track, skills, tools).
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
WORKFLOWS_DIR="${CYSKILLS_WORKFLOWS:-$SKILLS_ROOT/workflows}"
CATALOG="$SCRIPT_DIR/catalog.conf"

manifest() { sed -n "s/^$2=//p" "$1" | head -1; }

list() {
  echo "workflows:"
  local f name title
  for f in "$WORKFLOWS_DIR"/workflow-*/bundle.conf; do
    [ -f "$f" ] || continue
    name="$(manifest "$f" name)"; title="$(manifest "$f" title)"
    printf '  %-14s %s\n' "${name:-$(basename "$(dirname "$f")")}" "$title"
  done
}

skill_dir() { # $1 = skill name → prints its dir when present on disk
  local cat p
  cat="$(awk -F'|' -v s="$1" '$1==s{print $3; exit}' "$CATALOG" 2>/dev/null)"
  if [ -n "$cat" ] && [ -f "$SKILLS_ROOT/$cat/$1/SKILL.md" ]; then
    printf '%s' "$SKILLS_ROOT/$cat/$1"; return 0
  fi
  for p in "$SKILLS_ROOT"/*/"$1"/SKILL.md; do
    [ -f "$p" ] && { printf '%s' "${p%/SKILL.md}"; return 0; }
  done
  return 1
}

resolve() {
  local want="$1" bf="" cand name title track skills tools missing=0 i=0 s p
  for cand in "$WORKFLOWS_DIR"/workflow-*/bundle.conf; do
    [ -f "$cand" ] || continue
    name="$(manifest "$cand" name)"
    if [ "$name" = "$want" ] || [ "$(basename "$(dirname "$cand")")" = "workflow-$want" ]; then
      bf="$cand"; break
    fi
  done
  if [ -z "$bf" ]; then
    echo "[-] unknown workflow: $want" >&2
    list >&2
    return 1
  fi
  name="$(manifest "$bf" name)"; title="$(manifest "$bf" title)"
  track="$(manifest "$bf" track)"
  skills="$(manifest "$bf" skills)"; tools="$(manifest "$bf" tools)"
  echo "workflow: $name — $title"
  echo "inject (Skill tool, in order, then follow ${track:-$name}):"
  for s in $skills; do
    i=$((i+1))
    if p="$(skill_dir "$s")"; then
      printf '  %2d  %-16s ok\n' "$i" "$s"
    else
      printf '  %2d  %-16s MISSING — install the %s skill\n' "$i" "$s" "$s"
      missing=$((missing+1))
    fi
  done
  echo
  echo "readiness:"
  if [ -n "$tools" ]; then
    # shellcheck disable=SC2086
    bash "$SCRIPT_DIR/preflight.sh" $tools
  else
    echo "  (no tools declared in bundle.conf)"
  fi
  if [ "$missing" -gt 0 ]; then
    echo
    echo "[!] $missing module(s) missing — load the rest; ask the user to install the missing ones."
    return 1
  fi
  return 0
}

cmd="${1:-list}"; shift || true
case "$cmd" in
  list) list ;;
  -h|--help) sed -n '2,6p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' ;;
  *) resolve "$cmd" ;;
esac
