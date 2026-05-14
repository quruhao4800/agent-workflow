---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code
---

# Writing Plans

## Prerequisites

| From skill | Must already exist | If missing |
|------------|--------------------|------------|
| `brainstorming` | `docs/plans/YYYY-MM-DD-<feature>/01-requirements.md` with `Status: Approved` | Return to `brainstorming` — do not start planning without approved requirements |
| `brainstorming` | `05-change-log.md` if any CR was raised during brainstorming | Initialize it here if absent |

## Overview

Write implementation plans that are executable, traceable, and safe for mid-flight requirement changes.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

## Modes

Use one of these modes explicitly:

1. **Initial mode** - no existing plan artifacts for this feature
2. **Revision mode** - feature already has plan files and requirements or design changed

## Three-Phase Flow (Initial Mode)

<HARD-GATE>
Each phase requires explicit user approval before the next begins.
Do NOT start Phase 1 until Design Charter is confirmed.
Do NOT produce `03-implementation-plan.md` until `02-design.md` is approved.
</HARD-GATE>

### Phase 0 — Holistic Thinking & Design Charter

1. Read `01-requirements.md` and load project rules (`rules/**/*.md`).
2. Apply the relevant language skill based on tech stack.
3. **Perform holistic thinking** across all dimensions (see Holistic Thinking Framework section).
4. Produce Design Charter draft with three lists:
   - **Decisions Manifest**: specific questions requiring explicit design — executing agent cannot correctly decide alone
   - **Agent-Handled List**: what executing agent handles independently per project conventions
   - **Explicitly Excluded**: items considered during holistic thinking but confirmed out of scope
5. Present Charter to user and state:
   > "Phase 0 complete. Here is the Design Charter. Please confirm the decisions boundary before I begin designing."
6. **Wait for explicit confirmation before continuing.**
7. Charter is now frozen. Any new decision point discovered in Phases 1–2 requires `DR [charter-amendment]` before it can be added.

### Phase 1 — Technical Design (within charter)

1. Answer each decision in the Design Charter's Decisions Manifest — in `02-design.md`.
2. Stop when all decisions are answered. Do NOT add content beyond the charter.
3. **Run Design Completeness Gate** — verify every charter decision has a clear, unambiguous answer.
4. Output proactive completion declaration (see Design Completeness Gate section).
5. Present the design to the user and state:
   > "Phase 1 complete. Please review `02-design.md`. Confirm to proceed to implementation planning."
6. **Wait for explicit confirmation before continuing.**

### Phase 2 — Implementation Planning (after design approved)

1. Produce `03-implementation-plan.md` with tasks derived from approved design.
2. Initialize `04-verification.md` skeleton using the template below.
3. Initialize `05-change-log.md` and `99-mistake-log.md` if not present.
4. Offer execution handoff.

## Holistic Thinking Framework (Phase 0)

Before proposing any design, think across ALL dimensions simultaneously. This is a single upfront scan — not incremental discovery. Every dimension must be considered before the charter is presented.

### Dimensions to Scan

| Dimension | Questions to answer |
|-----------|-------------------|
| Functional path | What are the core responsibilities? What does success look like end-to-end? |
| Failure modes | What can go wrong at each step? What is the recovery strategy? |
| Data concerns | Consistency requirements? Idempotency? Data integrity constraints? |
| System interactions | Who calls this? What does it call? What are upstream/downstream SLAs? |
| Non-functional concerns | Concurrency? Retry logic? Compensation? Performance targets? |
| Boundary conditions | Edge cases? Extreme inputs? Partial failures? |

### Decision Classification Rule

For each concern surfaced by the scan:

- **Needs explicit design** → multiple valid approaches exist, executing agent cannot correctly choose alone → add to Decisions Manifest
- **Executing agent handles** → single correct approach per project conventions, no architectural choice involved → add to Agent-Handled List

When in doubt, add to Decisions Manifest and let the user confirm whether it needs explicit design.

### Cross-REQ Pass (MANDATORY)

After scanning per-REQ, do one cross-REQ pass for shared concerns:
- Transaction boundaries spanning multiple REQs
- Shared error handling strategy
- Concurrency or idempotency across operations
- Consistent state management across the feature

Add any cross-REQ decisions to the Decisions Manifest.

### Red Flags — STOP if you are doing this

