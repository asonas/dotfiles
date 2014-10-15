# see also
# https://gist.github.com/mollifier/4979906

#######################################
# Alias

alias be="bundle exec"
alias g="git"
alias r="rails"
alias rmstore="rm .DS_Store; rm */.DS_Store"
alias rmstorer="rm **/.DS_Store"
alias pythonserver='python -m SimpleHTTPServer'
alias chhash="perl -pi -e 's/:([\w\d_]+)(\s*)=>/\1:/g'"
alias mm="middleman"
alias o='git ls-files | peco | xargs open'
alias e='cd $(ghq list -p | peco)'
alias br='bin/rails'

function randomstr() {
  cat /dev/urandom | LC_CTYPE=C tr -dc '[:alnum:]' | head -c $1 | xargs echo
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

# プロンプト
# 1行表示
# PROMPT="%~ %# "
# 2行表示
PROMPT="%{$fg[blue]%}.-%{${reset_color}%}%{${fg[cyan]}%}[%T]%{${reset_color}%} %{$fg[blue]%}%n%{${reset_color}%}:%~ %1(v|%F{magenta}%1v%f|)
%{$fg[blue]%}\`-%{${reset_color}%}%# "

# personal bin directory
export PATH="$HOME/dev/bin:$PATH"
export PATH="$HOME/dev/local/bin:$PATH"
export PATH="$HOME/dotfiles/script:$PATH"

# rbenv
export PATH="$HOME/.rbenv/shims:$PATH"
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

# android sdk
export ANDROID_SDK_HOME=/Users/fuji_seal/dev/local/android/sdk
export PATH=$PATH:$ANDROID_SDK_HOME/tools
export PATH=$PATH:$ANDROID_SDK_HOME/platform-tools

# node
export PATH=$PATH:/usr/local/share/npm/bin

# terminal-notifier
autoload -U add-zsh-hook
export SYS_NOTIFIER="/usr/local/bin/terminal-notifier"
source ~/.zsh.d/zsh-notify/notify.plugin.zsh
export NOTIFY_COMMAND_COMPLETE_TIMEOUT=10

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

########################################
# 補完
# 補完機能を有効にする
autoload -Uz compinit
compinit

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
zstyle ':vcs_info:*' formats '(%b)'
zstyle ':vcs_info:*' actionformats '(%b|%a)'

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

# ディレクトリ名だけでcdする
setopt auto_cd

# cd したら自動的にpushdする
setopt auto_pushd
# 重複したディレクトリを追加しない
setopt pushd_ignore_dups

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

# sudo の後のコマンドでエイリアスを有効にする
alias sudo='sudo '

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
    # z
    . `brew --prefix`/etc/profile.d/z.sh
    ;;
  linux*)
    #Linux用の設定
    ;;
esac

# vim:set ft=zsh:

function precmd () {
  # z
  z --add "$(pwd -P)"

  # VCS
  psvar=()
  LANG=en_US.UTF-8 vcs_info
  [[ -n "$vcs_info_msg_0_" ]] && psvar[1]="$vcs_info_msg_0_"
}
