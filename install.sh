#!/bin/bash
set -e

cd "$(dirname "$0")"

"$PWD/bin/ensure_main_worktree"

"$PWD/bin/link_legacy_dotfiles" "$PWD" "$HOME"

# Apply entries that have already migrated to chezmoi. The legacy link loop
# remains in place while the source state is migrated incrementally; machines
# without chezmoi keep the existing behavior.
if command -v chezmoi >/dev/null 2>&1; then
    echo "==> chezmoi apply (migrated dotfiles)"
    "$PWD/bin/apply_chezmoi_dotfiles"
fi

"$PWD/bin/install_gpg_agent_config" \
    "$PWD/.gnupg/gpg-agent.conf" \
    "$HOME/.gnupg/gpg-agent.conf"

[ ! -d "$HOME/bin" ] && mkdir "$HOME/bin"
ln -sf "$PWD/bin/check_sip.sh" "$HOME/bin/check_sip.sh"
ln -sf "$PWD/bin/setup_workspace" "$HOME/bin/setup_workspace"
ln -sf "$PWD/bin/herdr-focus-attention" "$HOME/bin/herdr-focus-attention"
ln -sf "$PWD/bin/hw" "$HOME/bin/hw"
ln -sf "$PWD/bin/herdr-fork-claude-session" "$HOME/bin/herdr-fork-claude-session"
ln -sf "$PWD/bin/herdr-fork-codex-session" "$HOME/bin/herdr-fork-codex-session"

case "$OSTYPE" in
  darwin*)
    # macOS
    GIT_PATH=$(brew --prefix git)
    ln -sf "$GIT_PATH/share/git-core/contrib/diff-highlight/diff-highlight" "$HOME/bin/diff-highlight"
    ;;
  linux*)
    # Linux
    GIT_PATH=$(dirname "$(which git)")
    ln -sf "$GIT_PATH/../share/git/contrib/diff-highlight/diff-highlight" "$HOME/bin/diff-highlight"
    ;;
  *)
    echo "Unsupported OS: $OSTYPE"
    ;;
esac

# Merge dotfiles-managed Codex defaults without replacing runtime state such as
# project trust and hook hashes that Codex writes to the same file.
mkdir -p "$HOME/.codex"
"$PWD/bin/install_codex_config" \
    "$PWD/.config/codex/config.toml" \
    "$HOME/.codex/config.toml"

# herdr: link the OS-appropriate config into place. herdr reads a single
# ~/.config/herdr/config.toml (no include/merge support), so we keep one
# self-contained file per platform and symlink the right one. Only config.toml
# is linked; herdr's runtime files (session.json, logs, sockets, plugins) in the
# same directory are left untouched.
mkdir -p "$HOME/.config/herdr"
case "$OSTYPE" in
  darwin*)
    ln -sf "$PWD/.config/herdr/config.macos.toml" "$HOME/.config/herdr/config.toml"
    ;;
  linux*)
    ln -sf "$PWD/.config/herdr/config.linux.toml" "$HOME/.config/herdr/config.toml"
    ;;
esac

# Herdr's installer owns the reporting script. Keep the repository copy linked so
# an integration upgrade updates the tracked script, then normalize the settings
# it writes after APM has finished below.
mkdir -p "$HOME/.claude/hooks"
ln -sf "$PWD/.claude/hooks/herdr-agent-state.sh" "$HOME/.claude/hooks/herdr-agent-state.sh"

# Link ~/.apm/apm.yml to this repo's apm.yml so 'apm install -g' is driven
# from the version-controlled file.
mkdir -p "$HOME/.apm"
apm_link="$HOME/.apm/apm.yml"
if [ -L "$apm_link" ] || [ -e "$apm_link" ]; then
    if [ "$(readlink "$apm_link" 2>/dev/null)" != "$PWD/apm.yml" ]; then
        rm -rf "$apm_link"
        ln -s "$PWD/apm.yml" "$apm_link"
    fi
else
    ln -s "$PWD/apm.yml" "$apm_link"
fi