| Thought | Reality |
|---------|---------|
| "I'll add this to the design if it comes up" | Front-load all thinking now. Discovering decisions in Phase 1 means Phase 0 was incomplete. |
| "This is probably obvious" | If multiple valid approaches exist, it is not obvious. Add it to the manifest. |
| "The user didn't mention compensation / retry / etc." | User states WHAT. Holistic thinking surfaces HOW concerns. Surface them, let user decide scope. |

## Folder-First Rule (MANDATORY)

Create or reuse one feature folder:

`docs/plans/YYYY-MM-DD-<feature-name>/`

Required artifacts in that folder:

- `01-requirements.md` (produced by brainstorming — read, do not overwrite)
- `02-design.md` (produced here — technical design: HOW)
- `03-implementation-plan.md` (produced here — executable tasks)
- `04-verification.md` (produced here — checklist skeleton)
- `05-change-log.md`
- `99-mistake-log.md`

Conditional artifact:

- `06-research-notes.md` when external information affects decisions

## `02-design.md` Template

```markdown
# [Feature Name] — Technical Design

**Status:** Draft | Approved
**Requirements:** docs/plans/YYYY-MM-DD-<feature-name>/01-requirements.md

## Design Charter
**Chartered:** YYYY-MM-DD

### Decisions Manifest
_(Questions that required explicit design — executing agent cannot decide alone)_
1. [specific design question] (REQ-###)
2. [specific design question] (REQ-###)

### Agent-Handled
_(Executing agent handles per project conventions — no design decision needed)_
- [e.g., Spring Boot annotation syntax, method body implementation consistent with AC]

### Explicitly Excluded
_(Considered during holistic thinking, confirmed out of scope — CR required to add)_
- [e.g., retry mechanism, compensation logic, monitoring setup]

---

## Architecture Decision
[2-3 sentences: what is being built and how it fits into the existing system]

## Key Design Decisions
| Decision | Options Considered | Chosen | Reason |
|----------|--------------------|--------|--------|
| [topic]  | [A, B, C]          | [A]    | [why]  |

## Data Model
[DDL-level detail: table names, column names, types, constraints, indexes, FK relationships]

## Component Contracts

### [ClassName] (`com.example.package.ClassName`)
**Responsibility:** [one sentence]

| Method | Signature | Returns | Throws |
|--------|-----------|---------|--------|
| [methodName] | `(ParamType param)` | `ReturnType` | `ExceptionType` |

_(Repeat for each new or modified class)_

## API Contracts

### [HTTP Method] [/path]
**REQ:** REQ-###
**Auth:** [required role / none]

**Request:**
```json
{ "field": "type — required/optional, constraints" }
```

**Response (success):**
```json
HTTP [status]
{ ... }
```

**Response (errors):**
| Condition | HTTP | Body |
|-----------|------|------|
| [condition] | [4xx] | `{"code":"X","message":"Y"}` |

## Error Taxonomy
| Exception Class | HTTP Status | Error Code | Trigger Condition |
|----------------|-------------|------------|-------------------|
| [ExceptionName] | [4xx/5xx] | [ERROR_CODE] | [when this is thrown] |

## Business Rules & Constraints
[Explicit constraints the implementing agent must follow — uniqueness, state machine transitions, calculation rules. Agent must NOT override these.]
- BR-001: [rule]

## Tech Stack
[Key technologies and versions used]

## Component Interaction
[Numbered sequence: which component calls which, in what order]

## REQ Coverage Mapping
| REQ | Covered by |
|-----|-----------|
| REQ-001 | [ClassName.methodName() / /endpoint] |
| REQ-002 | [ClassName.methodName()] |

## Rollback Plan
[How to revert if deployment fails — required for DB changes and breaking API changes]
```

## Design Completeness Gate (MANDATORY — before Phase 1 user confirmation)

After producing `02-design.md`, run this gate before presenting to the user.

### Step 1 — Charter decisions check

For each item in the Design Charter's Decisions Manifest:
- [ ] Decision #N has a clear, unambiguous answer in the design document
- [ ] The answer is specific enough that the executing agent faces no further design choices

All decisions answered = design is complete. Do NOT check for things outside the charter.

### Step 2 — REQ coverage check

For each REQ-### in `01-requirements.md`:
- [ ] REQ-### appears in REQ Coverage Mapping
- [ ] REQ-### error path AC is addressed in Error Taxonomy or Component Contracts

