---
name: executing-plans
description: Use when you have a written implementation plan to execute in a separate session with review checkpoints
---

# Executing Plans

## Prerequisites

| From skill | Must already exist | If missing |
|------------|--------------------|------------|
| `writing-plans` | `02-design.md` with `Status: Approved` | Return to `writing-plans` Phase 1 — do not implement against unapproved design |
| `writing-plans` | `03-implementation-plan.md` with at least one `pending` task | Return to `writing-plans` Phase 2 |
| `writing-plans` | `04-verification.md` skeleton initialized | Initialize it now using the template in `writing-plans` |
| `writing-plans` | `99-mistake-log.md` | Initialize as empty file if absent |

## Execution Mode Selection (MANDATORY — before anything else)

Read `03-implementation-plan.md`. Count tasks by status and estimate per-task file impact from the `Files` / `Impact` field.

| Condition | Decision |
|-----------|----------|
| Pending tasks ≤ 8 **AND** every task touches ≤ 5 files | ✅ Continue with `executing-plans` (this skill) |
| Pending tasks > 8 **OR** any task touches > 5 files | 🔄 Switch to `quruhao-skills:subagent-driven-development` |

Announce: `"Mode: executing-plans — N pending tasks, max M files per task."` or `"Switching to subagent-driven-development — reason: [N tasks / task X touches M files]."`

**Why this matters:** `executing-plans` runs entirely in the main context. As tasks accumulate, context grows and output quality drops. `subagent-driven-development` gives each task a fresh context, preventing contamination across tasks. For small plans (≤8 tasks), `executing-plans` avoids the per-subagent token overhead of cold-starting multiple agents.

## Overview

Load plan artifacts, execute tasks in batches, and stop immediately when requirements drift.

**Announce at start:** "I'm using the executing-plans skill to implement this plan."

## Step 0: Load Project Rules

1. Search for rules files in this order:
   - `rules/**/*.md`
   - `.claude/rules/**/*.md`
   - `docs/rules/**/*.md`
   - `CLAUDE.md`, `AGENTS.md` (project root)

2. Read all found files.

3. Extract two separate checklists from the loaded content:
   - `MUST_CHECK`: rules under `## Mandatory` sections — objective, verifiable, block task completion if violated
   - `SHOULD_CHECK`: rules under `## Recommended` sections — flag in report but do not block completion
   - `SKIP`: principles without a clear pass/fail test (e.g., "prefer clarity", "keep it simple")

4. Enforcement:
   - `MUST_CHECK` violation → task **cannot** be marked `completed`; fix before proceeding
   - `SHOULD_CHECK` violation → record in batch report as flagged item; task may still complete

5. Output a compact summary:
   > "Loaded N rules files. Extracted X MUST_CHECK items, Y SHOULD_CHECK items."

   If no rules files are found: note it and continue without a checklist.

This checklist is used in every task DoD and the Post-Batch Rules Sweep.

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
   - [ ] Commit message: `type(scope): one-line summary`
   - [ ] Rules compliance: check changed files against AUTO_CHECK items from Step 0 checklist; fix violations before marking complete
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

## Post-Batch Rules Sweep (MANDATORY before Step 3)

After all tasks in the batch are complete, scan every file changed in this batch against the AUTO_CHECK checklist from Step 0.

**Decision table per violation:**

| Violation type | Action |
|----------------|--------|
| Objective, no ambiguity (wrong naming, missing annotation, forbidden import) | AUTO_FIX: fix immediately, note in report |
| Requires judgment (unclear which rule applies, trade-off involved) | NEEDS_DECISION: collect and present to user as a numbered list |

Do not ask the user about AUTO_FIX items individually — fix them silently and list what was fixed in the batch report.

If the Step 0 checklist is empty (no rules files found), skip this sweep.

## Step 3: Report Batch

After each batch:

- Show completed tasks
- Show verification evidence summary
- List AUTO_FIX rules corrections applied (if any)
- List NEEDS_DECISION rules findings as a numbered batch (if any) — wait for user response before next batch
- List any open `CR-###`
- **Re-state the AUTO_CHECK checklist** (compact form) so rules stay in context near-top for the next batch
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