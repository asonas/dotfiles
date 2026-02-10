# zmodload zsh/zprof && zprof

# see also
# https://gist.github.com/mollifier/4979906

#######################################
# Alias
alias be="bundle exec"
alias g="git"
alias rmstore="rm .DS_Store; rm */.DS_Store"
alias rmstorer="rm **/.DS_Store"
alias pythonserver='python -m http.server'
alias chhash="perl -pi -e 's/:([\w\d_]+)(\s*)=>/\1:/g'"
alias mm="middleman"
alias o='git ls-files | peco | xargs vim '
alias e='cd $GHQ_ROOT/$(ghq list | peco )'
alias q='cd $(GHQ_ROOT=~/go ghq list -p | peco)'
alias s='ssh $(grep -iE "^host[[:space:]]+[^*]" ~/.ssh/config|peco|awk "{print \$2}")'
alias sd='ssh $(grep -iE "^host[[:space:]]+[^*]" ~/.ssh/config|grep deploy|peco|awk "{print \$2}")'
alias br='bin/rails'
alias r="bin/rails routes | peco | sed 's/[ \t]*//' | awk -F ' ' '{ print \$1 }' | perl -pe 's/\n//g' | pbcopy"
alias dc='docker-compose'
alias nv="nvim"
alias vim="nvim"
alias le="less"
alias cip='ifconfig en0 | grep -Eo "inet \d+(\.\d+){3}" | sed -e "s/inet //g" | tr -d "\n" | pbcopy'
alias p=peco-checkout-pull-request
alias cdg='cd $(git rev-parse --show-toplevel)'

alias la='ls -a'
alias ll='ls -l'
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias mkdir='mkdir -p'
alias -g L='| less'
alias -g G='| grep'
alias pn='pnpm'

function pr() {
  git branch -a --sort=authordate | grep -e 'remotes' | grep -v -e '->' -e '*' -e 'asonas' -e 'master' | perl -pe 's/^\h+//g' | perl -pe 's#^remotes/##' | perl -nle 'print if !$c{$_}++' | peco | ruby -e '
    r = STDIN.read.strip
    exit if r.empty?

    branch_name = r.split("/")[1..-1].join("/")

    local_branches = `git branch --format="%(refname:short)"`.split("\n").map(&:strip)

    if local_branches.include?(branch_name)
      puts "Local branch \"#{branch_name}\" exists. Switching to it..."
      system("git", "switch", branch_name)
    else
      puts "Creating new local branch \"#{branch_name}\" from \"#{r}\"..."
      system("git", "switch", "-c", branch_name, r)
    end
  '
}

function pskill() {
  local pid
  pid=$(ps -ef | sed 1d | peco --query "$LBUFFER" | awk '{print $2}')

  if [ -n "$pid" ]; then
    ps -p $pid -o pid,ppid,user,%cpu,%mem,command
    kill -9 $pid
  fi
}

function pwdc() {
  if [ -n "$1" ]; then
    ruby -rfileutils -e "print FileUtils.pwd.gsub(' ', '\\ ').gsub('(', '\\(').gsub(')', '\\)') + '/' + ARGV[0]" -- "$1" | pbcopy
  else
    ruby -rfileutils -e "print FileUtils.pwd.gsub(' ', '\\ ').gsub('(', '\\(').gsub(')', '\\)')" | pbcopy
  fi
}

function display_branches_with_pr() {
  git branch | while read branch; do
    clean_branch=$(echo $branch | sed 's/^[ *]*//')
    pr_info=$(gh pr list --head $clean_branch --json number,title,url -q ".[] | [.title, .url] | @tsv" 2>/dev/null)

    if [[ -n "$pr_info" ]]; then
      pr_title=$(echo $pr_info | cut -f1)
      pr_url=$(echo $pr_info | cut -f2)
      printf "  %s: %s (%s)\n" "$clean_branch" "$pr_title" "$pr_url"
    else
      if [[ "$branch" == \** ]]; then
      	echo "$branch"
      else
      	echo "  $branch"
      fi

    fi
  done
}

