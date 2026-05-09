---
name: springboot-patterns
description: Spring Boot architecture patterns, REST API design, layered services, data access, caching, async processing, and logging. Use for Java Spring Boot backend work.
---

# Spring Boot Development Patterns

## Tech Stack Detection (MANDATORY — run before applying any pattern)

Read `build.gradle` (or `pom.xml`) and identify:

| What to look for | Detected value | Section to apply |
|-----------------|---------------|-----------------|
| `mybatis-plus-boot-starter` / `mybatis-plus` | MyBatis Plus | → [Data Access: MyBatis Plus] |
| `spring-boot-starter-data-jpa` | Spring Data JPA | → [Data Access: Spring Data JPA] |
| `sourceCompatibility` / `languageVersion` ≥ 16 | Java 16+ | → DTO: use `record` |
| `sourceCompatibility` / `languageVersion` < 16 | Java 11–15 | → DTO: use `@Data` class |

If both ORMs are present, or neither is found, ask the user which to use before proceeding.

Output: `"Detected: [ORM], Java [version]. Applying [ORM] data access patterns and [record|@Data] DTO style."`

---

## Controller Layer (universal)

```java
@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    @GetMapping("/{id}")
    public BaseResp<UserResponse> getById(@PathVariable Long id) {
        return BaseResp.ok(userService.getById(id));
    }

    @PostMapping
    public BaseResp<UserResponse> create(@Valid @RequestBody CreateUserRequest request) {
        return BaseResp.ok(userService.create(request));
    }

    @GetMapping
    public BaseResp<Page<UserResponse>> list(@Valid PageRequest request) {
        return BaseResp.ok(userService.list(request));
    }
}
```

Rules:
- `@RequiredArgsConstructor` (Lombok) for constructor injection — never `@Autowired` on fields
- `@Valid` on every `@RequestBody` and `@ModelAttribute` param — without it, bean validation annotations on the DTO do not fire
- Controller delegates immediately to Service — no business logic, no conversion here
- Return uniform response envelope (`BaseResp` or equivalent defined in the project)

---

## Service Layer (universal)

```java
@Service
@RequiredArgsConstructor
public class UserServiceImpl implements UserService {

    private final UserMapper userMapper;      // MyBatis Plus — or UserRepository for JPA

    @Override
    @Transactional(readOnly = true)
    public UserResponse getById(Long id) {
        UserDO user = userMapper.selectById(id);
        if (user == null) {
            throw new BusinessException("User not found: " + id);
        }
        return UserConverter.toResponse(user);
    }

    @Override
    @Transactional
    public UserResponse create(CreateUserRequest request) {
        UserDO user = UserDO.create(request.getName(), request.getEmail());
        userMapper.insert(user);
        return UserConverter.toResponse(user);
    }
}
```

Rules:
- `@Transactional(readOnly = true)` on pure query methods
- `@Transactional` on all write methods
- **Never** put `@Transactional` on `private` methods — Spring AOP proxy cannot intercept them
- Object conversion is done via `XxxConverter` static methods — not inline in Service
- Entity DO creation via static factory `XxxDO.create(...)` — not Builder, not direct `new` + setters

---

## DTOs and Validation

### Java 11–15 (use @Data class)

```java
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateUserRequest {
    @NotBlank
    @Size(max = 100)
    private String name;

    @NotBlank
    @Email
    private String email;
}

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserResponse {
    private Long id;
    private String name;
    private String email;
}
```

### Java 16+ (use record)

```java
public record CreateUserRequest(
    @NotBlank @Size(max = 100) String name,
    @NotBlank @Email String email) {}

public record UserResponse(Long id, String name, String email) {}
```

---

## Converter Layer (universal)

```java
public class UserConverter {

    public static UserResponse toResponse(UserDO user) {
        return UserResponse.builder()
            .id(user.getId())
            .name(user.getName())
            .email(user.getEmail())
            .build();
    }

    public static UserDO toDO(CreateUserRequest request) {
        return UserDO.create(request.getName(), request.getEmail());
    }
}
```

Rules:
- All static methods — no Spring bean injection
- Named `XxxConverter`, placed in `convert` package
- Service calls `UserConverter.toResponse(entity)` — never maps fields inline

---

## Exception Handling (universal)