# Sync APM ignore rules into this repo's local .git/info/exclude. These cannot
# live in .gitignore because that file is symlinked to ~/.gitignore (the global
# core.excludesfile); anchored patterns like /CLAUDE.md and /.cursor/ would then
# hide those files in every other repository. Keeping them repo-local avoids
# that. The block is delimited by markers so this stays idempotent.
exclude_file=$(git rev-parse --git-path info/exclude 2>/dev/null || echo .git/info/exclude)
if [ -n "$exclude_file" ]; then
    mkdir -p "$(dirname "$exclude_file")"
    [ -f "$exclude_file" ] || touch "$exclude_file"
    tmp=$(mktemp)
    # Drop any previously managed block, then append the current one.
    sed '/# === APM (managed by install.sh) ===/,/# === end APM ===/d' \
        "$exclude_file" > "$tmp"
    cat >> "$tmp" <<'APM_EXCLUDE'
# === APM (managed by install.sh) ===
# APM dependencies and generated artifacts.
# Sources to keep tracked: .apm/instructions/, apm.yml.
# Run `apm install && apm compile --clean` after clone to regenerate everything below.
# These live here (not in the symlinked .gitignore) so they don't pollute the
# global core.excludesfile and hide CLAUDE.md/AGENTS.md/etc. in other repos.
apm_modules/
# apm.lock.yaml pins floating deps to whatever commit was latest at install
# time and is regenerated per-machine, so tracking it causes noisy diffs and
# cross-machine merge conflicts. Re-resolved by `apm install` after clone.
/apm.lock.yaml
/AGENTS.md
/CLAUDE.md
/.agents/
/.cursor/
/.claude/skills/
/.claude/agents/
/.claude/hooks/
/.claude/apm-hooks.json
/.claude/rules/
# APM-deployed commands. Allow-list hand-written ones below.
/.claude/commands/*.md
!/.claude/commands/gemini-search.md
# === end APM ===
APM_EXCLUDE
    mv "$tmp" "$exclude_file"
fi

apm_install_ok=0

# Compile APM primitives (.apm/instructions/) into CLAUDE.md and AGENTS.md,
# then refresh dependency refs and run global install so skills are deployed
# to ~/.claude and ~/.agents at their latest upstream versions.
if command -v apm >/dev/null 2>&1; then
    echo "==> apm compile (.apm/instructions -> CLAUDE.md, AGENTS.md)"
    apm compile --clean
    echo "==> apm update --yes (refresh ~/.apm/apm.lock.yaml to latest refs)"
    set +e
    (cd "$HOME/.apm" && apm update --yes --target claude,cursor,codex)
    apm_update_status=$?
    set -e
    if [ "$apm_update_status" -ne 0 ]; then
        echo "warning: 'apm update' reported errors; continuing with available dependency refs."
    fi
    echo "==> apm install -g --target claude,cursor,codex (deploy skills, agents, commands)"
    # Tolerate non-zero exit: 'apm install' returns an error if ANY dependency
    # fails (e.g. an upstream subdirectory was removed), but the packages we
    # depend on still install. Under 'set -e' a partial failure here would abort
    # the script before the hook bridge and settings normalization below run,
    # leaving .claude/settings.json polluted with the invalid 'sessionStart' key.
    if (cd "$HOME/.apm" && apm install -g --target claude,cursor,codex); then
        apm_install_ok=1
    else
        echo "warning: 'apm install' reported errors (e.g. unavailable dependencies);" \
             "continuing so the hook bridge and settings normalization still run."
    fi
    # apm.lock.yaml is intentionally not version-controlled (see .git/info/exclude):
    # it is regenerated per-machine by 'apm update'/'apm install' above and lives
    # only in ~/.apm. Mirroring it back into this repo is no longer needed.
else
    echo "warning: apm not found in PATH; skipping 'apm compile' and 'apm install -g'."
    echo "         Install Agent Package Manager so global rules and skills can be regenerated."
fi

# APM can leave project-local copies of globally deployed Skills under
# .agents/skills. Codex discovers both locations when this repository is the
# working directory, so the local copy shadows the global one. Drop the local
# copy only when it is genuinely redundant.
#
# Deliberately conservative, because the 'apm install' failure above is
# tolerated: a partial install can leave the global side stale, empty, or a
# dangling symlink while the project side still holds the only good copy.
# Matching on the name alone would then delete it. Require all of:
#
#   - 'apm install' reported success on this run
#   - the global entry resolves and actually carries a SKILL.md
#   - the two directories are identical
#
# Anything else is reported and left in place. Verified by
# test/codex_global_agents_distribution_test.sh.
project_skill_dir="$PWD/.agents/skills"
global_skill_dir="$HOME/.agents/skills"
if [ "$apm_install_ok" -eq 1 ] && [ -d "$project_skill_dir" ] && [ -d "$global_skill_dir" ]; then
    for project_skill in "$project_skill_dir"/*
    do
        [ -d "$project_skill" ] || continue
        skill_name=$(basename "$project_skill")
        global_skill="$global_skill_dir/$skill_name"

        # -f follows symlinks, so a dangling global link fails here and the
        # project copy survives.
        [ -f "$project_skill/SKILL.md" ] || continue
        [ -f "$global_skill/SKILL.md" ] || continue

        if diff -rq "$project_skill" "$global_skill" >/dev/null 2>&1; then
            echo "==> removing duplicate project-local Codex Skill: $skill_name"
            command rm -rf "$project_skill"
        else
            echo "warning: keeping project-local Codex Skill '$skill_name':" \
                 "it differs from the global copy, so it may be the newer one."
        fi
    done
fi

# APM's per-dependency targets control where the current install is integrated,
# but they do not remove real files deployed by an earlier, broader target set.
# Remove only the known APM paths whose target ownership changed. The helper
# preserves symlinks so locally-maintained Skills are handled by the link
# cleanup below instead.
if [ "$apm_install_ok" -eq 1 ]; then
    "$PWD/bin/prune_stale_apm_paths" "$HOME/.agents/skills" \
        brainstorming \
        dispatching-parallel-agents \
        executing-plans \
        finishing-a-development-branch \
        receiving-code-review \
        requesting-code-review \
        subagent-driven-development \
        systematic-debugging \
        test-driven-development \
        using-git-worktrees \
        using-superpowers \
        verification-before-completion \
        writing-plans \
        writing-skills \
        rails ruby spec-conventions
    "$PWD/bin/prune_stale_apm_paths" "$HOME/.claude/skills" \
        grill-me \
        grilling \
        wayfinder \
        implement \
        tdd \
        code-review \
        prototype \
        wizard \
        handoff \
        to-questionnaire \
        rails ruby spec-conventions
    "$PWD/bin/prune_stale_apm_paths" "$HOME/.claude/commands" \
        implement.md review.md validate.md
    "$PWD/bin/prune_stale_apm_paths" "$HOME/.cursor/commands" \
        implement.md review.md validate.md
fi

codex_agents_source="$PWD/AGENTS.md"
codex_agents_target="$HOME/.codex/AGENTS.md"
if [ -f "$codex_agents_source" ]; then
    if [ -d "$codex_agents_target" ] && [ ! -L "$codex_agents_target" ]; then
        echo "error: $codex_agents_target is a directory; cannot install Codex global guidance." >&2
        exit 1
    fi
    ln -sfn "$codex_agents_source" "$codex_agents_target"
else
    echo "warning: $codex_agents_source not found; skipping Codex global guidance."
fi

# Codex loads APM-deployed skills directly and does not need the Claude-specific
# SessionStart hook, whose output schema is incompatible with Codex.
command rm -f "$PWD/.codex/hooks.json" "$HOME/.codex/hooks.json"

# APM 0.25.0 drops the multiline security-reviewer description when translating
# YAML frontmatter to Codex TOML. The fixer changes blank descriptions only.
"$PWD/bin/fix_codex_agent_description" "$PWD/.codex/agents/security-reviewer.toml"
"$PWD/bin/fix_codex_agent_description" "$HOME/.codex/agents/security-reviewer.toml"

# Root cause of the above: sorah-guides' security-reviewer.md has invalid YAML
# frontmatter (an unquoted description ending in "Examples:"), so EVERY key is
# dropped -- including `tools: ["Read", "Grep", "Glob", "Bash"]`. Measured
# 2026-07-26: the agent did not load in Claude Code at all. Repair the deployed
# copies after each install; the upstream file in apm_modules/ is refetched on
# update, so this has to run every time rather than being fixed at the source.
# The fixer parses YAML to decide whether a file is actually broken, so it needs
# Ruby. Without mise-managed Ruby we skip rather than guess -- see
# bin/fix_agent_frontmatter.
if command -v mise >/dev/null 2>&1 && mise exec -- ruby --version >/dev/null 2>&1; then
    mise exec -- ruby "$PWD/bin/fix_agent_frontmatter" "$PWD/.claude/agents/security-reviewer.md"
    mise exec -- ruby "$PWD/bin/fix_agent_frontmatter" "$HOME/.claude/agents/security-reviewer.md"
else
    echo "warning: mise-managed ruby not found; skipping agent frontmatter repair." \
         "security-reviewer may load without its read-only tool restriction."
fi

# Companion workaround: 'apm install' and Herdr rewrite .claude/settings.json.
# Run Herdr after APM so its hook script is current, then normalize the result.
# 'apm install' rewrites .claude/settings.json to wire in
# the SessionStart hook that superpowers declares. Verified against APM 0.24.1
# (2026-07-12): it appends its own superpowers 'SessionStart' entry on every run
# (with the install-time-expanded absolute path), so repeated runs accumulate
# duplicate entries. The older 0.14.0 damage -- an invalid lowercase 'sessionStart'
# key and commands pointing at doubled hooks/hooks/ paths -- is no longer produced,
# but we still guard against it. We normalize the hooks block here: drop any stray
# lowercase 'sessionStart' key and pin SessionStart to our canonical entries.
#
# superpowers' entry is deliberately NOT canonical: its session-start script reads
# skills/using-superpowers/SKILL.md in full and injects ~3.5KB into every session,
# which we do not want upfront. Pinning SessionStart to the herdr entry alone is
# what strips APM's re-appended superpowers entry on each run. To re-enable the
# bootstrap, add it back to the canonical list here and in settings.json.
# Herdr's Claude integration reports each pane's session id to the running server
# so it can resume the right conversation after a restart. Its installer appends
# a broad matcher, so the helper pins that output to the canonical matcher after
# refreshing the integration.
"$PWD/bin/install_herdr_claude_integration" "$PWD/.claude/settings.json"

# cman is managed as a Claude Code plugin (`/plugin install cman@cman`), not APM.
# The plugin ships its own .mcp.json pointing at ${CLAUDE_PLUGIN_ROOT}/server.py,
# so nothing needs to be written into settings.json. An earlier revision of this
# script registered mcpServers.plugin_cman_cman against the APM copy at
# ~/.apm/apm_modules/laiso/cman/server.py; that entry outlived the move to plugin
# management and kept launching a stale tree, so it was removed.
#
# What does need doing is a patch. server.py declares `mcp>=1.0` with no upper
# bound and imports mcp.server.fastmcp, which mcp 2.0.0 removed, so a fresh
# dependency resolve breaks every cman MCP tool at startup. See the header of
# patches/cman-pin-mcp.patch for the investigation. Re-run this script after
# `/plugin update cman@cman`: the update replaces the cached server.py and drops
# the patch.
cman_patch="$PWD/patches/cman-pin-mcp.patch"
cman_cache="$HOME/.claude/plugins/cache/cman/cman"
if [ -f "$cman_patch" ] && [ -d "$cman_cache" ]; then
    if ! command -v uv >/dev/null 2>&1; then
        echo "warning: uv not found in PATH; cman MCP server will fail to launch until uv is installed."
    fi
    for cman_server in "$cman_cache"/*/server.py; do
        [ -f "$cman_server" ] || continue
        cman_dir=$(dirname "$cman_server")
        # --forward makes an already-patched tree exit non-zero, so this is idempotent.
        if patch --dry-run -s -N -p1 -d "$cman_dir" < "$cman_patch" >/dev/null 2>&1; then
            patch -s -N -p1 -d "$cman_dir" < "$cman_patch" \
                && echo "==> patched cman: ${cman_dir#"$HOME"/}"
        fi
    done
