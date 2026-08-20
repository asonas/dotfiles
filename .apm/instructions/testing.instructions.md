---
description: Test strategy for risk-based, behavior-focused verification.
---

# Testing Strategy

- Tests exist to reduce change risk, not to satisfy a TDD ritual, coverage target, or test-count target.
- Before adding a test, identify the requirement, reproduced bug, or existing contract it protects and the change that could make it fail.
- Use TDD when it is explicitly requested or when it reduces the risk of implementing non-trivial behavior or a regression. Do not apply test-first mechanically to simple changes.
- Each test should verify one coherent behavior observable through a public interface. Do not add one test per function, branch, or assertion.
- Derive expected values independently from the implementation and test helpers, using the specification, known results, or manually checked fixtures.
- Prefer real components and real public interfaces. Do not mock internal classes, internal modules, trivial delegation, or call order.
- Restrict mocks, stubs, spies, and fakes to external services, external processes, time, randomness, or boundaries that are impractically slow or non-deterministic. If test-double setup is more complex than the test itself, consider an integration test with the real components.
- Choose the smallest sufficient test level: small tests for pure logic, integration tests for multiple owned components, and E2E tests only for important user paths or system contracts that lower-level tests cannot verify.
- Do not use E2E tests to cover every branch or input. Cover a small number of important paths and important failure classes.
- Do not normally test simple constants, unchanged configuration, or prose and instruction wording. When configuration merging, distribution, permissions, exit codes, or other side effects change, verify the generated result or execution behavior rather than the wording.
- Run a shell program as one process and verify its exit code, stdout, stderr, files, links, and other side effects. Replace commands only at external process boundaries; do not mock internal shell logic.
- Use `grep` against source prose only for minimal distribution or generation contracts. Do not treat wording presence as a feature test or add one test per sentence.
- Stop once the requirement, regression, and high-risk contracts that could be broken by the change are covered. Do not add a test unless you can explain what new failure it could detect.
- During Red-Green, run focused checks near the change. Run the full suite only for broad-impact changes or when the repository or CI requires it.
