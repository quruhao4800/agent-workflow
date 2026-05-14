---
name: finishing-a-development-branch
description: Use when implementation is complete, all tests pass, and you need to decide how to integrate the work - guides completion of development work by presenting structured options for merge, PR, or cleanup
---

# Finishing a Development Branch

## Prerequisites

| From skill | Must already exist | If missing |
|------------|--------------------|------------|
| `verification-before-completion` | All gates passed (unmapped_req = 0, open_cr = 0, open_dr = 0, pending_recheck = 0) | Return to `verification-before-completion` |
| `verification-before-completion` | `04-verification.md` Status = Complete | Return to `verification-before-completion` |
| `executing-plans` | All tasks `completed`, no tasks `in_progress` | Return to `executing-plans` |

## Overview

Verify technical checks and requirement closure first, then present integration options.

**Announce at start:** "I'm using the finishing-a-development-branch skill to complete this work."

## Step 1: Verify Tests

Run project test suite. If failing, stop and fix.

## Step 2: Verify Requirement Closure

Confirm from plan artifacts:

- `04-verification.md` is updated
- `unmapped_req = 0`
- `open_cr = 0`
- `open_dr = 0`
- `pending_recheck = 0`

If any check fails, stop. Do not offer merge/PR/discard options.

## Step 3: Security Review (Conditional)

If the implementation touches any of the following, invoke `agent-workflow:security-review` before proceeding:

- API endpoints or HTTP handlers
- Authentication / authorization logic
- User input processing
- Sensitive data (tokens, passwords, PII)
- File upload or external service calls

If none of the above apply, skip this step.

## Step 4: Verify Commit-msg Hook

Run:
```bash
git config core.hookspath
```

- If a path is returned and the hook file exists → proceed.
- If not configured → stop and prompt the user:

  > This project has no commit-msg hook. The agent-workflow repo provides one that enforces conventional commit format.
  >
  > Options:
  > 1. Copy `.githooks/` into this project and configure: `git config core.hookspath .githooks`
  > 2. Point to agent-workflow hooks directly: `git config core.hookspath <agent-workflow-path>/.githooks`
  > 3. Skip — proceed without hook
  >
  > Which do you prefer?

  Execute the user's choice before continuing. If option 3, still enforce single-line conventional commit format manually.

## Step 5: Determine Base Branch

Find base (`main`/`master`) via `git merge-base` and confirm if needed.

## Step 6: Present Options

Present exactly:

1. Merge back to `<base-branch>` locally
2. Push and create a Pull Request
3. Keep the branch as-is (handle later)
4. Discard this work

## Step 7: Execute Choice

### Option 1: Merge Locally

- Checkout base branch
- Pull latest
- Merge feature branch
- Re-run tests on merged result
- Delete feature branch if tests pass

### Option 2: Push and Create PR

- Push feature branch
- Create PR with summary and test plan

### Option 3: Keep As-Is

- Report branch preserved
- No action

### Option 4: Discard

- Require exact typed confirmation: `discard`
- Delete feature branch

## Red Flags

Never:

- Proceed with failing tests
- Proceed with open requirement closure gates
- Delete work without explicit confirmation
- Force-push without explicit request

## Integration

Called by:

- `agent-workflow:subagent-driven-development`
- `agent-workflow:executing-plans`