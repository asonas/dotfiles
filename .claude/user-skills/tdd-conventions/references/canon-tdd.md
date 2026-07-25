## Canon TDD by Kent Beck

Reference: t-wada's article on Kent Beck's canonical TDD workflow https://t-wada.hatenablog.jp/entry/canon-tdd-by-kent-beck

### Goals of TDD

TDD aims to bring the system into the following four states:

1. Everything that used to work still works
2. New behavior works as expected
3. The system is ready for further changes
4. The programmer and their colleagues are confident in all of the above

### The Five Steps

#### Step 1: Create a Test List (Analysis Phase)

Identify test scenarios that need to be covered and compile them into a list (the test list).

- Enumerate expected behaviors comprehensively for the required changes — happy paths, error cases, boundary values, etc.
- Write the test list in plan.md or as comments
- **Do not mix in implementation design decisions** — focus only on "what should it do", and defer "how to implement it" to later steps
- Skipping this step leads to the misconception that "TDD means jumping straight into code with no sense of when you'll be done"
- The test list provides visibility into when the work will be complete

#### Step 2: Pick One Test, Write a Failing Test (Red)

Pick "just one" item from the test list, translate it into a concrete, executable test, and verify that the test fails.

- **Why "just one" matters**: If you write multiple tests upfront and then need to revise the design while making the first test pass, all the others must be rewritten too. The order in which you pick tests "has a significant impact on both the comfort of programming and the quality of the final result" — a skill acquired only through experience
- Each test should include Setup, Execution, and Assertion
- Writing the test drives interface design decisions — "how should this behavior be invoked?"
- **Why verify failure**: Confirms the test correctly detects the absence of the feature. Without seeing the failure, you risk writing a meaningless test that always passes
- Pro tip: Start writing from the assertion and work upward
- **Anti-patterns**:
  - Writing tests without assertions (tests that only chase coverage)
  - Translating all test list items into test code first and then trying to make them pass one by one

#### Step 3: Make the Test Pass (Green)

Change the production code to make the current test (and all previously written tests) pass. Add any new insights to the test list along the way.

- "Make it work, then make it right" — clean code comes in the next step
- Verify not just the new test but **all previously written tests** continue to pass. This achieves TDD goal #1: "everything that used to work still works"
- If you discover new test needs during Red-to-Green, add them to the test list
- If you hit a critical realization (e.g., "we can't handle empty folders"), consider starting over — "but this time, pick the tests in a different order"
- **Anti-patterns**:
  - Deleting assertions to fake a passing test
  - Copying the actual output directly into the expected value (loses the value of double-checking)
  - Mixing refactoring into the Green step ("wearing two hats" problem)

#### Step 4: Refactor to Improve the Design

Refactor as needed to improve the implementation design.

- This is where **implementation design decisions** are finally made — "how should the system implement this behavior?"
- The separation of interface design (Step 2) and implementation design (Step 4) is the core design insight of TDD
- Refactoring is safe because all tests are Green
- **Anti-patterns**:
  - Over-refactoring (procrastinating on the next test out of anxiety)
  - Premature abstraction ("duplication is a hint, not a directive")

#### Step 5: Repeat Until the Test List Is Empty

Return to Step 2 and repeat until the test list is empty.

- "Keep testing and coding until anxiety about the code's behavior turns into boredom"
- The test list serves as a progress barometer

### Separation of Interface Design and Implementation Design

The fundamental design philosophy of TDD is separating two kinds of design:

- **Interface design** (Step 2): "How should this behavior be invoked?"
- **Implementation design** (Step 4): "How should the system implement this behavior?"

Kent Beck: "In school, these were called logical design and physical design, and we were told never to mix them. But nobody ever showed us how." — TDD is the workflow that achieves this separation.

### Precise Terminology

These are all distinct concepts and must not be conflated:

| Term | Definition | Relation to TDD |
|------|-----------|-----------------|
| Automated Test | Test code using a testing framework | Prerequisite for TDD |
| Developer Testing | Test code written by the developer themselves | Prerequisite for TDD |
| Test-First | Writing test code before implementation | Prerequisite for TDD |
| Test-Driven Development | The entire workflow: Test List → Red → Green → Refactor | — |

"Many of the benefits attributed to TDD are actually benefits of automated testing or developer testing."
