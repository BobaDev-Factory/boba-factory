#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Boba Factory Installer"
APP_VERSION="2.5.0"

REPO_URL_DEFAULT="https://github.com/BobaDev-Factory/boba-factory.git"
TARGET_ROOT_DEFAULT="$HOME/.openclaw/workspace"
TARGET_REPO_DEFAULT="$TARGET_ROOT_DEFAULT/boba-factory"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IN_REPO_MODE=0

# ---------- UI ----------
if [[ -t 1 ]]; then
  C_RESET='\033[0m'
  C_BOLD='\033[1m'
  C_DIM='\033[2m'
  C_BLUE='\033[34m'
  C_CYAN='\033[36m'
  C_GREEN='\033[32m'
  C_YELLOW='\033[33m'
  C_RED='\033[31m'
else
  C_RESET=''; C_BOLD=''; C_DIM=''; C_BLUE=''; C_CYAN=''; C_GREEN=''; C_YELLOW=''; C_RED=''
fi

banner() {
  echo -e "${C_CYAN}${C_BOLD}"
  cat <<'ASCII'
 ____        _            _____          _
| __ )  ___ | |__   __ _ |  ___|_ _  ___| |_ ___  _ __ _   _
|  _ \ / _ \| '_ \ / _` || |_ / _` |/ __| __/ _ \| '__| | | |
| |_) | (_) | |_) | (_| ||  _| (_| | (__| || (_) | |  | |_| |
|____/ \___/|_.__/ \__,_||_|  \__,_|\___|\__\___/|_|   \__, |
                                                        |___/
ASCII
  echo -e "${C_RESET}${C_BOLD}${APP_NAME}${C_RESET} ${C_DIM}v${APP_VERSION}${C_RESET}"
  echo
}

step() { echo -e "${C_BLUE}${C_BOLD}→${C_RESET} ${C_BOLD}$1${C_RESET}"; }
info() { echo -e "${C_DIM}· $1${C_RESET}"; }
ok()   { echo -e "${C_GREEN}●${C_RESET} $1"; }
warn() { echo -e "${C_YELLOW}! $1${C_RESET}"; }
err()  { echo -e "${C_RED}x $1${C_RESET}"; }

ask() {
  local var_name="$1"; shift
  local label="$1"; shift
  local default_value="${1:-}"
  local value
  echo
  if [[ -n "$default_value" ]]; then
    read -r -p "→ ${label} [${default_value}]: " value
    value="${value:-$default_value}"
  else
    read -r -p "→ ${label}: " value
  fi
  printf -v "$var_name" '%s' "$value"
}

ask_yes_no() {
  local var_name="$1"; shift
  local label="$1"; shift
  local default_value="${1:-y}"
  local answer
  local hint="Y/n"
  [[ "$default_value" =~ ^[Nn]$ ]] && hint="y/N"
  echo
  read -r -p "→ ${label} [${hint}]: " answer
  answer="${answer:-$default_value}"
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    printf -v "$var_name" '%s' "y"
  else
    printf -v "$var_name" '%s' "n"
  fi
}

ask_secret() {
  local var_name="$1"; shift
  local label="$1"; shift
  local value
  echo
  echo -e "${C_DIM}  (masked input — no visible characters)${C_RESET}"
  read -r -s -p "→ ${label}: " value
  echo
  printf -v "$var_name" '%s' "$value"
}

print_summary() {
  local config_file="$1"
  local boot_path="$2"
  local agents_file="$3"
  local projects_root="$4"
  local runtime_dir="$5"
  local cron_status="$6"

  echo
  echo -e "${C_GREEN}${C_BOLD}"
  cat <<'ASCII'
  ____                                
 / ___| _   _ _ __ ___  _ __ ___   __ _ _ __ _   _
 \___ \| | | | '_ ` _ \| '_ ` _ \ / _` | '__| | | |
  ___) | |_| | | | | | | | | | | | (_| | |  | |_| |
 |____/ \__,_|_| |_| |_|_| |_| |_|\__,_|_|   \__, |
                                              |___/
ASCII
  echo -e "${C_RESET}"

  echo -e "${C_BOLD}Summary${C_RESET}"
  ok "Installation completed"
  info "Config file:    $config_file"
  info "BOOT updated:   $boot_path"
  info "AGENTS pointer: $agents_file"
  info "Projects root:  $projects_root"
  info "Runtime dir:    $runtime_dir"
  info "OpenClaw cron:  $cron_status"
}

if [[ "${1:-}" == "--in-repo" ]]; then
  IN_REPO_MODE=1
  shift
fi

bootstrap_repo_if_needed() {
  local repo_url="${BOBA_FACTORY_REPO_URL:-$REPO_URL_DEFAULT}"
  local target_root="${BOBA_FACTORY_HOME:-$TARGET_ROOT_DEFAULT}"
  local target_repo="${BOBA_FACTORY_REPO_DIR:-$TARGET_REPO_DEFAULT}"

  mkdir -p "$target_root"

  step "Bootstrap repository"
  if [[ ! -d "$target_repo/.git" ]]; then
    info "Clone target: $target_repo"
    git clone "$repo_url" "$target_repo"
  else
    info "Repository already present: $target_repo"
    info "Updating local copy"
    git -C "$target_repo" pull --ff-only || warn "Pull failed, continuing with local state"
  fi

  info "Re-launching installer from target repository"
  exec "$target_repo/install.sh" --in-repo "$@"
}

# Standalone mode: run from anywhere, normalize to ~/.openclaw/workspace/boba-factory
if [[ "$IN_REPO_MODE" -eq 0 ]]; then
  if [[ ! -f "$SCRIPT_DIR/BOOT.md" || ! -d "$SCRIPT_DIR/templates/workspace" ]]; then
    bootstrap_repo_if_needed "$@"
  fi

  TARGET_REPO="${BOBA_FACTORY_REPO_DIR:-$TARGET_REPO_DEFAULT}"
  if [[ "$SCRIPT_DIR" != "$TARGET_REPO" ]]; then
    bootstrap_repo_if_needed "$@"
  fi
fi

REPO_ROOT="$SCRIPT_DIR"
CONFIG_DIR="$REPO_ROOT/config"
CONFIG_FILE="$CONFIG_DIR/local.env"
TEMPLATES_DIR="$REPO_ROOT/templates/workspace"
mkdir -p "$CONFIG_DIR"

banner
step "Configuration"
info "Fill the fields below. Press Enter to keep defaults."

DEFAULT_WORKSPACE="$HOME/.openclaw/workspace"
ask WORKSPACE_PATH "OpenClaw workspace path" "$DEFAULT_WORKSPACE"
ask BF_OWNER_NAME "Owner display name" "BobaMaster"
ask BF_MAIN_AGENT_NAME "Main agent name" "Boba"
ask JIRA_BASE_URL "Jira base URL (no trailing slash)" "https://bobacloud.atlassian.net"
ask JIRA_PROJECT_KEY "Jira project key" "BDF"
ask GITHUB_ORG "GitHub organization" "BobaDev-Factory"
ask GITHUB_TOKEN_MODE "GitHub token source (gh|env|none)" "gh"
ask JIRA_EMAIL "Jira email/login (optional)" ""
ask PROJECT_NAME "Default project name for runtime setup" "Rynade"
ask CRON_EXPR "OpenClaw cron expression" "*/10 * * * *"
ask_yes_no ENABLE_OPENCLAW_CRON "Create OpenClaw cron monitor job for this project" "y"
ask_secret JIRA_TOKEN "Jira token (optional)"
ask_secret GITHUB_PAT "GitHub PAT (optional)"

echo
step "Applying configuration"
mkdir -p "$WORKSPACE_PATH"
AGENTS_FILE="$WORKSPACE_PATH/AGENTS.md"
BOOT_PATH="$REPO_ROOT/BOOT.md"

cat > "$CONFIG_FILE" <<CFG
# Local config generated by install.sh (gitignored)
BF_OWNER_NAME=$BF_OWNER_NAME
BF_MAIN_AGENT_NAME=$BF_MAIN_AGENT_NAME
JIRA_BASE_URL=$JIRA_BASE_URL
JIRA_PROJECT_KEY=$JIRA_PROJECT_KEY
JIRA_EMAIL=$JIRA_EMAIL
JIRA_TOKEN=$JIRA_TOKEN
GITHUB_PAT=$GITHUB_PAT
GITHUB_ORG=$GITHUB_ORG
GITHUB_TOKEN_MODE=$GITHUB_TOKEN_MODE
WORKSPACE_PATH=$WORKSPACE_PATH
PROJECT_NAME=$PROJECT_NAME
CRON_EXPR=$CRON_EXPR
CFG
chmod 600 "$CONFIG_FILE"

GITIGNORE_FILE="$REPO_ROOT/.gitignore"
touch "$GITIGNORE_FILE"
for line in "config/*" "!config/.gitkeep" "projects/*" "!projects/.gitkeep" "projects/*/.boba/ACTIVE_CONTEXT.json" "projects/*/.boba/LOCK" "projects/*/.boba/active-tasks.json" "projects/*/.boba/proposed-tasks.json" "projects/*/.boba/cron.json"; do
  grep -qxF "$line" "$GITIGNORE_FILE" || echo "$line" >> "$GITIGNORE_FILE"
done
mkdir -p "$REPO_ROOT/projects"
touch "$REPO_ROOT/projects/.gitkeep" "$REPO_ROOT/config/.gitkeep"

PROJECT_DIR="$REPO_ROOT/projects/$PROJECT_NAME"
mkdir -p "$PROJECT_DIR/.boba/specs" "$PROJECT_DIR/.boba/reports" "$PROJECT_DIR/.boba/logs"

ACTIVE_CONTEXT_FILE="$PROJECT_DIR/.boba/ACTIVE_CONTEXT.json"
if [[ ! -f "$ACTIVE_CONTEXT_FILE" ]]; then
  cat > "$ACTIVE_CONTEXT_FILE" <<JSON
{
  "project": "$PROJECT_NAME",
  "repo": "",
  "sprint": "",
  "current_ticket": "",
  "execution_mode": "step_confirm",
  "last_updated_at": "$(date -u +%FT%TZ)"
}
JSON
fi

if [[ ! -f "$PROJECT_DIR/.boba/specs/SPEC_LIGHT.md" ]]; then
  cat > "$PROJECT_DIR/.boba/specs/SPEC_LIGHT.md" <<'MD'
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

[[ -f "$PROJECT_DIR/.boba/active-tasks.json" ]] || echo '{"tasks":[]}' > "$PROJECT_DIR/.boba/active-tasks.json"
[[ -f "$PROJECT_DIR/.boba/proposed-tasks.json" ]] || echo '{"tasks":[]}' > "$PROJECT_DIR/.boba/proposed-tasks.json"

BOOT_BEGIN="<!-- BOBA_FACTORY:GENERATED:START -->"
BOOT_END="<!-- BOBA_FACTORY:GENERATED:END -->"
GENERATED_BOOT=$(cat <<EOB
$BOOT_BEGIN
- Owner: **$BF_OWNER_NAME**
- Main agent: **$BF_MAIN_AGENT_NAME**
- GitHub org: \`$GITHUB_ORG\`
- Jira: \`$JIRA_BASE_URL\` (project \`$JIRA_PROJECT_KEY\`)
$BOOT_END
EOB
)

if grep -q "$BOOT_BEGIN" "$BOOT_PATH"; then
  awk -v start="$BOOT_BEGIN" -v end="$BOOT_END" -v repl="$GENERATED_BOOT" '
    BEGIN{inblk=0}
    $0==start{print repl; inblk=1; next}
    $0==end{inblk=0; next}
    !inblk{print}
  ' "$BOOT_PATH" > "$BOOT_PATH.tmp" && mv "$BOOT_PATH.tmp" "$BOOT_PATH"
else
  printf "\n%s\n" "$GENERATED_BOOT" >> "$BOOT_PATH"
fi

AG_BEGIN="<!-- BOBA_FACTORY:START -->"
AG_END="<!-- BOBA_FACTORY:END -->"
mkdir -p "$(dirname "$AGENTS_FILE")"
touch "$AGENTS_FILE"
POINTER_BLOCK=$(sed "s|{{BOOT_PATH}}|$BOOT_PATH|g" "$TEMPLATES_DIR/AGENTS.block.md")
POINTER_FULL="$AG_BEGIN
$POINTER_BLOCK
$AG_END"

if grep -q "$AG_BEGIN" "$AGENTS_FILE"; then
  awk -v start="$AG_BEGIN" -v end="$AG_END" -v repl="$POINTER_FULL" '
    BEGIN{inblk=0}
    $0==start{print repl; inblk=1; next}
    $0==end{inblk=0; next}
    !inblk{print}
  ' "$AGENTS_FILE" > "$AGENTS_FILE.tmp" && mv "$AGENTS_FILE.tmp" "$AGENTS_FILE"
else
  printf "\n%s\n" "$POINTER_FULL" >> "$AGENTS_FILE"
fi

CRON_SETUP_STATUS="disabled"
CRON_JOB_ID=""
if [[ "$ENABLE_OPENCLAW_CRON" == "y" ]]; then
  if command -v openclaw >/dev/null 2>&1; then
    step "OpenClaw cron setup"
    CRON_NAME="BF monitor - $PROJECT_NAME"
    MONITOR_MSG="Run boba-factory monitor for project $PROJECT_NAME. Report only blocked/ready states."
    set +e
    cron_add_out=$(openclaw cron add --name "$CRON_NAME" --cron "$CRON_EXPR" --session isolated --message "$MONITOR_MSG" --announce 2>&1)
    rc=$?
    set -e
    if [[ $rc -eq 0 ]]; then
      CRON_SETUP_STATUS="enabled"
      CRON_JOB_ID=$(printf '%s' "$cron_add_out" | grep -Eo '[0-9a-fA-F-]{8,}' | head -n1 || true)
      echo "$cron_add_out" > "$PROJECT_DIR/.boba/cron-add.log"
      cat > "$PROJECT_DIR/.boba/cron.json" <<JSON
{"enabled":true,"name":"$CRON_NAME","expr":"$CRON_EXPR","jobId":"$CRON_JOB_ID"}
JSON
      ok "OpenClaw cron job created"
    else
      CRON_SETUP_STATUS="failed"
      warn "OpenClaw cron add failed (see $PROJECT_DIR/.boba/cron-add.log)"
      echo "$cron_add_out" > "$PROJECT_DIR/.boba/cron-add.log"
    fi
  else
    CRON_SETUP_STATUS="missing_openclaw_cli"
    warn "openclaw CLI not found; cron job not created"
  fi
fi

print_summary "$CONFIG_FILE" "$BOOT_PATH" "$AGENTS_FILE" "$REPO_ROOT/projects" "$PROJECT_DIR/.boba" "$CRON_SETUP_STATUS"
