#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="${1:-}"
if [[ -z "$PROJECT_DIR" ]]; then
  echo '{"status":"error","message":"usage: check-agents.sh <project-dir>"}'
  exit 1
fi

TASKS_FILE="$PROJECT_DIR/.boba/active-tasks.json"
if [[ ! -f "$TASKS_FILE" ]]; then
  echo '{"status":"ok","running":0,"blocked":0,"ready_for_review":0,"stale":0,"note":"no active tasks file"}'
  exit 0
fi

if ! command -v jq >/dev/null 2>&1; then
  echo '{"status":"error","message":"jq is required"}'
  exit 1
fi

running=$(jq '[.tasks[]? | select(.status=="running")] | length' "$TASKS_FILE")
blocked=$(jq '[.tasks[]? | select(.status=="blocked")] | length' "$TASKS_FILE")
ready=$(jq '[.tasks[]? | select(.status=="ready_for_review" or .status=="done")] | length' "$TASKS_FILE")
stale=$(jq '[.tasks[]? | select(.status=="stale" or .status=="timeout")] | length' "$TASKS_FILE")

echo "{\"status\":\"ok\",\"running\":$running,\"blocked\":$blocked,\"ready_for_review\":$ready,\"stale\":$stale}"
