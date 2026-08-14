---
name: tidy-first-conventions
description: Use when a requested behavioral change requires behavior-preserving restructuring first, or when separating structural and behavioral changes or commits
---

# Tidy First Conventions

Keep structural work subordinate to the requested behavior. If the change fits the existing structure, skip tidying and proceed with the behavioral work.

## Classify the change

- **Structural:** Rename, move, extract, or rearrange without changing observable behavior.
- **Behavioral:** Add or change observable behavior.

Do not classify unrelated cleanup as preparation. A structural change is necessary only when the requested behavioral change cannot be made safely or clearly in the existing structure.

## Apply Tidy First

1. Establish a relevant passing baseline.
2. Make the smallest necessary structural change.
3. Run the closest relevant validation and confirm behavior is unchanged.
4. Make the requested behavioral change using the `test-driven-development` skill.

## Commits

Only apply commit rules when the user asks for commits.

- Keep material structural and behavioral changes in separate commits.
- Do not create a separate structural commit for a trivial rename or formatting change that is inseparable from the requested behavior.
- Do not commit automatically.
