# Specs Policy (Boba Factory)

## Rule 1 — Project specs do not belong in Boba Factory
Boba Factory stores framework/process only.
All project specs must live in project repositories.

## Rule 2 — Required spec split per project
Each project must maintain two levels of specifications:

1. **Light spec** (session-recovery scope)
   - Path (recommended): `projects/<ProjectName>/.boba/specs/SPEC_LIGHT.md`
   - Purpose: concise current scope, active decisions, acceptance criteria summary.
   - Size target: 100–200 lines max.

2. **Full specs** (delivery scope)
   - Path: inside project repositories (for example `docs/specs/*`).
   - Purpose: complete product/technical details.

## Rule 3 — Session startup behavior
At startup, main agent reads **SPEC_LIGHT.md** for selected project.
Full specs are loaded on-demand based on active ticket/stage.

## Rule 4 — Ownership
- Atlas owns initial spec drafting and updates.
- Main orchestrator enforces that `SPEC_LIGHT.md` stays aligned with current sprint/tickets.
- Any major scope decision must be reflected in both light and full specs.

## Rule 5 — Anti-regression
No project-specific spec file should be committed in `boba-factory/docs/specs/`.
