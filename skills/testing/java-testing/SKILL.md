---
name: java-testing
description: Java testing patterns for Spring Boot projects using JUnit 5, Mockito, MockMvc, and MyBatis Plus. Follows TDD methodology with layered test strategies.
---

# Java Testing Patterns

Comprehensive testing patterns for Spring Boot + MyBatis Plus projects following TDD methodology.

## When to Activate

- Writing new Java methods, services, or controllers
- Adding test coverage to existing code
- Following TDD workflow in Spring Boot projects
- Testing MyBatis Plus mapper queries
- Verifying REST API behavior with MockMvc

## TDD Workflow for Java

```
RED     → Write a failing test first (@Test, compile error is acceptable)
GREEN   → Write minimal code to pass the test
REFACTOR → Improve code while keeping tests green
REPEAT  → Continue with next requirement
```

## Test Layering Strategy

| Layer | Tool | Scope |
|-------|------|-------|
| Unit | JUnit 5 + Mockito | Service, Converter, Entity business methods |
| Slice | `@WebMvcTest` + MockMvc | Controller layer only |
| Slice | `@DataJpaTest` / MyBatis slice | Mapper + SQL queries |
| Integration | `@SpringBootTest` | Full context, critical flows only |

Prefer unit and slice tests. Use `@SpringBootTest` sparingly — it is slow.

## Unit Tests (Service Layer)

```java
@ExtendWith(MockitoExtension.class)
class AssetServiceTest {

    @InjectMocks
    private AssetServiceImpl assetService;

    @Mock
    private AssetMapper assetMapper;

    @Mock
    private RedisUtil redisUtil;

    @Test
    @DisplayName("充值成功：MySQL更新后Redis递增")
    void recharge_success() {
        // Arrange
        Long advId = 1L;
        BigDecimal amount = new BigDecimal("100.00");
        AssetDO asset = AssetDO.create(advId, amount);
        when(assetMapper.selectByAdvId(advId)).thenReturn(asset);
        when(redisUtil.hmIncrAtomic(anyString(), anyString(), any(), anyLong()))
                .thenReturn(100.0);

        // Act
        assetService.recharge(advId, amount);

        // Assert
        verify(assetMapper).updateByIdIgnoreTenant(any(AssetDO.class));
        verify(redisUtil).hmIncrAtomic(anyString(), anyString(), any(), anyLong());
    }

    @Test
    @DisplayName("Redis失败时抛出BusinessException触发MySQL回滚")
    void recharge_redisFailure_throwsBusinessException() {
        Long advId = 1L;
        when(assetMapper.selectByAdvId(advId)).thenReturn(AssetDO.create(advId, BigDecimal.ZERO));
        when(redisUtil.hmIncrAtomic(anyString(), anyString(), any(), anyLong()))
                .thenReturn(null); // Redis failure

        assertThrows(BusinessException.class, () -> assetService.recharge(advId, new BigDecimal("50")));
    }
}
```

## Parameterized Tests

Use `@ParameterizedTest` for table-driven cases — the Java equivalent of Go's table-driven tests.

```java
@ParameterizedTest(name = "{0}")
@MethodSource("rechargeAmountProvider")
@DisplayName("充值金额边界校验")
void recharge_amountBoundary(String scenario, BigDecimal amount, boolean shouldThrow) {
    if (shouldThrow) {
        assertThrows(BusinessException.class, () -> assetService.recharge(1L, amount));
    } else {
        assertDoesNotThrow(() -> assetService.recharge(1L, amount));
    }
}

static Stream<Arguments> rechargeAmountProvider() {
    return Stream.of(
        Arguments.of("零金额拒绝", BigDecimal.ZERO, true),
        Arguments.of("负金额拒绝", new BigDecimal("-1"), true),
        Arguments.of("正常金额通过", new BigDecimal("100"), false),
        Arguments.of("最小金额通过", new BigDecimal("0.01"), false)
    );
}
```

## Controller Slice Test (MockMvc)

```java
@WebMvcTest(AssetController.class)
class AssetControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private AssetService assetService;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    @DisplayName("充值接口：参数合法时返回200")
    void recharge_validRequest_returns200() throws Exception {
        RechargeReq req = new RechargeReq();
        req.setAdvId(1L);
        req.setAmount(new BigDecimal("100.00"));

        mockMvc.perform(post("/asset/recharge")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true));
    }

    @Test
    @DisplayName("充值接口：金额为空时返回400")
    void recharge_missingAmount_returns400() throws Exception {
        mockMvc.perform(post("/asset/recharge")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{}"))
            .andExpect(status().isBadRequest());
    }
}
```

## MyBatis Plus Mapper Test

