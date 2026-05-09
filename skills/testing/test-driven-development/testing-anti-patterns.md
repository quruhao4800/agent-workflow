# Testing Anti-Patterns

**Load this reference when:** writing or changing tests, adding mocks, or tempted to add test-only methods to production code.

## Overview

Tests must verify real behavior, not mock behavior. Mocks are a means to isolate, not the thing being tested.

**Core principle:** Test what the code does, not what the mocks do.

**Following strict TDD prevents these anti-patterns.**

## The Iron Laws

```
1. NEVER test mock behavior
2. NEVER add test-only methods to production classes
3. NEVER mock without understanding dependencies
```

## Anti-Pattern 1: Testing Mock Behavior

**The violation:**
```java
// BAD: The only assertion is that the mapper was called — proves nothing about service behavior
@Test
@DisplayName("getUser 调用了 mapper")
void getUser_callsMapper() {
    when(userMapper.selectById(1L)).thenReturn(new UserDO());

    userService.getById(1L);

    verify(userMapper).selectById(1L); // Tests implementation detail, not outcome
}
```

**Why this is wrong:**
- You're verifying the mock was invoked, not that the service returned the right value
- Test passes as long as the mapper is called once, regardless of what data comes back
- Tells you nothing about conversion, null-handling, or business logic

**your human partner's correction:** "Are we testing the behavior of a mock?"

**The fix:**
```java
// GOOD: Assert on what the service produces — the actual business outcome
@Test
@DisplayName("getUser 正确将 entity 转换为响应对象")
void getUser_convertsEntityToResponse() {
    UserDO user = new UserDO();
    user.setId(1L);
    user.setName("Alice");
    user.setEmail("alice@example.com");
    when(userMapper.selectById(1L)).thenReturn(user);

    UserResponse response = userService.getById(1L);

    assertThat(response.getName()).isEqualTo("Alice");
    assertThat(response.getEmail()).isEqualTo("alice@example.com");
}

// If mapper must be mocked for isolation:
// Don't stop at verify() — also assert on the returned value or state change
```

### Gate Function

```
BEFORE writing an assertion:
  Ask: "Am I asserting on the real service output or just on mock interactions?"

  IF asserting only on verify() with no outcome assertion:
    STOP — Add assertion on the actual return value or side effect

  Test real behavior instead
```

## Anti-Pattern 2: Test-Only Methods in Production

**The violation:**
```java
// BAD: resetForTest() is only ever called from test teardown
@Service
public class AssetServiceImpl implements AssetService {
    private BigDecimal cachedBalance;

    public void resetForTest() {  // Looks like production API!
        this.cachedBalance = null;
    }
}

// In test
@AfterEach
void cleanup() {
    assetService.resetForTest();
}
```

**Why this is wrong:**
- Production class polluted with test-only code
- Dangerous if accidentally called in production
- Violates YAGNI and separation of concerns
- Suggests service holds mutable state it shouldn't own

**The fix:**
```java
// GOOD: Service holds no test-only methods — cleanup is the test's responsibility

// AssetServiceImpl has no reset() — state lives in DB

// In test (slice test or integration test)
@AfterEach
void cleanup() {
    assetMapper.delete(new LambdaQueryWrapper<AssetDO>()
        .eq(AssetDO::getAdvId, TEST_ADV_ID));
}

// OR: use @Transactional on the test class — Spring rolls back after each test automatically
@SpringBootTest
@Transactional
class AssetServiceIntegrationTest { ... }
```

### Gate Function

```
BEFORE adding any method to a production class:
  Ask: "Is this only used by tests?"

  IF yes:
    STOP — Don't add it
    Handle cleanup in @AfterEach or use @Transactional rollback instead

  Ask: "Does this class own this resource's lifecycle?"

  IF no:
    STOP — Wrong class for this method
```

## Anti-Pattern 3: Mocking Without Understanding

**The violation:**
```java
// BAD: Mock swallows the DB write that the audit log depends on
@Test
@DisplayName("充值成功后写入审计日志")
void recharge_writesAuditLog() {
    // Mocking insert prevents the record being there for the audit query!
    doNothing().when(assetMapper).insert(any(AssetDO.class));

    assetService.recharge(advId, amount);

    // Audit log query finds nothing — test passes for the wrong reason
    verify(auditMapper).insert(any());
}
```

**Why this is wrong:**
- Mocked `insert` had a side effect (persisting the record) the audit step depended on
- Over-mocking to "be safe" breaks the actual behavior chain
- Test may pass or fail for reasons unrelated to the feature

**The fix:**
```java
// GOOD: Mock only what's slow or external — preserve the behavior the test needs
@ExtendWith(MockitoExtension.class)
class AssetServiceTest {

    @Mock RedisUtil redisUtil;        // External — mock it
    @Mock AuditMapper auditMapper;    // Verify this interaction
    @InjectMocks AssetServiceImpl assetService;

    // Keep assetMapper real via @MybatisPlusTest if the test needs actual DB writes
    // OR use ArgumentCaptor to verify what would have been persisted
    @Test
    @DisplayName("MySQL先于Redis更新，且写入审计日志")
    void recharge_mysqlBeforeRedisAndAuditWritten() {
        when(assetMapper.selectByAdvId(advId)).thenReturn(AssetDO.create(advId, BigDecimal.ZERO));
        when(redisUtil.hmIncrAtomic(anyString(), anyString(), any(), anyLong())).thenReturn(100.0);

        assetService.recharge(advId, amount);

        InOrder order = inOrder(assetMapper, redisUtil, auditMapper);
        order.verify(assetMapper).updateByIdIgnoreTenant(any());
        order.verify(redisUtil).hmIncrAtomic(anyString(), anyString(), any(), anyLong());
        order.verify(auditMapper).insert(any());
    }
}
```

