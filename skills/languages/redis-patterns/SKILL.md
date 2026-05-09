---
name: redis-patterns
description: Redis usage patterns for Spring Boot projects — configuration, key naming, serialization, caching, distributed locks, atomic operations, idempotency, rate limiting, Redis Stream, and Pub/Sub. Use for any Redis-related implementation.
---

# Redis Patterns for Spring Boot

## When to Activate

- Adding or modifying cache logic
- Implementing distributed locks
- Building idempotency or deduplication
- Implementing rate limiting / frequency control
- Setting up Redis Stream or Pub/Sub
- Reviewing Redis key naming or TTL strategy

---

## Configuration (MANDATORY baseline)

### RedisTemplate Serialization

```java
@Configuration
public abstract class BaseRedisConfig {

    @Bean
    public RedisTemplate<String, Object> redisTemplate(RedisConnectionFactory factory) {
        RedisTemplate<String, Object> template = new RedisTemplate<>();
        template.setConnectionFactory(factory);

        StringRedisSerializer strSerializer = new StringRedisSerializer();
        GenericJackson2JsonRedisSerializer jsonSerializer =
            new GenericJackson2JsonRedisSerializer(customObjectMapper());

        template.setKeySerializer(strSerializer);
        template.setHashKeySerializer(strSerializer);
        template.setValueSerializer(jsonSerializer);
        template.setHashValueSerializer(jsonSerializer);
        template.afterPropertiesSet();
        return template;
    }

    @Bean
    public CacheManager cacheManager(RedisConnectionFactory factory) {
        RedisCacheConfiguration defaultConfig = RedisCacheConfiguration.defaultCacheConfig()
            .entryTtl(Duration.ofMinutes(60))
            .disableCachingNullValues()
            .serializeKeysWith(RedisSerializationContext.SerializationPair
                .fromSerializer(new StringRedisSerializer()))
            .serializeValuesWith(RedisSerializationContext.SerializationPair
                .fromSerializer(new GenericJackson2JsonRedisSerializer()));

        Map<String, RedisCacheConfiguration> configMap = getCacheConfigurationMap();
        return RedisCacheManager.builder(factory)
            .cacheDefaults(defaultConfig)
            .withInitialCacheConfigurations(configMap)
            .build();
    }

    // Override in each service to register named caches with specific TTLs
    protected Map<String, RedisCacheConfiguration> getCacheConfigurationMap() {
        return Map.of();
    }
}
```

### Lettuce Connection Pool (application.yml)

```yaml
spring:
  redis:
    host: ${REDIS_IP}
    port: 6379
    database: 2
    password: ${REDIS_PASSWD}
    ssl: true
    lettuce:
      pool:
        max-active: 32
        max-idle: 16
        min-idle: 8
```

Rules:
- Always configure `max-active`, `max-idle`, `min-idle` explicitly — never rely on defaults
- Use `ssl: true` in production; disable only in local dev
- Use database index to isolate services (e.g., auth on DB2, advertiser on DB2, motion stream on DB0)

---

## Key Naming Convention (MANDATORY)

### Format

```
service:{service-name}:{domain}:{entity}[:{id}]
stream:{service-name}:{event-type}
lock:{service-name}:{domain}:{id}
```

### Examples

```
# Cache
service:auth:system:user:captcha:code:{email}
service:advertiser:asset:points:idempotent:{idempotentKey}

# Lock
service:advertiser:lock:asset:{advId}
service:advertiser:lock:points:transaction:{transactionNo}

# Stream
stream:advertiser:notification
stream:auth:brand-permission

# Pub/Sub channel
notification:user:{advId}:{userId}
```

### Rules

- All keys defined as constants in a dedicated `XxxRedisConst` or `XxxConstants` class — never inline string literals
- Group constants by domain (asset, notification, motion) — one constants class per bounded context
- Never use generic prefixes like `cache:` or `redis:` — always include service name
- Key segments separated by `:` (colon), never `.` or `_`

```java
// constants class pattern
public class AssetConstants {
    public static final String LOCK_ASSET = "service:advertiser:lock:asset:";
    public static final String IDEMPOTENT_POINTS = "service:advertiser:asset:points:idempotent:";
    public static final String FREQ_PREFIX = "service:advertiser:freq:";

    // Compose at call site: LOCK_ASSET + advId
}
```

---

## Serialization Strategy

### Default: JSON for values, String for keys

Use `GenericJackson2JsonRedisSerializer` for all cached objects — readable, type-safe on deserialization.

### Exception: plain String for Hash fields that need arithmetic

