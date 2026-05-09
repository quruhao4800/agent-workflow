---
name: brainstorming
description: "You MUST use this before any creative work - creating features, building components, adding functionality, or modifying behavior. Explores requirements and design before implementation."
---

# Brainstorming Ideas Into Designs

## Overview

Turn ideas into approved design artifacts before implementation.

<HARD-GATE>
Do NOT invoke implementation skills or write code until design is approved.
</HARD-GATE>

## Core Output Contract

Create one feature folder first:

`docs/plans/YYYY-MM-DD-<topic>/`

Brainstorming output:

- `01-requirements.md` (approved requirements baseline — WHAT)

If scope is expected to evolve, also initialize:

- `05-change-log.md` (append-only CR/DR entries)

## `01-requirements.md` Template (MANDATORY)

Use this exact structure:

```markdown
# [Feature Name] — Requirements

**Status:** Draft | Review | Approved
**Feature folder:** docs/plans/YYYY-MM-DD-<feature-name>/

## Problem Statement
[What problem are we solving? For whom? What evidence do we have it matters?]

## Goals & Success Metrics
[Measurable outcomes — not feature lists. E.g., "reduce X by Y%", "support Z concurrent users"]

## Non-Goals
[Explicit statement of what this does NOT address]

## Users / Affected Systems
[Primary users, secondary users, downstream systems impacted]

## Functional Requirements

### REQ-001: [Short title]
**Priority:** Must Have | Should Have | Could Have
**Description:** [Behavior description — what the system does, not how]
**Acceptance Criteria:**
- Given [context], When [action], Then [exact outcome — HTTP status, field names, response shape]
- Given [context], When [error/edge case], Then [exact error: HTTP status + body shape e.g. `{"code":"X","field":"Y"}`]
**Non-goals for this requirement:** [What this REQ explicitly excludes]
**Agent Execution Context:**
- Entities/tables: [list entities or tables involved]
- External services: [list external calls, or "none"]
- Hard constraints: [things the implementing agent must NOT override — e.g., field names, status codes, business rules]

### REQ-002: ...

## Non-Functional Requirements

### REQ-NFR-001: [Short title]
**Category:** Performance | Security | Availability | Maintainability | Compliance
**Requirement:** [Measurable target, e.g., "P99 response ≤ 500ms under 500 concurrent users"]
**Priority:** Must Have | Should Have | Could Have

## Assumptions & Dependencies
- [What must be true for this to work]
- [External systems or teams this depends on]

## Open Questions
| Question | Owner | Due |
|----------|-------|-----|
| [question] | [name] | [date] |

## Glossary
| Term | Definition |
|------|-----------|
| [term] | [definition] |
```

## Requirement Quality Gate

Before finalizing each REQ, verify:

- **Testable**: Can a pass/fail acceptance test be written for it?
- **Behavioral, not implementational**: Does it describe WHAT, not HOW? (flag: "shall use Redis", "shall call API X")
- **Measurable**: No vague qualifiers — replace "fast", "reliable", "flexible" with numeric targets
- **Has error path**: Every functional REQ must have at least one `Given [error/edge case]` acceptance criterion
- **MoSCoW priority assigned**: Must Have / Should Have / Could Have
- **Non-goal stated**: What this REQ does NOT cover
- **Deterministic AC**: Acceptance criteria must specify exact values — HTTP status codes, field names, error body shape. Replace vague outcomes ("returns error", "handles correctly") with precise contracts (e.g., `HTTP 400, body: {"code":"INVALID_EMAIL","field":"email"}`).
- **Agent Execution Context filled**: Entities/tables, external services, and hard constraints are explicitly listed — not left blank or implied.

## Design Self-Review Pass (MANDATORY — run after Cross-REQ Consistency Check, before presenting to user)

Run 3 internal passes. Do NOT present the design to the user until all 3 passes are complete.

### Pass 1 — Template completeness
For every REQ-###, check that all required template fields are filled (no blanks, no "TBD").
- `AUTO_FIX`: fill from information already available in this session.
- `NEEDS_DECISION`: field requires information only the user can provide — add to the decision batch.

### Pass 2 — Cross-REQ consistency
Check for contradictions, NFR feasibility conflicts, and non-goal conflicts across all requirements.
- `AUTO_FIX`: contradiction has a clear resolution derivable from context (e.g., one REQ explicitly takes priority, or one version is clearly more restrictive and consistent with stated goals).
- `NEEDS_DECISION`: genuine trade-off or ambiguity — add to the decision batch.

### Pass 3 — Quality Gate sweep
Apply the Requirement Quality Gate to every REQ-###.
- `AUTO_FIX`: rewrite vague or non-deterministic ACs into precise ones where the correct value is derivable from context (e.g., a standard HTTP 400 for validation failure).
- `NEEDS_DECISION`: requires business knowledge or policy the user must supply — add to the decision batch.

### After all 3 passes

Present to the user exactly once:

