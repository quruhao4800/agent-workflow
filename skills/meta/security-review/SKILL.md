---
name: security-review
description: Use this skill when adding authentication, handling user input, working with secrets, creating API endpoints, or implementing payment/sensitive features. Provides comprehensive security checklist and patterns for Java/Spring Boot.
---

# Security Review Skill

This skill ensures all code follows security best practices and identifies potential vulnerabilities.

## When to Activate

- Implementing authentication or authorization
- Handling user input or file uploads
- Creating new API endpoints
- Working with secrets or credentials
- Implementing payment features
- Storing or transmitting sensitive data
- Integrating third-party APIs

## Security Checklist

### 1. Secrets Management

#### ❌ NEVER Do This
```java
private static final String API_KEY = "sk-proj-xxxxx";  // Hardcoded secret
private static final String DB_PASSWORD = "password123"; // In source code
```

#### ✅ ALWAYS Do This
```java
// application.yml
// api.key: ${API_KEY}

@Value("${api.key}")
private String apiKey;

// Or use @ConfigurationProperties
@ConfigurationProperties(prefix = "app")
public record AppConfig(String apiKey, String dbUrl) {}
```

#### Verification Steps
- [ ] No hardcoded API keys, tokens, or passwords in source code
- [ ] All secrets in environment variables or Vault
- [ ] `.env` files in `.gitignore`
- [ ] No secrets in git history
- [ ] Production secrets managed via environment configuration

### 2. Input Validation

#### Always Validate User Input (Bean Validation)
```java
public record CreateUserRequest(
    @NotBlank @Email String email,
    @NotBlank @Size(min = 1, max = 100) String name,
    @Min(0) @Max(150) Integer age
) {}

@RestController
@Validated
public class UserController {
    @PostMapping("/api/v1/users")
    public ResponseEntity<UserResponse> createUser(
            @RequestBody @Valid CreateUserRequest request) {
        return ResponseEntity.status(201).body(userService.create(request));
    }
}
```

#### File Upload Validation
```java
@PostMapping("/upload")
public ResponseEntity<String> upload(@RequestParam MultipartFile file) {
    long maxSize = 5 * 1024 * 1024; // 5MB
    if (file.getSize() > maxSize) {
        throw new IllegalArgumentException("File too large (max 5MB)");
    }

    List<String> allowedTypes = List.of("image/jpeg", "image/png", "image/gif");
    if (!allowedTypes.contains(file.getContentType())) {
        throw new IllegalArgumentException("Invalid file type");
    }

    String filename = StringUtils.cleanPath(file.getOriginalFilename());
    if (filename.contains("..")) {
        throw new IllegalArgumentException("Invalid file path");
    }

    return ResponseEntity.ok("Uploaded");
}
```

#### Verification Steps
- [ ] All user inputs validated with `@Valid` and Bean Validation annotations
- [ ] File uploads restricted (size, type, path traversal check)
- [ ] No direct use of user input in queries
- [ ] Whitelist validation (not blacklist)
- [ ] Error messages don't leak sensitive info

### 3. SQL Injection Prevention

#### ❌ NEVER Concatenate SQL
```java
// DANGEROUS - SQL Injection vulnerability
String query = "SELECT * FROM users WHERE email = '" + userEmail + "'";
jdbcTemplate.query(query, ...);
```

#### ✅ ALWAYS Use Parameterized Queries
```java
// Safe - parameterized query with JdbcTemplate
String sql = "SELECT * FROM users WHERE email = ?";
jdbcTemplate.query(sql, rowMapper, userEmail);

// Safe - JPA/JPQL named parameter
@Query("SELECT u FROM User u WHERE u.email = :email")
Optional<User> findByEmail(@Param("email") String email);

// Safe - Spring Data method naming (automatically parameterized)
Optional<User> findByEmail(String email);
```

#### Verification Steps
- [ ] All database queries use parameterized queries or JPA
- [ ] No string concatenation in SQL
- [ ] No native queries with string interpolation
- [ ] JPQL or Criteria API used for dynamic queries

### 4. Authentication & Authorization

