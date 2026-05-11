# Security Standards

## Mandatory

All rules in this section block task completion and code submission when violated. No exceptions.

### No Hardcoded Credentials

Never hardcode API keys, passwords, tokens, or connection strings in source code or committed config files.
Use environment variables or a secrets manager. Validate required secrets are present at application startup.

### Parameterized Queries Only

All DB queries must use parameterized binding — `#{}` in MyBatis, never `${}`.
`${}` interpolation allows SQL injection regardless of input source.

```java
// BAD: SQL injection
@Select("SELECT * FROM user WHERE name = '${name}'")
User findByName(@Param("name") String name);

// GOOD: parameterized
@Select("SELECT * FROM user WHERE name = #{name}")
User findByName(@Param("name") String name);
```

### No Sensitive Data in Logs

Never log passwords, tokens, full card numbers, full ID numbers, or other PII in plain text.
Mask before logging where display is needed: `138****8888`.

### Input Validation at System Boundary

All external input must be validated at the Controller layer via `@Valid` / `@Validated`.

### Authentication Enforced on Protected Endpoints

Auth must be enforced at gateway or filter level for all protected endpoints. No endpoint may bypass auth without explicit allowlisting.

---

## When a Security Issue Is Found

1. STOP all other work immediately
2. Invoke `security-reviewer` agent
3. Fix CRITICAL issues before resuming any feature work
4. Rotate any exposed secrets
5. Grep the codebase for similar patterns before closing the issue
