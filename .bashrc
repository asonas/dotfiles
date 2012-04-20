export PATH=$PATH:~/.rvm/bin:/usr/local/sbin
export PATH=~/local/bin:$PATH

[[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm"
rvm use 1.9.2

alias rgu='rvm gemset use'
alias g="git"
alias bw="cd ~/Dropbox/Apps/Byword/"
if [ -f $HOME/git-completion.bash ]; then
    . $HOME/git-completion.bash
fi


