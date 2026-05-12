# Agent Orchestration

**Important:** These are AGENTS, not skills. Invoke them via the `Agent` tool, NOT the `Skill` tool.
Attempting to call them as `quruhao-skills:planner` or similar will fail with "Unknown skill".

## Available Agents

| Agent | Purpose | When to Use |
|-------|---------|-------------|
| `planner` | Implementation planning | Complex features, multi-phase work |
| `architect` | System design (Java / Spring Boot) | New module design, architectural decisions |
| `tdd-guide` | TDD for Java / JUnit 5 | All new features and bug fixes |
| `code-reviewer` | Java / Spring Boot code review | After writing or modifying any code |
| `security-reviewer` | Security analysis | Before commits touching auth, payments, or sensitive data |
| `build-error-resolver` | Java / Gradle build errors | When build or tests fail |

## Use Agents Proactively

| Situation | Agent tool (subagent_type) |
|-----------|--------|
| New feature or architectural decision | `planner` → `architect` |
| Writing new code or fixing a bug | `tdd-guide` |
| After any code change | `code-reviewer` |
| Build or test failure | `build-error-resolver` |
| Touching auth, payment, or PII | `security-reviewer` |

## Parallel Execution

For independent tasks, launch agents in parallel — never sequentially when tasks do not depend on each other.

```
# Example: parallel review
Agent 1: security-reviewer on auth module changes
Agent 2: code-reviewer on service layer changes
```
