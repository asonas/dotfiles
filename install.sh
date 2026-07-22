#!/bin/bash
set -e

cd "$(dirname "$0")"

required_dirs="
  .zshrc
  .skhdrc
  .yabairc
  .gitignore
  .gitconfig
  .tigrc
  .gemrc
  .irbrc
  .psqlrc
  .tmux.conf
  .config/nvim
  .config/karabiner
  .config/starship.toml
  .config/wezterm
  .config/rubocop
  .config/peco
  .config/htop
  .config/ghostty
  .config/git-ai-commit/config.toml
  .config/mise/config.toml

  .claude/commands/gemini-search.md
  .claude/commands/talk-review
  .claude/settings.json
  .claude/scripts
  .claude/rules
"

for dir in $required_dirs
do
    target="$PWD/$dir"
    link="$HOME/$dir"

    if [ -L "$link" ] || [ -e "$link" ]; then
	rm -rf "$link"
    fi

    mkdir -p "$(dirname "$link")"

    ln -s "$target" "$link"
done

[ ! -d "$HOME/bin" ] && mkdir "$HOME/bin"
ln -sf "$PWD/bin/check_sip.sh" "$HOME/bin/check_sip.sh"
ln -sf "$PWD/bin/setup_workspace" "$HOME/bin/setup_workspace"
ln -sf "$PWD/bin/ghro" "$HOME/bin/ghro"
ln -sf "$PWD/bin/herdr-focus-attention" "$HOME/bin/herdr-focus-attention"

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

# herdr Claude integration hook: vendor the reporting script instead of running
# `herdr integration install claude` on each machine. That command rewrites
# ~/.claude/settings.json (which is a symlink into this repo) with alphabetically
# sorted keys AND appends a duplicate '*'-matcher hook entry, dirtying the repo on
# every new-machine bootstrap. By symlinking the version-pinned script here, the
# hook is present everywhere and the SessionStart normalization below keeps its own
# canonical entry, so settings.json never gets churned. Re-vendor by copying
# ~/.claude/hooks/herdr-agent-state.sh after a `herdr` upgrade bumps the integration
# version (check with `herdr integration status`).
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
# Run `apm install && apm compile` after clone to regenerate everything below.
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

# Compile APM primitives (.apm/instructions/) into CLAUDE.md and AGENTS.md,
# then refresh dependency refs and run global install so skills are deployed
# to ~/.claude and ~/.agents at their latest upstream versions.
if command -v apm >/dev/null 2>&1; then
    echo "==> apm compile (.apm/instructions -> CLAUDE.md, AGENTS.md)"
    apm compile
    echo "==> apm update --yes (refresh ~/.apm/apm.lock.yaml to latest refs)"
    (cd "$HOME/.apm" && apm update --yes --target claude,cursor,codex)
    echo "==> apm install -g --target claude,cursor,codex (deploy skills, agents, commands)"
    # Tolerate non-zero exit: 'apm install' returns an error if ANY dependency
    # fails (e.g. an upstream subdirectory was removed), but the packages we
    # depend on still install. Under 'set -e' a partial failure here would abort
    # the script before the hook bridge and settings normalization below run,
    # leaving .claude/settings.json polluted with the invalid 'sessionStart' key.
    if ! (cd "$HOME/.apm" && apm install -g --target claude,cursor,codex); then
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

codex_agents_source="$PWD/AGENTS.md"
codex_agents_target="$HOME/.codex/AGENTS.md"
if [ -f "$codex_agents_source" ]; then
    if [ -d "$codex_agents_target" ]; then
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

# obra/superpowers ships a SessionStart hook (hooks/hooks.json) that runs
# run-hook.cmd, which execs the extensionless 'session-start' script and reads
# ${PLUGIN_ROOT}/skills/using-superpowers/SKILL.md (PLUGIN_ROOT resolves to
# ~/.claude/hooks/superpowers). Verified against APM 0.24.1 (2026-07-12):
#   - 'apm install' now deploys BOTH run-hook.cmd and session-start as real
#     files under ~/.claude/hooks/superpowers/hooks/. The older 0.14.0 bug that
#     skipped session-start (APM looked at a doubled hooks/hooks/ path) is fixed.
#   - It still does NOT deploy skills/ under the plugin hook root: superpowers
#     skills land in ~/.claude/skills/, not ~/.claude/hooks/superpowers/skills/,
#     so session-start cannot find SKILL.md there.
# So the only bridge still required is skills/. The session-start symlink is kept
# purely as a defensive fallback and is created only when APM left the file
# missing, so we don't clobber APM's real copy on every run.
superpowers_src="$HOME/.apm/apm_modules/obra/superpowers"
superpowers_dst="$HOME/.claude/hooks/superpowers"
if [ -d "$superpowers_src/skills" ]; then
    mkdir -p "$superpowers_dst/hooks"
    [ -e "$superpowers_dst/hooks/session-start" ] || \
        ln -sfn "$superpowers_src/hooks/session-start" \
                "$superpowers_dst/hooks/session-start"
    ln -sfn "$superpowers_src/skills" "$superpowers_dst/skills"
fi

