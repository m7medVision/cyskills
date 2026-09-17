#!/usr/bin/env bash
# Create a project work case with CONTEXT/scope artifacts and an authorization gate.
# Usage: scope-init.sh --case NAME --target TARGET --objective GOAL [--authorized --auth-basis BASIS]
set -euo pipefail

CASE=""; TARGET=""; OBJECTIVE=""; BASIS=""; AUTHORIZED=0; PROFILE="authorized_target_only"
while [ $# -gt 0 ]; do
  case "$1" in
    --case|-c) CASE="${2:-}"; shift 2 ;;
    --target|-t) TARGET="${2:-}"; shift 2 ;;
    --objective|-o) OBJECTIVE="${2:-}"; shift 2 ;;
    --auth-basis) BASIS="${2:-}"; shift 2 ;;
    --network-profile) PROFILE="${2:-}"; shift 2 ;;
    --authorized) AUTHORIZED=1; shift ;;
    -h|--help) sed -n '2,3p' "$0"; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

[ -n "$CASE" ] || { echo "ERROR: --case is required" >&2; exit 1; }
[ -n "$TARGET" ] || { echo "ERROR: --target is required" >&2; exit 1; }
[ -n "$OBJECTIVE" ] || { echo "ERROR: --objective is required" >&2; exit 1; }
case "$CASE" in
  [A-Za-z0-9]* ) : ;;
  *) echo "ERROR: case name must start with a letter or digit" >&2; exit 1 ;;
esac
case "$CASE" in
  *[!A-Za-z0-9._-]*|*..*) echo "ERROR: case name may only contain letters, digits, dot, underscore, hyphen" >&2; exit 1 ;;
esac

CASE_ROOT="$(pwd -P)/work/$CASE"
mkdir -p "$CASE_ROOT/evidence" "$CASE_ROOT/findings"

STATUS="pending"; READY="false"
if [ "$AUTHORIZED" = "1" ]; then
  [ -n "$BASIS" ] || { echo "ERROR: --authorized requires --auth-basis (written authorization reference)" >&2; exit 1; }
  STATUS="granted"; READY="true"
fi

cat > "$CASE_ROOT/scope.md" <<EOF
# Scope: $CASE

## authorization

- status: $STATUS
- basis: ${BASIS:-not provided}
- network_profile: $PROFILE
- ready_for_act: $READY

## target

- primary: $TARGET

## in_scope

- $TARGET

## out_of_scope

- Everything not listed above
EOF

[ -f "$CASE_ROOT/timeline.md" ] || cat > "$CASE_ROOT/timeline.md" <<EOF
# Timeline: $CASE

| time | actor | action | evidence |
|------|-------|--------|----------|
EOF

[ -f "$CASE_ROOT/workitems.md" ] || cat > "$CASE_ROOT/workitems.md" <<EOF
# Work items: $CASE

| id | item | status |
|----|------|--------|
| WI-001 | Establish scope and authorization | $([ "$READY" = true ] && echo done || echo pending) |
| WI-002 | Recon | pending |
| WI-003 | Analysis and validation | pending |
| WI-004 | Report | pending |
EOF

echo "case: $CASE_ROOT"
echo "authorization: $STATUS   ready_for_act: $READY"
echo "objective: $OBJECTIVE"
if [ "$STATUS" != "granted" ]; then
  echo "NEXT: obtain written authorization, then re-run with --authorized --auth-basis <reference>"
else
  echo "NEXT: run scripts/preflight.sh, then verify scope with scripts/scope-guard.sh --case $CASE"
fi