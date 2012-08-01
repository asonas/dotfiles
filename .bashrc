export PATH=$PATH:~/.rvm/bin:/usr/local/sbin
export PATH=~/local/bin:$PATH
export PATH=$PATH:~/.nave/src/0.4.6/build/bin
[[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm"

alias rgu='rvm gemset use'
alias g="git"
alias bw="cd ~/Dropbox/Apps/Byword/"

alias ls='ls -G'
alias ll='ls -lG'
alias la='ls -laG'
alias vi='vim'
alias red='git'
alias vima='vim **/*'
alias r='rails'

export GIT_EDITOR=vim

if [ -f $HOME/dotfiles/git-completion.bash ]; then
    . $HOME/dotfiles/git-completion.bash
fi

export PS1='\[\033[01;32m\]\u@\h\[\033[01;33m\] \w$(__git_ps1) \n\[\033[01;34m\]\$\[\033[00m\] '
