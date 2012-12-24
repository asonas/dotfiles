export PATH=$PATH:~/.rvm/bin:/usr/local/sbin
export PATH=~/local/bin:$PATH
export PATH=$PATH:~/.nave/src/0.4.6/build/bin
export RSENSE_HOME=$HOME/.vim/ref/rsense-0.3

[[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm"

alias rgu='rvm gemset use'
alias g="git"
alias bw="cd ~/Dropbox/Apps/Byword/"

alias ls='ls -G'
alias ll='ls -lG'
alias la='ls -laG'
alias vi='vim'
alias red='git'
alias via='vim **/*'
alias r='rails'
alias rgl='rvm gemset list'
alias ru='rvm use'
alias rb='rbenv'
alias rl='rbenv local'
alias be='bundle exec'
alias pythonserver='python -m SimpleHTTPServer'
export GIT_EDITOR=vim

if [ -f $HOME/dotfiles/.git-completion.bash ]; then
    . $HOME/dotfiles/git-prompt.sh
fi
source $HOME/dotfiles/.git-completion.bash
source $HOME/dotfiles/git-prompt.sh

export PS1='\[\033[01;32m\]\u@\h\[\033[01;33m\] \w$(__git_ps1) \n\[\033[01;34m\]\$\[\033[00m\] '
