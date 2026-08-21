---
description: Git workflow rules (worktree-first development, safe path handling).
---

# Git Workflow

- gitリポジトリで新しい作業（機能開発、バグ修正、実験）を始めるときは、標準の `git worktree` でworktreeを作成すること。mainブランチで直接コミットしない
- 新しいブランチとworktreeは `git worktree add -b <branch> .worktrees/<branch> <start-point>` で作成する
- 作業完了後は `git worktree remove .worktrees/<branch>` でworktreeを削除し、マージ済みを確認してから `git branch -d <branch>` と `git worktree prune` を実行する
- 詳細は `/using-git-worktrees` スキルを参照
- Never use `cd /path && git ...`. Use `git -C /path ...` instead to avoid bare repository attack warnings
- カレントディレクトリがworktree内であれば、絶対パスで `cd` せずそのままコマンドを実行すること。`cd /absolute/path/to/worktree && mise run test:backend` のような冗長なコマンドは禁止。単に `mise run test:backend` と実行すればよい

## Linear Integration

- Do not create merge commits in this repository.
- Immediately before integration, rebase the worktree branch onto the current `main` branch with `git rebase main`.
- Resolve rebase conflicts on the worktree branch, then run the relevant focused verification again before integration.
- From `main`, integrate a rebased branch only with `git merge --ff-only <branch>`.
- If fast-forward integration fails, stop and repair the branch history. Do not use a regular merge, `--no-ff`, or another workaround that creates a merge commit.
- Confirm that `main` is clean and has not moved unexpectedly before the fast-forward integration.
