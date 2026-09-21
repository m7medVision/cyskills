#!/usr/bin/env bash
# Recommend skills for a task from catalog.conf.
# Informational only: lists the skills, never installs them.
# Usage: recommend.sh "<task description>"
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TASK="$*"
[ -n "$TASK" ] || { echo 'usage: recommend.sh "<task description>"' >&2; exit 1; }

matches=$(awk -F'|' -v task="$TASK" '
BEGIN{ n=split(tolower(task), tw, /[^a-z0-9]+/) }
{
  skill=$1; hay=tolower($2 " " $3)
  s=0
  for(i=1;i<=n;i++){ w=tw[i]; if(length(w)>=4 && index(hay,w)>0) s++ }
  if(s>0) printf "%d|%s\n", s, skill
}' "$SCRIPT_DIR/catalog.conf" | sort -t'|' -k1,1rn | head -8)

if [ -z "$matches" ]; then
  echo "No confident match. Installed categories:"
  awk -F'|' '{print "  "$3}' "$SCRIPT_DIR/catalog.conf" | sort -u
  echo
  echo "Ask the user to install the skills this task needs before continuing."
  exit 0
fi

skills=$(printf '%s\n' "$matches" | cut -d'|' -f2 | tr '\n' ' ')
printf 'recommended: %s\n\n' "$skills"
printf 'Ask the user to install these skills before continuing; this skill does not install them.\n'
