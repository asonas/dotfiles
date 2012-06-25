export PATH=$PATH:~/.rvm/bin:/usr/local/sbin
export PATH=~/local/bin:$PATH

[[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm"

alias rgu='rvm gemset use'
alias g="git"
alias bw="cd ~/Dropbox/Apps/Byword/"

alias ls='ls -G'
alias ll='ls -lG'
alias la='ls -laG'
alias vi='vim'
alias red='git'

export GIT_EDITOR=vim

if [ -f $HOME/dotfiles/git-completion.bash ]; then
    . $HOME/dotfiles/git-completion.bash
fi


