---
name: logging-standards
description: Use when writing any log statement, configuring Logback, or reviewing code that produces logs — enforces SLF4J best practices, log level selection, MDC tracing, and security rules for Java/Spring Boot projects
---

# Logging Standards (SLF4J + Logback)

## Logger Declaration

Always use Lombok `@Slf4j`. Never declare loggers manually.

```java
// ✅ CORRECT
@Slf4j
@Service
public class OrderService {
    public void createOrder(Order order) {
        log.info("Creating order for user {}", order.getUserId());
    }
}

// ❌ WRONG — manual declaration
private static final Logger log = LoggerFactory.getLogger(OrderService.class);
```

## Log Level Rules

| Level | When to Use | Examples |
|-------|-------------|---------|
| `ERROR` | 需要人工介入的异常、系统无法自行恢复的错误 | 数据库连接失败、第三方服务调用全部失败 |
| `WARN` | 可自行恢复的异常、降级处理、即将过期的配置 | 重试后成功、缓存未命中回源、参数校验失败 |
| `INFO` | 业务关键节点、应用生命周期、外部调用摘要 | 订单创建成功、用户登录、服务启动完成 |
| `DEBUG` | 排查问题时的详细流程，生产环境关闭 | 方法入参、中间计算结果、SQL 参数 |
| `TRACE` | 极细粒度追踪，几乎不用于生产 | 循环内部状态、字节流内容 |

**决策规则：**
- 影响业务流程且需要告警 → `ERROR`
- 有损但系统可继续运行 → `WARN`
- 正常业务事件需要审计 → `INFO`
- 仅开发调试需要 → `DEBUG`

## SLF4J 写法规范

### 占位符 — 永远用 `{}`，不拼接字符串

```java
// ✅ CORRECT — 延迟求值，性能好
log.info("User {} placed order {}", userId, orderId);
log.debug("Processing {} items in batch {}", items.size(), batchId);

// ❌ WRONG — 字符串拼接，即使 DEBUG 关闭也会执行
log.debug("Processing " + items.size() + " items in batch " + batchId);
```

### 复杂对象的 DEBUG 日志 — 用 lambda 延迟求值

```java
// ✅ CORRECT — 只在 DEBUG 开启时才调用 toJson()
log.debug("Request payload: {}", () -> JsonUtil.toJson(request));

// ❌ WRONG — toJson() 无论日志级别都会执行
log.debug("Request payload: {}", JsonUtil.toJson(request));
```

### 异常日志 — 异常对象作为最后一个参数

```java
// ✅ CORRECT — 自动打印完整堆栈
log.error("Failed to process order {}", orderId, e);
log.warn("Retry attempt {} failed for user {}", retryCount, userId, e);

// ❌ WRONG — 丢失堆栈
log.error("Failed to process order {}: {}", orderId, e.getMessage());

// ❌ WRONG — 永远不用
e.printStackTrace();
```

## 日志内容规范

### INFO 日志 — 包含业务关键上下文

```java
// ✅ 包含操作对象、结果、关键 ID
log.info("Order {} created successfully for user {}, amount: {}", orderId, userId, amount);
log.info("Payment {} processed, status: {}, duration: {}ms", paymentId, status, duration);

// ❌ 信息不足，无法排查
log.info("Order created");
log.info("Done");
```

### WARN 日志 — 说明原因和处理方式

```java
// ✅ 说明触发条件和降级行为
log.warn("Cache miss for key {}, falling back to database query", cacheKey);
log.warn("Third-party service timeout after {}ms, using cached result", timeout);

// ❌ 缺少上下文
log.warn("Cache miss");
```

### ERROR 日志 — 包含完整上下文和异常

```java
// ✅ 完整上下文 + 异常对象
log.error("Failed to send notification to user {}, channel: {}, messageId: {}",
    userId, channel, messageId, e);

// ❌ 仅打印异常消息
log.error("Send failed: " + e.getMessage());
```

## 禁止记录的内容（安全红线）

```java
// ❌ 密码
log.info("User {} login with password {}", username, password);

// ❌ Token / 密钥
log.debug("Authorization header: {}", authHeader);
log.info("API key used: {}", apiKey);

// ❌ 完整信用卡 / 身份证号
log.info("Payment card: {}", cardNumber);

// ❌ 完整手机号 / 邮箱（需脱敏）
log.info("SMS sent to {}", phone);  // 应改为 mask(phone)

// ✅ 脱敏后记录
log.info("SMS sent to {}", maskPhone(phone));   // 138****8888
log.info("Payment card ending in {}", last4);
```

## MDC — 请求链路追踪

在 Filter 或 Interceptor 中设置请求 ID，所有后续日志自动携带。

