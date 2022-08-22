
#### FIG ENV VARIABLES ####
# Please make sure this block is at the start of this file.
[ -s ~/.fig/shell/pre.sh ] && source ~/.fig/shell/pre.sh
#### END FIG ENV VARIABLES ####
#zmodload zsh/zprof && zprof

# see also
# https://gist.github.com/mollifier/4979906

#######################################
# Alias

alias be="bundle exec"
alias g="git"
alias rmstore="rm .DS_Store; rm */.DS_Store"
alias rmstorer="rm **/.DS_Store"
alias pythonserver='python -m SimpleHTTPServer'
alias chhash="perl -pi -e 's/:([\w\d_]+)(\s*)=>/\1:/g'"
alias mm="middleman"
alias o='git ls-files | peco | xargs vim '
alias oa='git ls-files | peco | xargs atom'
alias e='cd $GHQ_ROOT/$(ghq list | peco )'
alias q='cd $(GHQ_ROOT=~/go ghq list -p | peco)'
alias n='atom $(find node_modules -maxdepth 1 -type d | peco)'
alias s='ssh $(grep -iE "^host[[:space:]]+[^*]" ~/.ssh/config|peco|awk "{print \$2}")'
alias sd='ssh $(grep -iE "^host[[:space:]]+[^*]" ~/.ssh/config|grep deploy|peco|awk "{print \$2}")'
alias br='bin/rails'
alias t='ghi show -w $(ghi list --sort updated | grep -v "open issue" | grep -v "Not Found" | peco | awk "{ print $1 }")'
alias r="bin/rails routes | peco | sed 's/[ \t]*//' | awk -F ' ' '{ print \$1 }' | perl -pe 's/\n//g' | pbcopy"
alias dc='docker-compose'
alias pwdc="ruby -rfileutils -e \"print FileUtils.pwd.gsub(' ', '\ ').gsub('(', '\(').gsub(')', '\)')\" | pbcopy"
alias nv="nvim"
alias vim="nvim"
alias le="less"
alias cip='ifconfig en0 | grep -Eo "inet \d+(\.\d+){3}" | sed -e "s/inet //g" | tr -d "\n" | pbcopy'
alias p=peco-checkout-pull-request
alias cdg='cd $(git rev-parse --show-toplevel)'

function pr() {
  git branch -a --sort=authordate | grep -e 'remotes' | grep -v -e '->' -e '*' -e 'asonas' -e 'master' | perl -pe 's/^\h+//g' | perl -pe 's#^remotes/##' | perl -nle 'print if !$c{$_}++' | peco | ruby -e 'r=STDIN.read;b=r.split("/")[1..];system("git", "switch", "-c", b.join("/").strip, r.strip)'
}

function refresh-remotes {
  all-remotes-cleanup
  all-remotes-fetch
}

function all-remotes-fetch() {
  for i in $(git remotes | awk '{print $1}' | uniq)
  do
    git fetch $i
  done
}

function all-remotes-cleanup() {
  for i in $(git remotes | awk '{print $1}' | uniq)
  do
    git cleanup $i
  done
}

function p2 () {
  local user="ec2-user"
  local host=$(envchain asonas-aws aws ec2 describe-instances --region ap-northeast-1 --output json --filters "Name=instance-state-code,Values=16" | jq -r '.Reservations[].Instances[] | [.Tags[] | select(.Key == "Name").Value][] + "\t" +  .InstanceType + "\t" + .PublicIpAddress + "\t" + .Platform' | awk '{if ($4 != "windows") printf "%-45s %-15s %-10s\n",$1,$2,$3}' | sort | peco | awk '{print $3}')
  ssh "$user@$host"
}

function peco-history-selection() {
    BUFFER=`history -n 1 | tail -r  | awk '!a[$0]++' | peco`
    CURSOR=$#BUFFER
    zle reset-prompt
}

function mkdirt() {
  prefix=$1
  date=`date '+%F'`
  if [ -n "$prefix" ]; then
    mkdir -p "$prefix-$date"
  else
    mkdir -p "$date"
  fi
}

