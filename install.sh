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
