if [ -f ~/.bashrc ] ; then
. ~/.bashrc
fi

alias ls='ls -G'
alias ll='ls -lG'
alias la='ls -laG'
alias vi='vim'
alias red='git'

export GIT_EDITOR=vim

export PATH=/usr/local/bin:$PATH
export PATH=/Users/fuji_seal/.nave/src/0.4.6/build/default:$PATH

#export TERM=xterm-256color
