# frozen_string_literal: true

require "minitest/autorun"
require "yaml"

class ApmSkillSubsetTest < Minitest::Test
  MANIFEST = File.expand_path("../apm.yml", __dir__)
  SORAH_GUIDES = "sorah/config/claude/marketplace/plugins/sorah-guides"
  SORAH_SPEC = "sorah/config/claude/marketplace/plugins/sorah-spec"
  GRILL_ME = "mattpocock/skills/skills/productivity/grill-me"
  GRILLING = "mattpocock/skills/skills/productivity/grilling"
  WAYFINDER = "mattpocock/skills/skills/engineering/wayfinder"
  RETIRED_COMMIT_SKILL = "asonas/skills/commit"
  BASE_INSTRUCTIONS = File.expand_path("../.apm/instructions/base.instructions.md", __dir__)
  RETAINED_SKILLS = %w[
    coding
    commit-style
    rust
    security
    terraform
    typescript
  ].freeze
  # rails and ruby are deliberately absent from the sorah-guides filter: sorah-spec
  # ships skills by the same names. Listing them in both makes APM deploy one over
  # the other on every install ("Skill 'rails' replaced -- previously from another
  # package", last installed wins), so which body lands depends on install order.
  DELEGATED_TO_SORAH_SPEC = %w[rails ruby].freeze

  def apm_entries
    YAML.safe_load_file(MANIFEST).fetch("dependencies").fetch("apm")
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

  def test_sorah_guides_does_not_duplicate_sorah_spec_skills
    skills = sorah_guides_entry.fetch("skills")

    DELEGATED_TO_SORAH_SPEC.each do |skill|
      refute_includes skills, skill,
                      "#{skill} also ships from sorah-spec; listing it here makes APM overwrite one copy with the other"
    end
  end

  def test_sorah_spec_still_supplies_the_delegated_skills
    assert_includes apm_entries, SORAH_SPEC,
                    "rails and ruby are deployed only via sorah-spec now, so dropping it would lose them"
  end

  def test_grill_me_installs_with_its_grilling_implementation
    assert_equal 1, apm_entries.count(GRILL_ME)
    assert_equal 1, apm_entries.count(GRILLING)
  end

  def test_wayfinder_is_installed
    assert_equal 1, apm_entries.count(WAYFINDER)
  end

  def test_mandatory_git_ai_commit_workflow_is_retired
    refute_includes apm_entries, RETIRED_COMMIT_SKILL
    refute_includes File.read(BASE_INSTRUCTIONS), "git ai-commit"
    refute_includes File.read(BASE_INSTRUCTIONS), "`/commit`"
  end
end
