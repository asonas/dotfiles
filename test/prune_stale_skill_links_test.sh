#!/bin/bash
set -eu

repo_root=$(cd "$(dirname "$0")/.." && pwd)
pruner="$repo_root/bin/prune_stale_skill_links"
test_root=$(mktemp -d)
trap 'command rm -rf "$test_root"' EXIT

assert_missing() {
    path="$1"

    if [ -L "$path" ] || [ -e "$path" ]; then
        echo "expected $path to be pruned" >&2
        return 1
    fi
}

assert_symlink() {
    path="$1"

    if [ ! -L "$path" ]; then
        echo "expected $path to remain a symlink" >&2
        return 1
    fi
}

# Each case builds its own user-skills dir and link dir so failures do not cascade.
new_case() {
    case_root="$test_root/$1"
    user_skills="$case_root/user-skills"
    links="$case_root/links"
    mkdir -p "$user_skills" "$links"
}

test_prunes_link_to_deleted_entry() {
    new_case prunes-deleted
    ln -s "$user_skills/gone" "$links/gone"

    "$pruner" "$user_skills" "$links"

    assert_missing "$links/gone"
}

test_keeps_link_to_existing_entry() {
    new_case keeps-existing
    mkdir "$user_skills/today"
    ln -s "$user_skills/today" "$links/today"

    "$pruner" "$user_skills" "$links"

    assert_symlink "$links/today"
}

test_keeps_dangling_link_to_other_source() {
    new_case keeps-other-source
    ln -s "$case_root/homebrew/libexec/skills/hunk-review" "$links/hunk-review"

    "$pruner" "$user_skills" "$links"

    assert_symlink "$links/hunk-review"
}

test_keeps_apm_deployed_directory() {
    new_case keeps-apm-dir
    mkdir "$links/brainstorming"
    : > "$links/brainstorming/SKILL.md"

    "$pruner" "$user_skills" "$links"

    if [ ! -f "$links/brainstorming/SKILL.md" ]; then
        echo "expected APM-deployed directory to be left alone" >&2
        return 1
    fi
}

# A user-skills entry can itself be a symlink to a skill kept outside the repo.
# When that ultimate target disappears the entry stops deploying, so its link is
# stale too.
test_prunes_link_through_broken_entry() {
    new_case prunes-through-broken-entry
    ln -s "$case_root/elsewhere/difit" "$user_skills/difit"
    ln -s "$user_skills/difit" "$links/difit"

    "$pruner" "$user_skills" "$links"

    assert_missing "$links/difit"
}

test_prunes_across_multiple_link_dirs() {
    new_case prunes-multiple-dirs
    claude_links="$case_root/claude"
    agents_links="$case_root/agents"
    mkdir -p "$claude_links" "$agents_links"
    ln -s "$user_skills/gone" "$claude_links/gone"
    ln -s "$user_skills/gone" "$agents_links/gone"

    "$pruner" "$user_skills" "$claude_links" "$agents_links"

    assert_missing "$claude_links/gone"
    assert_missing "$agents_links/gone"
}

test_tolerates_missing_link_dir() {
    new_case tolerates-missing
    "$pruner" "$user_skills" "$case_root/does-not-exist"
}

test_tolerates_empty_link_dir() {
    new_case tolerates-empty
    "$pruner" "$user_skills" "$links"
}

test_install_script_prunes_before_deploying() {
    install_script="$repo_root/install.sh"

    if ! grep -Fq '"$PWD/bin/prune_stale_skill_links" \' "$install_script"; then
        echo "expected install.sh to invoke bin/prune_stale_skill_links" >&2
        return 1
    fi

    prune_line=$(grep -n '"\$PWD/bin/prune_stale_skill_links"' "$install_script" | head -1 | cut -d: -f1)
    deploy_line=$(grep -n '^for skill in "\$PWD"/\.claude/user-skills/\*$' "$install_script" | head -1 | cut -d: -f1)
    if [ "$prune_line" -ge "$deploy_line" ]; then
        echo "expected the prune call (line $prune_line) to precede the deploy loop (line $deploy_line)" >&2
        return 1
    fi
}

test_install_script_verifies_wiki_health_assets() {
    install_script="$repo_root/install.sh"

    for asset in wiki-health.rb mentions.rb verify-sources.rb
    do
        if ! grep -Fq "wiki-update/health/$asset" "$install_script"; then
            echo "expected install.sh to verify wiki-update health asset $asset" >&2
            return 1
        fi
    done

    if ! grep -Fq "missing wiki-update health script" "$install_script"; then
        echo "expected install.sh to report missing wiki-update health scripts" >&2
        return 1
    fi
}

test_prunes_link_to_deleted_entry
test_keeps_link_to_existing_entry
test_keeps_dangling_link_to_other_source
test_keeps_apm_deployed_directory
test_prunes_link_through_broken_entry
test_prunes_across_multiple_link_dirs
test_tolerates_missing_link_dir
test_tolerates_empty_link_dir
test_install_script_prunes_before_deploying
test_install_script_verifies_wiki_health_assets
