# Exclude japanese-text Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Keep the `sorah-guides` package and its other primitives while preventing APM from deploying the `japanese-text` Skill.

**Architecture:** Convert only the `sorah-guides` dependency in apm.yml to object form and pin the eight retained Skills through its `skills:` field. A focused Ruby test parses YAML and asserts the exact allowlist. APM then updates the global lockfile and reconciles the installed files, removing the previously managed `japanese-text` deployment.

**Tech Stack:** YAML, Ruby standard library, Minitest, APM 0.26.0, shell verification

## Global Constraints

- Keep the `sorah-guides` package installed.
- Exclude only the `japanese-text` Skill.
- Retain `coding`, `commit-style`, `rails`, `ruby`, `rust`, `security`, `terraform`, and `typescript` exactly once.
- Preserve the `security-reviewer` agent and the existing `sorah-guides` commands.
- Do not add a manual `japanese-text` deletion to install.sh.
- Use `git ai-commit`; do not run `git commit` directly.

---

### Task 1: Pin the sorah-guides Skill allowlist

**Files:**
- Create: `test/apm_skill_subset_test.rb`
- Modify: `apm.yml:43-45`
- Modify: `docs/superpowers/specs/2026-07-22-exclude-japanese-text-design.md`
- Create: `docs/superpowers/plans/2026-07-22-exclude-japanese-text.md`

**Interfaces:**
- Consumes: APM object-form dependency entries with `git` and `skills` keys.
- Produces: One `sorah-guides` dependency whose `skills` value is the exact retained Skill list.

- [ ] **Step 1: Write the failing manifest test**

Create test/apm_skill_subset_test.rb:

```ruby
# frozen_string_literal: true

require "minitest/autorun"
require "yaml"

class ApmSkillSubsetTest < Minitest::Test
  MANIFEST = File.expand_path("../apm.yml", __dir__)
  SORAH_GUIDES = "sorah/config/claude/marketplace/plugins/sorah-guides"
  RETAINED_SKILLS = %w[
    coding
    commit-style
    rails
    ruby
    rust
    security
    terraform
    typescript
  ].freeze

  def test_sorah_guides_selects_every_skill_except_japanese_text
    entries = YAML.safe_load_file(MANIFEST).fetch("dependencies").fetch("apm")
    matches = entries.select do |entry|
      entry == SORAH_GUIDES || (entry.is_a?(Hash) && entry.fetch("git", nil) == SORAH_GUIDES)
    end

    assert_equal 1, matches.length
    assert_kind_of Hash, matches.first
    assert_equal RETAINED_SKILLS.sort, matches.first.fetch("skills").sort
    refute_includes matches.first.fetch("skills"), "japanese-text"
  end
end
```

- [ ] **Step 2: Run the test and verify RED**

Run: `ruby test/apm_skill_subset_test.rb`

Expected: FAIL because the current `sorah-guides` entry is a string, so `matches.length` is 0.

- [ ] **Step 3: Convert the dependency to object form**

Replace the string entry with:

```yaml
    - git: sorah/config/claude/marketplace/plugins/sorah-guides
      skills:
        - coding
        - commit-style
        - rails
        - ruby
        - rust
        - security
        - terraform
        - typescript
```

- [ ] **Step 4: Run the focused and existing tests**

Run:

```bash
ruby test/apm_skill_subset_test.rb
for test_file in test/*_test.sh; do bash "$test_file"; done
```

Expected: the Ruby test reports 1 run with 0 failures, and all shell tests exit 0.

- [ ] **Step 5: Update the design status**

Change the design checklist item for the allowlist and its static test to checked. Add this update:

```markdown
- 2026-07-22：`sorah-guides`のSkill許可リストと静的テストを追加しました。
```

- [ ] **Step 6: Commit the repository change**

Run:

```bash
git add apm.yml test/apm_skill_subset_test.rb docs/superpowers/specs/2026-07-22-exclude-japanese-text-design.md docs/superpowers/plans/2026-07-22-exclude-japanese-text.md
git ai-commit --context "Exclude only japanese-text from the sorah-guides APM bundle by pinning the retained skills and testing the manifest contract."
```

Expected: one commit containing the manifest, test, and design status.

### Task 2: Verify APM deployment in an isolated root

**Files:**
- Create temporarily: an isolated directory from `mktemp -d`
- Leave unchanged: `~/.apm/apm.lock.yaml` and the current global Skill installation

**Interfaces:**
- Consumes: The feature worktree's apm.yml through APM project scope.
- Produces: An isolated deployment without the `japanese-text` Skill, while retaining the package's selected Skills, agent, and commands.

- [ ] **Step 1: Create an isolated deployment root**

Run:

```bash
apm_test_root=$(mktemp -d)
test -d "$apm_test_root"
```

Expected: exit 0.

- [ ] **Step 2: Install into the isolated root**

Run:

```bash
apm install --root "$apm_test_root" --target claude,cursor,codex
```

Expected: exit 0; APM deploys project-scoped primitives under `$apm_test_root`.

- [ ] **Step 3: Verify the exclusion and retained primitives**

Run:

```bash
test ! -e "$apm_test_root/.agents/skills/japanese-text"
for skill in coding commit-style rails ruby rust security terraform typescript; do
  test -f "$apm_test_root/.agents/skills/$skill/SKILL.md" || exit 1
done
test -f "$apm_test_root/.claude/agents/security-reviewer.md"
test -f "$apm_test_root/.claude/commands/perform-security-review.md"
```

Expected: exit 0.

- [ ] **Step 4: Remove the isolated deployment root**

Run:

```bash
command rm -rf "$apm_test_root"
```

Expected: the explicit temporary directory no longer exists.

- [ ] **Step 5: Run the complete repository verification**

Run:

```bash
ruby test/apm_skill_subset_test.rb
for test_file in test/*_test.sh; do bash "$test_file"; done
bash -n install.sh
git diff --check
git status --short --branch
```

Expected: all tests and checks exit 0; the feature branch working tree is clean.

## Post-merge global reconciliation

After the reviewed branch is merged into main, run the following from the main checkout:

```bash
(cd "$HOME/.apm" && apm update --yes --target claude,cursor,codex)
(cd "$HOME/.apm" && apm install -g --target claude,cursor,codex)
test ! -e "$HOME/.agents/skills/japanese-text"
for skill in coding commit-style rails ruby rust security terraform typescript; do
  test -f "$HOME/.agents/skills/$skill/SKILL.md" || exit 1
done
test -f "$HOME/.claude/agents/security-reviewer.md"
test -f "$HOME/.claude/commands/perform-security-review.md"
```

Expected: both APM commands and every verification exit 0. The global lockfile and installation reflect the main branch's allowlist.