#### Spring Security Configuration
```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .csrf(csrf -> csrf.csrfTokenRepository(CookieCsrfTokenRepository.withHttpOnlyFalse()))
            .sessionManagement(sm -> sm.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/v1/auth/**").permitAll()
                .requestMatchers("/api/v1/admin/**").hasRole("ADMIN")
                .anyRequest().authenticated()
            )
            .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class);
        return http.build();
    }
}
```

#### Authorization Checks
```java
@PreAuthorize("hasRole('ADMIN') or #userId == authentication.name")
@DeleteMapping("/api/v1/users/{userId}")
public ResponseEntity<Void> deleteUser(@PathVariable String userId) {
    userService.delete(userId);
    return ResponseEntity.noContent().build();
}
```

#### Verification Steps
- [ ] JWT tokens validated on every request
- [ ] `@PreAuthorize` or security filter used for authorization
- [ ] Role-based access control implemented
- [ ] Tokens not logged or exposed in error messages
- [ ] Session management correctly configured (stateless for APIs)

### 5. XSS Prevention

#### Sanitize Output in Responses
```java
// If returning user-provided content as HTML, sanitize it
// Use OWASP Java HTML Sanitizer

PolicyFactory policy = Sanitizers.FORMATTING.and(Sanitizers.LINKS);
String safeHtml = policy.sanitize(userProvidedHtml);
```

#### Content Security Policy Header
```java
@Component
public class SecurityHeadersFilter extends OncePerRequestFilter {
    @Override
    protected void doFilterInternal(HttpServletRequest request,
            HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        response.setHeader("Content-Security-Policy",
            "default-src 'self'; script-src 'self'; img-src 'self' data: https:;");
        response.setHeader("X-Content-Type-Options", "nosniff");
        response.setHeader("X-Frame-Options", "DENY");
        chain.doFilter(request, response);
    }
}
```

#### Verification Steps
- [ ] User-provided HTML sanitized before rendering
- [ ] CSP headers configured
- [ ] `X-Content-Type-Options: nosniff` set
- [ ] `X-Frame-Options: DENY` set

### 6. CSRF Protection

```java
// Spring Security CSRF is enabled by default for stateful apps
// For stateless JWT APIs, CSRF is not needed but session fixation must be prevented
http.csrf(AbstractHttpConfigurer::disable)  // Only for stateless JWT APIs
    .sessionManagement(sm -> sm.sessionCreationPolicy(SessionCreationPolicy.STATELESS));

// For stateful apps (e.g. admin panel with sessions):
http.csrf(csrf -> csrf.csrfTokenRepository(CookieCsrfTokenRepository.withHttpOnlyFalse()));
```

#### Verification Steps
- [ ] CSRF enabled for stateful session-based endpoints
- [ ] Stateless JWT APIs have `SessionCreationPolicy.STATELESS`
- [ ] SameSite cookie attribute set where appropriate

### 7. Rate Limiting

#### With Bucket4j (Spring Boot)
```java
@Component
public class RateLimitingFilter extends OncePerRequestFilter {
    private final Map<String, Bucket> cache = new ConcurrentHashMap<>();

    private Bucket createNewBucket() {
        Bandwidth limit = Bandwidth.classic(100, Refill.greedy(100, Duration.ofMinutes(1)));
        return Bucket.builder().addLimit(limit).build();
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
            HttpServletResponse response, FilterChain chain) throws ServletException, IOException {
        String ip = request.getRemoteAddr();
        Bucket bucket = cache.computeIfAbsent(ip, k -> createNewBucket());

        if (bucket.tryConsume(1)) {
            chain.doFilter(request, response);
        } else {
            response.setStatus(HttpStatus.TOO_MANY_REQUESTS.value());
            response.getWriter().write("{\"error\":{\"code\":\"rate_limit_exceeded\"}}");
        }
    }
}
```

#### Verification Steps
- [ ] Rate limiting on all public API endpoints
- [ ] Stricter limits on expensive operations (search, export)
- [ ] `429 Too Many Requests` returned with `Retry-After` header

### 8. Sensitive Data Exposure

