# Remove crit Instructions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** crit固有のAIエージェント指示を生成元から削除し、AGENTS.mdとCLAUDE.mdへ再生成されない状態にする。

**Architecture:** `.apm/instructions/crit.instructions.md` を唯一の生成元として削除し、許可された `apm compile` だけを実行して生成物を更新する。Git管理外のmacOSスクリプトはリポジトリ変更と分離し、現在の環境から削除できない場合は未実施として報告する。

**Tech Stack:** Bash、APM CLI、Git

## Global Constraints

- `apm update` と `apm install` は実行しない。
- AGENTS.mdとCLAUDE.mdは手作業で部分編集せず、`apm compile` で再生成する。
- critプラグインの有効化設定とcrit本体は変更しない。
- `/Users/asonas/bin/crit-open.sh` はGit管理外であり、`install.sh` に恒久的な削除処理を追加しない。
- コミットはcommitスキル経由の `git ai-commit` を使う。

---

### Task 1: 生成元と生成物からcrit規則を削除する

**Files:**
- Create: `test/crit_instructions_removal_test.sh`
- Modify: `plan.md`
- Delete: `.apm/instructions/crit.instructions.md`
- Modify by generator: `AGENTS.md`
- Modify by generator: `CLAUDE.md`
- Modify: `docs/superpowers/specs/2026-07-23-remove-crit-instructions-design.md`

**Interfaces:**
- Consumes: `.apm/instructions/*.instructions.md` を入力とする `apm compile`。
- Produces: crit固有文字列を含まないAGENTS.mdとCLAUDE.md。

- [ ] **Step 1: テストリストを追加する**

`plan.md` へ次のセクションを追加する。

```markdown
## crit固有ルールの削除

- [ ] crit指示の生成元が存在しない
- [ ] AGENTS.mdにcrit固有文字列が存在しない
- [ ] CLAUDE.mdにcrit固有文字列が存在しない
- [ ] `apm compile` が成功する

### Updates

- 2026-07-23：削除対象と生成物のテストリストを追加した。
```

- [ ] **Step 2: 削除前に失敗するテストを書く**

`test/crit_instructions_removal_test.sh` を作る。

```bash
#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)

[ ! -e "$repo_root/.apm/instructions/crit.instructions.md" ]

for generated_file in AGENTS.md CLAUDE.md; do
  if grep -Eq 'crit-open\.sh|# crit（コードレビュー）|Profile 2' "$repo_root/$generated_file"; then
    echo "expected $generated_file to omit crit-specific instructions" >&2
    exit 1
  fi
done
```

- [ ] **Step 3: Redを確認する**

Run: `bash test/crit_instructions_removal_test.sh`

Expected: FAIL。生成元が存在するため終了コード1。

- [ ] **Step 4: 生成元を削除する**

`.apm/instructions/crit.instructions.md` を削除する。

- [ ] **Step 5: APM生成物を更新する**

Run: `apm compile`

Expected: 終了コード0。AGENTS.mdとCLAUDE.mdからcrit節が削除される。

- [ ] **Step 6: Greenを確認する**

Run: `bash test/crit_instructions_removal_test.sh`

Expected: PASS、終了コード0。

- [ ] **Step 7: 全体検証を行う**

```bash
for test_file in test/*.sh; do
  bash "$test_file"
done
bash -n test/crit_instructions_removal_test.sh
git --no-pager diff --check
```

Expected: 全コマンドが終了コード0。

- [ ] **Step 8: Current Statusを更新してコミットする**

`plan.md` のリポジトリ内項目を完了にする。
設計書では生成元、生成物、検証項目を完了にし、macOS側スクリプトだけを環境依存の未実施事項として残す。
commitスキルを使い、関連ファイルだけを `git ai-commit` する。

Suggested context: `Remove generated crit-specific agent instructions at their source.`

### Task 2: macOS側の未管理スクリプトを削除する

**Files:**
- Delete outside repository: `/Users/asonas/bin/crit-open.sh`
- Modify if deletion succeeds: `docs/superpowers/specs/2026-07-23-remove-crit-instructions-design.md`

**Interfaces:**
- Consumes: macOSのユーザーホームにあるGit管理外ファイル。
- Produces: `/Users/asonas/bin/crit-open.sh` が存在しない状態、または現在の環境では削除不能という明示的な報告。

- [ ] **Step 1: 正確な対象を確認する**

Run: `ls -la /Users/asonas/bin/crit-open.sh`

Expected: ファイルが存在する場合は対象の絶対パスを表示する。Linux環境からアクセスできない場合は終了コード非0。

- [ ] **Step 2: アクセス可能な場合だけ削除する**

対象が通常ファイルであることを確認できた場合だけ、`command rm /Users/asonas/bin/crit-open.sh` を実行する。
対象を確認できない場合は削除コマンドを実行しない。

- [ ] **Step 3: 削除結果を確認する**

Run: `test ! -e /Users/asonas/bin/crit-open.sh`

Expected: macOSファイルシステムへアクセスできる場合は終了コード0。
アクセスできない場合は、リポジトリ側の完了と分けて未実施事項を報告する。

### Task 3: 完了レビュー

**Files:**
- Review: `.apm/instructions/crit.instructions.md`
- Review: `AGENTS.md`
- Review: `CLAUDE.md`
- Review: `test/crit_instructions_removal_test.sh`
- Review: `plan.md`
- Review: `docs/superpowers/specs/2026-07-23-remove-crit-instructions-design.md`

- [ ] **Step 1: verification-before-completionスキルでTask 1の全検証を再実行する**

- [ ] **Step 2: requesting-code-reviewスキルで設計適合性とコード品質を確認する**

- [ ] **Step 3: macOS側スクリプトの削除可否をリポジトリ完了状態と分けて報告する**
