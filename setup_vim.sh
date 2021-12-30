mkdir -p tmp
curl https://raw.githubusercontent.com/Shougo/dein.vim/master/bin/installer.sh > tmp/installer.sh
sh ./tmp/installer.sh ~/.vim/dein

/usr/bin/python -m pip install pynvim

pip3 install --user pynvim