function gcloud_ssh() {
  selected_project=$(gcloud projects list --format="value(projectId)" | peco)
  if [ -z "$selected_project" ]; then
    return 1
  fi

  selected_service=$(gcloud app services list --project="$selected_project" --format="value(id)" | peco)
  if [ -z "$selected_service" ]; then
    return 1
  fi

  selected_instance=$(gcloud app instances list --service="$selected_service" --project="$selected_project" --format="value(id)" | peco)
  if [ -z "$selected_instance" ]; then
    return 1
  fi

  latest_version=$(gcloud app versions list --service="$selected_service" --project="$selected_project" --sort-by="~version" --limit=1 --format="value(id)")
  if [ -z "$latest_version" ]; then
    return 1
  fi
  echo "running version: $latest_version"

  gcloud app instances ssh "$selected_instance" --service "$selected_service" --version "$latest_version" --project "$selected_project"
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
    dirname="./$prefix-$date"
  else
    dirname="$date"
  fi
  mkdir -p $dirname
  cd $dirname
}

zle -N peco-history-selection
bindkey '^Q' peco-history-selection

function new() {
  if [ $# -eq 1 ]; then
    repo="$(ghq root)/github.com/asonas/$1"
  elif [ $# -eq 2 ]; then
    repo="$(ghq root)/github.com/$1/$2"
  else
    echo "Usage: new <repo_name> or new <org> <repo_name>"
    return 1
  fi
  mkdir -p $repo
  cd $repo
  git init
}

export DISABLE_SPRING=1

export FZF_DEFAULT_OPTS="--reverse --no-sort --no-hscroll --preview-window=down"
user_name=$(git config user.name)
fmt="\
%(if:equals=$user_name)%(authorname)%(then)%(color:default)%(else)%(color:brightred)%(end)%(refname:short)|\
%(committerdate:relative)|\
%(subject)"

function select-git-branch-friendly() {
  selected_branch=$(
    git branch --sort=-committerdate --format=$fmt --color=always \
    | column -ts'|' \
    | fzf --ansi --exact --preview='git log --oneline --graph --decorate --color=always -50 {+1}' \
    | awk '{print $1}' \
    | sed 's/^\* //'
  )

  if [[ -n $selected_branch ]]; then
    git switch "$selected_branch"
  else
    echo "No branch selected."
  fi
  #BUFFER="${LBUFFER}${selected_branch}${RBUFFER}"
  CURSOR=$#LBUFFER+$#selected_branch
  zle redisplay
}

zle -N select-git-branch-friendly
bindkey '^x' select-git-branch-friendly

########################################
# 環境変数
export LANG=ja_JP.UTF-8

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


# personal bin directory
export PATH="$HOME/bin:$PATH"
export PATH="/usr/local/bin:$PATH"

# go
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"

export GHQ_ROOT="$HOME/ghq"

setopt nolistbeep

#単語の区切り文字を指定する（遅延読み込み）
_setup_word_style() {
  if [[ -z "$_WORD_STYLE_SETUP" ]]; then
    autoload -Uz select-word-style
    select-word-style default
    # ここで指定した文字は単語区切りとみなされる
    # / も区切りと扱うので、^W でディレクトリ１つ分を削除できる
    zstyle ':zle:*' word-chars " /=;@:{},|"
    zstyle ':zle:*' word-style unspecified
    export _WORD_STYLE_SETUP=1
  fi
}

# 必要な時だけセットアップする関数をバインド
_lazy_word_setup() {
  _setup_word_style
  zle backward-kill-word
}
zle -N _lazy_word_setup
bindkey '^W' _lazy_word_setup

# 補完で小文字でも大文字にマッチさせる
#zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# ../ の後は今いるディレクトリを補完しない
zstyle ':completion:*' ignore-parents parent pwd ..

# sudo の後ろでコマンド名を補完する
zstyle ':completion:*:sudo:*' command-path /usr/local/sbin /usr/local/bin \
                   /usr/sbin /usr/bin /sbin /bin /usr/X11R6/bin

# ps コマンドのプロセス名補完
zstyle ':completion:*:processes' command 'ps x -o pid,s,args'

# gitサブコマンド補完 (git ai-commit)
zstyle ':completion:*:*:git:*' user-commands ai-commit:'generate commit message using AI'

# git
a() { git add $*; git status -s }

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

# ^R で履歴検索をするときに * でワイルドカードを使用出来るようにする
bindkey '^R' history-incremental-pattern-search-backward

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

    eval "$(/opt/homebrew/bin/brew shellenv)"

        if type brew &>/dev/null; then
      FPATH=$(brew --prefix)/share/zsh-completions:$FPATH
      FPATH=$HOME/.zsh.d/completions:$FPATH

      # 補完初期化の最適化
      autoload -Uz compinit

      # 補完の高速化 - セキュリティチェックを無効化
      # -u フラグで insecure directories の警告を無効にする
      if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
        compinit -u -d ~/.zcompdump
      else
        compinit -u -C -d ~/.zcompdump
      fi

      # 補完のリビルドを抑制
      _compinit_loaded=1
    fi

    # 遅延読み込みでnodenvを最適化
    if [[ -d "$HOME/.nodenv" ]]; then
      export PATH="$HOME/.nodenv/bin:$PATH"
      eval "$(nodenv init - --no-rehash zsh)"
    fi

    # 遅延読み込みでrbenvを最適化
    if [[ -d "$HOME/.rbenv" ]]; then
      export PATH="$HOME/.rbenv/shims:$PATH"
      export PATH="$HOME/.rbenv/bin:$PATH"
      eval "$(~/.rbenv/bin/rbenv init - --no-rehash zsh)"
    fi

    # Created by `pipx` on 2024-11-14 08:10:36
    export PATH="$PATH:/Users/asonas/.local/bin"
    if command -v mise &> /dev/null; then
      eval "$(mise activate zsh)"
    fi
    # pnpm
    export PNPM_HOME="/Users/asonas/Library/pnpm"
    case ":$PATH:" in
      *":$PNPM_HOME:"*) ;;
      *) export PATH="$PNPM_HOME:$PATH" ;;
    esac
    ;;
  linux*)
    # Linux用の設定 - macOSで既にcompinit済みの場合はスキップ
    if [[ -z "$_COMPINIT_DONE" ]]; then
      zstyle ':completion:*:*:git:*' script ~/.zsh/completions/git-completion.zsh
      autoload -Uz compinit
      compinit -u
      export _COMPINIT_DONE=1
    fi
    source /usr/share/mitamae/profile
    # rbenv
    eval "$(rbenv init - zsh)"
    eval "$(nodenv init - zsh)"
    # pnpm
    export PNPM_HOME="$HOME/.local/share/pnpm"
    case ":$PATH:" in
      *":$PNPM_HOME:"*) ;;
      *) export PATH="$PNPM_HOME:$PATH" ;;
    esac
    # GPG signing
    export GPG_TTY=$(tty)
    ;;
