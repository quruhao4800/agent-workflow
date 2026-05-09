# Plan Document Structure

All planning artifacts must be grouped by feature folder:

`docs/plans/YYYY-MM-DD-<feature-name>/`

## Required Files

- `01-requirements.md` - requirements baseline from brainstorming (WHAT)
- `02-design.md` - technical design from writing-plans (HOW)
- `03-implementation-plan.md` - executable implementation plan with tasks
- `04-verification.md` - verification evidence and final checklist
- `05-change-log.md` - append-only change log for requirements (CR-###) and design (DR-###)
- `99-mistake-log.md` - project-level mistakes and prevention checks

## Conditional Required File

- `06-research-notes.md` - required when any external research is used (web search, external docs, API references, third-party examples)

### `06-research-notes.md` Minimum Fields

- `Question` - what was being answered
- `Source` - URL / command / document location
- `Retrieved At` - timestamp
- `Key Findings` - concise takeaways
- `Decision Impact` - what implementation decision this informed
- `Recheck Needed` - yes/no and condition for revalidation

## File Responsibilities

| File | Produced by | Contains |
|------|-------------|----------|
| `01-requirements.md` | brainstorming | Problem, users, functional requirements, NFR, acceptance criteria |
| `02-design.md` | writing-plans | Architecture decisions, data model, API contracts, tech stack |
| `03-implementation-plan.md` | writing-plans | Ordered tasks with TDD steps, REQ/CR/DR traceability |
| `04-verification.md` | writing-plans (skeleton) + executing-plans (evidence) | Checklist per REQ, closure evidence |
| `05-change-log.md` | any phase | CR-### for requirement changes, DR-### for design changes |
| `06-research-notes.md` | any phase | External research decisions |
| `99-mistake-log.md` | any phase | Mistakes and prevention checks |

## ID Scheme

- `REQ-###` — functional/non-functional requirements in `01-requirements.md`
- `CR-###` (Change Request) — requirement changes in `05-change-log.md`
- `DR-###` (Design Revision) — design changes in `05-change-log.md`
- Every task in `03-implementation-plan.md` must reference one or more `REQ-###`
- Every verification item in `04-verification.md` must reference the corresponding `REQ-###` and any related `CR-###` / `DR-###`

## Change Handling Flow

### Requirement change (scope/behavior change)

1. Add `CR-###` entry in `05-change-log.md` (append only).
2. Update effective requirement state in `01-requirements.md`.
3. Update `03-implementation-plan.md` tasks with explicit `REQ-###` references.
4. Update `04-verification.md` checklist for impacted requirements.
5. Continue implementation only after steps 1-4 are complete.

### Design change (technical approach change, no scope change)

1. Add `DR-###` entry in `05-change-log.md` (append only).
2. Update `02-design.md`.
3. Update affected tasks in `03-implementation-plan.md`.
4. Continue implementation only after steps 1-3 are complete.

## File Templates

### `04-verification.md`

```markdown
# [Feature Name] — Verification

**Status:** In Progress | Complete
**Implementation Plan:** docs/plans/YYYY-MM-DD-<feature-name>/03-implementation-plan.md

## Checklist

| REQ / CR / DR | Description | Acceptance Criteria | Evidence | Status |
|---------------|-------------|---------------------|----------|--------|
| REQ-001 | [short title] | [Given/When/Then summary] | [test name / command output] | pending |

> **Status values:** `pending` | `verified` | `failed`

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

### `05-change-log.md`

```markdown
# [Feature Name] — Change Log

## CR-001: [Short Title]

**Type:** Requirement Change
**Date:** YYYY-MM-DD
**Requested by:** [user / stakeholder]
**Affected REQ:** REQ-###
**Description:** [What changed and why]
**Impact on plan:** [Which tasks were added / superseded / updated]

---

## DR-001: [Short Title]

**Type:** Design Revision
**Date:** YYYY-MM-DD
**Affected design section:** [e.g., Data Model / API Contracts]
**Description:** [What changed and why]
**Impact on plan:** [Which tasks were updated]

---
```

### `99-mistake-log.md`

```markdown
# [Feature Name] — Mistake Log

## M-001

**Mistake:** [What went wrong]
**Trigger:** [What action / assumption caused it]
**Prevention check:** [Concrete check to run before next similar step]
**Status:** open | resolved
```

## Rules

- Do not place feature plan files directly under `docs/plans/` root.
- Keep all docs for the same feature in the same folder.
- Use lowercase kebab-case for `<feature-name>`.
- Before task completion, review `06-research-notes.md` for all `Recheck Needed` items.
- Do not claim completion while any requirement is unmapped, any `CR-###` is open, or any required recheck is pending.