# Companion workaround: 'apm install' rewrites .claude/settings.json to wire in
# the SessionStart hook that superpowers declares. Verified against APM 0.24.1
# (2026-07-12): it appends its own superpowers 'SessionStart' entry on every run
# (with the install-time-expanded absolute path), so repeated runs accumulate
# duplicate entries. The older 0.14.0 damage -- an invalid lowercase 'sessionStart'
# key and commands pointing at doubled hooks/hooks/ paths -- is no longer produced,
# but we still guard against it. We normalize the hooks block here: drop any stray
# lowercase 'sessionStart' key and pin SessionStart to our canonical entries
# (superpowers with a portable $HOME path, plus the herdr hook below). This both
# de-duplicates APM's re-appended entry and keeps hand-managed hooks from being lost.
settings_file="$PWD/.claude/settings.json"
if command -v jq >/dev/null 2>&1 && [ -f "$settings_file" ]; then
    # Write a literal $HOME (not the install-time expansion) so the committed
    # settings.json is portable across macOS (/Users/...) and Linux (/home/...).
    # The hook command runs via a shell, which expands $HOME at session start.
    canonical_cmd='"$HOME/.claude/hooks/superpowers/hooks/run-hook.cmd" session-start'
    # herdr's Claude integration reports each pane's session id to the running
    # herdr server so it can `claude --resume <id>` after a server/host restart
    # (config: [session] resume_agents_on_restore). The reporting hook is the
    # herdr-agent-state.sh script vendored and symlinked above; without it herdr
    # only knows a pane runs claude, not which conversation. apm's normalization
    # would otherwise drop this entry, so bake it into the canonical SessionStart
    # here. Include it only when the script exists so non-herdr machines don't
    # get a "No such file or directory" SessionStart error. The 'resume' matcher
    # ensures the id is re-reported when a session is itself resumed.
    herdr_hook="$HOME/.claude/hooks/herdr-agent-state.sh"
    tmp=$(mktemp)
    if [ -f "$herdr_hook" ]; then
        herdr_cmd='"$HOME/.claude/hooks/herdr-agent-state.sh" session'
        jq --arg cmd "$canonical_cmd" --arg herdr "$herdr_cmd" '
          .hooks |= (
            del(.sessionStart)
            | .SessionStart = [
                {
                  matcher: "startup|clear|compact",
                  hooks: [{
                    type: "command",
                    command: $cmd,
                    async: false
                  }]
                },
                {
                  matcher: "startup|resume|clear|compact",
                  hooks: [{
                    type: "command",
                    command: $herdr
                  }]
                }
              ]
          )
        ' "$settings_file" > "$tmp" && mv "$tmp" "$settings_file"
    else
        jq --arg cmd "$canonical_cmd" '
          .hooks |= (
            del(.sessionStart)
            | .SessionStart = [{
                matcher: "startup|clear|compact",
                hooks: [{
                  type: "command",
                  command: $cmd,
                  async: false
                }]
              }]
          )
        ' "$settings_file" > "$tmp" && mv "$tmp" "$settings_file"
    fi
else
    echo "warning: jq not found or $settings_file missing; skipping SessionStart hook normalization."
fi

# Register cman MCP server. APM deploys cman's skills (cm-search, cm-status,
# remember) to ~/.claude/skills/ but does NOT register the MCP server that
# those skills depend on (their allowed-tools is mcp__plugin_cman_cman__*).
# The Claude plugin marketplace install path would wire the server under the
# 'plugin_cman_cman' name; we replicate that name so the tool prefix expected
# by the skills resolves. uv is required so PEP 723 inline-metadata
# dependencies in server.py are auto-installed on first run.
cman_server="$HOME/.apm/apm_modules/laiso/cman/server.py"
if [ -f "$cman_server" ] && command -v jq >/dev/null 2>&1 && [ -f "$settings_file" ]; then
    if ! command -v uv >/dev/null 2>&1; then
        echo "warning: uv not found in PATH; cman MCP server will fail to launch until uv is installed."
    fi
    tmp=$(mktemp)
    jq --arg path "$cman_server" '
      .mcpServers["plugin_cman_cman"] = {
        command: "uv",
        args: ["run", $path]
      }
    ' "$settings_file" > "$tmp" && mv "$tmp" "$settings_file"
fi

if [ -f "$PWD/CLAUDE.md" ]; then
    link="$HOME/.claude/CLAUDE.md"
    if [ -L "$link" ] || [ -e "$link" ]; then
        rm -rf "$link"
    fi
    mkdir -p "$(dirname "$link")"
    ln -s "$PWD/CLAUDE.md" "$link"
else
    echo "warning: $PWD/CLAUDE.md not found; skipping ~/.claude/CLAUDE.md symlink."
fi

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

# EasyEDA API skill (darwin-only). Unlike the source-only skills handled by APM,
# this one ships a Node.js bridge server (npm run server) and is driven against
# the EasyEDA Pro desktop client, so it needs a real working clone and is only
# useful on macOS. APM cannot express per-OS gating, hence it lives here. The
# skill bootstraps its own node_modules via `cd ${CLAUDE_SKILL_DIR} && npm install`,
# which rewrites package-lock.json and leaves the working tree dirty. A `-u` pull
# would then fail ("cannot pull with rebase: unstaged changes") and, under set -e,
# abort this script — so use plain `ghq get` (clone if missing, never auto-pull)
# and treat the clone as a working tree to be updated by hand. Guarded so a clone
# failure on this optional skill does not block the rest of install.
case "$OSTYPE" in
  darwin*)
    if ghq get easyeda/easyeda-api-skill; then
        easyeda_path=$(ghq list -p easyeda/easyeda-api-skill)
        if [ -n "$easyeda_path" ]; then
            mkdir -p "$HOME/.claude/skills"
            link="$HOME/.claude/skills/easyeda-api"
            if [ -L "$link" ] || [ -e "$link" ]; then
                rm -rf "$link"
            fi
            ln -s "$easyeda_path" "$link"
        fi
    fi
    ;;
esac

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
