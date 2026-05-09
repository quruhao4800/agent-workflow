# Testing quruhao-skills Skills

This document describes how to test skills, particularly integration tests for complex skills like `subagent-driven-development`.

## Testing Methodology

### Quick Summary

1. **RED** — Run the scenario WITHOUT the skill. Record what the agent does wrong.
2. **GREEN** — Write/update the SKILL.md. Re-run. Agent should now comply.
3. **REFACTOR** — Agent found a new rationalization to skip the skill? Add explicit counter. Re-test.

### Integration Testing

For complex skills that invoke subagents:

```bash
# Ensure you're in the quruhao-skills directory
cd ~/quruhao-skills

# For Claude Code:
# 1. Install the plugin
/plugin install --path .

# 2. Start a new session and trigger the skill
# e.g., "Let's build a REST API" should trigger brainstorming → planning → subagent workflow
```

### What to Verify

- Skill is discovered and invoked automatically (not just when explicitly requested)
- Agent announces which skill it's using
- Agent follows the skill's steps in order
- Agent doesn't skip steps or rationalize skipping
- Subagents (if applicable) receive correct prompts and constraints
- Verification step produces actual evidence (command output, not just claims)
