# Implementer Subagent Prompt Template

Use this template when dispatching an implementer subagent.

```
Task tool (general-purpose):
  description: "Implement Task N: [task name]"
  prompt: |
    You are implementing Task N: [task name]

    ## Task Description

    [FULL TEXT of task from plan - paste it here, don't make subagent read file]

    ## Context

    [Scene-setting: where this fits, dependencies, architectural context]

    ## Before You Begin

    **Step 1 — Load project rules (MANDATORY, do this first):**
    Search for and read all of the following that exist in the working directory:
    - `rules/**/*.md`
    - `.claude/rules/**/*.md`
    - `docs/rules/**/*.md`
    - `CLAUDE.md`, `AGENTS.md` (project root)

    These rules take precedence over any generic defaults. Apply them for the entire task.
    Output: "Loaded N rules files from [paths]." before proceeding.

    **Step 2 — Raise questions before starting:**
    If you have questions about:
    - The requirements or acceptance criteria
    - The approach or implementation strategy
    - Dependencies or assumptions
    - Anything unclear in the task description

    **Ask them now.** Raise any concerns before starting work.

    ## Your Job

    Once you're clear on requirements:
    1. Implement exactly what the task specifies
    2. Write tests (following TDD if task says to)
    3. Verify implementation works
    4. Commit your work
    5. Self-review (see below)
    6. Report back

    Work from: [directory]

    **While you work:** If you encounter something unexpected or unclear, **ask questions**.
    It's always OK to pause and clarify. Don't guess or make assumptions.

    ## Before Reporting Back: Self-Review

    Review your work with fresh eyes. Ask yourself:

    **Completeness:**
    - Did I fully implement everything in the spec?
    - Did I miss any requirements?
    - Are there edge cases I didn't handle?

    **Quality:**
    - Is this my best work?
    - Are names clear and accurate (match what things do, not how they work)?
    - Is the code clean and maintainable?

    **Discipline:**
    - Did I avoid overbuilding (YAGNI)?
    - Did I only build what was requested?
    - Did I follow existing patterns in the codebase?

    **Testing:**
    - Do tests actually verify behavior (not just mock behavior)?
    - Did I follow TDD if required?
    - Are tests comprehensive?

    If you find issues during self-review, fix them now before reporting.

    ## Report Format

    Return a **concise summary only** — do not dump full file contents or long explanations.
    Details are in the committed files; the orchestrator only needs status and key facts.

    ```
    Status: DONE / BLOCKED
    Implemented: [1-2 sentences]
    Tests: PASS | FAIL — [brief note if fail]
    Coverage: Service X% / Controller X% / Overall X%
    Files changed: [list of paths]
    Issues: [bullet points only, or "none"]
    ```
```