elif [ -f "$cman_patch" ]; then
    # The plugin cannot be installed from the CLI (`claude plugin` has no install
    # subcommand) and its marketplace/install state lives in Claude Code's own
    # ~/.claude/plugins/*.json, which this script deliberately does not write.
    echo "note: cman plugin not found; run '/plugin install cman@cman' in Claude Code, then re-run this script."
fi

# apm compile writes CLAUDE.md only when it has something to put in it: the
# `@apm_modules/<dep>/CLAUDE.md` lines for dependencies materialized with a root
# CLAUDE.md, plus the instruction bodies when they are not already in
# .claude/rules/. With every dependency scoped to a subpath and the instructions
# deployed as rules, neither applies and no CLAUDE.md is produced. Drop the link
# in that case so ~/.claude/CLAUDE.md does not dangle.
link="$HOME/.claude/CLAUDE.md"
if [ -f "$PWD/CLAUDE.md" ]; then
    if [ -L "$link" ] || [ -e "$link" ]; then
        rm -rf "$link"
    fi
    mkdir -p "$(dirname "$link")"
    ln -s "$PWD/CLAUDE.md" "$link"
elif [ -L "$link" ]; then
    echo "==> removing stale ~/.claude/CLAUDE.md symlink ($PWD/CLAUDE.md is gone)"
    command rm -f "$link"
