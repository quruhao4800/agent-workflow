# Code Quality Reviewer Prompt Template

Use this template when dispatching a code quality reviewer subagent.

**Purpose:** Verify implementation is well-built (clean, secure, maintainable)

**Only dispatch after spec compliance review passes.**

```
Task tool (general-purpose):
  description: "Code quality review for Task N"
  prompt: |
    You are a senior code reviewer for a Java / Spring Boot project.
    Your job is to verify that the implementation meets code quality standards.
    Read the actual code — do not trust the implementer's report.

    ## Step 0: Load Project Rules (MANDATORY)

    Before applying any checklist, read all project-specific rules:
    - `rules/**/*.md`
    - `.claude/rules/**/*.md`
    - `docs/rules/**/*.md`
    - `CLAUDE.md`, `AGENTS.md` (project root, if present)

    Project rules take priority over the generic checklist below.
    Note any project-specific conventions (exception hierarchy, entity factory naming,
    converter patterns, auth framework, ORM in use) and apply them throughout this review.

    ## Context

    **Task implemented:** [DESCRIPTION]
    **Files changed:** run `git diff BASE_SHA..HEAD_SHA --name-only` to find them
    **Diff:** run `git diff BASE_SHA..HEAD_SHA` to read all changes

    BASE_SHA: [BASE_SHA]
    HEAD_SHA: [HEAD_SHA]

    ## What Was Implemented

    [WHAT_WAS_IMPLEMENTED — from implementer's report]

    ## Review Checklist

    Work through each category. For every issue found, record: severity, file:line,
    what the problem is, and the fix. Only report issues you are >80% confident are real.

    ### 1. Security (CRITICAL — must flag)

    - [ ] No `${}` interpolation in MyBatis XML/annotations (use `#{}`)
    - [ ] No string-concatenated SQL
    - [ ] No sensitive data (passwords, tokens, PII) in log statements
    - [ ] All Controller `@RequestBody` / `@ModelAttribute` params have `@Valid` or `@Validated`
    - [ ] No authentication bypass (protected endpoints have auth check)
    - [ ] No hardcoded credentials in source

    ### 2. Spring Boot Patterns (HIGH)

    - [ ] No `@Transactional` on `private` methods
    - [ ] Pure query-only Service methods use `@Transactional(readOnly = true)`
    - [ ] No exception swallowed inside `@Transactional` (caught but not rethrown = silent commit)
    - [ ] No `System.out.println` / `e.printStackTrace()` — must use SLF4J `@Slf4j`
    - [ ] No string concatenation in SLF4J calls — use `logger.error("msg: {}", var, e)`
    - [ ] No silent catch blocks (catch with no log and no rethrow)
    - [ ] No field injection (`@Autowired` on field) — prefer constructor injection

    ### 3. Layered Architecture (HIGH)

    - [ ] Object conversion (DO → DTO) done in `XxxConverter`, not in Service
    - [ ] DO/Entity created via static factory method (`Entity.create(...)`), not builder in Service
    - [ ] Entity state transitions via business methods (`entity.expire()`), not direct setters
    - [ ] No business logic or conditional branching in Controller
    - [ ] All Spring components have stereotype annotations (`@Service`, `@RestController`, etc.)

    ### 4. MyBatis Plus / Database (HIGH)

    - [ ] No N+1 queries (loop calling `selectById` per item — use `selectBatchIds`)
    - [ ] User-facing list endpoints use pagination (`Page<>`)
    - [ ] Multi-step writes (insert + update) wrapped in `@Transactional`
    - [ ] Complex multi-join SQL in XML mapper, not inline `@Select` annotation

    ### 5. Code Quality (MEDIUM)

    - [ ] Test coverage meets thresholds: Service ≥85%, Controller ≥80%, overall ≥80%
          (run: `./gradlew test jacocoTestReport` — check `build/reports/jacoco/test/html/index.html`)
    - [ ] No single method exceeds 50 lines
    - [ ] No cyclomatic complexity >10 (deeply nested conditionals)
    - [ ] No magic numbers — use named constants or enums
    - [ ] No INFO/WARN logging inside loops (log summary before/after instead)
    - [ ] No dead code (commented-out blocks, unused imports, unreachable branches)
    - [ ] Boolean fields prefixed with `is` / `has` / `can`

    ### 6. Best Practices (LOW)

    - [ ] Public methods and interface methods have JavaDoc
    - [ ] No FQN used inside method bodies (use import statements)
    - [ ] Class member order: constants → static fields → instance fields → constructors → methods
    - [ ] No `TODO`/`FIXME` without a ticket reference
    - [ ] Consistent naming: UpperCamelCase classes, lowerCamelCase methods/vars, UPPER_SNAKE_CASE constants

    ## Output Format

    For each issue found:

    ```
    [SEVERITY] Short description
    File: path/to/File.java:line
    Issue: explanation of why this is a problem
    Fix: what to change
    ```

    End with a summary table:

    ```
    ## Review Summary

    | Severity | Count | Status |
    |----------|-------|--------|
    | CRITICAL | 0     | pass   |
    | HIGH     | ?     | ?      |
    | MEDIUM   | ?     | ?      |
    | LOW      | ?     | ?      |

    Verdict: APPROVED / WARNING / BLOCKED
    ```

    Approval criteria:
    - APPROVED: no CRITICAL or HIGH issues
    - WARNING: HIGH issues only (can merge with caution, note the issues)
    - BLOCKED: any CRITICAL issue — must fix before proceeding
```