zle -N peco-history-selection
bindkey '^Q' peco-history-selection

function randomstr() {
  cat /dev/urandom | LC_CTYPE=C tr -dc '[:alnum:]' | head -c $1 | xargs echo
}

function new() {
  repo="$(ghq root)/github.com/asonas/$1"
  mkdir -p $repo
  cd $repo
  git init
}

function rails_new() {
  root="$(ghq root)/github.com/asonas/"
  cd $root
  rails _6.0.3.1_ new --database postgresql $1
}

function peco-checkout-pull-request () {
    local selected_pr_id=$(gh pr list | peco | awk '{ print $1 }')
    if [ -n "$selected_pr_id" ]; then
        BUFFER="gh pr checkout ${selected_pr_id}"
        zle accept-line
    fi
    zle clear-screen
}
zle -N peco-checkout-pull-request

########################################
# 環境変数
export LANG=ja_JP.UTF-8

# 色を使用出来るようにする
autoload -Uz colors
colors

# emacs 風キーバインドにする
bindkey -e

# ヒストリの設定
HISTFILE=~/.zsh_history
HISTSIZE=1000000
SAVEHIST=1000000

# http://d.hatena.ne.jp/Yoshiori/20120814/1344913023
REPORTTIME=3

function current_branch() {
  git branch | grep \* | awk '{print $2}'
}

function git-diff-numstat-additions() {
  git diff $(current_branch)..master --numstat | awk 'NF==3 {plus+=$2} END {printf("+%\047d", plus)}'
}

function git-diff-numstat-deletions() {
  git diff $(current_branch)..master --numstat | awk 'NF==3 {minus+=$1} END {printf("+%\047d", minus)}'
}

