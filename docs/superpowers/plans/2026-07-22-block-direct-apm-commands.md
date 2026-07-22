# APM Direct Command Blocking Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** AIエージェントがBashツールから `apm update` または `apm install` を直接実行する前に拒否し、リポジトリの `install.sh` へ誘導する。

**Architecture:** 専用のPreToolUse Hookが入力JSONからBashコマンドを取得し、引用符内の文字列とコメントを除外した検査用文字列を作る。コマンド境界にある `apm update` または `apm install` を検出した場合だけ、Claude Codeの拒否JSONを標準出力へ返す。

**Tech Stack:** Bash、jq、POSIX awk、grep、Claude Code PreToolUse Hook

## Global Constraints

- `apm update` と `apm install` だけを拒否し、`apm compile` と `apm --version` は許可する。
- オプション付き、絶対パスまたは相対パス、複合コマンド内の対象呼び出しを拒否する。
- コメントと引用符内の単なる文字列は許可する。
- `./install.sh` は許可し、その内部で実行されるAPMコマンドには干渉しない。
- AGENTS.mdとCLAUDE.mdには同じ規則を追加しない。
- テストは一つずつRed、Green、Refactorを繰り返し、各サイクルで `plan.md` を更新する。
- コミットには必ずcommitスキルと `git ai-commit` を使い、`git commit` を直接実行しない。

---

## File Structure

- Create: `plan.md`：TDDのテストリスト、完了状態、各サイクルで得た知見を記録する。
- Create: `.claude/scripts/block-direct-apm-commands.sh`：PreToolUse入力を解析し、対象コマンドだけを拒否する。
- Create: `test/block_direct_apm_commands_test.sh`：Hookの拒否ケースと許可ケースを実際のJSON入出力で検証する。
- Modify: `.claude/settings.json`：Bash用PreToolUse Hookとして新しいスクリプトを登録する。
- Modify: `docs/superpowers/specs/2026-07-22-block-direct-apm-commands-design.md`：実装中のチェックリストと更新履歴を反映する。

### Task 1: 最小の拒否動作

**Files:**
- Create: `plan.md`
- Create: `test/block_direct_apm_commands_test.sh`
- Create: `.claude/scripts/block-direct-apm-commands.sh`

**Interfaces:**
- Consumes: Claude Code PreToolUseが標準入力へ渡すJSON。Bashコマンドは `.tool_input.command` に文字列として入る。
- Produces: `apm update` のとき、`hookSpecificOutput.hookEventName` が `PreToolUse`、`permissionDecision` が `deny` のJSONを標準出力へ返す実行可能スクリプト。

- [ ] **Step 1: テストリストを作る**

`plan.md` を次の内容で作成する。

```markdown
# APM直接実行拒否のテストリスト

- [ ] `apm update` を拒否する
- [ ] `apm install` を拒否する
- [ ] サブコマンド後のオプションを含む対象コマンドを拒否する
- [ ] 絶対パスと相対パスの `apm` を拒否する
- [ ] 複合コマンド内の対象コマンドを拒否する
- [ ] `apm compile` と `apm --version` を許可する
- [ ] コメントと引用符内の文字列を許可する
- [ ] 空入力とcommandなしの入力を許可する
- [ ] `./install.sh` を許可する
- [ ] PreToolUse設定からHookを呼び出す

## Updates

- 2026-07-22：設計書からテストリストを作成した。
```

- [ ] **Step 2: `apm update` の失敗テストを書く**

`test/block_direct_apm_commands_test.sh` を作る。

```bash
#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
hook="$repo_root/.claude/scripts/block-direct-apm-commands.sh"

run_hook() {
  local command=$1
  jq -cn --arg command "$command" '{tool_input: {command: $command}}' | "$hook"
}

output=$(run_hook 'apm update')
jq -e '
  .hookSpecificOutput.hookEventName == "PreToolUse" and
  .hookSpecificOutput.permissionDecision == "deny" and
  (.hookSpecificOutput.permissionDecisionReason | contains("install.sh"))
' <<<"$output" >/dev/null
```

- [ ] **Step 3: Redを確認する**

Run: `bash test/block_direct_apm_commands_test.sh`

Expected: FAIL。Hookが存在しないため終了コード127になる。

- [ ] **Step 4: 最小実装でGreenにする**

`.claude/scripts/block-direct-apm-commands.sh` を作る。

