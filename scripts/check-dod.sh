#!/usr/bin/env bash
set -euo pipefail

# Lightweight deterministic DoD checker from task registry.
PROJECT_DIR="${1:-}"
if [[ -z "$PROJECT_DIR" ]]; then
  echo '{"status":"error","message":"usage: check-dod.sh <project-dir>"}'
  exit 1
fi
TASKS_FILE="$PROJECT_DIR/.boba/active-tasks.json"
if [[ ! -f "$TASKS_FILE" ]]; then
  echo '{"status":"ok","ready_to_merge":false,"reason":"no tasks"}'
  exit 0
fi
if ! command -v jq >/dev/null 2>&1; then
  echo '{"status":"error","message":"jq is required"}'
  exit 1
fi

ready=$(jq '[.tasks[]? | select(.status=="ready_for_review") | select((.checks.ciPassed//false)==true)] | length' "$TASKS_FILE")
blocked=$(jq '[.tasks[]? | select(.status=="blocked")] | length' "$TASKS_FILE")

if [[ "$blocked" -gt 0 ]]; then
  echo '{"status":"ok","ready_to_merge":false,"reason":"blocked tasks exist"}'
  exit 0
fi

if [[ "$ready" -gt 0 ]]; then
  echo '{"status":"ok","ready_to_merge":true,"reason":"at least one task ready_for_review with ciPassed"}'
else
  echo '{"status":"ok","ready_to_merge":false,"reason":"no task passes ready gate"}'
fi
