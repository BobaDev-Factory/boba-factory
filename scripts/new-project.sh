#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="$REPO_ROOT/config/local.env"

usage() {
  echo "Usage: $0 <ProjectName> [--cron '*/10 * * * *'] [--no-cron] [--jira-board] [--no-jira-board]"
  exit 1
}

[[ $# -lt 1 ]] && usage
PROJECT_NAME="$1"; shift
CRON_EXPR="*/10 * * * *"
ENABLE_CRON="yes"
ENABLE_JIRA_BOARD="yes"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --cron)
      CRON_EXPR="${2:-}"; shift 2 ;;
    --no-cron)
      ENABLE_CRON="no"; shift ;;
    --jira-board)
      ENABLE_JIRA_BOARD="yes"; shift ;;
    --no-jira-board)
      ENABLE_JIRA_BOARD="no"; shift ;;
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
  "jira_board_id": "",
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

JIRA_BOARD_ID=""
if [[ "$ENABLE_JIRA_BOARD" == "yes" ]]; then
  read_env_value() {
    local key="$1"
    local file="$2"
    awk -F'=' -v k="$key" '$1==k { sub($1"=",""); print; exit }' "$file" 2>/dev/null || true
  }

  JIRA_BASE_URL="$(read_env_value "JIRA_BASE_URL" "$CONFIG_FILE")"
  JIRA_EMAIL="$(read_env_value "JIRA_EMAIL" "$CONFIG_FILE")"
  JIRA_TOKEN="$(read_env_value "JIRA_TOKEN" "$CONFIG_FILE")"
  DEFAULT_JIRA_PROJECT_KEY="$(read_env_value "JIRA_PROJECT_KEY" "$CONFIG_FILE")"
  JIRA_PROJECT_KEY="$(printf '%s' "$PROJECT_NAME" | tr -cd '[:alnum:]' | tr '[:lower:]' '[:upper:]' | cut -c1-10)"
  [[ -z "$JIRA_PROJECT_KEY" ]] && JIRA_PROJECT_KEY="$DEFAULT_JIRA_PROJECT_KEY"

  if [[ -z "$JIRA_BASE_URL" || -z "$JIRA_EMAIL" || -z "$JIRA_TOKEN" || -z "$JIRA_PROJECT_KEY" ]]; then
    echo "Jira config missing (JIRA_BASE_URL/JIRA_EMAIL/JIRA_TOKEN). Skipping board creation." >&2
  elif ! command -v curl >/dev/null 2>&1; then
    echo "curl not found, skipping Jira board creation" >&2
  else
    BOARD_NAME="$PROJECT_NAME - Sprint Board"

    project_check=$(curl -sS -u "$JIRA_EMAIL:$JIRA_TOKEN" \
      -H "Accept: application/json" \
      "$JIRA_BASE_URL/rest/api/3/project/$JIRA_PROJECT_KEY" || true)

    project_exists=$(python3 - <<'PY' "$project_check"
import json, sys
try:
    data = json.loads(sys.argv[1])
except Exception:
    print("0")
    raise SystemExit(0)
print("1" if data.get("key") else "0")
PY
)

    if [[ "$project_exists" != "1" ]]; then
      me_resp=$(curl -sS -u "$JIRA_EMAIL:$JIRA_TOKEN" -H "Accept: application/json" "$JIRA_BASE_URL/rest/api/3/myself" || true)
      lead_account_id=$(python3 - <<'PY' "$me_resp"
import json, sys
try:
    data = json.loads(sys.argv[1])
except Exception:
    print("")
    raise SystemExit(0)
print(data.get("accountId", ""))
PY
)

      if [[ -n "$lead_account_id" ]]; then
        CREATE_PROJECT_PAYLOAD=$(cat <<JSON
{
  "key": "$JIRA_PROJECT_KEY",
  "name": "$PROJECT_NAME",
  "projectTypeKey": "software",
  "projectTemplateKey": "com.pyxis.greenhopper.jira:gh-simplified-scrum-classic",
  "leadAccountId": "$lead_account_id"
}
JSON
)
        create_project_resp=$(curl -sS -u "$JIRA_EMAIL:$JIRA_TOKEN" \
          -H "Accept: application/json" \
          -H "Content-Type: application/json" \
          -X POST "$JIRA_BASE_URL/rest/api/3/project" \
          --data "$CREATE_PROJECT_PAYLOAD" || true)
        echo "$create_project_resp" > "$BOBA_DIR/jira-project-create.log"
      fi
    fi
    CREATE_BOARD_PAYLOAD=$(cat <<JSON
{
  "name": "$BOARD_NAME",
  "type": "scrum",
  "location": {
    "type": "project",
    "projectKeyOrId": "$JIRA_PROJECT_KEY"
  }
}
JSON
)

    set +e
    jira_resp=$(curl -sS -u "$JIRA_EMAIL:$JIRA_TOKEN" \
      -H "Accept: application/json" \
      -H "Content-Type: application/json" \
      -X POST "$JIRA_BASE_URL/rest/agile/1.0/board" \
      --data "$CREATE_BOARD_PAYLOAD")
    jira_rc=$?
    set -e

    if [[ $jira_rc -ne 0 ]]; then
      echo "$jira_resp" > "$BOBA_DIR/jira-board-create.log"
      echo "Failed to call Jira API for board creation. See $BOBA_DIR/jira-board-create.log" >&2
    else
      JIRA_BOARD_ID=$(python3 - <<'PY' "$jira_resp"
import json, sys
try:
    data = json.loads(sys.argv[1])
except Exception:
    print("")
    raise SystemExit(0)
board_id = data.get("id")
print(str(board_id) if board_id is not None else "")
PY
)

      if [[ -z "$JIRA_BOARD_ID" ]]; then
        FILTER_NAME="$PROJECT_NAME - Sprint Filter"
        FILTER_JQL="project = $JIRA_PROJECT_KEY ORDER BY Rank ASC"
        CREATE_FILTER_PAYLOAD=$(cat <<JSON
{
  "name": "$FILTER_NAME",
  "jql": "$FILTER_JQL",
  "description": "Auto-created by Boba Factory new-project.sh"
}
JSON
)

        set +e
        filter_resp=$(curl -sS -u "$JIRA_EMAIL:$JIRA_TOKEN" \
          -H "Accept: application/json" \
          -H "Content-Type: application/json" \
          -X POST "$JIRA_BASE_URL/rest/api/3/filter" \
          --data "$CREATE_FILTER_PAYLOAD")
        filter_rc=$?
        set -e

        if [[ $filter_rc -eq 0 ]]; then
          FILTER_ID=$(python3 - <<'PY' "$filter_resp"
import json, sys
try:
    data = json.loads(sys.argv[1])
except Exception:
    print("")
    raise SystemExit(0)
fid = data.get("id")
print(str(fid) if fid is not None else "")
PY
)

          if [[ -n "$FILTER_ID" ]]; then
            CREATE_BOARD_FROM_FILTER_PAYLOAD=$(cat <<JSON
{
  "name": "$BOARD_NAME",
  "type": "scrum",
  "filterId": "$FILTER_ID",
  "location": {
    "type": "project",
    "projectKeyOrId": "$JIRA_PROJECT_KEY"
  }
}
JSON
)

            set +e
            jira_resp_retry=$(curl -sS -u "$JIRA_EMAIL:$JIRA_TOKEN" \
              -H "Accept: application/json" \
              -H "Content-Type: application/json" \
              -X POST "$JIRA_BASE_URL/rest/agile/1.0/board" \
              --data "$CREATE_BOARD_FROM_FILTER_PAYLOAD")
            jira_retry_rc=$?
            set -e

            if [[ $jira_retry_rc -eq 0 ]]; then
              JIRA_BOARD_ID=$(python3 - <<'PY' "$jira_resp_retry"
import json, sys
try:
    data = json.loads(sys.argv[1])
except Exception:
    print("")
    raise SystemExit(0)
board_id = data.get("id")
print(str(board_id) if board_id is not None else "")
PY
)
            fi
          fi
        fi
      fi

      if [[ -n "$JIRA_BOARD_ID" ]]; then
        cat > "$BOBA_DIR/jira.json" <<JSON
{
  "enabled": true,
  "boardName": "$BOARD_NAME",
  "boardId": "$JIRA_BOARD_ID",
  "projectKey": "$JIRA_PROJECT_KEY",
  "createdAt": "$NOW"
}
JSON
      else
        {
          echo "Board create response:"
          echo "$jira_resp"
          [[ -n "${filter_resp:-}" ]] && { echo ""; echo "Filter create response:"; echo "$filter_resp"; }
          [[ -n "${jira_resp_retry:-}" ]] && { echo ""; echo "Board retry response:"; echo "$jira_resp_retry"; }
        } > "$BOBA_DIR/jira-board-create.log"
        echo "Jira board was not created. See $BOBA_DIR/jira-board-create.log" >&2
      fi
    fi
  fi
fi

if [[ -n "$JIRA_BOARD_ID" ]]; then
  python3 - <<'PY' "$BOBA_DIR/ACTIVE_CONTEXT.json" "$JIRA_BOARD_ID" "$NOW"
import json, sys
path, board_id, now = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path, "r", encoding="utf-8") as f:
    data = json.load(f)
data["jira_board_id"] = board_id
data["last_updated_at"] = now
with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
    f.write("\n")
PY
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
[[ -f "$BOBA_DIR/jira.json" ]] && echo "Jira board: enabled (id=$JIRA_BOARD_ID)" || echo "Jira board: disabled"
[[ -f "$BOBA_DIR/cron.json" ]] && echo "Cron: enabled ($CRON_EXPR)" || echo "Cron: disabled"
