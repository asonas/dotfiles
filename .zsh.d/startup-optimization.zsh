# zsh起動時間最適化設定

# 補完システムの最適化
zstyle ':completion:*' accept-exact '*(N)'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache

# 重い補完を無効化
zstyle ':completion:*:*:docker:*' disabled true
zstyle ':completion:*:*:kubectl:*' disabled true
zstyle ':completion:*:*:helm:*' disabled true
zstyle ':completion:*:*:terraform:*' disabled true
zstyle ':completion:*:*:aws:*' disabled true

# 不要なオプションの無効化
unsetopt menu_complete
unsetopt flowcontrol

# ヒストリの最適化
setopt hist_fcntl_lock

# プロンプトの最適化
setopt prompt_sp

# バックグラウンドジョブの最適化
setopt no_hup
setopt no_check_jobs

# 自動補完の最適化
zstyle ':completion::complete:*' use-cache on
zstyle ':completion::complete:*' cache-path ~/.zsh/cache
zstyle ':completion:*' menu select=2
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*::::' completer _expand _complete _ignored _approximate

# 補完候補をキャッシュ
zstyle ':completion:*' accept-exact '*(N)'

# 大文字小文字を区別しない補完
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# 補完のグループ化を無効化（軽量化）
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format ''

# ファイル補完の最適化
zstyle ':completion:*:*:*:*:files' ignored-patterns '*?.o' '*?.c~' '*?.old' '*?.pro'

# プロセス補完の最適化
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'

# SSH補完の最適化
zstyle ':completion:*:ssh:*' tag-order hosts-domain hosts-host hosts-ipaddr
zstyle ':completion:*:ssh:*' group-order hosts-domain hosts-host users hosts-ipaddr

# 関数の遅延読み込み設定
typeset -a lazyload_functions
lazyload_functions=(
  gh
  docker
  kubectl
  aws
)

# 遅延読み込み関数のセットアップ
for func in $lazyload_functions; do
  if command -v $func >/dev/null 2>&1; then
    eval "$func() { unfunction $func; $func \"\$@\" }"
  fi
done

# 補完の並列化設定（重い処理を避ける）
zstyle ':completion:*' single-ignored show
zstyle ':completion:*' squeeze-slashes true

# Homebrewの補完を制限（重いため）
if [[ -d /opt/homebrew/share/zsh-completions ]]; then
  # 特定の重い補完のみ無効化
  fpath=(${fpath:#/opt/homebrew/share/zsh-completions/_docker})
  fpath=(${fpath:#/opt/homebrew/share/zsh-completions/_kubectl})
  fpath=(${fpath:#/opt/homebrew/share/zsh-completions/_helm})
fi

# システム補完の制限
zstyle ':completion:*:manuals' separate-sections true
zstyle ':completion:*:manuals.*' insert-sections true
