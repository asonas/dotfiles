# git pull専用の高速補完
# この設定を有効にすると、git pullの補完が大幅に高速化されますが、
# リモートブランチの補完は利用できなくなります

# git pullの補完を上書き
_git-pull() {
    local cur="${words[CURRENT]}"
    local -a remotes options

    # オプションの定義
    options=(
        '--rebase[rebase current branch on top of upstream branch]'
        '--no-rebase[merge upstream branch into current branch]'
        '--ff-only[refuse to merge unless fast-forward]'
        '--no-ff[create merge commit even for fast-forward]'
        '--squash[produce working tree and index state as if merge happened]'
        '--no-squash[perform the merge and commit the result]'
        '--quiet[be quiet]'
        '--verbose[be verbose]'
    )

    # 現在の入力が--で始まる場合はオプションを補完
    if [[ "$cur" == --* ]]; then
        _describe 'options' options
    else
        # それ以外の場合はローカルに保存されているリモート名のみを補完
        remotes=(${(f)"$(git remote 2>/dev/null)"})
        if (( ${#remotes} )); then
            _describe 'remotes' remotes
        fi
    fi
}

# この設定を有効にするには、以下のコメントを外してください
# compdef _git-pull git-pull
