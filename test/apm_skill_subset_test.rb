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
      entry.is_a?(Hash) && entry.fetch("repo", nil) == SORAH_GUIDES
    end

    assert_equal 1, matches.length
    assert_equal RETAINED_SKILLS.sort, matches.first.fetch("skills").sort
    refute_includes matches.first.fetch("skills"), "japanese-text"
  end
end
