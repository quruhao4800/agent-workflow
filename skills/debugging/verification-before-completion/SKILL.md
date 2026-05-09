---
name: verification-before-completion
description: Use when about to claim work is complete, fixed, or passing, before committing or creating PRs - requires running verification commands and confirming output before making any success claims; evidence before assertions always
---

# Verification Before Completion

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

## Red Flags

- "Should pass now"
- "Looks good" without running commands
- Declaring done while requirement mapping is incomplete
- Delegated agent said success but no independent verification

## Bottom Line

Run commands. Read outputs. Verify requirement closure. Then claim completion.