# プロンプト
# 1行表示
# PROMPT="%~ %# "
# 2行表示
PROMPT='%{$fg[blue]%}.-%{${reset_color}%}%{${fg[cyan]}%}[%T]%{${reset_color}%} %{$fg[blue]%}%n@%m%{${reset_color}%}:%~ ${vcs_info_msg_0_}
%{$fg[blue]%}\`-%{${reset_color}%}%# '

# personal bin directory
export PATH="$HOME/bin:$PATH"
export PATH="$HOME/dev/bin:$PATH"
export PATH="$HOME/dev/local/bin:$PATH"
export PATH="$HOME/dotfiles/script:$PATH"
export PATH="/usr/local/bin:$PATH"
export PATH="/usr/local/sbin:$PATH"
export PATH="/usr/local/go/bin:$PATH"

# rbenv
export PATH="$HOME/.rbenv/shims:$PATH"
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

# android sdk
export ANDROID_SDK_HOME=/Users/asonas/dev/local/android/sdk
export PATH=$PATH:$ANDROID_SDK_HOME/tools
export PATH=$PATH:$ANDROID_SDK_HOME/platform-tools

# node
export PATH=$PATH:/usr/local/share/npm/bin

# go
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"

export GHQ_ROOT="$HOME/ghq"

setopt nolistbeep

#単語の区切り文字を指定する
autoload -Uz select-word-style
select-word-style default
# ここで指定した文字は単語区切りとみなされる
# / も区切りと扱うので、^W でディレクトリ１つ分を削除できる
zstyle ':zle:*' word-chars " /=;@:{},|"
zstyle ':zle:*' word-style unspecified

# 補完で小文字でも大文字にマッチさせる
#zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# ../ の後は今いるディレクトリを補完しない
zstyle ':completion:*' ignore-parents parent pwd ..

# sudo の後ろでコマンド名を補完する
zstyle ':completion:*:sudo:*' command-path /usr/local/sbin /usr/local/bin \
                   /usr/sbin /usr/bin /sbin /bin /usr/X11R6/bin

# ps コマンドのプロセス名補完
zstyle ':completion:*:processes' command 'ps x -o pid,s,args'

# git
a() { git add $*; git status -s }

########################################
# vcs_info

autoload -Uz vcs_info
zstyle ':vcs_info:*' formats '%F{magenta}(%b)%f'
zstyle ':vcs_info:*' actionformats '%F{magenta}(%b|%a)%f'
setopt prompt_subst
precmd() { vcs_info }

########################################
# オプション
# 日本語ファイル名を表示可能にする
setopt print_eight_bit

# beep を無効にする
setopt no_beep

# フローコントロールを無効にする
setopt no_flow_control

# '#' 以降をコメントとして扱う
setopt interactive_comments

# = の後はパス名として補完する
setopt magic_equal_subst

# 同時に起動したzshの間でヒストリを共有する
setopt share_history

# 同じコマンドをヒストリに残さない
setopt hist_ignore_all_dups

# ヒストリファイルに保存するとき、すでに重複したコマンドがあったら古い方を削除する
setopt hist_save_nodups

# スペースから始まるコマンド行はヒストリに残さない
setopt hist_ignore_space

# ヒストリに保存するときに余分なスペースを削除する
setopt hist_reduce_blanks

# 補完候補が複数あるときに自動的に一覧表示する
setopt auto_menu

# 高機能なワイルドカード展開を使用する
setopt extended_glob

########################################
# キーバインド

# ^R で履歴検索をするときに * でワイルドカードを使用出来るようにする
bindkey '^R' history-incremental-pattern-search-backward

########################################
# エイリアス

alias la='ls -a'
alias ll='ls -l'

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

alias mkdir='mkdir -p'

# グローバルエイリアス
alias -g L='| less'
alias -g G='| grep'

# C で標準出力をクリップボードにコピーする
# mollifier delta blog : http://mollifier.hatenablog.com/entry/20100317/p1
if which pbcopy >/dev/null 2>&1 ; then
    # Mac
    alias -g C='| pbcopy'
elif which xsel >/dev/null 2>&1 ; then
    # Linux
    alias -g C='| xsel --input --clipboard'
elif which putclip >/dev/null 2>&1 ; then
    # Cygwin
    alias -g C='| putclip'
fi


########################################
# OS 別の設定
case ${OSTYPE} in
  darwin*)
    #Mac用の設定
    export CLICOLOR=1
    alias ls='ls -G -F'

    ########################################
    # 補完
    # 補完機能を有効にする
    fpath=($(brew --prefix)/share/zsh/site-functions $fpath)
    fpath=(~/.zsh/completions $fpath)
    fpath=(~/.zsh.d/completions $fpath)
    alias git=hub
    autoload -Uz compinit
    compinit

    # terminal-notifier
    #autoload -U add-zsh-hook
    #export SYS_NOTIFIER="/usr/local/bin/terminal-notifier"
    #source ~/.zsh.d/zsh-notify/notify.plugin.zsh
    #export NOTIFY_COMMAND_COMPLETE_TIMEOUT=10

    test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
    ;;
  linux*)
    #Linux用の設定
    zstyle ':completion:*:*:git:*' script ~/.zsh/completions/git-completion.zsh
    autoload -Uz compinit
    compinit
    source /usr/share/mitamae/profile
    ;;
esac

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm

source $HOME/.cargo/env
source ~/.zsh.d/personal
# nvm() {
#    unset -f nvm
#    source "${NVM_DIR:-$HOME/.nvm}/nvm.sh"
#    nvm "$@"
#}

#if (which zprof > /dev/null) ;then
#  zprof | less
#fi
export PATH="/usr/local/opt/qt@5.5/bin:$PATH"

# heroku autocomplete setup
HEROKU_AC_ZSH_SETUP_PATH=/Users/asonas/Library/Caches/heroku/autocomplete/zsh_setup && test -f $HEROKU_AC_ZSH_SETUP_PATH && source $HEROKU_AC_ZSH_SETUP_PATH;
export PATH="/opt/brew/opt/awscli@1/bin:$PATH"
export PATH="/opt/brew/opt/avr-gcc@8/bin:$PATH"

#### FIG ENV VARIABLES ####
# Please make sure this block is at the end of this file.
# [ -s ~/.fig/fig.sh ] && source ~/.fig/fig.sh
#### END FIG ENV VARIABLES ####
eval "$(starship init zsh)"