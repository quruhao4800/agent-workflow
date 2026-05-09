# Code Quality Standards

## File and Method Size

- Single method: ≤50 lines, cyclomatic complexity ≤10
- Single file: ≤800 lines — extract by responsibility when approaching limit
- Organize by feature/domain, not by type

## Naming Conventions (Java)

| Target | Convention | Example |
|--------|-----------|---------|
| Class / Interface | UpperCamelCase | `UserService`, `OrderMapper` |
| Abstract class | `Base` or `Abstract` prefix | `BaseService` |
| Method / variable | lowerCamelCase | `findById`, `userName` |
| Constant | UPPER_SNAKE_CASE | `MAX_RETRY = 3` |
| Boolean field | `is` / `has` / `can` prefix | `isActive`, `hasPermission` |
| Enum class | UpperCamelCase | `OrderStatus` |
| Enum value | UPPER_SNAKE_CASE | `PENDING`, `COMPLETED` |
| Package | all lowercase, dot-separated | `com.example.user` |

## Class Member Order

Constants → static fields → instance fields → constructors → methods

## Error Handling

- Never silently swallow exceptions — empty catch blocks are forbidden
- Always log with context: `logger.error("failed to process user {}: {}", userId, reason, e)`
- Business failures: throw typed `BusinessException`, not raw `RuntimeException`
- Do not expose internal stack traces or system details to API callers

## Input Validation

- Validate all external input at system boundaries (Controller layer)
- Use `@Valid` / `@Validated` on Controller `@RequestBody` and `@ModelAttribute` params
- Fail fast with a specific, actionable error message

## API Response Format

- All endpoints return a uniform response envelope
- Success: HTTP 2xx + `{"code": 0, "data": {...}}`
- Error: HTTP 4xx/5xx + `{"code": "ERROR_CODE", "message": "..."}`
- Paginated list: response includes `total`, `pageNum`, `pageSize`

## No Magic Numbers

Use named constants or enums for all numeric/string literals that carry business meaning.

```java
// BAD
if (status == 2) { ... }

// GOOD
if (status == OrderStatus.COMPLETED.getCode()) { ... }
```

## Imports

- Never use FQN inside method bodies — always use `import` statements
- Exception: two classes with the same simple name in scope
