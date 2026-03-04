# Boba Factory — Process Health Status

Last update: 2026-03-04 UTC

## Scope
This file tracks global process health only (no project-specific execution data).

## Health checklist
- Session entrypoint (`BOOT.md`) is present and current.
- Install script is functional and idempotent.
- Project-scoped context+lock convention is active.
- Agent deliverable contract is defined and usable.
- Quality gates (DoR/DoD) are documented.
- Recovery runbook is available.

## Known process risks
- Keep `BOOT.md` as single runtime source to avoid rule duplication.
- Keep project execution reports outside this repository.

## Improvement queue (framework-level)
1. Add non-interactive installer mode for automation.
2. Add process lint checks (owner fields, duplicate rules, docs consistency).
3. Add migration helper for legacy BOOTCLAW imports.
