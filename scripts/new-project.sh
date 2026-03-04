#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="$REPO_ROOT/config/local.env"

usage() {
  echo "Usage: $0 <ProjectName> [--cron '*/10 * * * *'] [--no-cron]"
  exit 1
}

[[ $# -lt 1 ]] && usage
PROJECT_NAME="$1"; shift
CRON_EXPR="*/10 * * * *"
ENABLE_CRON="yes"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --cron)
      CRON_EXPR="${2:-}"; shift 2 ;;
    --no-cron)
      ENABLE_CRON="no"; shift ;;
    *)
      echo "Unknown arg: $1"; usage ;;
  esac
done

PROJECT_DIR="$REPO_ROOT/projects/$PROJECT_NAME"
BOBA_DIR="$PROJECT_DIR/.boba"
mkdir -p "$BOBA_DIR/specs" "$BOBA_DIR/reports" "$BOBA_DIR/logs"

NOW="$(date -u +%FT%TZ)"
cat > "$BOBA_DIR/ACTIVE_CONTEXT.json" <<JSON
{
  "project": "$PROJECT_NAME",
  "repo": "",
  "sprint": "",
  "current_ticket": "",
  "execution_mode": "step_confirm",
  "last_updated_at": "$NOW"
}
JSON

[[ -f "$BOBA_DIR/active-tasks.json" ]] || echo '{"tasks":[]}' > "$BOBA_DIR/active-tasks.json"
[[ -f "$BOBA_DIR/proposed-tasks.json" ]] || echo '{"tasks":[]}' > "$BOBA_DIR/proposed-tasks.json"

if [[ ! -f "$BOBA_DIR/specs/SPEC_LIGHT.md" ]]; then
cat > "$BOBA_DIR/specs/SPEC_LIGHT.md" <<'MD'
# SPEC_LIGHT

## Current objective
-

## Active scope
-

## Acceptance criteria (summary)
-

## Open decisions
-
MD
fi

if [[ "$ENABLE_CRON" == "yes" ]]; then
  if ! command -v openclaw >/dev/null 2>&1; then
    echo "openclaw CLI not found, cannot create cron job" >&2
    exit 2
  fi

  CRON_NAME="BF monitor - $PROJECT_NAME"
  MONITOR_MSG="Run boba-factory monitor for project $PROJECT_NAME. Report only blocked/ready states."

  set +e
  out=$(openclaw cron add --name "$CRON_NAME" --cron "$CRON_EXPR" --session isolated --message "$MONITOR_MSG" --announce 2>&1)
  rc=$?
  set -e

  if [[ $rc -ne 0 ]]; then
    echo "$out" > "$BOBA_DIR/cron-add.log"
    echo "Failed to create cron job. See $BOBA_DIR/cron-add.log" >&2
    exit 3
  fi

  job_id=$(printf '%s' "$out" | grep -Eo '[0-9a-fA-F-]{8,}' | head -n1 || true)
  cat > "$BOBA_DIR/cron.json" <<JSON
{
  "enabled": true,
  "name": "$CRON_NAME",
  "expr": "$CRON_EXPR",
  "jobId": "$job_id",
  "createdAt": "$NOW"
}
JSON
fi

echo "Project initialized: $PROJECT_NAME"
echo "Path: $PROJECT_DIR"
[[ -f "$BOBA_DIR/cron.json" ]] && echo "Cron: enabled ($CRON_EXPR)" || echo "Cron: disabled"
