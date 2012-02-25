export PATH=$PATH:/Users/fuji_seal/.rvm/bin:/usr/local/sbin
export PATH=~/local/bin:$PATH
export BASH_COMPLETION_DIR=/usr/local/etc/bash_completion.d

[[ -s "/Users/fuji_seal/.rvm/scripts/rvm" ]] && source "/Users/fuji_seal/.rvm/scripts/rvm"  # This loads RVM into a shell session.

rvm use 1.9.2
ruby $HOME/dotfiles/miserarenaiyo/start_up_term.rb

alias rgu='rvm gemset use'

if [ -f /usr/local/etc/bash_completion.d/git-completion.bash ]; then
    . /usr/local/etc/bash_completion.d/git-completion.bash
fi


