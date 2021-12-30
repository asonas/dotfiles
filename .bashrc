
#### FIG ENV VARIABLES ####
# Please make sure this block is at the start of this file.
[ -s ~/.fig/shell/pre.sh ] && source ~/.fig/shell/pre.sh
#### END FIG ENV VARIABLES ####
export PATH=~/local/bin:$PATH

alias g="git"
alias bw="cd ~/Dropbox/Apps/Byword/"

alias ls='ls -G'
alias ll='ls -lG'
alias la='ls -laG'
alias vi='vim'
alias red='git'
alias via='vim **/*'
alias r='rails'
alias rb='rbenv'
alias rl='rbenv local'
alias be='bundle exec'
alias pythonserver='python -m SimpleHTTPServer'
alias rmstore="rm .DS_Store; rm */.DS_Store"
alias rmstorer="rm **/.DS_Store"

export GIT_EDITOR=vim

if [ -f $HOME/dotfiles/.git-completion.bash ]; then
    . $HOME/dotfiles/git-prompt.sh
fi
source $HOME/dotfiles/.git-completion.bash
source $HOME/dotfiles/git-prompt.sh

export PS1='\[\033[01;32m\]\u@\h\[\033[01;33m\] \w$(__git_ps1) \n\[\033[01;34m\]\$\[\033[00m\] '

function share_history {  # 以下の内容を関数として定義
  history -a  # .bash_historyに前回コマンドを1行追記
  history -c  # 端末ローカルの履歴を一旦消去
  history -r  # .bash_historyから履歴を読み込み直す
}

PROMPT_COMMAND='share_history'
shopt -u histappend
export HISTFILE=~/.bash_history
export HISTSIZE=530000

# added by travis gem
source /Users/asonas/.travis/travis.sh

#### FIG ENV VARIABLES ####
# Please make sure this block is at the end of this file.
[ -s ~/.fig/fig.sh ] && source ~/.fig/fig.sh
#### END FIG ENV VARIABLES ####