```java
// Filter 中设置
@Component
public class MdcFilter extends OncePerRequestFilter {
    private static final String REQUEST_ID = "requestId";

    @Override
    protected void doFilterInternal(HttpServletRequest request,
            HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        String requestId = Optional
            .ofNullable(request.getHeader("X-Request-Id"))
            .orElse(UUID.randomUUID().toString().replace("-", "").substring(0, 16));
        MDC.put(REQUEST_ID, requestId);
        response.setHeader("X-Request-Id", requestId);
        try {
            chain.doFilter(request, response);
        } finally {
            MDC.clear();  // 必须清理，防止线程池复用时污染
        }
    }
}
```

Logback pattern 中引用：
```xml
<pattern>%d{yyyy-MM-dd HH:mm:ss.SSS} [%X{requestId}] [%thread] %-5level %logger{36} - %msg%n</pattern>
```

输出效果：
```
2026-03-27 14:23:01.456 [a3f8c1d2e9b4] [http-nio-8080-exec-1] INFO  c.e.service.OrderService - Order ORD-001 created successfully for user U-123
```

## Logback 推荐配置

```xml
<!-- src/main/resources/logback-spring.xml -->
<configuration>
    <springProperty scope="context" name="appName" source="spring.application.name"/>

    <!-- 控制台输出 -->
    <appender name="CONSOLE" class="ch.qos.logback.core.ConsoleAppender">
        <encoder>
            <pattern>%d{yyyy-MM-dd HH:mm:ss.SSS} [%X{requestId:--}] [%thread] %-5level %logger{36} - %msg%n</pattern>
            <charset>UTF-8</charset>
        </encoder>
    </appender>

    <!-- 滚动文件输出 -->
    <appender name="FILE" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <file>logs/${appName}.log</file>
        <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
            <fileNamePattern>logs/${appName}.%d{yyyy-MM-dd}.%i.log.gz</fileNamePattern>
            <timeBasedFileNamingAndTriggeringPolicy
                class="ch.qos.logback.core.rolling.SizeAndTimeBasedFNATP">
                <maxFileSize>100MB</maxFileSize>
            </timeBasedFileNamingAndTriggeringPolicy>
            <maxHistory>30</maxHistory>
            <totalSizeCap>3GB</totalSizeCap>
        </rollingPolicy>
        <encoder>
            <pattern>%d{yyyy-MM-dd HH:mm:ss.SSS} [%X{requestId:--}] [%thread] %-5level %logger{36} - %msg%n</pattern>
            <charset>UTF-8</charset>
        </encoder>
    </appender>

    <!-- 生产环境：INFO；开发环境通过 application.yml 覆盖 -->
    <springProfile name="prod">
        <root level="INFO">
            <appender-ref ref="CONSOLE"/>
            <appender-ref ref="FILE"/>
        </root>
    </springProfile>

    <springProfile name="!prod">
        <root level="DEBUG">
            <appender-ref ref="CONSOLE"/>
        </root>
        <!-- 第三方库保持 INFO，避免 DEBUG 日志噪音 -->
        <logger name="org.springframework" level="INFO"/>
        <logger name="org.hibernate" level="INFO"/>
        <logger name="com.zaxxer.hikari" level="INFO"/>
    </springProfile>
</configuration>
```

## 反模式速查

| 反模式 | 问题 | 正确做法 |
|--------|------|---------|
| `e.printStackTrace()` | 输出到 stderr，不受日志框架管理 | `log.error("msg", e)` |
| 字符串拼接 `"value: " + val` | 无论级别是否开启都执行拼接 | `log.xxx("value: {}", val)` |
| `catch (Exception e) {}` | 静默吞掉异常 | 至少 `log.warn` 记录 |
| `log.error(e.getMessage())` | 丢失堆栈信息 | `log.error("msg", e)` |
| 记录密码/token 明文 | 安全漏洞 | 脱敏或不记录 |
| MDC 不清理 | 线程池复用导致 requestId 串号 | `finally { MDC.clear(); }` |
| INFO 级别记录循环内部 | 日志量爆炸 | 循环外汇总或用 DEBUG |

## 检查清单

在每次涉及日志的代码提交前确认：

- [ ] 使用 `@Slf4j`，无手动 Logger 声明
- [ ] 所有占位符使用 `{}`，无字符串拼接
- [ ] 异常对象作为最后一个参数传入
- [ ] 无 `e.printStackTrace()` 调用
- [ ] 无密码、token、完整手机号/身份证明文
- [ ] MDC 在 finally 块中执行 `clear()`
- [ ] 循环体内无 INFO 级别日志
- [ ] DEBUG 日志中复杂对象使用 lambda 延迟求值
