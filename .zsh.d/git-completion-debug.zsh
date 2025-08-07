# Git補完のデバッグ用設定
# 補完が遅い原因を調査するために使用します

# 補完のデバッグを有効化（必要な時のみコメントを外す）
# zstyle ':completion:*' verbose yes
# zstyle ':completion:*:descriptions' format '%B%d%b'
# zstyle ':completion:*:messages' format '%d'
# zstyle ':completion:*:warnings' format 'No matches for: %d'

# 補完の実行時間を計測する関数
git_completion_benchmark() {
    local start_time=$(date +%s.%N)

    # 補完をテスト実行
    echo "Testing git pull completion..."
    zsh -c 'autoload -U compinit && compinit && _git-pull'

    local end_time=$(date +%s.%N)
    local duration=$(echo "$end_time - $start_time" | bc)

    echo "Completion took: ${duration} seconds"
}

# 現在の補完設定を確認する関数
show_git_completion_settings() {
    echo "=== Current git completion settings ==="
    echo "Remote branches completion:"
    zstyle -L ':completion:*:*:git:*' remote-branches
    echo ""
    echo "Cache settings:"
    zstyle -L ':completion:*:*:git:*' use-cache
    zstyle -L ':completion:*:*:git:*' cache-path
    echo ""
    echo "Environment variables:"
    echo "GIT_COMPLETION_CHECKOUT_NO_GUESS=$GIT_COMPLETION_CHECKOUT_NO_GUESS"
    echo "GIT_COMPLETION_SHOW_ALL_COMMANDS=$GIT_COMPLETION_SHOW_ALL_COMMANDS"
}
