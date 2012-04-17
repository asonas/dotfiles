export PATH=$PATH:~/.rvm/bin:/usr/local/sbin
export PATH=~/local/bin:$PATH

[[ -s "~/.rvm/scripts/rvm" ]] && source "~/.rvm/scripts/rvm"  # This loads RVM into a shell session.

rvm use 1.9.2
#ruby $HOME/dotfiles/miserarenaiyo/start_up_term.rb

alias rgu='rvm gemset use'
alias g="g"
if [ -f $HOME/git-completion.bash ]; then
    . $HOME/git-completion.bash
fi


