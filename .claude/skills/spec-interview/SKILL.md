---
name: spec-interview
description: Conduct an exhaustive specification interview session. Review a spec file, identify all ambiguities and gaps, then interview the author through 10+ rounds of focused questions until the spec is complete enough for implementation without further clarification.
allowed-tools: Read, Edit, Write, Glob, Grep, Bash(git:*), WebFetch, WebSearch, AskUserQuestion
user-invocable: true
---

You are conducting a specification interview session. Your goal is to review a spec file, identify all ambiguities, gaps, and missing details, then interview the spec author about **literally anything** until the spec is complete and unambiguous. This is an in-depth, exhaustive process — do not stop early. Ask about every detail: naming, defaults, error messages, edge cases, field types, method signatures, return values, logging payloads, configuration keys, test expectations, and more. Continue until you are confident that an implementor could build the feature from the spec alone without further questions.

## Input

The user provides a spec file path as argument: $ARGUMENTS

If no argument is given, ask the user which spec file to review.

## Preparation Phase

Before asking any questions:

1. **Read the spec file** thoroughly
2. **Read all referenced files** — follow every file reference, schema, existing code mentioned in the spec
3. **Read project principles** — look for CLAUDE.md, README.md, architecture docs, style guides, or any project-specific conventions
4. **Read existing specs and docs** — find similar spec files in the project to understand the established style and conventions
5. **Explore existing codebase** — investigate related models, modules, patterns, and conventions that the spec's implementation would interact with
6. **Check for inconsistencies** — field collisions in schemas, index types, formula errors, duplicated sections, naming mismatches between spec and code

## Interview Phase

Ask questions in focused batches of 2-4 using the AskUserQuestion tool. Group related questions together. **After every batch of answers, update the spec file before continuing to the next batch.** This keeps the spec current throughout the session and prevents losing context in long interviews.

Interview sessions are expected to be lengthy — often 10+ rounds of questions. Do not rush or skip areas. Cover these areas systematically, and revisit earlier areas if later answers reveal new ambiguities:

### Data Model
- Schema correctness (types, constraints, indexes, defaults)
- Serialization approach (JSON, protobuf, etc.)
- Naming conventions for identifiers and keys

### Architecture & Design
- Class/module structure (where logic lives, separation of concerns)
- Interface design (method signatures, return types, error handling)
- Naming conventions (classes, methods, files)
- Patterns for extensibility (strategy, template, plugin, etc.)

### Behavior & Logic
- Happy path flow end-to-end
- Error conditions and how each is handled
- Edge cases (concurrency, race conditions, nil/null values)
- Validation rules and where they're enforced

### Integration
- How new code interacts with existing models and modules
- Configuration values and their defaults
- External service dependencies
- Background job / async processing design
- Logging plan (what events at what levels, what payload data)

### Security
- Credential handling (hashing, comparison, storage)
- Authentication and authorization
- Rate limiting strategy and defaults
- Sensitive data that must not be logged

### Operations
- Development setup and local testing
- Deployment considerations
- Cleanup / purging strategies
- Migration and rollback plan

### Scope & Deliverables
- What's explicitly in/out of scope
- Dependencies on future work
- Expected file deliverables (code, tests, docs)
- For each deliverable: what it should cover

## Rules

- **Never assume** — if something is ambiguous, ask. Even if you think you know the answer, confirm with the user.
- **Flag bugs** — if you find errors in existing code or files referenced by the spec, call them out before asking questions.
- **Be specific** — provide concrete options with descriptions when asking questions. Don't ask open-ended questions when you can offer informed choices.
- **Update iteratively** — after every batch of answers (2-4 questions), update both the spec body AND the Current Status section before asking the next batch. This is critical for long interview sessions — never accumulate more than one batch of unapplied answers.
- **Polish language** — when updating the spec, improve the readability of surrounding prose, not just the newly added content. Fix awkward phrasing, tighten wordy sentences, and ensure consistent tone throughout. The spec should read as a coherent, well-edited document — not a patchwork of interview answers stapled together.
- **Spec completeness** — the spec must be self-contained. Inline all design details, schemas, and decision rationale directly in the spec. A reader should not need to open other files to understand the full design.
- **Check for TODOs** — find and resolve every TODO in the spec. TODOs that are deliverables (create a file during implementation) should be reworded as clear action items, not questions.
- **Verify completeness** — at the end, grep the spec for remaining TODOs and ambiguous language ("TBD", "maybe", "possibly", "to be decided").
- **Respect existing patterns** — when asking about implementation approaches, always include an option that follows existing codebase conventions.
- **Repeat until done** — keep asking questions until the spec is complete enough for an implementor to build the feature without further clarification. Do not stop early. If you think you're done, re-read the spec one more time and look for anything still vague or underspecified. The interview is expected to be long and thorough.
- **Current Status section** — the spec must always end with a "Current Status" section. Its content differs between interview and implementation phases:

  **During interview** (keep it concise):
  - List interview areas already covered with brief summary of decisions made
  - List remaining areas to be questioned, with approximate number of remaining questions
  - Example:
    ```
    ## Current Status

    Interview in progress.

    Covered:
    - Data Model: schema fields confirmed, index strategy decided
    - Architecture: service object pattern, module structure decided

    Remaining (~12 questions):
    - Behavior & Logic: main flow details, error handling
    - Security: rate limiting defaults, credential storage
    - Operations: setup, cleanup job
    - Scope & Deliverables: docs file scope
    ```

  **After interview completes**, expand into a full checklist format with implementation tasks. Include a strong instruction (e.g., "Implementors MUST keep this section updated as they work.") so the spec itself reminds implementors of the obligation.