```bash
#!/usr/bin/env bash
set -euo pipefail

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
[ "$cmd" = 'apm update' ] || exit 0

cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"`apm update` と `apm install` は直接実行できません。APMの更新と配備には、このリポジトリの `install.sh` を実行してください。"}}
JSON
```

Run: `chmod +x .claude/scripts/block-direct-apm-commands.sh`

- [ ] **Step 5: Greenを確認する**

Run: `bash test/block_direct_apm_commands_test.sh`

Expected: PASS、終了コード0。

- [ ] **Step 6: 進捗を更新してコミットする**

`plan.md` の最初の項目を完了にし、RedとGreenの結果をUpdatesへ追記する。
commitスキルを起動し、`plan.md`、テスト、Hookだけを `git ai-commit` でコミットする。

Suggested context: `Add the first TDD increment that blocks a direct apm update command.`

### Task 2: 拒否対象のコマンド形式

**Files:**
- Modify: `test/block_direct_apm_commands_test.sh`
- Modify: `.claude/scripts/block-direct-apm-commands.sh`
- Modify: `plan.md`
- Modify: `docs/superpowers/specs/2026-07-22-block-direct-apm-commands-design.md`

**Interfaces:**
- Consumes: Task 1の `run_hook(command)` とHookの拒否JSON。
- Produces: 引用符とコメントを除いた検査用文字列を生成する `shell_code_only` 関数と、対象APM呼び出しの境界判定。

- [ ] **Step 1: `apm install` の失敗テストを追加する**

```bash
output=$(run_hook 'apm install')
jq -e '.hookSpecificOutput.permissionDecision == "deny"' <<<"$output" >/dev/null
```

Run: `bash test/block_direct_apm_commands_test.sh`

Expected: FAIL。出力が空なので `jq` が失敗する。

- [ ] **Step 2: 最小の正規表現へ置き換える**

完全一致判定を次の判定へ置き換える。

```bash
if ! printf '%s' "$cmd" | grep -Eq '(^|[;&|()[:space:]])([^;&|()[:space:]]*/)?apm[[:space:]]+(update|install)([;&|()[:space:]]|$)'; then
  exit 0
fi
```

Run: `bash test/block_direct_apm_commands_test.sh`

Expected: PASS。

- [ ] **Step 3: 拒否境界を一つずつ追加する**

まずヘルパーを追加する。

```bash
assert_denied() {
  local command=$1
  run_hook "$command" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null
}
```

次の各ケースを一つずつ追加し、追加ごとにRed、最小実装、全テストのGreenを確認する。

```bash
assert_denied 'apm install -g --target claude,cursor,codex'
assert_denied '/home/asonas/.local/bin/apm update --yes'
assert_denied './bin/apm install'
assert_denied 'printf ready && apm update'
assert_denied 'apm install | tee /tmp/apm.log'
```

Run: `bash test/block_direct_apm_commands_test.sh`

Expected: 各サイクルの実装後にすべてPASS。

- [ ] **Step 4: 引用符の失敗テストを追加する**

```bash
assert_allowed() {
  local command=$1
  local output
  output=$(run_hook "$command")
  [ -z "$output" ]
}

assert_allowed 'printf "%s\n" "apm install"'
```

Run: `bash test/block_direct_apm_commands_test.sh`

Expected: FAIL。正規表現が引用符内を誤検出する。

- [ ] **Step 5: 字句処理を追加する**

Hookへ次を追加し、正規表現の入力を `$cmd` から `$code` へ変更する。

```bash
shell_code_only() {
  awk '
    BEGIN { quote = ""; escaped = 0; comment = 0 }
    {
      line = $0 "\n"
      for (i = 1; i <= length(line); i++) {
        ch = substr(line, i, 1)
        if (comment) {
          if (ch == "\n") { comment = 0; printf "\n" } else { printf " " }
        } else if (escaped) {
          printf "%s", ch
          escaped = 0
        } else if (ch == "\\") {
          printf "%s", ch
          escaped = 1
        } else if (quote != "") {
          if (ch == quote) { quote = "" }
          printf " "
        } else if (ch == "\"" || ch == "\047") {
          quote = ch
          printf " "
        } else if (ch == "#") {
          comment = 1
          printf " "
        } else {
          printf "%s", ch
        }
      }
    }
  '
}

code=$(printf '%s' "$cmd" | shell_code_only)
```

Run: `bash test/block_direct_apm_commands_test.sh`

Expected: PASS。

- [ ] **Step 6: 許可ケースを一つずつ追加する**

