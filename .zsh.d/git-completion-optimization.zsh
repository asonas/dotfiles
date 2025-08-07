# Git補完の高速化設定

# リモートブランチの補完を無効化
# これにより、git pullやgit pushの補完時にリモートへのアクセスを防ぎます
zstyle ':completion:*:*:git:*' remote-branches false

# git pullの補完を簡略化
# リモートとブランチの組み合わせを補完しないようにする
zstyle ':completion:*:git-pull:*' tag-order 'remote-branches:-remote:remote branches' 'branches:-local:local branches'

# git補完のキャッシュを有効化・最適化
zstyle ':completion:*:*:git:*' use-cache true
zstyle ':completion:*:*:git:*' cache-path ~/.zsh/cache
zstyle ':completion:*:*:git:*' cache-policy _git_cache_policy

# git補完のキャッシュポリシー
_git_cache_policy() {
  # キャッシュを10分間有効にする
  [[ -f "$1" && "$1" -nt "$(( $(date +%s) - 600 ))" ]]
}

# 補完候補の表示を高速化
zstyle ':completion:*' use-compctl false

# git補完で重い処理を無効化
zstyle ':completion:*:*:git:*' verbose false
zstyle ':completion:*:*:git-checkout:*' sort false
zstyle ':completion:*:*:git-add:*' ignored-patterns '*'
zstyle ':completion:*:*:git-rm:*' ignored-patterns '*'

# git statusの情報取得を無効化（プロンプト表示用）
# これは補完とは直接関係ないが、全体的なパフォーマンス向上に寄与
export GIT_COMPLETION_CHECKOUT_NO_GUESS=1

# リモートリポジトリへのアクセスを制限
export GIT_COMPLETION_SHOW_ALL_COMMANDS=0

# gitコマンドの補完を簡略化
zstyle ':completion:*:*:git:*' group-name ''
zstyle ':completion:*:*:git:*' format ''

# ブランチ名の補完を高速化（ローカルブランチのみ）
zstyle ':completion:*:*:git-checkout:*' tag-order 'heads:-local:local branches'
zstyle ':completion:*:*:git-switch:*' tag-order 'heads:-local:local branches'
zstyle ':completion:*:*:git-merge:*' tag-order 'heads:-local:local branches'

# git pullの補完を簡略化する関数
_git_pull_fast() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    case "$cur" in
        --*)
            # オプションの補完のみ提供
            COMPREPLY=($(compgen -W "--rebase --no-rebase --ff-only --no-ff --squash --no-squash" -- "$cur"))
            ;;
        *)
            # リモート名のみ補完（ネットワークアクセスなし）
            COMPREPLY=($(compgen -W "$(git remote 2>/dev/null)" -- "$cur"))
            ;;
    esac
}

# より高速な補完のためのオプション
zstyle ':completion:*:*:git-pull:*' ignored-patterns '*'
zstyle ':completion:*:*:git-pull:*' completer _complete

# git logの補完を無効化（重いため）
zstyle ':completion:*:*:git-log:*' tag-order ''

# git stashの補完を簡略化
zstyle ':completion:*:*:git-stash:*' tag-order 'stash-list'
