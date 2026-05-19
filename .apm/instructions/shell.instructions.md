---
description: Shell execution rules under the Bash tool (heredoc ban, alias bypass, pager handling, zsh globbing).
---

# Shell（Bash実行時の注意）

- 複数行のスクリプト（Python, Ruby, Node等）をヘレドク（`<< 'EOF'`）でインライン実行するのは禁止。代わりに Write ツールで一時ファイル（`/tmp/xxx.py` 等）に書き出してから Bash で実行すること
- .zshrc で `rm`, `cp`, `mv` に `-i`（インタラクティブモード）のエイリアスが設定されている
- Bashツールでこれらのコマンドを実行する際は、エイリアスをバイパスするために `command rm`, `command cp`, `command mv` を使うこと（`\rm` でも可）
- これにより、インタラクティブプロンプトでエージェントが停止する問題を防ぐ
- `git log`, `git diff`, `git show` 等のページャが起動するコマンドは `git --no-pager` を付けて実行すること（`GIT_PAGER=cat` は環境変数設定で毎回Permission確認が発生するため使用しない）
- `git merge` は `--no-edit` を付けてエディタの起動を防ぐこと
- `git rebase -i`, `git tag -a`, `crontab -e` など `$EDITOR` を起動するコマンドは使わないこと
- `npx` は `--yes` フラグを付けてインストール確認プロンプトを回避すること
- .zshrc 内の `peco`/`fzf` を使うエイリアス・関数（`e`, `o`, `s`, `p`, `wt`, `pr` 等）はインタラクティブ選択UIのため使用禁止
- zsh ではグロブ文字（`^`, `~`, `#`, `[`, `]` 等）を含む引数は必ずダブルクォートで囲むこと。例: `docker ps -qf "name=^app"` (`^` をクォートしないと `no matches found` エラーになる)
- ユーザーにコマンド例を提示するときも同様にzshで通る形にすること
