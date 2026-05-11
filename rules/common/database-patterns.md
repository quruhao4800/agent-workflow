# Database Patterns

## Query Rules

- Never query in a loop — loop calling `selectById(id)` per item causes N+1 queries; use `selectBatchIds(ids)` or a JOIN query
- All user-facing list endpoints must paginate — unbounded `selectList()` on large tables causes OOM and slow responses

```java
// BAD: N+1
for (Long id : ids) {
    Entity e = mapper.selectById(id);
    results.add(e);
}

// GOOD: batch fetch
List<Entity> results = mapper.selectBatchIds(ids);

// BAD: unbounded list
List<User> all = mapper.selectList(wrapper);

// GOOD: paginated
Page<User> page = mapper.selectPage(new Page<>(pageNum, pageSize), wrapper);
```

## Write Rules

- Multiple write operations (insert + update, or insert + insert) in the same method must be wrapped in `@Transactional` — partial failure without a transaction leaves data inconsistent

```java
// BAD: two writes, no transaction — second failure leaves orphan record
public void createOrder(OrderDO order, List<OrderItemDO> items) {
    orderMapper.insert(order);
    orderItemMapper.batchInsert(items); // fails → order exists, items missing
}

// GOOD
@Transactional
public void createOrder(OrderDO order, List<OrderItemDO> items) {
    orderMapper.insert(order);
    orderItemMapper.batchInsert(items);
}
```

## SQL Placement

- Complex queries (multi-join, multi-condition) belong in XML mapper files, not inline `@Select` annotations — XML is readable, testable, and supports dynamic SQL cleanly
