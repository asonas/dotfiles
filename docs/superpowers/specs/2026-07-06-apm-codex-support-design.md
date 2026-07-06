# APM による Codex 向け共通設定の配布設計

## 背景

このリポジトリは、APM の `apm.yml` を正本として Claude Code と Cursor に共通の instructions と skills を配布している。
APM 0.23.1 は Codex を target として正式に扱えるが、現在の `apm.yml` と `install.sh` は `claude` と `cursor` だけを指定している。
そのため、Codex は生成済みの `AGENTS.md` をリポジトリ内では参照できても、グローバルな instructions と汎用 skills の配布対象には含まれていない。

## 目的

`apm.yml` に宣言した共通 instructions と汎用 skills を、Claude Code、Cursor、Codex の 3 クライアントへ一元的に配布する。
利用者は `install.sh` を実行するだけで、3 クライアント向けの生成とグローバルインストールを更新できる状態にする。

## 対象外

Claude Code 固有の hooks、commands、settings を Codex の機能へ移植しない。
各クライアントで機能を完全に同等化するための代替 plugin や MCP server は追加しない。
APM が Codex 向けに変換できない primitive の独自変換処理も実装しない。

## 採用する方式

`apm.yml` の `targets` に `codex` を追加し、`install.sh` が実行する `apm update` と `apm install -g` の target 指定を `claude,cursor,codex` に統一する。
APM 標準の target 解決と配置規則を使うことで、クライアントごとの symlink やコピー処理をリポジトリ側で保守せずに済む。

`apm compile` は `apm.yml` の targets を参照し、共通の `.apm/instructions/` から各クライアントが読む指示ファイルを生成する。
`apm install -g` は同じ manifest と lockfile を使い、各 target が対応する skills をグローバル領域へ配布する。

## 変更範囲

`apm.yml` では `targets` に `codex` を加える。
`install.sh` では、更新とインストールの両方で target の集合を一致させる。
生成物を除外するローカル Git 設定には、APM が Codex target 用の管理ファイルをリポジトリ直下へ生成する場合に限り、必要な除外規則を追加する。
`apm.lock.yaml` は APM の更新結果に合わせて更新する。

Claude Code の hook bridge と settings 正規化は Claude Code 固有の後処理として維持する。
Codex target の追加を理由に、この後処理へ条件分岐や Codex 用 workaround を加えない。

## エラー処理

既存の `install.sh` は、1 件の依存解決失敗によって後続の Claude Code 設定正規化が省略されないよう、`apm install` の非ゼロ終了を警告へ変換して処理を続ける。
Codex target の追加後もこの挙動を維持する。

一方、target 名の誤りや shell script の構文エラーは検証で検出する。
Codex 固有 primitive の配布失敗を独自に握りつぶす処理は追加せず、APM の診断出力を利用者へ提示する。

## 検証方針

最初に、Codex を含む target 設定が manifest と install script の両方に存在することを自動テストで固定する。
次に、APM の `--dry-run` または一時ディレクトリを対象とした `--root` を使い、Codex target を含む install が受理されることを確認する。
その後、shell script の構文検査を実行し、既存の Claude Code と Cursor の target が削除されていないことを確認する。

外部リポジトリの取得が必要な検証はネットワーク状態に左右される。
そのため、ローカルで完結する設定検査と shell 構文検査を必須とし、APM の実インストール検査は実行環境でネットワークを利用できる場合に追加する。

## 完了条件

`apm.yml` と `install.sh` が `claude`、`cursor`、`codex` の同じ target 集合を使用している。
共通 instructions から Codex が利用する `AGENTS.md` を生成できる。
APM が Codex に対応すると判定した汎用 skills を、同じ manifest と lockfile からグローバルインストールできる。
既存の Claude Code 固有設定と Cursor 向け配布を維持し、同じインストール処理を繰り返しても設定が重複しない。
