# Agent Orchestration

## CRITICAL: Agents Are NOT Skills

**Never invoke agents via the Skill tool.** Agents must be called via the **Agent tool** with `subagent_type`.

```
// WRONG — will fail with "Unknown skill"
Skill(quruhao-skills:planner)
Skill(quruhao-skills:architect)
Skill(quruhao-skills:code-reviewer)

// CORRECT
Agent(subagent_type: "quruhao-skills:code-reviewer", ...)
Agent(subagent_type: "quruhao-skills:tdd-guide", ...)
```

## Available Agents (Agent tool only)

| subagent_type | Purpose | When to Use |
|---------------|---------|-------------|
| `quruhao-skills:planner` | Implementation planning | Complex features, multi-phase work |
| `quruhao-skills:architect` | System design (Java / Spring Boot) | New module design, architectural decisions |
| `quruhao-skills:tdd-guide` | TDD for Java / JUnit 5 | All new features and bug fixes |
| `quruhao-skills:code-reviewer` | Java / Spring Boot code review | After writing or modifying any code |
| `quruhao-skills:security-reviewer` | Security analysis | Before commits touching auth, payments, or sensitive data |
| `quruhao-skills:build-error-resolver` | Java / Gradle build errors | When build or tests fail |

## When to Use Which Agent

| Situation | Agent tool call |
|-----------|----------------|
| New feature or architectural decision | Agent(subagent_type: "quruhao-skills:planner") |
| Writing new code or fixing a bug | Agent(subagent_type: "quruhao-skills:tdd-guide") |
| After any code change | Agent(subagent_type: "quruhao-skills:code-reviewer") |
| Build or test failure | Agent(subagent_type: "quruhao-skills:build-error-resolver") |
| Touching auth, payment, or PII | Agent(subagent_type: "quruhao-skills:security-reviewer") |

## Parallel Execution

For independent tasks, launch agents in parallel — never sequentially when tasks do not depend on each other.

```
// Example: parallel review
Agent(subagent_type: "quruhao-skills:security-reviewer", description: "Review auth changes")
Agent(subagent_type: "quruhao-skills:code-reviewer", description: "Review service layer")
```
