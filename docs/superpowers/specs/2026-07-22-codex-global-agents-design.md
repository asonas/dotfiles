# Codexグローバル指示ファイルのクロスプラットフォーム配布設計

## 概要

このリポジトリでAPMが生成する `AGENTS.md` を、Codexがグローバル指示として読む場所へ配布します。
macOSとLinuxではリポジトリ内の生成物を参照するシンボリックリンクを作り、Windowsでは生成物をコピーします。

Codexのホームディレクトリは既定で `$HOME/.codex` です。
POSIX版はシェルの `$HOME`、Windows版はPowerShellの `$HOME` を使うため、ユーザーごとの絶対パスをスクリプトへ埋め込みません。

## 配布動作

`install.sh` は `apm compile` の完了後、`$HOME/.codex/AGENTS.md` をリポジトリ直下の `AGENTS.md` へのシンボリックリンクにします。
既存のファイル、リンク、またはリンク切れのシンボリックリンクがある場合は、対象だけを置き換えます。

`install.ps1` はリポジトリで `apm compile` を実行した後、`$HOME\.codex\AGENTS.md` へ `AGENTS.md` をコピーします。
WindowsではDeveloper Modeや管理者権限の有無にかかわらずコピーし、既存ファイルを上書きします。
この処理には、シンボリックリンクへ切り替わる可能性がある既存の `New-DotLink` 関数を使いません。

## APMを利用できない場合

APMを利用できない環境では、新しい `AGENTS.md` を生成できません。
ただし、リポジトリ直下に既存の `AGENTS.md` がある場合は、そのファイルを配布します。
生成物が存在しない場合は警告を表示して配布をスキップし、インストール全体は継続します。

## 処理順序

macOSとLinuxでは、既存の `apm compile` とグローバル依存配布が終了した直後にCodexのグローバル指示を配置します。
APMが見つからない分岐の後にも共通の配置処理を置くことで、既存の生成物を再利用できます。

Windowsでは、APM配布関数がリポジトリを作業場所として `apm compile` を実行します。
APM配布の成否にかかわらず、関数の終了後に既存の生成物をコピーします。
`-SkipApm` が指定された場合も、既存の `AGENTS.md` があればコピーします。

## エラー処理

配布元がない場合だけ警告して処理を継続します。
配布元があるにもかかわらずリンク作成またはコピーが失敗した場合は、既存の `$ErrorActionPreference = 'Stop'` または `set -e` に従ってインストールを失敗させます。
これにより、古いグローバル指示が残った状態を成功として扱いません。

## テスト

テストリストは次の順序で実装します。

1. POSIXインストーラーが `$HOME/.codex/AGENTS.md` をリポジトリの `AGENTS.md` へリンクする。
2. Windowsインストーラーが `$HOME\.codex\AGENTS.md` へ `Copy-Item` で配布する。
3. Windowsの配布が `New-DotLink` に依存せず、シンボリックリンク権限に左右されない。
4. WindowsのAPM処理がCodexをtargetに含め、配布前に `apm compile` を実行する。
5. 両インストーラーが配布元のない環境を警告付きでスキップする。

各項目は一つずつRed、Green、Refactorを進めます。
構文検査と既存のインストーラー関連テストも最後に実行します。

## 対象範囲

対象は `install.sh`、`install.ps1`、インストーラーの配布契約を検証するテストです。
APM本体の配置規則、各リポジトリ固有の `AGENTS.md`、`AGENTS.override.md` は変更しません。

## 変更対象

- `install.sh`
- `install.ps1`
- `test/codex_global_agents_distribution_test.sh`
- `plan.md`

## Current Status

Design approved. Implementation has not started.

### Checklist

- [ ] POSIX向けの失敗するテストを追加する
- [ ] POSIX向けのリンク配布を実装する
- [ ] Windows向けの失敗するテストを追加する
- [ ] Windows向けのコピー配布を実装する
- [ ] APM未導入時と生成物不在時の動作を検証する
- [ ] 構文検査と既存テストを実行する

### Updates

- 2026-07-22: macOSとLinuxはシンボリックリンク、Windowsはコピーとする設計を承認しました。
