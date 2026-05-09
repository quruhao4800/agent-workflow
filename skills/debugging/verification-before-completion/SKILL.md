---
name: verification-before-completion
description: Use when about to claim work is complete, fixed, or passing, before committing or creating PRs - requires running verification commands and confirming output before making any success claims; evidence before assertions always
---

# Verification Before Completion

## Prerequisites

| From skill | Must already exist | If missing |
|------------|--------------------|------------|
| `executing-plans` | All tasks in `03-implementation-plan.md` marked `completed` | Return to `executing-plans` — verification cannot start with open tasks |
| `executing-plans` | `04-verification.md` updated with evidence for each completed task | Return to `executing-plans` to fill evidence before running gates here |

## Overview

Claims require evidence. No completion claim is valid without fresh verification outputs.

## The Iron Law

`NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE`

## Command Evidence Gate

Before any success/completion statement:

1. Identify command(s) that prove the claim.
2. Run full command(s) now.
3. Read full output and exit code.
4. State result with evidence only.

## Mistake Recurrence Gate

Review:

- `docs/plans/YYYY-MM-DD-<feature-name>/99-mistake-log.md`
- `docs/memory/global-mistakes.md`

## Research Recheck Gate

If `06-research-notes.md` exists:

If known mistakes repeated without prevention checks, stop and fix process first.

1. Recheck all entries marked `Recheck Needed`.
2. Record recheck result in `04-verification.md`.

Completion claims are invalid while required rechecks are pending.

## Requirement Closure Gate (MANDATORY)

Before completion claim, verify from plan artifacts:

- `unmapped_req = 0` (all active `REQ-###` mapped to plan tasks and verification items)
- `open_cr = 0` (all `CR-###` closed or explicitly deferred with approval)
- `open_dr = 0` (all `DR-###` closed or explicitly deferred with approval)
- `pending_recheck = 0` (research rechecks done)

Record these values in `04-verification.md`.

## Coverage Gate

Run coverage report and confirm thresholds are met:

| Layer | Minimum |
|-------|---------|
| Service (business logic) | 85% |
| Controller | 80% |
| Overall project | 80% |

Commands:
- Java: `./gradlew test jacocoTestReport` → check `build/reports/jacoco/`

If coverage is below threshold, add missing tests before claiming completion.

## Minimum Checklist

- Tests/build/lint evidence attached
- Coverage thresholds met (evidence from report)
- Requirement checklist verified line-by-line
- `04-verification.md` updated
- No open blocking mistakes in `99-mistake-log.md`
- No open `CR-###` or `DR-###` in `05-change-log.md`

## Evidence Templates by Task Type

Before completing the Minimum Checklist, confirm the evidence matches the task type:

### code-task
- Test run stdout: all tests passed (`BUILD SUCCESSFUL`, `Tests run: N, Failures: 0, Errors: 0`)
- JaCoCo coverage summary: Service ≥ 85%, Controller ≥ 80%, Overall ≥ 80%
  - Command: `./gradlew test jacocoTestReport`
  - Report: `build/reports/jacoco/test/html/index.html`
- If the task adds or modifies an API endpoint: include an actual HTTP request + response (status code + body)

### migration-task
- Flyway run log: `Successfully applied N migration(s) to schema`
- Schema state after migration: output of `DESCRIBE <table>` or `SHOW CREATE TABLE <table>` showing expected columns and indexes
- Rollback test: run rollback migration and confirm schema returns to pre-migration state (show output)

### config-task
- Application startup log showing configuration loaded without errors
- Functional smoke test output confirming the affected behavior works
- If multi-environment: list which environments the change has been applied to

### api-endpoint (supplement to code-task)
Provide all three:
```
# Success path
Request:  POST /api/xxx
Body:     {"field": "value"}
Response: HTTP 200 {"code": 0, "data": {...}}

# Error path
Request:  POST /api/xxx
Body:     {"field": ""}
Response: HTTP 400 {"code": "INVALID_PARAM", "message": "..."}

# Auth rejection (if endpoint is protected)
Request:  POST /api/xxx (no token)
Response: HTTP 401
```

"It should work" or "tests cover this" is not evidence. Paste actual output.

## Red Flags

- "Should pass now"
- "Looks good" without running commands
- Declaring done while requirement mapping is incomplete
- Delegated agent said success but no independent verification

## Bottom Line

Run commands. Read outputs. Verify requirement closure. Then claim completion.