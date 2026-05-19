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

# Compile APM primitives (.apm/instructions/) into CLAUDE.md and AGENTS.md,
# then run global install so skills are deployed to ~/.claude and ~/.agents.
if command -v apm >/dev/null 2>&1; then
    echo "==> apm compile (.apm/instructions -> CLAUDE.md, AGENTS.md)"
    apm compile
    echo "==> apm install -g --target claude,cursor (deploy skills, agents, commands)"
    (cd "$HOME/.apm" && apm install -g --target claude,cursor)
else
    echo "warning: apm not found in PATH; skipping 'apm compile' and 'apm install -g'."
    echo "         Install Agent Package Manager so global rules and skills can be regenerated."
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
    ghq get "$repo"
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

# Setup zsh completions
mkdir -p "$HOME/.zsh.d/completions"
curl -fsSL "https://gist.githubusercontent.com/takai/d42693fbd01e8957ca52fa08c8ae660a/raw/_mairu" -o "$HOME/.zsh.d/completions/_mairu"