When a Hash field will be used with `HINCRBYFLOAT`, `HINCRBY`, or Lua `tonumber()`, store values as plain strings, not JSON:

```java
// Use hmSetAndTime when Hash values need INCR or Lua arithmetic
Map<String, String> map = new HashMap<>();
map.put("packageBalance", balance.toPlainString());  // "10000.00" not "\"10000.00\""
map.put("status", status.name());
redisUtil.hmSetAndTime(key, map, ttl);

// Use hmSet (JSON) for purely read/write objects with no arithmetic
redisUtil.hmSet(key, objectMap, ttl);
```

**Why:** `HINCRBYFLOAT "\"10000.00\""` fails; `HINCRBYFLOAT "10000.00"` succeeds. Mixed serialization in the same Hash causes silent corruption.

Rule: within a single Hash key, pick one strategy — all JSON or all plain String. Never mix.

---

## Caching Patterns

### 1. @Cacheable (simple, declarative)

```java
@Service
@RequiredArgsConstructor
public class NotificationTemplateServiceImpl {

    @Cacheable(value = "notificationTemplate", key = "#templateId")
    @Transactional(readOnly = true)
    public TemplateResponse getTemplate(Long templateId) {
        return templateMapper.selectById(templateId);
    }

    @CacheEvict(value = "notificationTemplate", key = "#templateId")
    @Transactional
    public void updateTemplate(Long templateId, UpdateTemplateRequest request) {
        // update logic
    }
}
```

Register the named cache with its TTL in `getCacheConfigurationMap()`:

```java
@Override
protected Map<String, RedisCacheConfiguration> getCacheConfigurationMap() {
    return Map.of(
        "notificationTemplate", defaultConfig().entryTtl(Duration.ofHours(2))
    );
}
```

### 2. Manual cache-aside (RedisUtil)

Use when TTL depends on runtime data, or when you need fine-grained control:

```java
public PresignedUrlResponse getPresignedUrl(String videoId) {
    String key = RedisConst.VIDEO_AGENT_PRESIGNED_URL + videoId;
    Object cached = redisUtil.get(key);
    if (cached != null) {
        return (PresignedUrlResponse) cached;
    }
    PresignedUrlResponse result = videoAgentClient.generateUrl(videoId);
    redisUtil.set(key, result, 2, TimeUnit.HOURS);
    return result;
}
```

Rules:
- Write to DB first, then populate/evict cache — never cache-then-write
- Cache failure on write MUST propagate exception to trigger DB transaction rollback
- Never cache without TTL — every key must expire

---

## TTL Strategy

### Always set TTL — no eternal keys

```java
// CORRECT
redisUtil.set(key, value, 60, TimeUnit.MINUTES);

// WRONG — key never expires, grows unbounded
redisUtil.set(key, value);
```

### Add random jitter to prevent thundering herd

When many keys expire at the same time, they all miss cache simultaneously and flood the DB:

```java
private static final long TTL_BASE_SECONDS = 600;    // 10 min
private static final long TTL_JITTER_SECONDS = 1200;  // up to 20 min extra

long ttl = TTL_BASE_SECONDS + ThreadLocalRandom.current().nextLong(TTL_JITTER_SECONDS);
redisUtil.set(key, value, ttl, TimeUnit.SECONDS);
```

### Cache null results with a short TTL to prevent cache penetration

```java
private static final long NULL_TTL_BASE = 60;
private static final long NULL_TTL_JITTER = 120;

Object result = mapper.selectById(id);
if (result == null) {
    long nullTtl = NULL_TTL_BASE + ThreadLocalRandom.current().nextLong(NULL_TTL_JITTER);
    redisUtil.set(key, "NULL_PLACEHOLDER", nullTtl, TimeUnit.SECONDS);
    return null;
}
redisUtil.set(key, result, ttlWithJitter(), TimeUnit.SECONDS);
return result;
```

### Dynamic TTL for batch/async operations

When TTL must accommodate a variable processing time:

```java
long minTtl = 300;                   // 5 min floor
long baseTtl = 120;                  // 2 min base
long perItemEstimate = 1;            // 1 sec per advId
double safetyFactor = 1.5;

long dynamicTtl = Math.max(minTtl,
    (long)(baseTtl + advIds.size() * perItemEstimate * safetyFactor));
redisUtil.set(resetKey, true, dynamicTtl, TimeUnit.SECONDS);
```

---

## Distributed Lock (Redisson)

### Always use Redisson — never `setIfAbsent` for business locks

`setIfAbsent` (SETNX) has no lease renewal. If the JVM pauses (GC, slow DB), the lock expires while the business operation is still running, allowing another thread to enter.

### Standard pattern: watchdog (auto-renew)

