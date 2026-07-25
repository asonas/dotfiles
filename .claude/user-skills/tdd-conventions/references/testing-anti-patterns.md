## Testing Anti-Patterns

Reference: https://github.com/blas1n/claude-skills/blob/main/skills/test-driven-development/testing-anti-patterns.md

Core principle: **Test what the code does, not what the mocks do.** Mocks are isolation tools, not subjects of verification.

### 1. Testing Mock Behavior

Asserting on mock existence rather than real component functionality. Remove the mock entirely or restructure the test to verify actual behavior.

### 2. Test-Only Methods in Production

Adding methods to production classes solely for test cleanup pollutes the codebase. Test utilities should handle cleanup operations — keep production code focused on business logic.

### 3. Mocking Without Understanding Dependencies

Before mocking anything, understand what side effects the real method produces and whether your test depends on those effects. Mocking "to be safe" often breaks the very behavior the test should validate.

### 4. Incomplete Mocks

Partial mock objects that omit fields from real API responses create hidden failures. Complete mocks must mirror the entire real-world structure, not just immediately visible fields.

### 5. Integration Tests as Afterthought

Testing should precede implementation through TDD, ensuring tests drive design rather than validating completed code.

### Prevention

Following TDD naturally prevents these anti-patterns by forcing you to understand actual requirements before adding code.

### When Mocks Are Acceptable

Use mocks only when:
- External services (payment APIs, email providers) that cannot be called in tests
- Non-deterministic dependencies (system clock, random number generators)
- Extremely slow resources (network calls, large databases)

Even then, prefer fakes or in-memory implementations over mock libraries when possible.
