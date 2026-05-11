# Code Quality Standards

## Mandatory

Rules in this section block task completion and code submission when violated.

### No Empty Catch Blocks

Never silently swallow exceptions — empty catch blocks are forbidden.

```java
// BAD
try { repo.save(entity); } catch (Exception e) {}

// GOOD
try { repo.save(entity); } catch (Exception e) {
    log.error("Failed to save entity {}: {}", id, e.getMessage(), e);
    throw e;
}
```

### Do Not Expose Internal Details to API Callers

Never return stack traces, internal exception messages, or system details in API responses.

### Input Validation at Controller Boundary

Use `@Valid` / `@Validated` on all Controller `@RequestBody` and `@ModelAttribute` params.

### Uniform API Response Format

- Success: HTTP 2xx + `{"code": 0, "data": {...}}`
- Error: HTTP 4xx/5xx + `{"code": "ERROR_CODE", "message": "..."}`
- Paginated list: response includes `total`, `pageNum`, `pageSize`

### Logging Constraints

- Always use Lombok `@Slf4j` — never declare `Logger` manually
- Never use `System.out.println` or `e.printStackTrace()`
- Always use `{}` placeholders — never concatenate strings in log calls
- Always pass the exception object as the last argument: `log.error("msg: {}", id, e)`

```java
// BAD
System.out.println("user: " + userId);
log.error("failed: " + e.getMessage());
log.error("failed to process", e.getMessage());

// GOOD
log.info("Processing user {}", userId);
log.error("Failed to process user {}", userId, e);
```

---

## Recommended

Rules in this section are flagged in review but do not block submission. Exceptions are allowed when there is a clear reason.

### Method and File Size

- Business method: ≤50 lines, cyclomatic complexity ≤10
- Test method: ≤80 lines (Given/When/Then structure is naturally longer)
- Single file: ≤800 lines — extract by responsibility when approaching limit

### Naming Conventions (Java)

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

### Class Member Order

Constants → static fields → instance fields → constructors → methods

### Error Handling Style

- Log with context: `logger.error("failed to process user {}: {}", userId, reason, e)`
- Business failures: throw typed `BusinessException`, not raw `RuntimeException`

### No Magic Numbers

Use named constants or enums for all numeric/string literals that carry business meaning.

```java
// BAD
if (status == 2) { ... }

// GOOD
if (status == OrderStatus.COMPLETED.getCode()) { ... }
```

### Imports

Never use FQN inside method bodies — always use `import` statements.
Exception: two classes with the same simple name in scope.
