# APM直接実行を拒否するPreToolUse Hookの設計

## 背景

このリポジトリの `install.sh` は、APMがスキルを配備した後にCodexとClaude Codeの設定を正規化する。
正規化には、Codexが解釈できないSessionStart Hookを含む `$HOME/.codex/hooks.json` の削除が含まれる。

AIエージェントが `apm update` または `apm install` を単独で実行すると、APMはCodex用のSessionStart Hookを再生成する。
単独実行では `install.sh` 後段の正規化が動かないため、次回のCodex起動時に `hook returned invalid session start JSON output` が再発する。

## 目的

AIエージェントがBashツールから `apm update` または `apm install` を直接実行する前に、そのコマンドを拒否する。
拒否理由では、APMの更新と配備にリポジトリの `install.sh` を使うよう案内する。

## 採用する方式

Claude CodeのBash用PreToolUse Hookとして、APMの直接実行だけを判定するシェルスクリプトを追加する。
既存の `git wt` 用Hookには追加せず、APMの実行規則を独立した責務として扱う。

Hookは標準入力からPreToolUseのJSONを読み、`.tool_input.command` を取り出す。
実行対象としての `apm` に続く最初のサブコマンドが `update` または `install` であれば、次の形式で拒否を返す。

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "`apm update` と `apm install` は直接実行できません。APMの更新と配備には、このリポジトリの `install.sh` を実行してください。"
  }
}
```

判定対象には、オプション付きのコマンド、絶対パスまたは相対パスで指定された `apm`、複合コマンド内の呼び出しを含める。
`apm compile`、`apm --version`、コメントおよび引用符内の単なる文字列は許可する。

## `install.sh` との境界

PreToolUse Hookが検査する対象は、AIエージェントがBashツールへ渡したコマンド文字列である。
AIエージェントが `./install.sh` を実行した場合、Hookが受け取る文字列には `apm update` と `apm install` が含まれないため、`install.sh` 内部のAPM実行は拒否されない。

この境界により、人間が端末から直接実行するAPMコマンドには影響を与えず、AIエージェントのBash実行だけを制御する。

## 設定

`.claude/settings.json` の `PreToolUse` に、`matcher` が `Bash` のHookエントリを追加する。
コマンドは `~/.claude/scripts/block-direct-apm-commands.sh` を呼び出す。

スクリプトはリポジトリの `.claude/scripts/` に置く。
既存の `install.sh` が `.claude` 配下をホームディレクトリへ配備する仕組みを利用し、新しい配備経路は追加しない。

## エラー処理

標準入力が空、または `.tool_input.command` が存在しない場合は、何も出力せず終了コード0で終了する。
許可対象のコマンドも同様に、何も出力せず終了コード0で終了する。

拒否対象を検出した場合も終了コード0で終了する。
Claude CodeはJSON内の `permissionDecision: deny` を読み取り、コマンドを実行せずに理由をAIエージェントへ返す。

## テスト方針

シェルテストは一つの振る舞いずつ追加し、Red、Green、Refactorの順で進める。
最初に単純な `apm update` の拒否を固定し、次に `apm install`、オプションとパス指定、複合コマンドを追加する。
その後、`apm compile`、`apm --version`、コメント、引用符内の文字列、`./install.sh` が許可されることを確認する。

拒否ケースでは、終了コード、JSON構文、Hookイベント名、拒否判断、案内文を検証する。
許可ケースでは、終了コード0と標準出力が空であることを検証する。
最後に全シェルテストと対象スクリプトの構文検査を実行する。

## 対象範囲

対象には、専用PreToolUse Hook、その設定、単体テストを含む。
APM本体、`install.sh` のAPM実行順、既存のCodex用Hook削除処理は変更しない。
AGENTS.mdおよびCLAUDE.mdへ同じ規則を文章で追加しない。

## 変更対象

- `.claude/scripts/block-direct-apm-commands.sh`：APMの直接実行を検出して拒否する。
- `.claude/settings.json`：Bash用PreToolUse Hookを登録する。
- `test/block_direct_apm_commands_test.sh`：拒否ケースと許可ケースを検証する。
- `plan.md`：TDDのテストリストと進捗を記録する。

## Current Status

Hookのコマンド判定と単体テストを実装済み。PreToolUse設定は未実装。

### Checklist

- [x] `apm update` の直接実行を拒否する。
- [x] `apm install` の直接実行を拒否する。
- [x] オプション、パス指定、複合コマンド内の直接実行を拒否する。
- [x] 他のAPMサブコマンドと実行でない文字列を許可する。
- [x] `./install.sh` の実行を許可する。
- [x] 全シェルテストと構文検査を実行する。

### Updates

- 2026-07-22：専用PreToolUse Hook、拒否範囲、許可範囲、検証方針を確定した。
- 2026-07-22：オプション、パス指定、複合コマンドの拒否と、引用符、コメント、許可サブコマンド、入力欠落時の許可を実装した。
- 2026-07-22：対象スクリプトの構文検査と `test/*_test.sh` 7本を実行し、すべて終了コード0で成功した。
- 2026-07-22：追加レビューに基づき、コマンド置換、引用符付きコマンド語、コメント境界、リダイレクト、行継続、コマンド開始位置の判定を追加した。
