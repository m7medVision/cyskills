#!/usr/bin/env bash
# Scope hard gate before any target action. Exit 0 = allowed, 2 = not ready, 1 = error.
# Usage: scope-guard.sh --case NAME   |   scope-guard.sh --case-root DIR
set -uo pipefail

CASE=""; CASE_ROOT=""; QUIET=0
while [ $# -gt 0 ]; do
  case "$1" in
    --case|-c) CASE="${2:-}"; shift 2 ;;
    --case-root) CASE_ROOT="${2:-}"; shift 2 ;;
    --quiet) QUIET=1; shift ;;
    -h|--help) sed -n '2,3p' "$0"; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done
[ -n "$CASE_ROOT" ] || CASE_ROOT="$(pwd -P)/work/$CASE"
[ -n "$CASE" ] || [ -n "$CASE_ROOT" ] || { echo "ERROR: --case or --case-root required" >&2; exit 1; }

SCOPE="$CASE_ROOT/scope.md"
[ -f "$SCOPE" ] || { echo "DENY: scope.md missing at $SCOPE" >&2; exit 2; }

STATUS="$(awk -F': *' '/^[[:space:]]*-[[:space:]]*status:/{print $2; exit}' "$SCOPE")"
ASSETS="$(awk '/^## in_scope/{f=1;next} /^## /{f=0} f && /^- /{c++} END{print c+0}' "$SCOPE")"
READY="$(awk -F': *' '/^[[:space:]]*-[[:space:]]*ready_for_act:/{print $2; exit}' "$SCOPE")"

if [ "$STATUS" != "granted" ]; then
  [ "$QUIET" = 1 ] || echo "DENY: authorization status is '${STATUS:-missing}', expected 'granted'" >&2
  exit 2
fi
if [ "${ASSETS:-0}" -lt 1 ]; then
  [ "$QUIET" = 1 ] || echo "DENY: in_scope has no assets" >&2
  exit 2
fi
[ "$READY" = "true" ] || { [ "$QUIET" = 1 ] || echo "DENY: ready_for_act is '${READY:-missing}'" >&2; exit 2; }

[ "$QUIET" = 1 ] || echo "ALLOW: scope granted for $ASSETS in-scope asset(s)"
exit 0