```java
@ControllerAdvice
@Slf4j
public class GlobalExceptionHandler {

    @ExceptionHandler(BusinessException.class)
    public ResponseEntity<BaseResp<Void>> handleBusiness(BusinessException ex) {
        log.warn("Business error: {}", ex.getMessage());
        return ResponseEntity.badRequest()
            .body(BaseResp.fail(ex.getCode(), ex.getMessage()));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<BaseResp<Void>> handleValidation(MethodArgumentNotValidException ex) {
        String message = ex.getBindingResult().getFieldErrors().stream()
            .map(e -> e.getField() + ": " + e.getDefaultMessage())
            .collect(Collectors.joining(", "));
        return ResponseEntity.badRequest()
            .body(BaseResp.fail("INVALID_PARAM", message));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<BaseResp<Void>> handleGeneric(Exception ex) {
        log.error("Unexpected error", ex);
        return ResponseEntity.internalServerError()
            .body(BaseResp.fail("INTERNAL_ERROR", "Internal server error"));
    }
}
```

---

## Data Access Layer — MyBatis Plus (apply only if detected)

```java
// Mapper interface
@Mapper
public interface UserMapper extends BaseMapper<UserDO> {
    // Simple CRUD: inherited from BaseMapper — no extra code needed

    // Complex query: define here, implement in XML
    List<UserDO> selectActiveByDept(@Param("deptId") Long deptId,
                                     @Param("page") Page<UserDO> page);
}
```

```xml
<!-- resources/mapper/UserMapper.xml -->
<mapper namespace="com.example.mapper.UserMapper">
    <select id="selectActiveByDept" resultType="com.example.entity.UserDO">
        SELECT * FROM user
        WHERE dept_id = #{deptId}
          AND status = 'ACTIVE'
        ORDER BY created_at DESC
    </select>
</mapper>
```

```java
// Common patterns
// Single record
UserDO user = userMapper.selectById(id);

// Condition query
List<UserDO> users = userMapper.selectList(
    new LambdaQueryWrapper<UserDO>()
        .eq(UserDO::getStatus, UserStatus.ACTIVE)
        .orderByDesc(UserDO::getCreatedAt)
);

// Paginated query
Page<UserDO> page = userMapper.selectPage(
    new Page<>(pageNum, pageSize),
    new LambdaQueryWrapper<UserDO>().eq(UserDO::getDeptId, deptId)
);

// Batch read — NEVER loop selectById
List<UserDO> users = userMapper.selectBatchIds(ids);

// Update via business method + updateById
user.activate();
userMapper.updateById(user);
```

Rules:
- Simple CRUD: use `BaseMapper` inherited methods
- Condition queries: use `LambdaQueryWrapper` (type-safe, refactor-safe)
- Complex multi-join or aggregation: XML mapper only — never inline SQL in `@Select` annotation
- List endpoints: always `selectPage` — never `selectList` without a limit
- Batch reads: `selectBatchIds(ids)` — never loop `selectById` (N+1)
- Never use `${}` in XML — always `#{}`

---

## Data Access Layer — Spring Data JPA (apply only if detected)

```java
// Repository interface
public interface UserRepository extends JpaRepository<UserDO, Long> {

    // Simple finders: Spring Data derives query from method name
    List<UserDO> findByDeptIdAndStatus(Long deptId, UserStatus status);

    // Complex query: use @Query with JPQL
    @Query("SELECT u FROM UserDO u WHERE u.deptId = :deptId AND u.status = 'ACTIVE' ORDER BY u.createdAt DESC")
    Page<UserDO> findActiveByDept(@Param("deptId") Long deptId, Pageable pageable);
}
```

```java
// Common patterns
// Single record
UserDO user = userRepository.findById(id)
    .orElseThrow(() -> new BusinessException("User not found: " + id));

// Paginated query
Page<UserDO> page = userRepository.findActiveByDept(
    deptId, PageRequest.of(pageNum, pageSize, Sort.by("createdAt").descending())
);

// Batch read
List<UserDO> users = userRepository.findAllById(ids);

// Save (insert or update)
UserDO saved = userRepository.save(user);
```

