# frozen_string_literal: true

require "json"
require "minitest/autorun"
require "open3"
require "shellwords"
require "tmpdir"

class AppleInterfaceGuidelinesScriptsTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)
  SKILL = File.join(ROOT, ".claude/user-skills/apply-apple-interface-guidelines")
  FIXTURES = File.join(ROOT, "test/fixtures/apple-interface-guidelines")
  COMPARE = File.join(SKILL, "scripts/compare-manifests")
  VALIDATE = File.join(SKILL, "scripts/validate-hig-sources")

  def test_reports_new_page
    stdout, stderr, status = Open3.capture3(COMPARE, fixture("old-manifest.json"), fixture("new-manifest.json"))

    assert status.success?, stderr
    assert_equal ["new-control"], JSON.parse(stdout).fetch("new")
  end

  def test_reports_updated_page
    result = compare

    assert_equal ["changed"], result.fetch("updated")
  end

  def test_classifies_moved_missing_and_unchanged_pages
    result = compare

    assert_equal ["moved"], result.fetch("moved")
    assert_equal ["gone"], result.fetch("missing")
    assert_equal ["stable"], result.fetch("unchanged")
  end

  def test_accepts_valid_current_source
    _stdout, stderr, status = Open3.capture3(
      VALIDATE,
      fixture("valid-manifest.json"),
      fixture("sources")
    )

    assert status.success?, stderr
  end

  def test_rejects_unknown_status
    manifest = JSON.parse(File.read(fixture("valid-manifest.json")))
    manifest.fetch("pages").first["status"] = "stale"

    Dir.mktmpdir do |directory|
      path = File.join(directory, "manifest.json")
      File.write(path, JSON.generate(manifest))
      _stdout, stderr, status = Open3.capture3(VALIDATE, path, fixture("sources"))

      refute status.success?
      assert_includes stderr, "invalid status stale"
    end
  end

  def test_rejects_source_note_that_does_not_match_manifest
    Dir.mktmpdir do |directory|
      source = File.join(directory, "HIG - Charts.md")
      File.write(source, "---\nslug: charts\n---\n\n# Charts\n")
      _stdout, stderr, status = Open3.capture3(
        VALIDATE,
        fixture("valid-manifest.json"),
        directory
      )

      refute status.success?
      assert_includes stderr, "frontmatter does not match manifest"
    end
  end

  def test_fetch_rejects_empty_ax_output
    Dir.mktmpdir do |directory|
      ax = File.join(directory, "ax")
      File.write(ax, "#!/bin/sh\nexit 0\n")
      File.chmod(0o755, ax)
      script = File.join(SKILL, "scripts/fetch-hig-page")
      _stdout, stderr, status = Open3.capture3(
        { "PATH" => "#{directory}:#{ENV.fetch("PATH")}" },
        script,
        "https://developer.apple.com/jp/design/human-interface-guidelines/charts"
      )

      refute status.success?
      assert_includes stderr, "not extracted"
    end
  end

  def test_fetch_rejects_whitespace_ax_output
    assert_ax_output_is_rejected("fetch-hig-page", "  \n")
  end

  def test_discover_rejects_empty_result_array
    assert_ax_output_is_rejected("discover-hig-pages", "[]\n")
  end

  private

  def fixture(name)
    File.join(FIXTURES, name)
  end

  def compare
    stdout, stderr, status = Open3.capture3(COMPARE, fixture("old-manifest.json"), fixture("new-manifest.json"))
    assert status.success?, stderr
    JSON.parse(stdout)
  end

  def assert_ax_output_is_rejected(script_name, output)
    Dir.mktmpdir do |directory|
      ax = File.join(directory, "ax")
      File.write(ax, "#!/bin/sh\nprintf '%s' #{Shellwords.escape(output)}\n")
      File.chmod(0o755, ax)
      script = File.join(SKILL, "scripts", script_name)
      _stdout, _stderr, status = Open3.capture3(
        { "PATH" => "#{directory}:#{ENV.fetch("PATH")}" },
        script,
        "https://developer.apple.com/design/human-interface-guidelines/charts"
      )

      refute status.success?
    end
  end
end