#### Logging
```java
// ❌ WRONG: Logging sensitive data
log.info("User login: email={}, password={}", email, password);
log.info("Payment: cardNumber={}, cvv={}", cardNumber, cvv);

// ✅ CORRECT: Redact sensitive data
log.info("User login: email={}, userId={}", email, userId);
log.info("Payment: last4={}, userId={}", card.getLast4(), userId);
```

#### Error Messages
```java
// ❌ WRONG: Exposing internal details
@ExceptionHandler(Exception.class)
public ResponseEntity<Map<String, Object>> handleException(Exception e) {
    return ResponseEntity.status(500).body(Map.of(
        "error", e.getMessage(),
        "stackTrace", Arrays.toString(e.getStackTrace())
    ));
}

// ✅ CORRECT: Generic error messages
@ExceptionHandler(Exception.class)
public ResponseEntity<Map<String, Object>> handleException(Exception e) {
    log.error("Internal error", e);
    return ResponseEntity.status(500).body(Map.of(
        "error", Map.of("code", "internal_error",
                        "message", "An error occurred. Please try again.")
    ));
}
```

#### Verification Steps
- [ ] No passwords, tokens, or secrets in logs
- [ ] Error messages generic for users
- [ ] Detailed errors only in server logs
- [ ] No stack traces exposed in API responses

### 9. Dependency Security

#### Regular Updates
```bash
# Check for vulnerabilities (OWASP Dependency Check)
./gradlew dependencyCheckAnalyze

# List outdated dependencies
./gradlew dependencyUpdates

# Check direct dependencies
./gradlew dependencies --configuration runtimeClasspath
```

#### Verification Steps
- [ ] OWASP Dependency Check passes with no critical CVEs
- [ ] Dependencies up to date
- [ ] Lock file (`gradle.lockfile`) committed for reproducible builds
- [ ] Dependabot or Renovate enabled on GitHub

## Security Testing

### Automated Security Tests (JUnit 5)
```java
// Test authentication required
@Test
void protectedEndpointRequiresAuthentication() throws Exception {
    mockMvc.perform(get("/api/v1/users"))
        .andExpect(status().isUnauthorized());
}

// Test authorization
@Test
@WithMockUser(roles = "USER")
void adminEndpointForbiddenForUser() throws Exception {
    mockMvc.perform(delete("/api/v1/admin/users/123"))
        .andExpect(status().isForbidden());
}

// Test input validation
@Test
void rejectsInvalidEmail() throws Exception {
    String body = """{"email": "not-an-email", "name": "Test"}""";
    mockMvc.perform(post("/api/v1/users")
            .contentType(MediaType.APPLICATION_JSON)
            .content(body))
        .andExpect(status().isBadRequest());
}
```

## Pre-Deployment Security Checklist

Before ANY production deployment:

- [ ] **Secrets**: No hardcoded secrets, all in env vars or Vault
- [ ] **Input Validation**: All user inputs validated with `@Valid`
- [ ] **SQL Injection**: All queries parameterized or using JPA
- [ ] **XSS**: User-provided HTML sanitized, CSP headers set
- [ ] **CSRF**: Protection configured for session-based endpoints
- [ ] **Authentication**: Spring Security configured correctly
- [ ] **Authorization**: `@PreAuthorize` or security filters in place
- [ ] **Rate Limiting**: Enabled on public endpoints
- [ ] **HTTPS**: Enforced in production
- [ ] **Error Handling**: No stack traces or internal details in responses
- [ ] **Logging**: No sensitive data logged
- [ ] **Dependencies**: OWASP check passes, no critical CVEs
- [ ] **CORS**: Properly configured for allowed origins
- [ ] **File Uploads**: Validated (size, type, path traversal)

## Resources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Spring Security Reference](https://docs.spring.io/spring-security/reference/)
- [OWASP Java HTML Sanitizer](https://github.com/OWASP/java-html-sanitizer)
- [Bucket4j Rate Limiting](https://bucket4j.com/)

---

**Remember**: Security is not optional. One vulnerability can compromise the entire platform. When in doubt, err on the side of caution.
