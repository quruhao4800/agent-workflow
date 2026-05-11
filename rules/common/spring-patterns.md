# Spring Boot Patterns

## @Transactional Rules

- Never put `@Transactional` on a `private` method — Spring AOP proxy cannot intercept it; the annotation is silently ignored and no transaction wraps the call
- Never swallow exceptions inside `@Transactional` — catching an exception without rethrowing means the transaction commits even on failure; always rethrow or let exceptions propagate

```java
// BAD: @Transactional on private — silently ignored
@Transactional
private void saveInternal() { ... }

// BAD: swallowed exception — transaction commits on failure
@Transactional
public void process() {
    try {
        repo.save(entity);
    } catch (Exception e) {
        log.warn("failed"); // transaction still commits
    }
}

// GOOD: exception propagates — transaction rolls back
@Transactional
public void process() {
    try {
        repo.save(entity);
    } catch (Exception e) {
        log.error("failed to process: {}", id, e);
        throw e;
    }
}
```

## @Async Rules

- Never call an `@Async` method from within the same class — Spring AOP proxy cannot intercept internal calls; the method runs synchronously with no error
- `@Async` methods returning `void` silently swallow exceptions — always return `Future<?>` or `CompletableFuture<?>` so the caller can handle failures
- `@EnableAsync` must be present on a `@Configuration` class — without it all `@Async` annotations are silently ignored

```java
// BAD: internal call — @Async silently ignored, runs synchronously
@Service
public class NotificationService {
    public void notify(Long userId) {
        sendEmail(userId); // same-class call, proxy bypassed
    }

    @Async
    public void sendEmail(Long userId) { ... }
}

// GOOD: call from another bean
@Service
@RequiredArgsConstructor
public class OrderService {
    private final NotificationService notificationService;

    public void complete(Long orderId) {
        notificationService.sendEmail(orderId); // crosses proxy boundary
    }
}

// BAD: void @Async swallows exception silently
@Async
public void process() {
    throw new RuntimeException("failed"); // caller never knows
}

// GOOD: return CompletableFuture so caller can handle failure
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

## Dependency Injection

- Prefer constructor injection over `@Autowired` on fields — enables immutability and easier unit testing without Spring context

```java
// BAD: field injection
@Autowired
private UserMapper userMapper;

// GOOD: constructor injection (Lombok @RequiredArgsConstructor)
@RequiredArgsConstructor
@Service
public class UserService {
    private final UserMapper userMapper;
}
```

## Layered Architecture

- Object conversion (DO → DTO / DTO → DO) must be done in a `XxxConverter` class, not in Service
- Entity/DO instances must be created via static factory methods (`Entity.create(...)`), not via builder in Service layer
- Entity state transitions must go through entity business methods (`entity.expire()`), not direct field setters
- Controller must delegate immediately to Service — no conditional logic, data transformation, or business rules in Controller

```java
// BAD: conversion in Service
UserResponse response = new UserResponse();
response.setId(userDO.getId());
response.setName(userDO.getName());

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