```java
@Service
@RequiredArgsConstructor
public class PointsServiceImpl {

    private final RedissonLockUtil redissonLockUtil;

    @Transactional
    public ConsumePointsResponse consume(Long advId, ConsumePointsRequest request) {
        String lockKey = AssetConstants.LOCK_ASSET + advId;
        long waitTime = LockWaitTimeUtil.calculateWaitTime(OperationType.CONSUME_POINTS);

        return redissonLockUtil.tryLockWithWatchdog(lockKey, waitTime, () -> {
            // leaseTime = -1 → watchdog renews every (watchdogTimeout / 3) seconds
            return executeConsumePoints(advId, request);
        });
    }
}
```

### Lock rules

- Lock key must be scoped to the resource being protected: `lock:asset:{advId}` not `lock:asset`
- Watchdog timeout configured once globally: `config.lockWatchdogTimeout(60000)` (60s)
- Never put `@Transactional` and lock acquisition in the same method — the DB transaction must open *inside* the lock, not outside it
- Always release lock in `finally` — RedissonLockUtil must handle this internally

```java
// WRONG: transaction wraps the lock → lock released before commit, race condition
@Transactional
public void consume(...) {
    redissonLockUtil.tryLockWithWatchdog(key, wait, () -> update());
}

// CORRECT: lock wraps the transaction
public void consume(...) {
    redissonLockUtil.tryLockWithWatchdog(key, wait, () -> {
        consumeInTransaction();  // @Transactional on the inner method
    });
}
```

---

## Atomic Operations (Lua Script)

Use Lua for operations that must be atomic across multiple Redis commands:

```java
// Atomic: HINCRBYFLOAT + EXPIRE in one round-trip
// Prevents: balance updated but TTL refresh fails
public Double hmIncrAtomic(String key, String field, BigDecimal delta, long ttlSeconds) {
    String luaScript =
        "local result = redis.call('HINCRBYFLOAT', KEYS[1], ARGV[1], ARGV[2])\n" +
        "redis.call('EXPIRE', KEYS[1], ARGV[3])\n" +
        "return result";

    return redisTemplate.execute(
        new DefaultRedisScript<>(luaScript, Double.class),
        List.of(key),
        field, delta.toPlainString(), String.valueOf(ttlSeconds)
    );
}
```

Rule: any sequence of Redis commands where partial execution is unacceptable must use a Lua script — not a Java loop with multiple `redisTemplate.execute()` calls.

---

## Idempotency Cache

Prevent duplicate processing of the same request:

```java
public ConsumePointsResponse consume(Long advId, ConsumePointsRequest request) {
    String idempotentKey = AssetConstants.IDEMPOTENT_POINTS
        + normalizeKey(advId, request.getIdempotentKey());

    // Check cache first
    Object cached = redisUtil.get(idempotentKey);
    if (cached != null) {
        return (ConsumePointsResponse) cached;
    }

    // Execute and store result
    ConsumePointsResponse result = redissonLockUtil.tryLockWithWatchdog(
        AssetConstants.LOCK_ASSET + advId,
        waitTime,
        () -> executeConsumePoints(advId, request)
    );

    redisUtil.set(idempotentKey, result, 24, TimeUnit.HOURS);
    return result;
}
```

Rules:
- Idempotent key TTL must exceed the maximum retry window of callers (typically 24h)
- Store the full response — not just a flag — so retries get the same data
- Normalize the key: `advId + ":" + idempotentKey` to prevent cross-tenant collision

---

## Rate Limiting (INCR + EXPIRE)

```java
public boolean isOverFrequency(String bizPrefix, String bizKey) {
    String freqKey = AssetConstants.FREQ_PREFIX + bizPrefix + bizKey;
    Long count = redisUtil.incr(freqKey);

    if (count == 1) {
        // First hit — set expiry
        redisUtil.expire(freqKey, FREQ_WINDOW_SECONDS, TimeUnit.SECONDS);
    }

    return count > FREQ_MAX_REQUESTS;
}

private static final long FREQ_WINDOW_SECONDS = 60;
private static final long FREQ_MAX_REQUESTS = 5;
```

Rule: INCR + EXPIRE is not atomic. For strict rate limiting under high concurrency, use a Lua script that combines both commands. The simple pattern above is acceptable for soft rate limiting (anti-spam, not billing).

---

## Batch Operations (Pipeline)

Never loop `get()` in a for-loop — use pipeline for multi-key reads:

```java
// WRONG: N round-trips
for (String key : keys) {
    results.add(redisUtil.get(key));
}

// CORRECT: 1 round-trip via pipeline
List<Object> results = redisTemplate.executePipelined((RedisCallback<Object>) connection -> {
    for (String key : keys) {
        connection.get(key.getBytes());
    }
    return null;
});
```

