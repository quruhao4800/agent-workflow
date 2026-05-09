# Security Standards

## Mandatory Checks Before Any Commit

- [ ] No hardcoded credentials (API keys, passwords, tokens, connection strings)
- [ ] All DB queries use parameterized binding (`#{}` in MyBatis, never `${}`)
- [ ] No sensitive data in logs (passwords, tokens, PII, payment info)
- [ ] External input validated at Controller boundary (`@Valid` / `@Validated`)
- [ ] Auth enforced at gateway or filter level for all protected endpoints

## Secret Management

- NEVER hardcode secrets in source code or committed config files
- Use environment variables or a secrets manager
- Validate required secrets are present at application startup
- Rotate any secret that may have been exposed immediately

## When a Security Issue Is Found

1. STOP all other work immediately
2. Invoke `security-reviewer` agent
3. Fix CRITICAL issues before resuming any feature work
4. Rotate exposed secrets
5. Grep the codebase for similar patterns before closing the issue
