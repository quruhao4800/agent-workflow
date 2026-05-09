---
name: subagent-driven-development
description: Use when executing implementation plans with independent tasks in the current session
---

# Subagent-Driven Development

Execute one planned task at a time with a fresh implementer subagent, then two reviews: spec compliance first, code quality second.

## Core Principle

Fresh subagent per task + strict traceability + two-stage review.

## Preflight (MANDATORY)

**Step 0:** Load project rules: read all files matching `rules/**/*.md`. Apply them for the entire session.

Load artifacts from one feature folder before dispatching any subagent:

- `01-requirements.md`
- `02-design.md`
- `03-implementation-plan.md`
- `04-verification.md`
- `05-change-log.md`
- `99-mistake-log.md`
- `06-research-notes.md` (if present)

Build a task list from `03-implementation-plan.md` and include `REQ-###`/`CR-###`/`DR-###` mapping per task.

## Per-Task Flow

1. Check `Depends on` — all listed tasks must be `completed` before dispatching. If not, skip and report blocked.
2. Dispatch implementer subagent using `implementer-prompt.md`.
3. If questions are raised, answer before implementation.
4. Implementer runs tests and reports outputs.
5. Implementer verifies every DoD item from `03-implementation-plan.md` before handing off:
   - [ ] All tests pass; coverage meets targets
   - [ ] No TODO / debug / temporary code left
   - [ ] Naming follows project rules
   - [ ] Error handling complete
   - [ ] All callers in `Impact` handled
   - [ ] Commit message: `type(scope): one-line English summary`
6. Dispatch spec reviewer (`spec-reviewer-prompt.md`).
7. If spec issues exist, implementer fixes and spec review repeats.
8. Dispatch code-quality reviewer (`code-quality-reviewer-prompt.md`).
9. If quality issues exist, implementer fixes and quality review repeats.
10. Update `04-verification.md` evidence for task REQ/CR/DR mapping.
11. Mark task complete.

## Plan Drift Gate (MANDATORY)

If a new requirement or optimization appears mid-run:

1. Stop dispatching implementers.
2. If scope change: add `CR-###` in `05-change-log.md`, update `01-requirements.md`.
   If design change only: add `DR-###` in `05-change-log.md`, update `02-design.md`.
3. Update `03-implementation-plan.md` tasks/status (`pending/in_progress/completed/superseded/cancelled`).
4. Update impacted verification entries in `04-verification.md`.
6. Re-extract tasks, then resume dispatch.

No task implementation is allowed for unmapped requests.

## Completion Gate

Before final reviewer and branch-finishing:

- `unmapped_req = 0`
- `open_cr = 0`
- `pending_recheck = 0`

Then invoke `quruhao-skills:finishing-a-development-branch`.

## Red Flags

Never:

- Skip either review stage
- Start code quality review before spec compliance passes
- Move to next task with unresolved reviewer issues
- Implement requirement changes without CR + plan updates
- Start work on main/master without explicit user consent

## Integration

- **REQUIRED:** `quruhao-skills:writing-plans`
- **REQUIRED:** `quruhao-skills:requesting-code-review`
- **REQUIRED:** `quruhao-skills:finishing-a-development-branch`
- **Subagents should use:** `quruhao-skills:test-driven-development`