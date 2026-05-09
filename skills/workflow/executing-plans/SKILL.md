---
name: executing-plans
description: Use when you have a written implementation plan to execute in a separate session with review checkpoints
---

# Executing Plans

## Overview

Load plan artifacts, execute tasks in batches, and stop immediately when requirements drift.

**Announce at start:** "I'm using the executing-plans skill to implement this plan."

## Step 0: Load Project Rules

Read all files matching `rules/**/*.md` and apply them for the entire execution session.

## Step 1: Load And Review Plan Set

Read these files in the same feature folder:

- `01-requirements.md`
- `02-design.md`
- `03-implementation-plan.md`
- `04-verification.md`
- `05-change-log.md`
- `99-mistake-log.md`
- `06-research-notes.md` (if present)

Before coding:

1. Confirm every active task maps to `REQ-###`.
2. Confirm all open `CR-###` and `DR-###` items are represented in tasks.
3. Raise gaps before execution.

## Step 2: Execute Batch

**Default batch size: first 3 pending tasks.**

For each task:

1. Check `Depends on` — all listed tasks must be `completed` before starting. If not, skip and report blocked.
2. Mark task `in_progress`.
3. Follow plan steps exactly based on task type:
   - `code-task`: apply `quruhao-skills:test-driven-development` (write failing test → verify failure → implement → verify pass)
   - `migration-task`: write forward + rollback scripts, verify both
   - `config-task`: verify affected environments, document change
4. Before marking complete, verify every DoD item from `03-implementation-plan.md`:
   - [ ] All tests pass; coverage meets targets
   - [ ] No TODO / debug / temporary code left
   - [ ] Naming follows project rules
   - [ ] Error handling complete
   - [ ] All callers in `Impact` handled
   - [ ] `04-verification.md` evidence updated
   - [ ] Commit message: `type(scope): one-line English summary`
5. Mark task `completed`.

## Unexpected Situation Protocol (MANDATORY)

When something unexpected is encountered during task execution (design assumption wrong, file missing, interface different from spec):

**Decision rule:**

| Situation | Action |
|-----------|--------|
| Affects interface, data model, or other tasks | **STOP.** Report to user. Open `DR-###` in `05-change-log.md`. Do not proceed until user confirms revised design. |
| Affects current task internals only | May adapt. Note in commit message: `adjusted X because Y`. No DR-### needed. |
| Unclear which category applies | **Default to STOP.** Ask the user. |

Never make silent design decisions that affect scope, contracts, or other tasks.

## Plan Drift Gate (MANDATORY)

If a new request, adjustment, or optimization appears during execution:

1. **Stop implementation immediately.**
2. If scope change: add `CR-###` in `05-change-log.md`, update `01-requirements.md`.
   If design change only: add `DR-###` in `05-change-log.md`, update `02-design.md`.
3. Update `03-implementation-plan.md` tasks/statuses.
4. Update impacted checklist items in `04-verification.md`.
6. Resume execution only after 2-5 are complete.

No coding is allowed for unmapped requirements.

## Step 3: Report Batch

After each batch:

- Show completed tasks
- Show verification evidence summary
- List any open `CR-###`
- Say: "Ready for feedback."

## Step 4: Continue

Based on feedback:

- Apply plan updates if needed
- Execute next batch
- Repeat until all required tasks are complete

## Step 5: Completion Gate

Before branch-finishing workflow:

- `unmapped_req = 0`
- `open_cr = 0`
- `pending_recheck = 0`

Then announce and invoke:

- `quruhao-skills:finishing-a-development-branch`

## When To Stop And Ask For Help

Stop and escalate when:

- Plan gaps block execution
- Verification repeatedly fails
- Dependencies/instructions are unclear
- Requirement drift cannot be safely mapped

## Integration

- **REQUIRED:** `quruhao-skills:writing-plans`
- **REQUIRED:** `quruhao-skills:finishing-a-development-branch`