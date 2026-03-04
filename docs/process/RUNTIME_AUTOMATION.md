# Runtime Automation (Boba Factory)

This document defines the automation layer inspired by high-throughput orchestration patterns.

## Core runtime files (project-scoped)
- `projects/<ProjectName>/.boba/active-tasks.json`
- `projects/<ProjectName>/.boba/proposed-tasks.json`
- `projects/<ProjectName>/.boba/cron.json`
- `projects/<ProjectName>/.boba/logs/cron-monitor.jsonl`

## Implemented components
1. Project initializer (`scripts/new-project.sh`)
2. Monitoring loop (OpenClaw cron)
3. Task registry (`active-tasks.json`)
4. Deterministic checks (`check-agents.sh`, `check-dod.sh`)
5. Retry decision hooks (status-driven)
6. Notification trigger points (`ready_for_review`, `blocked`, `needs_human`)

## DoD gate signals
A task is considered ready only when explicit checks are true in registry:
- `checks.prCreated`
- `checks.ciPassed`
- optional review flags (`checks.codexReviewPassed`, `checks.claudeReviewPassed`, etc.)

## Cron behavior
- Prefer one cron per project.
- Keep cadence low by default (`*/10 * * * *`).
- Cron must post only actionable summaries to avoid noise.