fi

# Drop links left over from user-skills entries that were deleted or renamed. The
# deploy loops below only walk entries that exist, so without this the link stays
# and dangles. Runs first so a rename is pruned and re-created in the same pass.
"$PWD/bin/prune_stale_skill_links" \
    "$PWD/.claude/user-skills" \
    "$HOME/.claude/skills" \
    "$HOME/.agents/skills"

# Expose each entry under .claude/user-skills/ as a per-entry symlink under
# ~/.claude/skills/. The parent ~/.claude/skills/ is left as a real directory so
# apm-installed skills coexist without writing back into this repo.
mkdir -p "$HOME/.claude/skills"
for skill in "$PWD"/.claude/user-skills/*
do
    [ -e "$skill" ] || continue
    skill_name=$(basename "$skill")
    link="$HOME/.claude/skills/$skill_name"
    if [ -L "$link" ] || [ -e "$link" ]; then
        rm -rf "$link"
    fi
    ln -s "$skill" "$link"
done

# Expose the same locally-maintained skills to Codex without replacing the
# APM-managed parent directory.
mkdir -p "$HOME/.agents/skills"
for skill in "$PWD"/.claude/user-skills/*
do
    [ -e "$skill" ] || continue
    skill_name=$(basename "$skill")
    link="$HOME/.agents/skills/$skill_name"
    if [ -L "$link" ]; then
        rm "$link"
    elif [ -e "$link" ]; then
        echo "warning: refusing to replace non-symlink Skill at $link"
        continue
    fi
    ln -s "$skill" "$link"
done

# Keep the wiki-update health helpers available alongside the skill symlink.
for health_script in \
    "$HOME/.claude/skills/wiki-update/health/wiki-health.rb" \
    "$HOME/.claude/skills/wiki-update/health/mentions.rb" \
    "$HOME/.claude/skills/wiki-update/health/verify-sources.rb"
do
    if [ ! -f "$health_script" ]; then
        echo "error: missing wiki-update health script: $health_script" >&2
        exit 1
    fi
done

# Setup zsh completions
mkdir -p "$HOME/.zsh.d/completions"
curl -fsSL "https://gist.githubusercontent.com/takai/d42693fbd01e8957ca52fa08c8ae660a/raw/_mairu" -o "$HOME/.zsh.d/completions/_mairu"

# ax CLI (the AI-era curl: fetch / discover / extract). APM deploys the ax
# SKILL.md (yusukebe/ax) but not the binary, so the skill is inert without this.
# Install it here for new machines. Idempotent: skip if already on PATH.
if ! command -v ax >/dev/null 2>&1; then
    echo "==> installing ax (https://ax.yusuke.run)"
    curl -fsSL https://ax.yusuke.run/install | sh
fi

# Herdr's Codex integration must be installed after the APM cleanup above,
# which removes Codex hooks generated by unrelated APM dependencies.
if command -v herdr >/dev/null 2>&1; then
    echo "==> installing Herdr Codex integration"
    herdr integration install codex
else
    echo "warning: herdr not found; skipping Codex integration"
fi
