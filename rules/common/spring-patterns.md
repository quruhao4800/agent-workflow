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
