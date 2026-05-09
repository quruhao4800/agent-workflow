# Git Workflow

## Commit Message Format
```
<type>(<scope>): <description>
```

- `<scope>` is optional
- Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`

### Rules
- **Language**: commit message must be written in English
- **Length**: `<description>` must be a single summary sentence, max 72 characters — describe the intent, not a list of every changed file or line
- **After committing**: explain the commit in Chinese to the user — one sentence summarizing what was done and why

### Commit-msg Hook

A `commit-msg` hook is in `.githooks/commit-msg`. It auto-normalizes and validates every commit message before it is saved.

**First-time setup** (run once per clone):
```bash
git config core.hooksPath .githooks
chmod +x .githooks/commit-msg
```

The hook will:
- Convert full-width colons（：）to half-width（:）
- Lowercase the type automatically
- Block the commit if the format does not match the regex

Note: Attribution disabled globally via ~/.claude/settings.json.

## Pull Request Workflow

When creating PRs:
1. Analyze full commit history (not just latest commit)
2. Use `git diff [base-branch]...HEAD` to see all changes
3. Draft comprehensive PR summary
4. Include test plan with TODOs
5. Push with `-u` flag if new branch

> For the full development process (planning, TDD, code review) before git operations,
> see [development-workflow.md](./development-workflow.md).