### Step 3 — Proactive completion declaration (MANDATORY)

When all items above are ✓, Agent MUST immediately output:

> "设计章程中所有决策均已回答。
> **已回答的决策：** [list decisions from manifest]
> **Agent 自行处理：** [Agent-Handled list from charter]
> **本次明确不设计：** [Explicitly Excluded list from charter]
> **状态变更为 Draft（待审批）。** 请确认后进入 Phase 2。"

**Do NOT wait to be asked if anything is missing.** The charter defines completeness. If every charter decision is answered, the design is complete.

### Re-check Protocol (three-way branch)

When re-checking `02-design.md` at any point, classify every finding before acting:

```
发现问题
  ├── 章程内，尚未回答
  │     → 立即补充，无需用户确认
  │
  ├── 章程内，但当前答案不够清晰
  │     → 澄清现有答案，不扩展范围
  │
  ├── 章程内，但需调整章程边界
  │     → 提出 DR [charter-amendment]，等待用户确认后再修改
  │
  └── 章程外
        → 记录为 CR 候选，告知用户，不在当前设计中处理
```

**"章程外的发现"不是遗漏，是边界决策。** 不得直接加入设计。

## `04-verification.md` Template

```markdown
# [Feature Name] — Verification

**Status:** In Progress | Complete
**Implementation Plan:** docs/plans/YYYY-MM-DD-<feature-name>/03-implementation-plan.md

## Checklist

| REQ / CR / DR | Description | Acceptance Criteria | Evidence | Status |
|---------------|-------------|---------------------|----------|--------|
| REQ-001 | [short title] | [Given/When/Then summary] | [test name / command output] | pending |
| REQ-002 | [short title] | [Given/When/Then summary] | [test name / command output] | pending |
| CR-001 | [change description] | [updated criteria] | [evidence] | pending |
| DR-001 | [design change] | [verification approach] | [evidence] | pending |

> **Status values:** `pending` (not started) | `verified` (test passed, evidence recorded) | `failed` (check did not pass, needs fix)

## Coverage

| Layer | Target | Actual | Status |
|-------|--------|--------|--------|
| Service | 85% | — | pending |
| Controller | 80% | — | pending |
| Overall | 80% | — | pending |

## Closure Gate

- `unmapped_req`: 0
- `open_cr`: 0
- `open_dr`: 0
- `pending_recheck`: 0
```

## Project Standards Baseline

Before writing tasks, capture standards from:

1. `rules/**/*.md`
2. Root instructions (`AGENTS.md`, `CLAUDE.md`, project docs)
3. Nearby implementation patterns

Then identify the active tech stack from `01-requirements.md` and `02-design.md`, and apply the relevant language skill:

| Tech Stack | Apply Skill |
|------------|------------|
| Java / Spring Boot | `agent-workflow:springboot-patterns` |
| Any backend | `agent-workflow:api-design` (for API tasks) |
| DB migrations | `agent-workflow:database-migrations` |

## Traceability Rules (MANDATORY)

- Requirements use `REQ-###` IDs (defined in `01-requirements.md`).
- Requirement changes use `CR-###` IDs in `05-change-log.md`.
- Design changes use `DR-###` IDs in `05-change-log.md`.
- Every task in `03-implementation-plan.md` must map to one or more `REQ-###`.
- `04-verification.md` must verify each `REQ-###` and related `CR-###` / `DR-###` if changed.

## Plan Header

Every implementation plan (`03-implementation-plan.md`) starts with:

```markdown
# [Feature Name] — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use agent-workflow:executing-plans to implement this plan task-by-task.

**Requirements:** docs/plans/YYYY-MM-DD-<feature-name>/01-requirements.md
**Design:** docs/plans/YYYY-MM-DD-<feature-name>/02-design.md
**Project Conventions:** [Concrete rule files in `rules/**/*.md`]
**Traceability:** [REQ/CR/DR strategy for this feature]
**Research Notes:** [Path to `06-research-notes.md` if used]

---

## Task Summary

| Task | Type | REQ | Depends on | Status |
|------|------|-----|------------|--------|
| Task 1: [name] | code-task | REQ-001 | — | pending |
| Task 2: [name] | migration-task | REQ-002 | Task 1 | pending |

## Definition of Done

Every task must satisfy all items before being marked `completed`:

- [ ] All tests pass; coverage meets targets (Service ≥ 85%, Controller ≥ 80%, Overall ≥ 80%)
- [ ] No TODO / debug / temporary code left
- [ ] Naming follows project rules (`rules/**/*.md`)
- [ ] Error handling complete (no silent failures)
- [ ] All callers listed in `Impact` have been handled
- [ ] `04-verification.md` evidence updated for related REQ / CR / DR
- [ ] Commit message format: `type(scope): one-line English summary`

> Override: project `rules/**/*.md` may extend or tighten this list.
```

