#!/bin/sh
cd $(dirname $0)
for dotfile in .?*
do
    if [ $dotfile != '..' ] && [ $dotfile != '.git' ]
    then
        ln -Fis "$PWD/$dotfile" $HOME
    fi
done

mkdir $HOME/bin
ln -Fis "$PWD/bin/video_rahmen" $HOME/bin
ln -Fis "$PWD/bin/loadavg.sh" $HOME/bin
ln -Fis $PWD/.config/nvim $HOME/.config/nvim
ln -Fis $PWD/.config/karabiner $HOME/.config/karabiner
ln -Fis $PWD/.config/starship.toml $HOME/.config/starship.toml
ln -Fis $PWD/.config/wezterm $HOME/.config/wezterm
ln -Fis $PWD/.config/rubocop $HOME/.config/rubocop
