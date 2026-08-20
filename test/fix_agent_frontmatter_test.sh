#!/bin/bash
set -eu

repo_root=$(cd "$(dirname "$0")/.." && pwd)
test_root=$(mktemp -d)
trap 'command rm -rf "$test_root"' EXIT

if ! command -v mise >/dev/null 2>&1 || ! mise exec -- ruby --version >/dev/null 2>&1; then
    echo "mise-managed ruby not found; skipping $(basename "$0")" >&2
    exit 0
fi

run_ruby() {
    mise exec -- ruby "$@"
}

run_fixer() {
    run_ruby "$repo_root/bin/fix_agent_frontmatter" "$@"
}

failures=0

fail() {
    echo "FAIL: $*" >&2
    failures=$((failures + 1))
}

# The exact shape sorah-guides ships: an unquoted description ending in
# "Examples:" followed by indented blocks, which makes the whole block unparseable.
write_broken_agent() {
    printf '%s\n' \
        '---' \
        'name: security-reviewer' \
        'description: Use this agent when reviewing security. Examples:' \
        '' \
        '  <example>' \
        '  user: "Review the security of my changes"' \
        '  </example>' \
        '' \
        'model: inherit' \
        'color: red' \
        'tools: ["Read", "Grep", "Glob", "Bash"]' \
        '---' \
        '' \
        'You must never modify any files.' > "$1"
}

frontmatter_key() {
    run_ruby -ryaml -e '
      body = File.read(ARGV[0])
      fm = body[/\A---\n(.*?\n)---[ \t]*\n/m, 1]
      abort "no frontmatter" if fm.nil?
      value = YAML.safe_load(fm).fetch(ARGV[1])
      print value.is_a?(Array) ? value.join(",") : value.to_s
    ' "$1" "$2"
}

assert_unchanged() {
    label="$1"
    file="$2"
    before=$(shasum "$file" | cut -d' ' -f1)
    run_fixer "$file" >/dev/null 2>&1
    after=$(shasum "$file" | cut -d' ' -f1)

    if [ "$before" != "$after" ]; then
        fail "$label: expected the file to be left byte-for-byte unchanged"
    fi
}

test_repairs_the_broken_agent() {
    agent_file="$test_root/broken.md"
    write_broken_agent "$agent_file"

    run_fixer "$agent_file" >/dev/null

    tools=$(frontmatter_key "$agent_file" tools)
    if [ "$tools" != "Read,Grep,Glob,Bash" ]; then
        fail "repair: expected the tools restriction to survive, got '$tools'"
    fi

    if [ "$(frontmatter_key "$agent_file" model)" != "inherit" ]; then
        fail "repair: expected model to survive"
    fi

    case "$(frontmatter_key "$agent_file" description)" in
        *"<example>"*) ;;
        *) fail "repair: expected the examples to be preserved in the description" ;;
    esac

    if ! grep -Fqx 'You must never modify any files.' "$agent_file"; then
        fail "repair: expected the body outside the frontmatter to be untouched"
    fi
}

test_repair_is_idempotent() {
    agent_file="$test_root/idempotent.md"
    write_broken_agent "$agent_file"
    run_fixer "$agent_file" >/dev/null

    assert_unchanged "idempotent" "$agent_file"
}

test_leaves_valid_frontmatter_alone() {
    # A quoted description is already valid; rewriting it would fold the quotes
    # into the value.
    agent_file="$test_root/quoted.md"
    printf '%s\n' \
        '---' \
        'name: some-agent' \
        'description: "Control herdr from inside it."' \
        'model: inherit' \
        '---' \
        '' \
        'Body.' > "$agent_file"

    assert_unchanged "quoted description" "$agent_file"

    # A bare single-line plain scalar is valid too.
    agent_file="$test_root/plain.md"
    printf '%s\n' \
        '---' \
        'name: some-agent' \
        'description: Review code for vulnerabilities' \
        '---' \
        '' \
        'Body.' > "$agent_file"

    assert_unchanged "valid plain scalar" "$agent_file"

    # Block scalars with chomping and indent indicators are valid.
    agent_file="$test_root/block.md"
    printf '%s\n' \
        '---' \
        'name: some-agent' \
        'description: |-' \
        '  Already a block scalar. Steps:' \
        '' \
        '  more' \
        '---' \
        '' \
        'Body.' > "$agent_file"

    assert_unchanged "block scalar" "$agent_file"
}

test_leaves_non_agent_files_alone() {
    # No `name:` key: a co-located doc or a slash command, not an agent.
    agent_file="$test_root/no-name.md"
    printf '%s\n' \
        '---' \
        'description: A co-located doc, not an agent. Steps:' \
        '' \
        '  1. do the thing' \
        'allowed-tools: Bash' \
        '---' \
        '' \
        'Docs.' > "$agent_file"

    assert_unchanged "no name key" "$agent_file"
}

test_leaves_files_without_a_closing_delimiter_alone() {
    agent_file="$test_root/unterminated.md"
    printf '%s\n' \
        '---' \
        'name: some-agent' \
        'description: Broken and never closed. Steps:' \
        '' \
        '  1. do the thing' > "$agent_file"

    assert_unchanged "no closing delimiter" "$agent_file"
}

test_fails_closed_on_duplicated_keys() {
    agent_file="$test_root/duplicated.md"
    printf '%s\n' \
        '---' \
        'name: security-reviewer' \
        'description: First. Steps:' \
        '' \
        '  indented' \
        'description: Second' \
        '---' \
        '' \
        'Body.' > "$agent_file"

    assert_unchanged "duplicated description key" "$agent_file"
}

test_preserves_file_mode() {
    agent_file="$test_root/mode.md"
    write_broken_agent "$agent_file"
    chmod 644 "$agent_file"

    run_fixer "$agent_file" >/dev/null

    mode=$(stat -f '%Lp' "$agent_file" 2>/dev/null || stat -c '%a' "$agent_file")
    if [ "$mode" != "644" ]; then
        fail "mode: expected 644 to be preserved, got $mode"
    fi
}

test_is_a_no_op_for_missing_files() {
    if ! run_fixer "$test_root/does-not-exist.md" >/dev/null 2>&1; then
        fail "missing file: expected exit 0"
    fi
}

test_repairs_the_broken_agent
test_repair_is_idempotent
test_leaves_valid_frontmatter_alone
test_leaves_non_agent_files_alone
test_leaves_files_without_a_closing_delimiter_alone
test_fails_closed_on_duplicated_keys
test_preserves_file_mode
test_is_a_no_op_for_missing_files

if [ "$failures" -ne 0 ]; then
    echo "$failures assertion(s) failed" >&2
    exit 1
fi

echo "ok: $(basename "$0")"
