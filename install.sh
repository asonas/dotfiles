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
# Sources to keep tracked: .apm/instructions/, apm.yml, apm.lock.yaml.
# Run `apm install && apm compile` after clone to regenerate everything below.
# These live here (not in the symlinked .gitignore) so they don't pollute the
# global core.excludesfile and hide CLAUDE.md/AGENTS.md/etc. in other repos.
apm_modules/
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
    # ~/.apm/apm.yml is a symlink into this repo, but the lockfile written by
    # 'apm update' lives in ~/.apm. Mirror it back so the deployed versions
    # stay version-controlled alongside apm.yml.
    if [ -f "$HOME/.apm/apm.lock.yaml" ]; then
        cp "$HOME/.apm/apm.lock.yaml" "$PWD/apm.lock.yaml"
    fi
else
    echo "warning: apm not found in PATH; skipping 'apm compile' and 'apm install -g'."
    echo "         Install Agent Package Manager so global rules and skills can be regenerated."
fi

# Workaround for APM v0.14.0 bug: 'apm install' deploys only run-hook.cmd
# from obra/superpowers' hooks/ directory and silently skips session-start
# (APM searches at hooks/hooks/run-hook.cmd, a doubled 'hooks/' segment),
# leaving the SessionStart hook configured in .claude/settings.json pointing
# at a non-existent script. Bridge the missing files from apm_modules/ so
# 'run-hook.cmd session-start' resolves. Remove once APM ships a fix.
superpowers_src="$HOME/.apm/apm_modules/obra/superpowers"
superpowers_dst="$HOME/.claude/hooks/superpowers"
if [ -f "$superpowers_src/hooks/session-start" ]; then
    mkdir -p "$superpowers_dst/hooks"
    ln -sfn "$superpowers_src/hooks/session-start" \
            "$superpowers_dst/hooks/session-start"
    # session-start reads ${PLUGIN_ROOT}/skills/using-superpowers/SKILL.md,
    # where PLUGIN_ROOT resolves to $superpowers_dst, so bridge skills/ too.
    ln -sfn "$superpowers_src/skills" "$superpowers_dst/skills"
fi

# Companion workaround: 'apm install' rewrites .claude/settings.json by
# (1) adding an invalid 'sessionStart' (lowercase) key whose commands point at
# the doubled hooks/hooks/ paths APM tried and failed to find, and
# (2) duplicating the canonical 'SessionStart' entry. Both happen on every run,
# so we normalize the hooks block here: drop the lowercase key and pin
# SessionStart to a single entry that calls our workaround symlinks.
settings_file="$PWD/.claude/settings.json"
if command -v jq >/dev/null 2>&1 && [ -f "$settings_file" ]; then
    # Write a literal $HOME (not the install-time expansion) so the committed
    # settings.json is portable across macOS (/Users/...) and Linux (/home/...).
    # The hook command runs via a shell, which expands $HOME at session start.
    canonical_cmd='"$HOME/.claude/hooks/superpowers/hooks/run-hook.cmd" session-start'
    tmp=$(mktemp)
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

# Setup external Claude skills via ghq, parked under .claude/user-skills/
# so they live alongside the hand-authored skills.
ghq_skills="
  git@github.com:blader/humanizer.git
"
for repo in $ghq_skills
do
    ghq get -u "$repo"
    repo_path=$(ghq list -p "$repo")
    skill_name=$(basename "$repo_path")
    link="$PWD/.claude/user-skills/$skill_name"
    if [ -L "$link" ] || [ -e "$link" ]; then
        rm -rf "$link"
    fi
    ln -Fis "$repo_path" "$link"
done

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