## Task Structure

Every task starts with the traceability + files header, then uses the steps template matching its type.

````markdown
### Task N: [Component Name]

**Type:** `code-task` | `migration-task` | `config-task`

**Traceability:**
- REQ: `REQ-001`, `REQ-002`
- CR: `CR-003` (if applicable)
- Status: `pending` | `in_progress` | `completed` | `superseded` | `cancelled`

**Files:**
- Create: `exact/path/to/file`
- Modify: `exact/path/to/existing:line`
- Test: `tests/exact/path/to/test`

**Depends on:** Task N (optional — list task numbers that must be `completed` before this task starts)

**Impact:** [List existing modules/callers affected, or "none" if new code only]

**Test layer:** `unit` | `slice` | `integration` | `e2e` (choose all that apply)
````

### code-task steps (default for feature/bugfix/refactor)

```
Step 1: Write the failing test (at the layer specified in Test layer)
Step 2: Run test — verify it fails for the expected reason
Step 3: Write minimal implementation following project language skill
Step 4: Run test — verify it passes; run full suite for regression
Step 5: Self-review: no debug code, naming follows rules, error handling complete
Step 6: Commit — format: type(scope): one-line English summary
```

### migration-task steps (DB schema / data migration)

```
Step 1: Write migration script (forward)
Step 2: Write rollback script (backward)
Step 3: Test forward migration on dev data — verify schema/data correctness
Step 4: Test rollback — verify state restored
Step 5: Confirm zero-downtime compatibility if required
Step 6: Commit — format: type(scope): one-line English summary
```

### config-task steps (config / env var / parameter change)

```
Step 1: Identify all affected environments
Step 2: Apply change with backward-compatible default if needed
Step 3: Verify affected behavior in dev environment
Step 4: Document change and affected services
Step 5: Commit — format: type(scope): one-line English summary
```

## Revision Mode Rules

**Requirement change** (scope/behavior):
1. Append `CR-###` to `05-change-log.md`.
2. Update `01-requirements.md` effective requirement state.
3. Update `03-implementation-plan.md` tasks and statuses.
4. Keep superseded tasks for audit (`Status: superseded`), do not silently delete history.
5. Update `04-verification.md` checklist for impacted `REQ/CR`.

**Design change** (technical approach, no scope change):
1. Append `DR-###` to `05-change-log.md`.
2. Update `02-design.md` and set its **Status back to `Draft`**.
3. Present updated design to the user and state:
   > "Design revised (DR-###). Please review `02-design.md`. Confirm to resume implementation."
4. **Wait for explicit confirmation before continuing.**
5. Upon approval, set `02-design.md` status to `Approved (amended: DR-###)`.
6. Update affected tasks in `03-implementation-plan.md`.
7. Update `04-verification.md` if verification steps are affected.

**Charter amendment** (new decision point discovered after Phase 0):
1. Stop current design work immediately.
2. Append `DR-### [charter-amendment]` to `05-change-log.md` with the new decision point and why it was not identified in Phase 0.
3. Present to user:
   > "发现章程外的设计决策点：[description]。建议将其加入 Decisions Manifest。请确认是否纳入本次设计范围，或记为 CR 候选。"
4. **Wait for explicit confirmation before continuing.**
5. If confirmed in scope: update Design Charter in `02-design.md`, answer the new decision, continue.
6. If confirmed out of scope: add to Explicitly Excluded in charter, record as CR candidate, continue without designing it.

## Execution Handoff

After saving or revising the plan, offer:

1. **Subagent-Driven (this session)** - use `agent-workflow:subagent-driven-development`
2. **Parallel Session (separate)** - use `agent-workflow:executing-plans`

Ask: "Which approach?"