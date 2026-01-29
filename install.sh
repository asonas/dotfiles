#!/bin/sh
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
  .claude/settings.json
  .claude/CLAUDE.md
  .claude/skills
"

for dir in $required_dirs
do
    target="$PWD/$dir"
    link="$HOME/$dir"

    if [ -L "$link" ] || [ -e "$link" ]; then
	rm -rf "$link"
    fi

    mkdir -p "$(dirname "$link")"

    ln -Fis "$target" "$link"
done

[ ! -d "$HOME/bin" ] && mkdir "$HOME/bin"
ln -Ffs "$PWD/bin/check_sip.sh" "$HOME/bin/check_sip.sh"
ln -Ffs "$PWD/bin/setup_workspace" "$HOME/bin/setup_workspace"

case "$OSTYPE" in
  darwin*)
    # macOS
    GIT_PATH=$(brew --prefix git)
    ln -Ffs "$GIT_PATH/share/git-core/contrib/diff-highlight/diff-highlight" "$HOME/bin/diff-highlight"
    ;;
  linux*)
    # Linux
    GIT_PATH=$(dirname "$(which git)")
    ln -Ffs "$GIT_PATH/../share/git/contrib/diff-highlight/diff-highlight" "$HOME/bin/diff-highlight"
    ;;
  *)
    echo "Unsupported OS: $OSTYPE"
    ;;
esac

# Setup zsh completions
mkdir -p "$HOME/.zsh.d/completions"
curl -fsSL "https://gist.githubusercontent.com/takai/d42693fbd01e8957ca52fa08c8ae660a/raw/_mairu" -o "$HOME/.zsh.d/completions/_mairu"
