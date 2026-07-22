# CodexグローバルAGENTS.md配布 最終修正レポート

## Status

最終レビューの5件のfindingへ対応しました。POSIX実動作テスト、Windows向け実動作テストスクリプト、静的契約テスト、設計書、進捗を更新しています。現在のLinux環境では`pwsh`と`powershell`が見つからなかったため、PowerShell parserとWindows実動作テストだけは未実行です。

## Finding対応表

| Finding | 対応 | 検証 |
|---|---|---|
| 1. Windowsの既存symlink経由でリンク先を上書きし得る | `Copy-CodexGlobalAgents`で`LinkType`を先に判定し、リンク自体を`Delete()`してからコピーするよう変更しました。非リンクの実ディレクトリだけを拒否し、通常ファイルは`Copy-Item -Force`で上書きします。 | Bash静的契約はGreenです。ファイルsymlink、リンク切れ、ディレクトリsymlink、実ディレクトリ、通常ファイルを含むPowerShell実動作テストを追加しました。Windows実行は未検証です。 |
| 2. POSIXのディレクトリsymlinkを実ディレクトリと誤判定する | 拒否条件を`-d`かつ`! -L`へ限定しました。 | ディレクトリsymlink置換の実動作テストでREDからGreenを確認しました。 |
| 3. 実動作テスト不足 | 一時HOMEと一時repoを使うPOSIXテスト、および7ケースのWindows PowerShellテストを追加しました。 | POSIXは新規、配布元不在、通常ファイル、通常symlink、リンク切れ、ディレクトリsymlink、実ディレクトリ拒否を実行済みです。Windowsは静的確認のみです。 |
| 4. APM失敗時の設計契約が不正確 | `apm update`と`apm install`の非ゼロは継続し、`apm compile`の非ゼロは古い生成物を避けるため停止する契約へ設計書を修正しました。POSIXの`apm update`も警告付き継続へ合わせました。 | 偽`apm`でupdate/install非ゼロ継続とcompile非ゼロ停止を実動作確認しました。Windowsは既存のcompile直後の終了コード検査を静的確認しました。 |
| 5. planとCurrent Statusが実績と不一致 | テストリスト、完了項目、最終検証結果、Windows未検証事項を実績に合わせました。 | `plan.md`と設計書のCurrent Status/Updatesを目視確認しました。 |

## RED / GREEN証拠

### POSIXディレクトリsymlink

REDコマンドは`bash test/codex_global_agents_distribution_test.sh`です。終了コード1で、次を出力しました。

```text
error: /tmp/tmp.PLz1PWSfJG/directory-symlink/home/.codex/AGENTS.md is a directory; cannot install Codex global guidance.
```

`install.sh`の拒否条件を実ディレクトリだけへ限定後、同じコマンドは終了コード0になりました。

### Windowsリンク削除順序

REDコマンドは`bash test/codex_global_agents_distribution_test.sh`です。終了コード1で、次を出力しました。

```text
expected /tmp/tmp.pHuMEDmkCo/Copy-CodexGlobalAgents.ps1 to contain ^        if \(\$existing\.LinkType\) \{ \$existing\.Delete\(\) \}$ 1 time(s), got 0
```

`install.ps1`で`LinkType`を先に処理後、同じコマンドは終了コード0になりました。

### APM update非ゼロ継続

REDコマンドは`bash test/codex_global_agents_distribution_test.sh`です。偽`apm update`の終了コード17がそのまま返り、テストも終了コード17になりました。

`apm update`区間の終了コードを捕捉して警告付き継続へ変更後、同じコマンドは終了コード0になりました。追加した実動作テストで`apm install`非ゼロ時の継続と`apm compile`非ゼロ時の配布停止も確認しています。

### 既存契約との整合

最初の全シェルテスト実行では、`test/apm_codex_support_test.sh`が既存のupdate呼び出し行を検出できず失敗しました。呼び出し行を維持しつつその区間だけ`errexit`を制御する形へ調整し、対象テストと全シェルテストを再実行してGreenを確認しました。初回テストループは失敗を最終終了コードへ反映しない構造だったため、検証証拠には採用せず、再実行では`set -e`を付けました。

## 最終テスト

次のコマンドを実行しました。

```sh
bash test/codex_global_agents_distribution_test.sh
```

終了コード0、出力なしでした。

```sh
set -e
for test_file in test/*.sh; do
    printf 'RUN %s\n' "$test_file"
    bash "$test_file"
done
bash -n install.sh
bash -n test/codex_global_agents_distribution_test.sh
```

終了コード0で、次の7テストを実行しました。

```text
RUN test/apm_codex_support_test.sh
RUN test/apple_interface_guidelines_skill_test.sh
RUN test/codex_global_agents_distribution_test.sh
RUN test/fix_codex_agent_description_test.sh
RUN test/git_ai_commit_config_test.sh
RUN test/install_codex_config_test.sh
RUN test/wezterm_herdr_shortcuts_test.sh
```

