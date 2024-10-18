#!/bin/sh
set -e

cd "$(dirname "$0")"

required_dirs="
  .config/nvim
  .config/karabiner
  .config/starship.toml
  .config/wezterm
  .config/rubocop
  .config/peco
  .config/htop
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
