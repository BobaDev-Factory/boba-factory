#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_NAME="${1:-}"
if [[ -z "$PROJECT_NAME" ]]; then
  echo "Usage: cron-monitor.sh <ProjectName>" >&2
  exit 1
fi
PROJECT_DIR="$REPO_ROOT/projects/$PROJECT_NAME"
if [[ ! -d "$PROJECT_DIR" ]]; then
  echo "Project not found: $PROJECT_DIR" >&2
  exit 1
fi

mkdir -p "$PROJECT_DIR/.boba/logs"
stamp="$(date -u +%FT%TZ)"
agent_json="$($REPO_ROOT/scripts/check-agents.sh "$PROJECT_DIR")"
dod_json="$($REPO_ROOT/scripts/check-dod.sh "$PROJECT_DIR")"

printf '{"timestamp":"%s","project":"%s","agents":%s,"dod":%s}\n' "$stamp" "$PROJECT_NAME" "$agent_json" "$dod_json" >> "$PROJECT_DIR/.boba/logs/cron-monitor.jsonl"

echo "[$stamp] project=$PROJECT_NAME agents=$agent_json dod=$dod_json"