PowerShellが利用可能な場合に実行するコマンドは次のとおりです。

```powershell
pwsh -NoProfile -File test/codex_global_agents_distribution_windows_test.ps1
```

このLinux環境では`pwsh`と`powershell`が見つからず、PowerShell parserとWindows実動作テストをスキップしました。

## 変更ファイル

- `install.sh`
- `install.ps1`
- `test/codex_global_agents_distribution_test.sh`
- `test/codex_global_agents_distribution_windows_test.ps1`
- `plan.md`
- `docs/superpowers/specs/2026-07-22-codex-global-agents-design.md`
- `.superpowers/sdd/final-fix-report.md`

## 自己レビュー

POSIX側は実際のインストーラー前半を一時repoで実行しており、対象ブロックのコピーではなく実装コードを検証しています。実ディレクトリは維持したまま失敗し、symlinkはリンク先を変更せず置換されます。APMテストはcompile、update、installの各終了経路を分離しています。

Windows側はPowerShell ASTから`Copy-CodexGlobalAgents`の実際の関数定義を取り出して実行するため、テスト用の再実装はありません。symlinkのリンク先にsentinelを置き、コピー後も変更されないことを検証します。通常ファイル、実ディレクトリ、配布元不在も別ケースです。

差分へ`git diff --check`を実行し、空白エラーがないことを確認しました。他者の変更や所有範囲外のファイルは変更していません。

## 未検証事項

Windows実動作テストとPowerShell parserは未実行です。Windowsのsymlinkケースを実行するにはDeveloper Modeまたは管理者権限が必要です。権限を満たすWindows環境で上記PowerShellコマンドを実行してください。

レポート作成後に`mdv .superpowers/sdd/final-fix-report.md`を実行しましたが、この環境には`mdv`がなく、終了コード127でした。そのためターミナル上のMarkdownプレビューは未実施です。

## 最終再レビュー追補

### Finding対応

Windowsの`Invoke-ApmDistribution`は、`apm update`と`apm install`の終了コードを確認していなかったため、失敗時に警告しませんでした。また、利用者が`$PSNativeCommandUseErrorActionPreference`をtrueにしている場合は、非ゼロ終了が`$ErrorActionPreference = 'Stop'`により停止へ変わり、継続契約に反していました。

update/installの実行スコープだけ`$PSNativeCommandUseErrorActionPreference`をfalseへ固定し、各コマンド直後の`$LASTEXITCODE`を警告へ変換しました。finallyでは、呼び出し前の値があればその値へ戻し、未定義ならローカル変数を削除します。compileの実行と非ゼロ時のthrowは変更していません。

PowerShell実動作テストにはfake native `apm.cmd`を追加しました。compileは0、updateは23、installは29を返します。preferenceがfalse、true、未定義の3ケースで、update/installの警告、`Invoke-ApmDistribution`後の`Copy-CodexGlobalAgents`実行、元のpreference状態の復元を検証します。

### RED / GREEN

REDコマンドは`bash test/codex_global_agents_distribution_test.sh`です。終了コード1で次を出力しました。

```text
expected /tmp/tmp.6WIH2ACoPF/Invoke-ApmDistribution.ps1 to contain ^    \$nativeErrorPreference = Get-Variable -Name PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue$ 1 time(s), got 0
```

最小実装後、固定インデントに依存していた既存静的テストを空白量に依存しない検査へ直しました。再実行は終了コード0、出力なしでした。

### Covering tests

次を失敗伝播付きで実行しました。

```sh
set -e
bash test/codex_global_agents_distribution_test.sh
for test_file in test/*.sh; do
    printf 'RUN %s\n' "$test_file"
    bash "$test_file"
done
bash -n install.sh
bash -n test/codex_global_agents_distribution_test.sh
```

終了コード0で、全7件のシェルテストとBash構文検査が成功しました。出力は次のとおりです。

```text
RUN test/apm_codex_support_test.sh
RUN test/apple_interface_guidelines_skill_test.sh
RUN test/codex_global_agents_distribution_test.sh
RUN test/fix_codex_agent_description_test.sh
RUN test/git_ai_commit_config_test.sh
RUN test/install_codex_config_test.sh
RUN test/wezterm_herdr_shortcuts_test.sh
SKIP pwsh parser and Windows execution tests: pwsh not available
```

このLinux環境には`pwsh`と`powershell`がないため、追加した10件のPowerShell実動作テストとparserは未実行です。Windowsでの実行コマンドは次のとおりです。

```powershell
pwsh -NoProfile -File test/codex_global_agents_distribution_windows_test.ps1
```

### 追加変更ファイル

- `install.ps1`
- `test/codex_global_agents_distribution_test.sh`
- `test/codex_global_agents_distribution_windows_test.ps1`
- `plan.md`
- `docs/superpowers/plans/2026-07-22-codex-global-agents.md`
- `docs/superpowers/specs/2026-07-22-codex-global-agents-design.md`
- `.superpowers/sdd/final-fix-report.md`