```bash
assert_allowed 'apm compile'
assert_allowed 'apm --version'
assert_allowed 'echo ready # apm update'
assert_allowed "printf '%s\\n' 'apm update'"
assert_allowed './install.sh'
```

各テスト追加後に `bash test/block_direct_apm_commands_test.sh` を実行する。

Expected: すべてPASS。

- [ ] **Step 7: 入力欠落ケースを一つずつ追加する**

```bash
assert_raw_input_allowed() {
  local input=$1
  local output
  output=$(printf '%s' "$input" | "$hook")
  [ -z "$output" ]
}

assert_raw_input_allowed ''
assert_raw_input_allowed '{}'
```

Run: `bash test/block_direct_apm_commands_test.sh`

Expected: すべてPASS。

- [ ] **Step 8: Refactor、進捗更新、コミットを行う**

拒否JSON出力を `deny_direct_apm` 関数へ抽出する。
Refactor前後に対象テストを実行し、両方がPASSすることを確認する。
`plan.md` と設計書の該当項目を完了にし、commitスキルでテスト、Hook、進捗文書を `git ai-commit` する。

Suggested context: `Expand direct APM command blocking while avoiding strings and comments.`

### Task 3: PreToolUse設定と全体検証

**Files:**
- Modify: `test/block_direct_apm_commands_test.sh`
- Modify: `.claude/settings.json`
- Modify: `plan.md`
- Modify: `docs/superpowers/specs/2026-07-22-block-direct-apm-commands-design.md`

**Interfaces:**
- Consumes: Task 2で完成したHook。
- Produces: `.claude/settings.json` のBash用PreToolUseエントリ。

- [ ] **Step 1: Hook登録の失敗テストを追加する**

```bash
settings="$repo_root/.claude/settings.json"
jq -e '
  .hooks.PreToolUse[] |
  select(.matcher == "Bash") |
  .hooks[] |
  select(.type == "command") |
  select(.command == "~/.claude/scripts/block-direct-apm-commands.sh")
' "$settings" >/dev/null
```

Run: `bash test/block_direct_apm_commands_test.sh`

Expected: FAIL。settingsに対象Hookが存在しない。

- [ ] **Step 2: Hookを登録する**

`.claude/settings.json` の `PreToolUse` 配列へ追加する。

```json
{
  "matcher": "Bash",
  "hooks": [
    {
      "type": "command",
      "command": "~/.claude/scripts/block-direct-apm-commands.sh"
    }
  ]
}
```

Run: `bash test/block_direct_apm_commands_test.sh`

Expected: PASS。

- [ ] **Step 3: 全シェルテストと構文検査を実行する**

```bash
for test_file in test/*.sh; do
  bash "$test_file"
done
bash -n .claude/scripts/block-direct-apm-commands.sh
bash -n test/block_direct_apm_commands_test.sh
jq -e . .claude/settings.json >/dev/null
git --no-pager diff --check
```

Expected: 全コマンドが終了コード0。警告とJSONエラーがなく、`diff --check` が何も出力しない。

- [ ] **Step 4: 進捗を完了にしてコミットする**

`plan.md` の全項目を完了にし、設計書のCurrent Statusを「実装完了。」へ変更して最終検証結果を追記する。
commitスキルを使い、settings、テスト、`plan.md`、設計書を `git ai-commit` する。

Suggested context: `Register the APM command blocker and record successful verification.`

### Task 4: 完了前レビュー

**Files:**
- Review: `.claude/scripts/block-direct-apm-commands.sh`
- Review: `.claude/settings.json`
- Review: `test/block_direct_apm_commands_test.sh`
- Review: `plan.md`
- Review: `docs/superpowers/specs/2026-07-22-block-direct-apm-commands-design.md`

**Interfaces:**
- Consumes: Task 1からTask 3までのコミット済み成果物。
- Produces: 設計適合性、コード品質、回帰の有無を確認した完了判断。

- [ ] **Step 1: 完了検証を再実行する**

verification-before-completionスキルを使い、Task 3 Step 3の全コマンドを新しい実行結果として再実行する。

- [ ] **Step 2: コードレビューを行う**

requesting-code-reviewスキルを使い、設計書、実装計画、`master..HEAD` の差分をレビューする。
指摘があれば一件ずつTDDで修正する。

- [ ] **Step 3: 最終状態を確認する**

```bash
git status --short
git --no-pager log --oneline master..HEAD
```

Expected: ワーキングツリーが空で、設計、拒否動作、設定の独立コミットが表示される。
