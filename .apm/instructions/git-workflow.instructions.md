---
description: Git workflow rules (worktree-first development, safe path handling).
---

# Git Workflow

- gitリポジトリで新しい作業（機能開発、バグ修正、実験）を始めるときは、必ず `git wt` を使ってworktreeを作成すること。mainブランチで直接コミットしない
- `git checkout -b` ではなく `git wt feature/xxx` を使う
- 詳細は `/git-worktree-workflow` スキルを参照
- Never use `cd /path && git ...`. Use `git -C /path ...` instead to avoid bare repository attack warnings
- カレントディレクトリがworktree内であれば、絶対パスで `cd` せずそのままコマンドを実行すること。`cd /absolute/path/to/worktree && mise run test:backend` のような冗長なコマンドは禁止。単に `mise run test:backend` と実行すればよい
