export PATH=$PATH:~/.rvm/bin:/usr/local/sbin
export PATH=~/local/bin:$PATH

[[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm"
rvm use 1.9.3-p194

alias rgu='rvm gemset use'
alias g="git"
alias bw="cd ~/Dropbox/Apps/Byword/"
if [ -f $HOME/dotfiles/git-completion.bash ]; then
    . $HOME/dotfiles/git-completion.bash
fi

alias ls='ls -G'
alias ll='ls -lG'
alias la='ls -laG'
alias vi='vim'
alias red='git'
alias vima='vim **/*'

export GIT_EDITOR=vim