esac

source $HOME/.cargo/env
#source ~/.zsh.d/00-lazyenv.bash
source ~/.zsh.d/personal


# heroku autocomplete setup - 遅延読み込み
_setup_heroku() {
  if [[ -z "$_HEROKU_SETUP" ]] && [[ -f /Users/asonas/Library/Caches/heroku/autocomplete/zsh_setup ]]; then
    source /Users/asonas/Library/Caches/heroku/autocomplete/zsh_setup
    export _HEROKU_SETUP=1
  fi
}

# herokuコマンドが実行される時に初期化
heroku() {
  _setup_heroku
  command heroku "$@"
}


# starshipの初期化（プロンプトなので即座に必要）
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

export WASMTIME_HOME="$HOME/.wasmtime"

export PATH="$WASMTIME_HOME/bin:$PATH"

function switch-aws-profile() {
    local profiles=$(aws configure list-profiles)
    local profile=$(echo "$profiles" | fzf --prompt="Select AWS Profile: ")

    if [ -n "$profile" ]; then
        export AWS_PROFILE="$profile"
        echo "Switched to AWS profile: $AWS_PROFILE"
    else
        echo "No profile selected."
    fi
}

eval "$(mise activate zsh)"

# Dart補完の遅延読み込み
_setup_dart_completion() {
  if [[ -z "$_DART_COMPLETION_SETUP" ]] && [[ -f /Users/asonas/.dart-cli-completion/zsh-config.zsh ]]; then
    source /Users/asonas/.dart-cli-completion/zsh-config.zsh
    export _DART_COMPLETION_SETUP=1
  fi
}

# dartコマンドが実行される時に初期化
dart() {
  _setup_dart_completion
  command dart "$@"
}

### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="/Users/asonas/.rd/bin:$PATH"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)

export PATH="$HOME/.nodenv/bin:$PATH"

#zprof

[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"

# bun completions
[ -s "/Users/asonas/.bun/_bun" ] && source "/Users/asonas/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

eval "$(git wt --init zsh)"
wt() {
  git wt "$(git wt | tail -n +2 | peco | awk '{print $(NF-1)}')"
}

# Added by Antigravity
export PATH="/Users/asonas/.antigravity/antigravity/bin:$PATH"