Rules:
- Use method-name queries for simple conditions
- Use `@Query` (JPQL) for joins and aggregations
- Always use `Pageable` on list queries — never return `List<T>` from user-facing endpoints
- `findById` returns `Optional<T>` — always handle the empty case explicitly

---

## Caching (universal)

Requires `@EnableCaching` on a `@Configuration` class.

```java
@Service
@RequiredArgsConstructor
@Slf4j
public class UserCacheService {

    private final UserMapper userMapper;  // or UserRepository

    @Cacheable(value = "user", key = "#id")
    @Transactional(readOnly = true)
    public UserResponse getById(Long id) {
        UserDO user = userMapper.selectById(id);
        if (user == null) throw new BusinessException("User not found: " + id);
        return UserConverter.toResponse(user);
    }

    @CacheEvict(value = "user", key = "#id")
    public void evict(Long id) {
        log.debug("Cache evicted for user {}", id);
    }
}
```

Cache-aside rule: write to DB first, evict/update cache after. Cache failure on write must throw to trigger DB rollback.

---

## Async Processing (universal)

Requires `@EnableAsync` on a `@Configuration` class.

```java
@Service
@Slf4j
public class NotificationService {

    @Async
    public CompletableFuture<Void> sendAsync(Long userId, String message) {
        log.info("Sending notification to user {}", userId);
        // send email / push / SMS
        return CompletableFuture.completedFuture(null);
    }
}
```

Rule: publish async calls **after** the enclosing `@Transactional` method commits — never inside the transaction, as rollback cannot cancel an already-dispatched async task.

---

## Logging (universal)

```java
@Service
@Slf4j  // Lombok — generates: private static final Logger log = LoggerFactory.getLogger(...)
public class OrderService {

    public OrderResponse process(Long orderId) {
        log.info("Processing order {}", orderId);
        try {
            // business logic
        } catch (BusinessException ex) {
            log.warn("Order {} rejected: {}", orderId, ex.getMessage());
            throw ex;
        } catch (Exception ex) {
            log.error("Order {} failed unexpectedly", orderId, ex);
            throw ex;
        }
        log.info("Order {} completed", orderId);
        return result;
    }
}
```

Rules:
- Use `@Slf4j` (Lombok) — never `LoggerFactory.getLogger()` manually
- Use parameterized logging: `log.info("user={}", id)` — never string concatenation
- Never log inside a loop at INFO or above — log summary before/after
- Never log passwords, tokens, or PII

---

## Scheduled Jobs (universal)

```java
@Component
@Slf4j
public class DailyReportJob {

    private final ReportService reportService;

    @Scheduled(cron = "0 0 2 * * ?")  // 02:00 daily
    public void run() {
        log.info("DailyReportJob started");
        try {
            reportService.generate();
        } catch (Exception ex) {
            log.error("DailyReportJob failed", ex);
            // scheduled jobs: log and continue — do not propagate
        }
        log.info("DailyReportJob completed");
    }
}
```

Rules:
- Always catch and log exceptions — let the scheduler reschedule normally
- Use a distributed lock (Redis / ShedLock) to prevent concurrent execution across instances
- Cross-tenant or system-level queries must bypass tenant filters

---

## External Call Resilience (universal)

```java
public <T> T withRetry(Supplier<T> call, int maxAttempts) {
    int attempt = 0;
    while (true) {
        try {
            return call.get();
        } catch (Exception ex) {
            attempt++;
            if (attempt >= maxAttempts) throw ex;
            long backoffMs = (long) Math.pow(2, attempt) * 100L;
            try { Thread.sleep(backoffMs); } catch (InterruptedException ie) {
                Thread.currentThread().interrupt();
                throw ex;
            }
        }
    }
}
```

For Feign clients: configure `Retryer`, `ErrorDecoder`, and `connectTimeout` / `readTimeout` explicitly. Never rely on defaults in production.

---

## Production Defaults (universal)

- Constructor injection everywhere (`@RequiredArgsConstructor`) — no field `@Autowired`
- `@Transactional(readOnly = true)` on all Service query methods
- Configure HikariCP pool size and connection timeout explicitly
- Structured logging (JSON) for production via Logback encoder
- Sensitive config (passwords, tokens, API keys) via environment variables — never hardcoded

**Remember**: thin controllers, focused services, ORM-appropriate data access, central error handling.
