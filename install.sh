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
  .zsh.d/pnpm-completion.zsh
  .claude/commands/gemini-search.md
  .claude/commands/talk-review
  .claude/settings.json
  .claude/CLAUDE.md
  .claude/skills
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

# Setup external Claude skills via ghq
ghq_skills="
  git@github.com:blader/humanizer.git
"
for repo in $ghq_skills
do
    ghq get "$repo"
    repo_path=$(ghq list -p "$repo")
    skill_name=$(basename "$repo_path")
    link="$PWD/.claude/skills/$skill_name"
    if [ -L "$link" ] || [ -e "$link" ]; then
        rm -rf "$link"
    fi
    ln -Fis "$repo_path" "$link"
done

# Setup zsh completions
mkdir -p "$HOME/.zsh.d/completions"
curl -fsSL "https://gist.githubusercontent.com/takai/d42693fbd01e8957ca52fa08c8ae660a/raw/_mairu" -o "$HOME/.zsh.d/completions/_mairu"
