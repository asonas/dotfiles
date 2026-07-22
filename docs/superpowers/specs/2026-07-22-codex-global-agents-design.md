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
既存のファイルsymlink、リンク切れのsymlink、ディレクトリsymlinkがある場合はリンク自体を削除してからコピーし、リンク先は変更しません。
実ディレクトリがある場合は配布を拒否します。
この処理には、シンボリックリンクへ切り替わる可能性がある既存の `New-DotLink` 関数を使いません。

## APMを利用できない場合

APMを利用できない環境では、新しい `AGENTS.md` を生成できません。
ただし、リポジトリ直下に既存の `AGENTS.md` がある場合は、そのファイルを配布します。
生成物が存在しない場合は警告を表示して配布をスキップし、インストール全体は継続します。

## 処理順序

macOSとLinuxでは、既存の `apm compile` とグローバル依存配布が終了した直後にCodexのグローバル指示を配置します。
APMが見つからない分岐の後にも共通の配置処理を置くことで、既存の生成物を再利用できます。

Windowsでは、APM配布関数がリポジトリを作業場所として `apm compile` を実行します。
`apm update` または `apm install` が非ゼロで終了しても、利用可能な依存関係と生成物を使って後続処理を継続します。
一方、`apm compile` が非ゼロで終了した場合は、古い生成物を配布しないため、その場でインストールを停止してコピーを実行しません。
`-SkipApm` が指定された場合も、既存の `AGENTS.md` があればコピーします。

## エラー処理

配布元がない場合、および `apm update` または `apm install` が部分的に失敗した場合は警告して処理を継続します。
`apm compile` が失敗した場合は、配布元に古い生成物が残っていても処理を停止します。
Windowsではupdate/installの実行中だけ `$PSNativeCommandUseErrorActionPreference` をfalseに固定し、各終了コードを警告へ変換した後、元の値または未定義状態へ復元します。
配布元があるにもかかわらずリンク作成またはコピーが失敗した場合は、既存の `$ErrorActionPreference = 'Stop'` または `set -e` に従ってインストールを失敗させます。
これにより、古いグローバル指示が残った状態を成功として扱いません。

## テスト

テストリストは次の順序で実装します。

1. POSIXインストーラーが `$HOME/.codex/AGENTS.md` をリポジトリの `AGENTS.md` へリンクする。
2. Windowsインストーラーが `$HOME\.codex\AGENTS.md` へ `Copy-Item` で配布する。
3. Windowsの配布が `New-DotLink` に依存せず、シンボリックリンク権限に左右されない。
4. WindowsのAPM処理がCodexをtargetに含め、配布前に `apm compile` を実行する。
5. 両インストーラーが配布元のない環境を警告付きでスキップする。
6. POSIX版が新規配置、既存ファイル、既存symlink、リンク切れ、ディレクトリsymlinkを実行して置き換え、実ディレクトリを拒否する。
7. Windows版が新規配置、既存ファイル、ファイルsymlink、リンク切れ、ディレクトリsymlinkを実行してコピーし、実ディレクトリを拒否する。
8. `apm update` と `apm install` の非ゼロ終了では継続し、`apm compile` の非ゼロ終了では停止する。

各項目は一つずつRed、Green、Refactorを進めます。
構文検査と既存のインストーラー関連テストも最後に実行します。

## 対象範囲

対象は `install.sh`、`install.ps1`、インストーラーの配布契約を検証するテストです。
APM本体の配置規則、各リポジトリ固有の `AGENTS.md`、`AGENTS.override.md` は変更しません。

## 変更対象

- `install.sh`
- `install.ps1`
- `test/codex_global_agents_distribution_test.sh`
- `test/codex_global_agents_distribution_windows_test.ps1`
- `plan.md`

## Current Status

Implementation and POSIX verification complete. Windows execution verification is pending on a PowerShell-capable Windows environment.

### Checklist

- [x] POSIXの全配置ケースを実動作で検証する
- [x] POSIXのディレクトリsymlink置換を実装する
- [x] Windowsのリンク先を変更しない置換を実装する
- [x] Windowsの全配置ケースとAPM失敗時のpreference復元を検証する実動作テストを用意する
- [x] APM未導入時、生成物不在時、各APMコマンド失敗時の契約を検証する
- [x] BashによるWindows実装とテスト項目の静的契約を検証する
- [ ] WindowsでPowerShell実動作テストを実行する
- [x] 利用可能な最終構文検査と全`test/*.sh`を実行する

### Updates

- 2026-07-22: macOSとLinuxはシンボリックリンク、Windowsはコピーとする設計を承認しました。
- 2026-07-22: POSIXのディレクトリsymlink誤拒否と`apm update`非ゼロ停止を実動作テストで再現し、修正後にGreenを確認しました。
- 2026-07-22: Windows向けに10ケースのPowerShell実動作テストを用意し、Bash側からテスト項目と実装契約を静的確認しました。
- 2026-07-22: `bash test/codex_global_agents_distribution_test.sh`、全7件の`test/*.sh`、`bash -n install.sh`、配布テスト自身のBash構文検査は、すべて終了コード0でした。
- 2026-07-22: Windowsのupdate/installが非ゼロでも `$PSNativeCommandUseErrorActionPreference` の設定に左右されず警告付きで継続し、元の定義状態を復元する実装とfake APMテストを追加しました。現在のLinuxではPowerShellテストを実行できないため、Bash静的契約のみ終了コード0を確認しました。
- 2026-07-22: 現在のLinux環境に`pwsh`と`powershell`がないため、Windows実動作テストとPowerShell parserは未実行です。Windowsでは `pwsh -NoProfile -File test/codex_global_agents_distribution_windows_test.ps1` で実行します。
