# Testing Standards

## Coverage Thresholds (enforced by JaCoCo)

| Layer | Minimum |
|-------|---------|
| Service | 85% |
| Controller | 80% |
| Overall | 80% |

```bash
./gradlew test jacocoTestReport
# Report: build/reports/jacoco/test/html/index.html
```

## TDD Workflow (MANDATORY)

1. Write failing test — confirm it fails for the right reason (RED)
2. Write minimal implementation (GREEN)
3. Refactor — tests must stay green (IMPROVE)
4. Verify coverage meets thresholds above

## Test Layer Selection

| Layer | Annotation | Use when |
|-------|-----------|----------|
| Unit | `@ExtendWith(MockitoExtension.class)` | Service, Converter, domain logic in isolation |
| Controller slice | `@WebMvcTest` | HTTP mapping, validation, error responses |
| Repository slice | `@MybatisTest` / `@DataJpaTest` | Mapper queries |
| Integration | `@SpringBootTest` + TestContainers | Cross-layer flows, async jobs |

Default to the narrowest slice. Use `@SpringBootTest` only when lower slices cannot cover the case.

## Agent Support

Use `tdd-guide` agent proactively for all new features and bug fixes.
