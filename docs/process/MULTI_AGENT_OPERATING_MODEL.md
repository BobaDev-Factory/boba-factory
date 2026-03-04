# Multi-Agent Operating Model (Boba Factory)

## Purpose
Define the default orchestration model used by the main agent across projects.

## Default pipeline
Spec → Code → Review → Browser/E2E Test → Test (lint/unit/typecheck) → Doc → Orchestrator decision

## Core rules
1. One agent = one mission + expected output.
2. Sub-agents never merge directly.
3. Orchestrator is the only integration authority.
4. Stage failure (`fail`/`blocked`) stops pipeline until remediation decision.
5. Jira transitions are mandatory during execution.
6. Ticket/sprint closure requires explicit human approval.

## Execution modes
- `step_confirm` (default)
- `sprint_autorun`

Mode is stored in project `ACTIVE_CONTEXT` and can be changed explicitly by the owner.

## Browser test policy
UI-impacting work must include browser-level validation (manual or automated) in addition to API/unit checks.

## Specs policy linkage
- Project specs are not stored in Boba Factory.
- Startup must load selected project `SPEC_LIGHT.md`.
- Full specs remain in project repositories and are loaded on-demand.
- Reference: `docs/process/SPECS_POLICY.md`.
