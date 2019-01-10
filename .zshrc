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
alias o='git ls-files | peco | xargs open'
alias oa='git ls-files | peco | xargs atom'
alias e='cd $(ghq list -p | peco)'
alias n='atom $(find node_modules -maxdepth 1 -type d | peco)'
alias s='ssh $(grep -iE "^host[[:space:]]+[^*]" ~/.ssh/config|peco|awk "{print \$2}")'
alias sd='ssh $(grep -iE "^host[[:space:]]+[^*]" ~/.ssh/config|grep deploy|peco|awk "{print \$2}")'
alias br='bin/rails'
alias t='ghi show -w $(ghi list --sort updated | grep -v "open issue" | grep -v "Not Found" | peco | awk "{ print $1 }")'
alias r="bin/rails routes | peco | sed 's/[ \t]*//' | awk -F ' ' '{ print \$1 }' | perl -pe 's/\n//g' | pbcopy"
alias dc='docker-compose'
alias chrome="/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome"
alias pwdc="ruby -rfileutils -e \"print FileUtils.pwd.gsub(' ', '\ ').gsub('(', '\(').gsub(')', '\)')\" | pbcopy"
alias nv="nvim"
alias vim="nvim"

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
  rails new --database postgresql $1
}

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

# pyenv
export PYENV_ROOT=/usr/local/var/pyenv
if which pyenv > /dev/null; then eval "$(pyenv init -)"; fi

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
    ;;
esac

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm

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
