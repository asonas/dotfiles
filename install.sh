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
ln -Fis "$PWD/bin/video_rahmen" "$HOME/bin/video_rahmen"
ln -Fis "$PWD/bin/loadavg.sh" "$HOME/bin/loadavg.sh"

case "$OSTYPE" in
  darwin*)
    # macOS
    GIT_PATH=$(brew --prefix git)
    ln -Fis "$GIT_PATH/share/git-core/contrib/diff-highlight/diff-highlight" "$HOME/bin/diff-highlight"
    ;;
  linux*)
    # Linux
    GIT_PATH=$(dirname "$(which git)")
    ln -Fis "$GIT_PATH/../share/git/contrib/diff-highlight/diff-highlight" "$HOME/bin/diff-highlight"
    ;;
  *)
    echo "Unsupported OS: $OSTYPE"
    ;;
esac
