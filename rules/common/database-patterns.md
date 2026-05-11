# Database Patterns

## Mandatory

Rules in this section block task completion and code submission when violated.

### No N+1 Queries

Never query inside a loop — use `selectBatchIds` or a JOIN query instead.

```java
// BAD: N queries
for (Long id : ids) {
    Entity e = mapper.selectById(id);
    results.add(e);
}

// GOOD: 1 query
List<Entity> results = mapper.selectBatchIds(ids);
```

### List Endpoints Must Paginate

Never use unbounded `selectList()` on user-facing list endpoints — large tables cause OOM and slow responses.

```java
// BAD
List<User> all = mapper.selectList(wrapper);

// GOOD
Page<User> page = mapper.selectPage(new Page<>(pageNum, pageSize), wrapper);
```

### Multi-Step Writes Require @Transactional

Two or more write operations in the same method must be wrapped in `@Transactional` —
partial failure without a transaction leaves data inconsistent.

```java
// BAD: second failure leaves orphan record
public void createOrder(OrderDO order, List<OrderItemDO> items) {
    orderMapper.insert(order);
    orderItemMapper.batchInsert(items);
}

// GOOD
@Transactional
public void createOrder(OrderDO order, List<OrderItemDO> items) {
    orderMapper.insert(order);
    orderItemMapper.batchInsert(items);
}
```

### Batch Write for Multiple Records

Never insert or update multiple records in a loop — use batch operations.

```java
// BAD: N round-trips
for (OrderItemDO item : items) {
    orderItemMapper.insert(item);
}

// GOOD: 1 round-trip
orderItemMapper.batchInsert(items); // MyBatis Plus saveBatch
```

---

## Recommended

Rules in this section are flagged in review but do not block submission.

### Complex SQL in XML Mapper

Multi-join or multi-condition queries should be in XML mapper files, not inline `@Select` annotations —
XML is more readable, testable, and supports dynamic SQL cleanly.