Rule: batch reads across more than 3 keys must use pipeline or `mget`.

---

## Redis Stream

```java
// Producer
@Service
@RequiredArgsConstructor
public class NotificationEventPublisher {

    private final RedisTemplate<String, String> stringRedisTemplate;

    public void publish(NotificationEvent event) {
        Map<String, String> payload = Map.of(
            "eventId", event.getId().toString(),
            "type", event.getType().name(),
            "advId", event.getAdvId().toString()
        );
        stringRedisTemplate.opsForStream()
            .add(NotificationConstants.STREAM_KEY, payload);
    }
}

// Consumer (Spring Data Redis StreamListener)
@Component
@RequiredArgsConstructor
@Slf4j
public class NotificationStreamListener implements StreamListener<String, MapRecord<String, String, String>> {

    @Override
    public void onMessage(MapRecord<String, String, String> record) {
        try {
            String eventId = record.getValue().get("eventId");
            log.info("Stream message received: eventId={}", eventId);
            processEvent(record.getValue());
            // ACK after successful processing
            redisTemplate.opsForStream().acknowledge(
                NotificationConstants.CONSUMER_GROUP, record);
        } catch (Exception ex) {
            log.error("Stream processing failed: recordId={}", record.getId(), ex);
            // Do NOT ACK — message stays in PEL for retry
        }
    }
}
```

Stream configuration rules:
- Always use consumer groups — never read raw stream without a group
- ACK only after successful processing — failed messages stay in PEL
- Set `maxLength` or `retention-ms` — unbounded streams fill memory
- Use a dedicated connection factory and `RedisTemplate` if the stream is on a different DB index
- Consumer name must be unique per instance: `service-name-{uuid}` or `service-name-{hostname}`

---

## Pub/Sub

```java
// Publisher
redisUtil.publish(NotificationConstants.CHANNEL_PREFIX + advId + ":" + userId, payload);

// Subscriber (Spring MessageListenerAdapter)
@Bean
public RedisMessageListenerContainer listenerContainer(
        RedisConnectionFactory factory,
        NotificationRedisMessageListener listener) {
    RedisMessageListenerContainer container = new RedisMessageListenerContainer();
    container.setConnectionFactory(factory);
    container.addMessageListener(listener,
        new PatternTopic(NotificationConstants.CHANNEL_PREFIX + "*"));
    return container;
}
```

Pub/Sub rules:
- Pub/Sub is fire-and-forget — no persistence, no retry. Use Redis Stream when delivery guarantee is required.
- Pattern subscriptions (`PSUBSCRIBE`) consume more broker resources than exact topics — prefer exact topics when the subscriber set is bounded

---

## Anti-Patterns

| Anti-Pattern | Why | Fix |
|---|---|---|
| `KEYS *` in production | Blocks Redis for entire key scan | Use `SCAN` with cursor |
| No TTL on any key | Redis fills up, OOM eviction corrupts cache | Every `set()` call must include TTL |
| `setIfAbsent` for business-critical locks | Lock expires during GC pause, double processing | Use Redisson with watchdog |
| `@Transactional` wrapping lock acquisition | Transaction commits after lock release, another thread enters before commit | Lock must wrap the transaction, not vice versa |
| Mixed serialization in one Hash | `HINCRBYFLOAT` on JSON string silently corrupts value | One Hash = one serialization strategy |
| Hardcoded key strings at call site | Keys drift, duplicates, impossible to audit | All keys as constants in a dedicated class |
| Pipeline/mget skipped for >3 key reads | N network round-trips, latency multiplies | Use pipeline or `mget` |
| Idempotent key storing only a flag | Retries can't reconstruct the original response | Store the full response object |
| Pub/Sub for reliable delivery | No ACK, no retry, lost on restart | Use Redis Stream with consumer group |

---

## Pre-Implementation Checklist

- [ ] Key name follows `service:{service}:{domain}:{entity}:{id}` format
- [ ] Key defined as a constant — no inline string
- [ ] TTL set on every key, with jitter if many keys expire together
- [ ] Hash fields that need arithmetic stored as plain String, not JSON
- [ ] Distributed lock uses Redisson watchdog, not `setIfAbsent`
- [ ] Lock wraps the `@Transactional` method, not the other way around
- [ ] Multi-key reads use pipeline or `mget`
- [ ] Stream consumers ACK only on success
- [ ] Null results cached with short TTL to block cache penetration
- [ ] No `KEYS` command — use `SCAN`