```java
@MybatisPlusTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@TestPropertySource(locations = "classpath:application-test.yml")
class AssetMapperTest {

    @Autowired
    private AssetMapper assetMapper;

    @Test
    @DisplayName("按advId查询资产")
    void selectByAdvId_existingId_returnsAsset() {
        // Arrange — use @Sql or insert directly
        AssetDO asset = AssetDO.create(999L, new BigDecimal("500.00"));
        assetMapper.insert(asset);

        // Act
        AssetDO result = assetMapper.selectByAdvId(999L);

        // Assert
        assertThat(result).isNotNull();
        assertThat(result.getPackageBalance()).isEqualByComparingTo("500.00");
    }

    @Test
    @DisplayName("跨租户查询：@InterceptorIgnore 不添加 WHERE adv_id 条件")
    void selectListIgnoreTenant_returnsAllTenants() {
        List<AssetDO> results = assetMapper.selectListIgnoreTenant(new QueryWrapper<>());
        // Should include records from multiple advIds without filtering
        assertThat(results).isNotEmpty();
    }
}
```

## Mockito Patterns

### Verify Interaction Order

```java
@Test
@DisplayName("MySQL先于Redis更新")
void update_mysqlBeforeRedis() {
    InOrder inOrder = inOrder(assetMapper, redisUtil);

    assetService.recharge(1L, new BigDecimal("100"));

    inOrder.verify(assetMapper).updateByIdIgnoreTenant(any());
    inOrder.verify(redisUtil).hmIncrAtomic(anyString(), anyString(), any(), anyLong());
}
```

### Capture Arguments

```java
@Test
@DisplayName("创建资产时使用静态工厂方法")
void createAsset_usesStaticFactory() {
    ArgumentCaptor<AssetDO> captor = ArgumentCaptor.forClass(AssetDO.class);

    assetService.initAsset(1L);

    verify(assetMapper).insert(captor.capture());
    AssetDO saved = captor.getValue();
    assertThat(saved.getAdvId()).isEqualTo(1L);
    assertThat(saved.getPackageBalance()).isEqualByComparingTo(BigDecimal.ZERO);
}
```

## Test Coverage with JaCoCo

```groovy
// build.gradle
jacocoTestReport {
    reports {
        xml.required = true
        html.required = true
    }
}

jacocoTestCoverageVerification {
    violationRules {
        rule {
            limit {
                minimum = 0.80  // 80% minimum
            }
        }
    }
}

test.finalizedBy jacocoTestReport
check.dependsOn jacocoTestCoverageVerification
```

```bash
# Run tests with coverage
./gradlew test jacocoTestReport

# View report
open build/reports/jacoco/test/html/index.html
```

### Coverage Targets

| Code Type | Target |
|-----------|--------|
| Business logic (Service) | 80%+ |
| Controllers | 80%+ |
| Mappers (SQL tested via slice tests) | Exclude generated |
| Entity business methods | 90%+ |

## Test File Organization

```
src/
├── main/java/com/opt/advertiser/
│   ├── controller/AssetController.java
│   ├── service/impl/AssetServiceImpl.java
│   └── mapper/AssetMapper.java
└── test/java/com/opt/advertiser/
    ├── controller/AssetControllerTest.java   # @WebMvcTest slice
    ├── service/AssetServiceTest.java          # @ExtendWith(MockitoExtension)
    └── mapper/AssetMapperTest.java            # @MybatisPlusTest slice
```

## Common Anti-Patterns

```java
// ❌ 错误：在Service中直接new依赖，无法Mock
class AssetServiceImpl {
    private final AssetMapper mapper = new AssetMapperImpl(); // 无法Mock
}

// ✅ 正确：构造器注入，可以Mock
class AssetServiceImpl {
    private final AssetMapper mapper;
    public AssetServiceImpl(AssetMapper mapper) { this.mapper = mapper; }
}

// ❌ 错误：测试实现细节（调用了几次某方法）
verify(mapper, times(1)).selectById(any()); // 脆弱

// ✅ 正确：测试业务行为
assertThat(result.getBalance()).isEqualByComparingTo("200.00");

// ❌ 错误：一个测试验证多个场景
@Test
void testAll() {
    // 测试创建 + 更新 + 删除 + 异常 ...
}

// ✅ 正确：一个测试一个行为
@Test void create_success() { ... }
@Test void create_duplicateAdvId_throwsException() { ... }
```

## Running Tests

```bash
# Run all tests
./gradlew test

# Run specific test class
./gradlew test --tests "com.opt.advertiser.service.AssetServiceTest"

# Run with coverage
./gradlew test jacocoTestReport

# Run with verbose output
./gradlew test --info
```

**Remember:** Tests for Spring Boot Java projects should be layered. Most logic lives in unit tests with Mockito. Reserve `@SpringBootTest` for critical integration flows only — it starts the full context and is expensive.