### Gate Function

```
BEFORE mocking any method:
  STOP — Don't mock yet

  1. Ask: "What side effects does the real method have?"
  2. Ask: "Does this test depend on any of those side effects?"
  3. Ask: "Do I fully understand what this test needs?"

  IF depends on side effects:
    Mock at lower level (the actual slow/external operation)
    OR use test doubles that preserve necessary behavior
    NOT the high-level method the test depends on

  IF unsure what test depends on:
    Run test with real implementation FIRST
    Observe what actually needs to happen
    THEN add minimal mocking at the right level

  Red flags:
    - "I'll mock this to be safe"
    - "This might be slow, better mock it"
    - Mocking without understanding the dependency chain
```

## Anti-Pattern 4: Incomplete Mocks

**The violation:**
```java
// BAD: Only populate the field you think you need right now
AssetDO mockAsset = new AssetDO();
mockAsset.setAdvId(1L);
// Missing: packageBalance, status, version — the update logic uses all of them

when(assetMapper.selectByAdvId(1L)).thenReturn(mockAsset);
// Result: NullPointerException or wrong balance calculation in service logic
```

**Why this is wrong:**
- **Partial mocks hide structural assumptions** — you only set fields you know about today
- **Downstream logic may read fields you didn't set** — silent NPE or wrong result
- **Tests pass but real behavior breaks** — mock incomplete, real DB record complete
- **False confidence** — test proves nothing about actual data flow

**The Iron Rule:** Mock the COMPLETE data structure as it exists in reality, not just fields your immediate test uses.

**The fix:**
```java
// GOOD: Use the static factory — it mirrors what production code creates
AssetDO mockAsset = AssetDO.create(1L, new BigDecimal("500.00"));
// Static factory ensures packageBalance, status, version are all set correctly

when(assetMapper.selectByAdvId(1L)).thenReturn(mockAsset);

// OR: build a TestFixture helper that represents a canonical "valid" entity
public class AssetFixture {
    public static AssetDO validAsset(Long advId) {
        AssetDO asset = AssetDO.create(advId, new BigDecimal("100.00"));
        asset.setStatus(AssetStatus.ACTIVE);
        return asset;
    }
}
```

### Gate Function

```
BEFORE creating a mock entity:
  Check: "What fields does the real DB record contain?"

  Actions:
    1. Look at the entity DO class — all fields that matter
    2. Prefer the static factory (XxxDO.create(...)) over manual new + setters
    3. If factory doesn't exist, set ALL fields the service logic reads

  Critical:
    If you're stubbing a mapper return, you must populate the complete entity
    Partial stubs fail silently when service reads unset fields

  If uncertain: use the static factory or add missing fields
```

## Anti-Pattern 5: Integration Tests as Afterthought

**The violation:**
```
✅ Implementation complete
❌ No tests written
"Ready for testing"
```

**Why this is wrong:**
- Testing is part of implementation, not optional follow-up
- TDD would have caught this
- Can't claim complete without tests

**The fix:**
```
TDD cycle:
1. Write failing test (@Test, compile error acceptable)
2. Implement minimal code to make it pass
3. Refactor — tests stay green
4. THEN claim complete
```

## When Mocks Become Too Complex

**Warning signs:**
- Mock setup longer than test logic
- Mocking everything to make test pass
- Mocks missing fields real entities have
- Test breaks when mock changes

**your human partner's question:** "Do we need to be using a mock here?"

**Consider:** `@MybatisPlusTest` slice or `@SpringBootTest` + `@Transactional` integration tests are often simpler than elaborate mock setups

## TDD Prevents These Anti-Patterns

**Why TDD helps:**
1. **Write test first** → Forces you to think about what you're actually testing
2. **Watch it fail** → Confirms test tests real behavior, not mocks
3. **Minimal implementation** → No test-only methods creep in
4. **Real dependencies** → You see what the test actually needs before mocking

**If you're testing mock behavior, you violated TDD** — you added mocks without watching the test fail against real code first.

## Quick Reference

| Anti-Pattern | Fix |
|--------------|-----|
| Only `verify()`, no outcome assertion | Also assert on return value or state change |
| Test-only methods in production class | Use `@AfterEach` cleanup or `@Transactional` rollback |
| Mock without understanding side effects | Understand dependency chain first, mock minimally |
| Incomplete entity stubs | Use static factory (`XxxDO.create(...)`) or set all fields |
| Tests as afterthought | TDD — failing test first |
| Over-complex mock setup | Consider `@MybatisPlusTest` / `@SpringBootTest` slice |

## Red Flags

- Assertion only checks `verify()` with no business outcome assertion
- Methods only called in `@AfterEach` or test setup
- `when(...).thenReturn(new XxxDO())` with no fields set
- Mock setup is >50% of test
- Test fails when you remove mock
- Can't explain why mock is needed
- Mocking "just to be safe"

## The Bottom Line

**Mocks are tools to isolate, not things to test.**

If TDD reveals you're testing mock behavior, you've gone wrong.

Fix: Test real behavior or question why you're mocking at all.
