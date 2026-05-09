# Git Workflow

## Commit Message Format
```
<type>(<scope>): <description>
```

- `<scope>` is optional
- Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`

### Rules
- **Single line only**: one summary sentence, max 72 characters — no body, no bullet list, no multi-line description
- **Language**: commit message must be written in English; after committing, explain what was done and why in Chinese to the user
- **Intent over detail**: describe WHY / WHAT, not which files changed

### Hook Setup Gate (MANDATORY before any commit)

Before running `git commit` in **any project**, check whether the project has a `commit-msg` hook configured:

```bash
git config core.hookspath
```

**Decision table:**

| Result | Action |
|--------|--------|
| Returns a path (e.g. `.githooks`) and `.githooks/commit-msg` exists | Hook is active — proceed with commit |
| Empty / not set | Prompt the user (see below) |

**Prompt to user when hook is not configured:**

> This project does not have a commit-msg hook configured.
> The quruhao-skills repo provides one at `<quruhao-skills-path>/.githooks/commit-msg` that enforces conventional commit format.
>
> Options:
> 1. Copy `.githooks/` into this project and run `git config core.hookspath .githooks`
> 2. Point directly to the quruhao-skills hooks: `git config core.hookspath <quruhao-skills-path>/.githooks`
> 3. Skip — proceed without hook
>
> Which do you prefer?

If the user chooses option 1 or 2, execute the corresponding commands before committing. If the user chooses option 3, proceed but still apply the commit message format rules manually.

## Pull Request Workflow

When creating PRs:
1. Analyze full commit history (not just latest commit)
2. Use `git diff [base-branch]...HEAD` to see all changes
3. Draft comprehensive PR summary
4. Include test plan with TODOs
5. Push with `-u` flag if new branch

> For the full development process (planning, TDD, code review) before git operations,
> see [development-workflow.md](./development-workflow.md).
