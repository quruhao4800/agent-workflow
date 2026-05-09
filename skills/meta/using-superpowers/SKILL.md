---
name: using-superpowers
description: Use when starting any conversation - establishes how to find and use skills, requiring Skill tool invocation before ANY response including clarifying questions
---

<EXTREMELY-IMPORTANT>
If you think there is even a 1% chance a skill might apply to what you are doing, you ABSOLUTELY MUST invoke the skill.

IF A SKILL APPLIES TO YOUR TASK, YOU DO NOT HAVE A CHOICE. YOU MUST USE IT.

This is not negotiable. This is not optional. You cannot rationalize your way out of this.
</EXTREMELY-IMPORTANT>

## How to Access Skills

**In Claude Code:** Use the `Skill` tool. When you invoke a skill, its content is loaded and presented to you鈥攆ollow it directly. Never use the Read tool on skill files.

**In other environments:** Check your platform's documentation for how skills are loaded.

# Using Skills

## The Rule

**Invoke relevant or requested skills BEFORE any response or action.** Even a 1% chance a skill might apply means that you should invoke the skill to check. If an invoked skill turns out to be wrong for the situation, you don't need to use it.

```dot
digraph skill_flow {
    "User message received" [shape=doublecircle];
    "About to EnterPlanMode?" [shape=doublecircle];
    "Already brainstormed?" [shape=diamond];
    "Invoke brainstorming skill" [shape=box];
    "Might any skill apply?" [shape=diamond];
    "Invoke Skill tool" [shape=box];
    "Announce: 'Using [skill] to [purpose]'" [shape=box];
    "Has checklist?" [shape=diamond];
    "Create TodoWrite todo per item" [shape=box];
    "Follow skill exactly" [shape=box];
    "Respond (including clarifications)" [shape=doublecircle];

    "About to EnterPlanMode?" -> "Already brainstormed?";
    "Already brainstormed?" -> "Invoke brainstorming skill" [label="no"];
    "Already brainstormed?" -> "Might any skill apply?" [label="yes"];
    "Invoke brainstorming skill" -> "Might any skill apply?";

    "User message received" -> "Might any skill apply?";
    "Might any skill apply?" -> "Invoke Skill tool" [label="yes, even 1%"];
    "Might any skill apply?" -> "Respond (including clarifications)" [label="definitely not"];
    "Invoke Skill tool" -> "Announce: 'Using [skill] to [purpose]'";
    "Announce: 'Using [skill] to [purpose]'" -> "Has checklist?";
    "Has checklist?" -> "Create TodoWrite todo per item" [label="yes"];
    "Has checklist?" -> "Follow skill exactly" [label="no"];
    "Create TodoWrite todo per item" -> "Follow skill exactly";
}
```

## Red Flags

These thoughts mean STOP鈥攜ou're rationalizing:

| Thought | Reality |
|---------|---------|
| "This is just a simple question" | Questions are tasks. Check for skills. |
| "I need more context first" | Skill check comes BEFORE clarifying questions. |
| "Let me explore the codebase first" | Skills tell you HOW to explore. Check first. |
| "I can check git/files quickly" | Files lack conversation context. Check for skills. |
| "Let me gather information first" | Skills tell you HOW to gather information. |
| "This doesn't need a formal skill" | If a skill exists, use it. |
| "I remember this skill" | Skills evolve. Read current version. |
| "This doesn't count as a task" | Action = task. Check for skills. |
| "The skill is overkill" | Simple things become complex. Use it. |
| "I'll just do this one thing first" | Check BEFORE doing anything. |
| "This feels productive" | Undisciplined action wastes time. Skills prevent this. |
| "I know what that means" | Knowing the concept 鈮?using the skill. Invoke it. |

## Skill Priority

When multiple skills could apply, use this order:

1. **Process skills first** (brainstorming, debugging) - these determine HOW to approach the task
2. **Implementation skills second** (frontend-design, mcp-builder) - these guide execution

"Let's build X" 鈫?brainstorming first, then implementation skills.
"Fix this bug" 鈫?debugging first, then domain-specific skills.

## Skill Types

**Rigid** (TDD, debugging): Follow exactly. Don't adapt away discipline.

**Flexible** (patterns): Adapt principles to context.

The skill itself tells you which.

## Pre-Modification Gate (MANDATORY BEFORE ANY FILE CHANGE)

Before executing any Edit, Write, or Delete operation, you MUST present a plan and wait for explicit confirmation.

### Required Output Format

```
## Plan

**Changes:**
1. [file path] — [what and why]
2. [file path] — [what and why]
...

**Expected outcome:** [one sentence]

Waiting for confirmation.
```

### Confirmation Rule

Only proceed after the user responds with an explicit confirmation (e.g., "yes", "go ahead", "确认", "可以").

### Exceptions — May Proceed Without Confirmation

- User has specified the exact operation with no ambiguity (e.g., "rename X to Y in file Z") AND only one file is affected.
- User explicitly granted advance authorization in the same message (e.g., "直接改", "you decide", "just do it").

### Cannot Be Bypassed — Always Confirm First

- Any change spanning 2 or more files.
- Any task where I am interpreting a goal into concrete actions (user stated WHAT, I am deciding HOW).
- Any file or directory deletion.

### Red Flags — STOP, Do Not Proceed

| Thought | Reality |
|---------|---------|
| "The user clearly wants this" | Clarity of intent ≠ confirmation to act. Present first. |
| "This is a small change" | Scope does not override the gate. |
| "I already explained what I'd do" | Explanation is not confirmation. Wait for the user's reply. |
| "We're in the middle of a task" | Mid-task changes still require confirmation per change set. |

## Project Standards Gate (MANDATORY BEFORE CODING)

Before writing or editing code, load project-specific standards first:

1. `rules/**/*.md` in the current project
2. Root instructions (`AGENTS.md`, `CLAUDE.md`, project docs)
3. Existing code patterns in nearby files
4. Lint/format/type configs (`eslint`, `prettier`, `checkstyle`, `spotbugs`, etc.)

Priority order: project rules > language/framework skill > generic defaults.

If project rules conflict with a generic skill, follow project rules.

## Error Memory Loop (DO NOT REPEAT MISTAKES)

When an error, failed review finding, or user correction appears:

1. Record it in a mistake log:
   - Project-level: `docs/plans/YYYY-MM-DD-<feature-name>/99-mistake-log.md`
   - Cross-project: `docs/memory/global-mistakes.md` (only reusable patterns)
2. Convert prevention into a concrete pre-check for the next similar step.
3. Re-check mistake logs before new edits and before claiming completion.

Minimum fields for each entry:
- `Mistake`
- `Trigger`
- `Prevention check`
- `Status` (`open`/`resolved`)

## External Research Persistence Gate

When using web search or external documents for task decisions:

1. Persist findings in `docs/plans/YYYY-MM-DD-<feature-name>/06-research-notes.md`.
2. Include: `Question`, `Source`, `Retrieved At`, `Key Findings`, `Decision Impact`, `Recheck Needed`.
3. If the insight is cross-project reusable, also add a distilled prevention/action entry to `docs/memory/global-mistakes.md` when relevant.

Do not rely on chat history alone for decision-critical external information.
## User Instructions

Instructions say WHAT, not HOW. "Add X" or "Fix Y" doesn't mean skip workflows.


