if [ -f ~/.bashrc ] ; then
. ~/.bashrc
fi

alias ls='ls -G'
alias ll='ls -lG'
alias la='ls -laG'
alias emacs='emacs-23.3'
alias red='git'

export EDITOR=emacs
export GIT_EDITOR=emacs

export PATH=/usr/local/bin:$PATH
export PATH=/Users/fuji_seal/.nave/src/0.4.6/build/default:$PATH

#export TERM=xterm-256color
