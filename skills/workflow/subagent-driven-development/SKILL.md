---
name: subagent-driven-development
description: Use when executing implementation plans with many tasks or large file impact. Also invoked automatically when executing-plans detects the plan exceeds its threshold (>8 tasks or any task touches >5 files).
---

# Subagent-Driven Development

Execute one planned task at a time with a fresh implementer subagent, then two reviews: spec compliance first, code quality second.

## Core Principle

Fresh subagent per task + strict traceability + two-stage review.

## RESUME Mode (when session was interrupted)

If `03-implementation-plan.md` already has tasks with status other than `pending`, a prior session was interrupted. Do not start from scratch.

1. Read all task statuses.
2. `completed` → skip entirely, do not re-implement.
3. `in_progress` → check whether the implementer produced any code output (look for commits or file changes since the task was marked `in_progress`):
   - **Code exists** → interrupted mid-review. Do not re-implement. Run spec review and quality review on the existing output. If reviews pass, mark `completed`. If reviews fail, dispatch implementer to fix only the flagged issues.
   - **No code exists** → interrupted before implementer finished. Treat as `pending` and dispatch implementer normally.
4. `pending` → enter normal dispatch flow.
5. Announce: `"Resuming plan. Completed: N | In-progress (review-only): M | In-progress (re-dispatch): L | Pending: K."`

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

## Parallel Task Identification (after Preflight)

Before dispatching any implementer, scan the full task list for parallelism opportunities:

1. Find the **ready set**: tasks whose `Depends on` lists are fully `completed`.
2. Within the ready set, group tasks that have **no shared file targets** and **no shared DB table modifications**.
3. Tasks in the same group may be dispatched in parallel — send multiple implementer subagents in a single message.
4. Tasks with shared files or tables must remain sequential even if dependencies are met.

Announce: `"Ready set: [Task A, B, C]. Parallel groups: [[A, C], [B] (sequential — shared file XxxMapper.xml)]."`

**Parallel review:** each parallel implementer completes its own spec review and quality review independently. If one implementer's review fails, the others continue uninterrupted. The failed task returns to `in_progress` for targeted fixes only.

**When not to parallelize:** if you cannot confidently determine the file/table overlap from the plan, default to sequential. Incorrect parallelism with overlapping writes causes merge conflicts and is harder to recover from than sequential slowness.

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

**[USER CHECKPOINT 1]** Present implementer's concise report to user. Wait for explicit confirmation (e.g. "continue", "ok", "确认") before proceeding to review. Do NOT dispatch reviewers until confirmed.

6. Dispatch spec reviewer (`spec-reviewer-prompt.md`).
7. If spec issues exist, implementer fixes and spec review repeats.
8. Dispatch code-quality reviewer (`code-quality-reviewer-prompt.md`).
9. If quality issues exist:

**[USER CHECKPOINT 2]** Present review findings (MUST/SHOULD violations) to user. Wait for explicit confirmation before dispatching implementer to fix. User may choose to skip SHOULD fixes.

   Implementer fixes confirmed issues and quality review repeats.
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

Then invoke `agent-workflow:finishing-a-development-branch`.

## Red Flags

Never:

- Skip either review stage
- Start code quality review before spec compliance passes
- Move to next task with unresolved reviewer issues
- Implement requirement changes without CR + plan updates
- Start work on main/master without explicit user consent

## Integration

- **REQUIRED:** `agent-workflow:writing-plans`
- **REQUIRED:** `agent-workflow:requesting-code-review`
- **REQUIRED:** `agent-workflow:finishing-a-development-branch`
- **Subagents should use:** `agent-workflow:test-driven-development`