# Codex の SessionStart フック無効化設計

## 背景

`apm install -g --target claude,cursor,codex` は、`obra/superpowers` が提供する Claude Code 用の `SessionStart` フックを Codex にも配備する。
Codex はリポジトリ直下の .codex/hooks.json とグローバルの ~/.codex/hooks.json を読み込むため、同じフックを 2 回実行する。

グローバルのフックには `session-start` スクリプトが配備されるが、Codex を判別する環境変数がないため、スクリプトは SDK 標準形式の `additionalContext` を返す。
この形式は Codex の `SessionStart` 出力として受理されず、`hook returned invalid session start JSON output` になる。

リポジトリ直下のフックには `run-hook.cmd` だけが配備され、呼び出し先の `session-start` が存在しない。
そのため、`bash` がコマンドを見つけられず、フックは終了コード 127 で失敗する。

Codex は APM が配備した `using-superpowers` をスキルとして直接読み込む。
したがって、Claude Code 用フックによる同じ内容の追加注入は不要である。

## 目的

Codex の起動時に表示される 2 件の `SessionStart` エラーを解消する。
Claude Code では superpowers の `SessionStart` フックを維持し、従来どおりセッションコンテキストを注入する。
Codex では superpowers を含む APM のスキル配布を維持する。

## 採用する方式

install.sh は APM のグローバルインストール後に、リポジトリ直下とグローバル領域に生成された Codex 用 hooks.json を削除する。
APM を再実行すると Codex 用フックが再生成されるため、インストール処理の後段で毎回正規化する。
リポジトリ直下の .codex/hooks.json は追跡対象からも削除し、install.sh の実行後に削除差分が残らないようにする。

削除対象は次の 2 ファイルに限定する。

- $PWD/.codex/hooks.json
- $HOME/.codex/hooks.json

削除には `command rm -f` を使う。
ファイルが存在しない環境でもインストールを継続でき、シェルの対話的な `rm` エイリアスも回避できる。

.claude/settings.json と $HOME/.claude/hooks/superpowers/ は変更しない。
Claude Code の `SessionStart` 正規化は既存処理のまま維持する。

## 代替案

リポジトリ直下の .codex/hooks.json だけを手動で削除する案は採用しない。
この方法ではグローバル側のエラーが残り、次回の APM インストールでファイルが再生成される。

Codex 向けに `session-start` と JSON 出力を変換する案も採用しない。
Codex は同じ指示をスキルとして読み込むため、フックを動作させるとコンテキストが重複する。
さらに、既存設計の「Claude Code 固有の hooks を Codex の機能へ移植しない」という対象外条件にも反する。

## エラー処理

削除対象が存在しない場合は正常終了する。
削除対象を 2 ファイルに固定し、ディレクトリやワイルドカードを削除対象にしない。

APM のインストール自体が失敗した場合も、既存処理は警告を表示して後続処理を続ける。
Codex 用フックが部分的に生成されている可能性があるため、削除処理は APM の終了状態にかかわらず実行する。

## 検証方針

シェルテストで install.sh に Codex 用フックの削除処理が 1 回だけ存在することを確認する。
同じテストで Claude Code の `SessionStart` 正規化コマンドが残っていることを確認し、Codex の修正が Claude Code の動作を削除しないようにする。

実装後は全シェルテストと `bash -n install.sh` を実行する。
最後に、Codex 用 hooks.json が存在しない状態と、Claude Code 用 `SessionStart` が .claude/settings.json に残る状態を確認する。

## 対象範囲

対象には、install.sh による Codex 用フックの削除と、その動作を固定するテストを含む。
APM 自体の Codex 変換処理、superpowers の上流スクリプト、Claude Code のフック設定は変更しない。

## 変更対象

- install.sh：APM が生成した Codex 用 hooks.json を削除する。
- test/apm_codex_support_test.sh：Codex 用フックの削除と Claude Code 用フックの維持を検証する。

## Current Status

実装完了。

### Checklist

- [x] Codex 用フックの削除を検証する失敗テストを追加する。
- [x] `install.sh` に最小限の削除処理を追加する。
- [x] `.codex/hooks.json` を追跡対象から削除する。
- [x] 全シェルテストと構文検査を実行する。

### Updates

- 2026-07-22：Codex と Claude Code のフック境界、削除対象、検証方針を確定した。
- 2026-07-22：Codex 用フックの削除処理と回帰テストを追加した。
- 2026-07-22：リポジトリ内の Codex 用フックを追跡対象から削除した。
- 2026-07-22：全シェルテストと install.sh の構文検査が成功した。
