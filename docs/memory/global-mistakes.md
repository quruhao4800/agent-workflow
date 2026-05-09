# Global Mistakes Memory

Cross-project reusable mistakes and prevention checks.

## Usage

- Add only reusable patterns that can prevent mistakes across projects.
- Keep project-specific mistakes in `docs/plans/YYYY-MM-DD-<feature-name>/99-mistake-log.md`.
- Review this file before implementation and before completion claims.

## Entry Template

```markdown
## [Short title]

- Mistake: [what went wrong]
- Trigger: [when this tends to happen]
- Prevention check: [specific pre-check to run]
- Status: [open/resolved]
- Last seen: [YYYY-MM-DD]
```