```
## Design Self-Review完成

**已自动修复 (AUTO_FIX):**
- [brief list of what was fixed]

**需要你决策 (NEEDS_DECISION):**
1. [issue] — [two options or a concrete question]
2. ...

请逐条确认或选择，确认后继续进入 Completeness Gate。
```

If there are zero NEEDS_DECISION items, state that and proceed directly to the Completeness Gate without waiting.

## Cross-REQ Consistency Check (MANDATORY)

Before requesting approval, check for contradictions across all requirements:

1. **Functional conflicts**: Do any two REQ acceptance criteria contradict each other? (e.g., REQ-001 says field X is required, REQ-002 says field X is optional)
2. **NFR feasibility**: Are NFR targets achievable given the functional REQ constraints? (e.g., P99 ≤ 100ms is incompatible with a REQ that requires a synchronous third-party call with no SLA)
3. **Non-goal conflicts**: Do any Non-goals invalidate a Must Have REQ? (e.g., non-goal says "no email validation" but REQ-003 requires email format enforcement)

If a conflict is found: surface it to the user immediately, resolve it, and re-check before proceeding.

## Requirement Baseline Rules

In `01-requirements.md`:

- Assign requirement IDs as `REQ-###` (functional) and `REQ-NFR-###` (non-functional).
- Keep each requirement testable and unambiguous.
- Mark non-goals explicitly to prevent scope creep.

## Required Process

1. Load project rules: search and read all files in `rules/**/*.md`, `.claude/rules/**/*.md`, `docs/rules/**/*.md`, `CLAUDE.md`, `AGENTS.md`. Apply them throughout this session.
2. Identify task type from the list below — this determines which domain questions to ask.
3. Explore project context (files, docs, recent commits).
4. Gather ALL clarifying questions from the domain checklist for all identified task types. Present them as a single numbered batch, grouped by topic. Do NOT ask one question per message. Exception: if a follow-up question's answer logically depends on a prior answer, split into at most 2 rounds.
5. Capture non-functional requirements (NFR) — include in the same question batch when possible.
6. Propose 2-3 approaches with trade-offs and recommendation.
7. Draft all REQ-### entries and apply the Requirement Quality Gate to each.
8. Run Cross-REQ Consistency Check.
9. Run Design Self-Review Pass — resolve what can be resolved internally, then batch remaining decisions to the user.
10. Run Requirements Completeness Gate — output proactive completion declaration.
11. Write approved requirements to `01-requirements.md` with Scope Freeze Declaration.
12. Transition to `writing-plans` for executable tasks.

## Task Type Detection

Identify the primary type before asking questions:

| Type | Trigger keywords |
|------|-----------------|
| `api-endpoint` | 新增/修改接口、Controller、REST |
| `db-change` | 新增表/字段、迁移、Schema 变更 |
| `batch-job` | 定时任务、@Scheduled、批量处理 |
| `integration` | 三方服务、Feign、外部 API 对接 |
| `refactor` | 重构、优化、拆分、不新增功能 |
| `config` | 配置变更、参数调整、环境变量 |

One feature may span multiple types — list all that apply.

## Domain Question Checklists

Use only the checklist(s) for the identified type(s). Skip others.

### api-endpoint
- Who are the consumers (frontend / other services / external)?
- Does this change existing contracts? Is backward compatibility required?
- What authentication/authorization does this endpoint require?
- What are the expected request volume and peak concurrency?
- What should happen on partial failure or timeout?

### db-change
- Is a data migration required, or schema-only?
- Can this be deployed with zero downtime (online DDL)?
- What is the approximate data volume in affected tables?
- Is rollback of the migration possible? What is the rollback plan?
- Are there foreign key or index implications?

### batch-job
- Must the job be idempotent (safe to re-run)?
- What is the execution frequency and expected duration?
- How should failures be handled — retry, skip, or alert?
- How is concurrent execution prevented?
- Are there cross-tenant data access requirements?

### integration
- What is the SLA/availability of the external service?
- What timeout and retry strategy is appropriate?
- What is the fallback/degradation behavior if the service is down?
- Is the integration synchronous or asynchronous?
- What data sensitivity/compliance requirements apply?

### refactor
- What is the measurable goal (performance, readability, decoupling)?
- Which callers/consumers will be affected?
- Are there behavioral changes, or is this purely structural?
- What is the regression test strategy?

### config
- Which environments are affected (dev / test / prod)?
- Is this change backward compatible with the old value?
- Is a service restart required?

## NFR Capture (MANDATORY)

After domain questions, explicitly ask and record in `01-requirements.md`:

- **Concurrency:** Expected peak concurrent requests or records processed
- **Error tolerance:** Acceptable failure rate; behavior on partial failure
- **Data consistency:** Strong consistency required, or eventual consistency acceptable?
- **Security:** Data sensitivity level; any compliance requirements
- **Observability:** Logging, alerting, or monitoring expectations

If the user has no specific targets, record "no constraint defined" explicitly — do not silently omit.

## Scope-Change Return Gate (MANDATORY)

If implementation-time change affects acceptance criteria, boundaries, or non-goals:

1. Stop implementation planning/execution.
2. Return to brainstorming.
3. Append `CR-###` in `05-change-log.md`.
4. Update effective requirements in `01-requirements.md` (`REQ-###` mapping kept intact).
5. Re-enter `writing-plans` in revision mode.

If change is technical approach only (no scope change), use `DR-###` in `05-change-log.md` and update `02-design.md` — no need to return to brainstorming.

Do not continue coding with undocumented requirement changes.

## Verification Handoff (04-verification.md)

Brainstorming defines what must be verifiable; downstream skills execute the checks.

- Ensure each `REQ-###` in `01-requirements.md` is testable and has clear acceptance criteria.
- `writing-plans` must initialize/update `04-verification.md` with checklist items for every active `REQ-###` and related `CR-###`.
- If scope changes in brainstorming (`CR-###` added), mark impacted requirements so `writing-plans` revision mode updates `04-verification.md` before implementation resumes.

## Open Questions Closure Gate (MANDATORY)

Before setting `01-requirements.md` status to `Approved`:

1. Review the Open Questions table.
2. Every row must have a resolved answer — no row may be left blank or marked "TBD".
3. If any question is unresolved, ask the user for an answer before proceeding.
4. Only after all questions are closed may status be changed to `Approved` and the transition to `writing-plans` begin.

## Requirements Completeness Gate (MANDATORY)

After closing all open questions, run this gate before declaring approval.

### Step 1 — Built-in skeleton check (mark ✓ or N/A per task type)

**api-endpoint:**
- [ ] Consumer(s) identified
- [ ] Authentication/authorization defined
- [ ] Request validation rules defined
- [ ] Success response contract defined (HTTP status + body shape)
- [ ] All error response contracts defined (HTTP status + body shape)
- [ ] Idempotency decision documented
- [ ] Rate limiting / concurrency decision documented
- [ ] Backward compatibility decision documented

**db-change:**
- [ ] Schema changes fully specified (tables, fields, types, constraints)
- [ ] Migration strategy defined (online DDL / offline)
- [ ] Rollback plan defined
- [ ] Data volume impact assessed
- [ ] Index/FK implications documented

**batch-job:**
- [ ] Idempotency requirement defined
- [ ] Schedule and expected duration defined
- [ ] Failure handling strategy defined (retry / skip / alert)
- [ ] Concurrency prevention strategy defined

**integration:**
- [ ] External service SLA and availability defined
- [ ] Timeout and retry strategy defined
- [ ] Fallback/degradation behavior defined
- [ ] Sync vs async decision documented
- [ ] Data sensitivity/compliance requirements defined

**refactor:**
- [ ] Measurable goal defined
- [ ] Affected callers/consumers identified
- [ ] Behavioral change scope defined (none / partial / full)
- [ ] Regression test strategy defined

**config:**
- [ ] Affected environments listed
- [ ] Backward compatibility confirmed
- [ ] Service restart requirement documented

**All task types — NFR:**
- [ ] Concurrency target (or "no constraint defined")
- [ ] Error tolerance (or "no constraint defined")
- [ ] Data consistency requirement (or "no constraint defined")
- [ ] Security/compliance requirement (or "no constraint defined")
- [ ] Observability requirement (or "no constraint defined")

### Step 2 — REQ coverage items (instantiated per task)

For each REQ-### in this document:
- [ ] REQ-### has at least one deterministic Given/When/Then AC with exact values
- [ ] REQ-### has at least one error path AC
- [ ] REQ-### has Agent Execution Context filled (entities, services, hard constraints)
- [ ] REQ-### has explicit Non-goals

### Step 3 — Proactive completion declaration (MANDATORY)

When all items above are ✓ or N/A, Agent MUST immediately output:

> "需求已基于 [task types] 完整性清单全部覆盖。
> **已覆盖：** [REQ-### list]
> **已考虑并显式排除：** [3~5 items considered but deliberately excluded from this scope]
> **状态变更为 Approved。** 批准后任何新增内容须通过 CR-### 流程处理。"

**Do NOT wait to be asked if anything is missing.** The checklist defines completeness. If the checklist is fully checked, requirements are complete.

## After Requirements Approval

Append the following section to `01-requirements.md` before committing:

```
## Scope Freeze Declaration
**Covered:** [REQ-### list]
**Explicitly excluded:** [items considered but deliberately out of scope]
**Freeze date:** [YYYY-MM-DD]
Any addition after this point requires a CR-### entry in `05-change-log.md`.
```

Then:
- Commit `01-requirements.md` (and `05-change-log.md` if created).
- Invoke `quruhao-skills:writing-plans` as the only next workflow skill, passing:
  - Feature folder path (`docs/plans/YYYY-MM-DD-<feature-name>/`)
  - Active `REQ-###` list and Scope Freeze Declaration
  - Tech stack and key constraints identified during brainstorming
  - Any external research or open questions for `06-research-notes.md`

## Key Principles

- One question per message when clarifying.
- Prefer concrete constraints over assumptions.
- Keep design minimal (YAGNI), but explicit.
- Validate incrementally with the user.