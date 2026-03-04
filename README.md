# Boba Factory

Boba Factory is a **multi-agent delivery framework** for OpenClaw.

Mission: industrialize software delivery (spec, code, review, testing, docs, CI/CD, runbooks, rollback) with strict orchestration discipline.

---

## What it is (and what it is not)

### ✅ Boba Factory
- A process framework for orchestrating a main agent + subagents
- A single session entrypoint (`BOOT.md`)
- Recovery, locking, active context, quality gates, and Jira/GitHub governance
- A multi-project structure (`projects/<ProjectName>/...`)

### ❌ Boba Factory
- Not a business application repo
- Not a place to store project-specific specs/tickets/reports

> Project data should stay in each project’s own repositories.

---

## Requirements

- OpenClaw installed and running
- Git installed
- Network access to GitHub + Jira
- A GitHub account (PAT recommended)
- A Jira account (email + API token)

Optional but recommended:
- `gh` (GitHub CLI)

---

## Installation

### Quick install (one-liner)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/BobaDev-Factory/boba-factory/main/install.sh)
```

The installer will:
1. clone/update `boba-factory` into `~/.openclaw/workspace/boba-factory`
2. ask for setup values
3. generate `config/local.env` (local only, gitignored)
4. inject runtime metadata at the top of `BOOT.md`
5. inject a Boba Factory pointer block into `~/.openclaw/workspace/AGENTS.md`
6. initialize baseline git protections (`.gitignore`, hooks when configured)

---

## Activation in an OpenClaw session

In a new session, explicitly say:

> `Read /home/<user>/.openclaw/workspace/boba-factory/BOOT.md and apply it strictly.`

Then the boot process handles:
- project selection
- `ACTIVE_CONTEXT` load/init
- project lock handling
- connectivity checks
- readiness summary

---

## Recommended structure

```txt
~/.openclaw/workspace/
  boba-factory/
    BOOT.md
    install.sh
    config/
      local.env          # local only (gitignored)
    projects/
      .gitkeep
      <ProjectName>/
        .boba/
          ACTIVE_CONTEXT.json
          LOCK
          reports/
```

- `projects/` is tracked as a folder, but its content is ignored
- `ACTIVE_CONTEXT` and `LOCK` are **project-scoped**

---

## Required access (Jira / GitHub)

The installer stores these values in `config/local.env`:

- `JIRA_BASE_URL`
- `JIRA_PROJECT_KEY`
- `JIRA_EMAIL`
- `JIRA_TOKEN`
- `GITHUB_ORG`
- `GITHUB_PAT`
- `GITHUB_TOKEN_MODE`

> `config/local.env` is gitignored and must never be committed.

### How to get credentials

#### Jira API token
1. Go to: [https://id.atlassian.com/manage-profile/security/api-tokens](https://id.atlassian.com/manage-profile/security/api-tokens)
2. Create an API token
3. Use:
   - `JIRA_EMAIL` = Atlassian account email
   - `JIRA_TOKEN` = generated token

#### GitHub PAT
1. Go to GitHub → Settings → Developer settings → Personal access tokens
2. Create a token (fine-grained or classic)
3. Typical minimum scopes:
   - repo read/write
   - pull requests/issues (depending on workflow)
4. Set it in `GITHUB_PAT`

---

## Security

- Never commit `config/local.env`
- A pre-commit hook is included to block:
  - `config/local.env`
  - common token/secret patterns

Quick checks:

```bash
cd ~/.openclaw/workspace/boba-factory
git status --short
git ls-files config
```

At most, `config/.gitkeep` should be tracked.

---

## Recommended workflow (short)

1. Start session + load `BOOT.md`
2. Select the target project in `projects/`
3. Load context + acquire project lock
4. Run pipeline:
   - Spec → Code → Review → Browser/E2E Test → Test → Doc → orchestrator decision
5. Update **project** reports (not framework reports)
6. Release lock at session end

---

## Quick troubleshooting

### One-liner install fails
- Check internet connectivity
- Check repository visibility/access

### Jira/GitHub checks fail at startup
- Validate `config/local.env`
- Check token expiration/revocation
- Verify Jira URL/key and GitHub org values

### Lock appears stale
- Inspect `projects/<ProjectName>/.boba/LOCK`
- Follow `docs/runbooks/SESSION_RECOVERY.md`

---

## Principles

Boba Factory prioritizes:
- execution clarity,
- explicit responsibility per agent,
- evidence before claims,
- lower token/noise costs,
- strict separation between framework data and project data.
