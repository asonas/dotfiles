export PATH=$PATH:/Users/fuji_seal/.rvm/bin:/usr/local/sbin
export PATH=~/local/bin:$PATH
export BASH_COMPLETION_DIR=/usr/local/etc/bash_completion.d

[[ -s "/Users/fuji_seal/.rvm/scripts/rvm" ]] && source "/Users/fuji_seal/.rvm/scripts/rvm"  # This loads RVM into a shell session.

rvm use 1.9.2

alias rgu='rvm gemset use'

if [ -f /usr/local/etc/bash_completion.d/git-completion.bash ]; then
    . /usr/local/etc/bash_completion.d/git-completion.bash
fi

__git_reminder() {
  [ -d "$PWD/.git" ] || return
  M=
  git status | grep -q '^nothing to commit' 2>/dev/null || M=$M'*'
  [ ! -z "$(git log --pretty=oneline  origin/master..HEAD 2>/dev/null)" ] && M=$M'^'
  echo -n "$M"
}

#_colesc="\[\e["
#_cse="\]"
#_colreset="${_colesc}0m${_cse}"

#export PS1="\u@\h \w[\$(__git_ps1 \"${_colesc}${_cse}%s${_colesc}${_cse}\$(__git_reminder)${_colreset}\")]\\$ "
#export PS1="[\u@\h \w]\$(__git_branch)${_colesc};1m${_cse}${_colesc}31;1m${_cse}\$(__git_reminder)${_colreset}$ "
#export PS1="\u@\h \w[\$(__git_ps1 \"${_colesc}${_cse}%s${_colesc}${_cse}\$(__git_reminder)${_colreset}\")]\\$ "

