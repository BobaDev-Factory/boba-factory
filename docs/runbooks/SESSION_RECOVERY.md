# Session Recovery Runbook

Use this runbook when session startup or context restoration fails.

## Recovery steps
1. Confirm selected project exists under `projects/<ProjectName>/`.
2. Validate presence/format of `.boba/ACTIVE_CONTEXT.json`.
3. Check lock file state and detect stale lock.
4. Verify `config/local.env` credentials for Jira/GitHub.
5. Re-run S1→S8 readiness sequence.
6. If critical step still fails, stop and request explicit owner decision.

## Stale lock handling
- Never force-override silently.
- Ask owner confirmation before replacing lock.
- Log reason and timestamp in the project report repo (not in boba-factory).
