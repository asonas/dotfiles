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

"$PWD/bin/install_apm_environment"

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
