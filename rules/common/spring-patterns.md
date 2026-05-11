# Spring Boot Patterns

## Mandatory

Rules in this section block task completion and code submission when violated.

### @Transactional: No Private Methods

Never put `@Transactional` on a `private` method — Spring AOP proxy cannot intercept it;
the annotation is silently ignored and no transaction wraps the call.

```java
// BAD: silently ignored
@Transactional
private void saveInternal() { ... }

// GOOD: public method
@Transactional
public void save() { ... }
```

### @Transactional: No Swallowed Exceptions

Never catch an exception inside a `@Transactional` method without rethrowing — the transaction
commits even on failure, causing silent data inconsistency.

```java
// BAD: transaction commits on failure
@Transactional
public void process() {
    try {
        repo.save(entity);
    } catch (Exception e) {
        log.warn("failed"); // transaction still commits
    }
}

// GOOD: rethrow so transaction rolls back
@Transactional
public void process() {
    try {
        repo.save(entity);
    } catch (Exception e) {
        log.error("Failed to process {}", id, e);
        throw e;
    }
}
```

### @Async: No Same-Class Internal Calls

Never call an `@Async` method from within the same class — Spring AOP proxy is bypassed;
the method runs synchronously with no error or warning.

```java
// BAD: internal call bypasses proxy, runs synchronously
@Service
public class NotificationService {
    public void notify(Long userId) {
        sendEmail(userId); // proxy bypassed
    }

    @Async
    public void sendEmail(Long userId) { ... }
}

// GOOD: call through another bean
@Service
@RequiredArgsConstructor
public class OrderService {
    private final NotificationService notificationService;

    public void complete(Long orderId) {
        notificationService.sendEmail(orderId);
    }
}
```

### @Async: No void Return (Exceptions Silently Lost)

`@Async` methods returning `void` silently swallow exceptions — callers have no way to detect failure.
Always return `CompletableFuture<?>`.

```java
// BAD: exception silently lost
@Async
public void process() {
    throw new RuntimeException("failed"); // caller never knows
}

// GOOD
@Async
public CompletableFuture<Void> process() {
    try {
        // ...
        return CompletableFuture.completedFuture(null);
    } catch (Exception e) {
        return CompletableFuture.failedFuture(e);
    }
}
```

### @EnableAsync Must Be Present

`@EnableAsync` must be present on a `@Configuration` class when `@Async` is used — without it
all `@Async` annotations are silently ignored.

---

## Recommended

Rules in this section are flagged in review but do not block submission.

### Constructor Injection Over Field Injection

Prefer constructor injection over `@Autowired` on fields — enables immutability and easier unit testing.

```java
// BAD
@Autowired
private UserMapper userMapper;

// GOOD
@RequiredArgsConstructor
@Service
public class UserService {
    private final UserMapper userMapper;
}
```

### Layered Architecture

- Object conversion (DO → DTO / DTO → DO) should be done in a `XxxConverter` class, not in Service
- Entity/DO instances should be created via static factory methods (`Entity.create(...)`), not builder in Service
- Entity state transitions should go through entity business methods (`entity.expire()`), not direct setters
- Controller should delegate immediately to Service — no conditional logic or data transformation in Controller

```java
// BAD: conversion in Service
UserResponse response = new UserResponse();
response.setId(userDO.getId());

// GOOD: delegate to Converter
return UserConverter.toResponse(userDO);

// BAD: builder in Service
UserDO user = UserDO.builder().id(id).name(name).build();

// GOOD: static factory
UserDO user = UserDO.create(id, name);

// BAD: direct setter for state change
allocation.setStatus(AllocationStatusEnum.EXPIRED.getCode());

// GOOD: business method
allocation.expire();
```
