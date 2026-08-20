# frozen_string_literal: true

require "minitest/autorun"
require "yaml"

class ApmSkillSubsetTest < Minitest::Test
  MANIFEST = File.expand_path("../apm.yml", __dir__)
  SUPERPOWERS = "obra/superpowers"
  MATT_SKILLS = "mattpocock/skills"
  SORAH_GUIDES = "sorah/config/claude/marketplace/plugins/sorah-guides"
  SORAH_SPEC = "sorah/config/claude/marketplace/plugins/sorah-spec"
  RETIRED_COMMIT_SKILL = "asonas/skills/commit"
  BASE_INSTRUCTIONS = File.expand_path("../.apm/instructions/base.instructions.md", __dir__)
  SUPERPOWERS_PATHS = %w[
    skills/brainstorming
    skills/dispatching-parallel-agents
    skills/executing-plans
    skills/finishing-a-development-branch
    skills/receiving-code-review
    skills/requesting-code-review
    skills/subagent-driven-development
    skills/systematic-debugging
    skills/test-driven-development
    skills/using-git-worktrees
    skills/using-superpowers
    skills/verification-before-completion
    skills/writing-plans
    skills/writing-skills
  ].freeze
  MATT_PATHS = %w[
    skills/productivity/grill-me
    skills/productivity/grilling
    skills/engineering/wayfinder
    skills/engineering/implement
    skills/engineering/tdd
    skills/engineering/code-review
    skills/engineering/prototype
    skills/engineering/wizard
    skills/productivity/handoff
    skills/productivity/to-questionnaire
  ].freeze
  RETAINED_SKILLS = %w[
    coding
    commit-style
    rust
    security
    terraform
    typescript
  ].freeze
  def apm_entries
    YAML.safe_load_file(MANIFEST).fetch("dependencies").fetch("apm")
  end

  def dependency_entry(source, path)
    matches = apm_entries.select do |entry|
      entry.is_a?(Hash) && entry.fetch("git", nil) == source && entry.fetch("path", nil) == path
    end

    assert_equal 1, matches.length, "expected exactly one #{source}/#{path} dependency"
    matches.first
  end

  def assert_targeted_dependency(source, path, target)
    assert_equal [target], dependency_entry(source, path).fetch("targets")
  end

  def sorah_guides_entry
    matches = apm_entries.select do |entry|
      entry == SORAH_GUIDES || (entry.is_a?(Hash) && entry.fetch("git", nil) == SORAH_GUIDES)
    end

    assert_equal 1, matches.length
    assert_kind_of Hash, matches.first
    matches.first
  end

  def test_sorah_guides_selects_the_retained_skill_subset
    skills = sorah_guides_entry.fetch("skills")

    assert_equal RETAINED_SKILLS.sort, skills.sort
    refute_includes skills, "japanese-text"
  end

  def test_sorah_guides_does_not_install_rails_or_ruby
    skills = sorah_guides_entry.fetch("skills")

    refute_includes skills, "rails"
    refute_includes skills, "ruby"
  end

  def test_sorah_spec_is_removed
    refute(apm_entries.any? do |entry|
      entry == SORAH_SPEC || (entry.is_a?(Hash) && entry.fetch("git", nil) == SORAH_SPEC)
    end)
  end

  def test_grill_me_installs_with_its_grilling_implementation
    assert_targeted_dependency(MATT_SKILLS, "skills/productivity/grill-me", "codex")
    assert_targeted_dependency(MATT_SKILLS, "skills/productivity/grilling", "codex")
  end

  def test_wayfinder_is_installed
    assert_targeted_dependency(MATT_SKILLS, "skills/engineering/wayfinder", "codex")
  end

  def test_superpowers_are_installed_for_claude_only
    SUPERPOWERS_PATHS.each do |path|
      assert_targeted_dependency(SUPERPOWERS, path, "claude")
    end
  end

  def test_selected_matt_skills_are_installed_for_codex_only
    MATT_PATHS.each do |path|
      assert_targeted_dependency(MATT_SKILLS, path, "codex")
    end
  end

  def test_mandatory_git_ai_commit_workflow_is_retired
    refute_includes apm_entries, RETIRED_COMMIT_SKILL
    refute_includes File.read(BASE_INSTRUCTIONS), "git ai-commit"
    refute_includes File.read(BASE_INSTRUCTIONS), "`/commit`"
  end
end
