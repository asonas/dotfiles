# TDDテストリスト

## crit固有ルールの削除

- [x] crit指示の生成元が存在しない
- [x] AGENTS.mdにcrit固有文字列が存在しない
- [x] CLAUDE.mdにcrit固有文字列が存在しない
- [x] `apm compile` が成功する

### Updates

- 2026-07-23：削除対象と生成物のテストリストを追加した。
- 2026-07-23：REDとして `bash test/crit_instructions_removal_test.sh` を実行し、生成元の存在により終了コード1で失敗した。
- 2026-07-23：生成元を削除し、`apm compile` が終了コード0でAGENTS.mdとCLAUDE.mdを再生成した。
- 2026-07-23：GREENとして `bash test/crit_instructions_removal_test.sh` を実行し、終了コード0で成功した。

## Codexグローバル指示ファイル配布

- [x] POSIXで新規配置が成功する
- [x] POSIXで配布元がない場合は警告して継続する
- [x] POSIXで既存ファイルをsymlinkへ置き換える
- [x] POSIXで既存symlink（リンク切れを含む）を置き換える
- [x] POSIXでディレクトリsymlinkを置き換える
- [x] POSIXで実ディレクトリを拒否する
- [x] Windowsで新規配置、既存ファイル、ファイルsymlink、リンク切れ、ディレクトリsymlink、実ディレクトリ拒否、配布元不在を検証する実動作テストを用意する
- [ ] WindowsでPowerShell実動作テストを実行する（現在のLinux環境に`pwsh`/`powershell`なし）
- [x] Windows実装と実動作テストの静的契約をBashで検証する
- [x] WindowsのAPM処理がCodexをtargetに含め、コピー前にcompileする
- [x] APM update/installの非ゼロは許容し、compileの非ゼロは停止する
- [x] Windowsのnative command error preferenceがfalse・true・未定義の各状態でupdate/install失敗を警告付きで許容し、元の状態を復元するテストと実装を用意する
- [x] 利用可能な構文検査と全`test/*.sh`が成功する
## APM直接実行拒否

- [x] `apm update` を拒否する
- [x] `apm install` を拒否する
- [x] サブコマンド後のオプションを含む対象コマンドを拒否する
- [x] 絶対パスと相対パスの `apm` を拒否する
- [x] 複合コマンド内の対象コマンドを拒否する
- [x] `apm compile` と `apm --version` を許可する
- [x] コメントと引用符内の対象形を拒否する
- [x] 空入力とcommandなしの入力を許可する
- [x] `./install.sh` を許可する
- [x] 二重引用符内のコマンド置換で対象APMを拒否する
- [x] バッククォート内の対象APMを拒否する
- [x] 単語中の `#` より後にある対象APMを拒否する
- [x] リダイレクト直前の対象APMを拒否する
- [x] バックスラッシュ改行を挟む対象APMを拒否する
- [x] 引数として現れる `apm update` を保守的に拒否する
- [x] 単一引用符内の末尾バックスラッシュ後に続く対象APMを拒否する
- [x] 引用符付きの対象APMコマンド語を拒否する
- [x] 二重引用符内のバッククォート置換で対象APMを拒否する
- [x] 引用符付きの対象APMサブコマンドを拒否する
- [x] 前置代入後の対象APMを拒否する
- [x] 代入値中のAPM対象形を保守的に拒否する
- [x] 引用サブコマンドに接尾文字がある場合は許可する
- [x] 分割引用された対象APMサブコマンドを拒否する
- [x] 引用を含む対象APMコマンド語を拒否する
- [x] `=` を含む対象APM実行パスを拒否する
- [x] `capm update` と `myapm install` を許可する
- [x] PreToolUse設定からHookを呼び出す

## Updates

- 2026-07-22：設計書からテストリストを作成した。
- 2026-07-22：REDとして `bash test/block_direct_apm_commands_test.sh` を実行し、Hook未作成により終了コード127で失敗した。
- 2026-07-22：GREENとして `chmod +x .claude/scripts/block-direct-apm-commands.sh` 実行後に `bash test/block_direct_apm_commands_test.sh` を実行し、終了コード0で成功した。
- 2026-07-22：`apm install` の指定テストは空出力でも `jq -e` が終了コード0になる偽陽性だったため、拒否出力の非空検証を追加した。
- 2026-07-22：REDとして `bash test/block_direct_apm_commands_test.sh` を実行し、`apm install` の拒否出力が空のため終了コード1で失敗した。
- 2026-07-22：GREENとして完全一致の `apm install` だけを拒否対象へ追加し、`bash test/block_direct_apm_commands_test.sh` が終了コード0で成功した。
- 2026-07-22：REDとしてオプション付き `apm install` を追加し、`bash test/block_direct_apm_commands_test.sh` が拒否出力なしの終了コード1で失敗した。
- 2026-07-22：GREENとして `apm install` 後方の引数を許容する最小のcase分岐を追加し、`bash test/block_direct_apm_commands_test.sh` が終了コード0で成功した。
- 2026-07-22：REDとして絶対パスの `apm update` を追加し、`bash test/block_direct_apm_commands_test.sh` が拒否出力なしの終了コード1で失敗した。
- 2026-07-22：GREENとしてパス付き `apm update` と後方引数を許容する最小のcase分岐を追加し、`bash test/block_direct_apm_commands_test.sh` が終了コード0で成功した。
- 2026-07-22：REDとして相対パスの `apm install` を追加し、`bash test/block_direct_apm_commands_test.sh` が拒否出力なしの終了コード1で失敗した。
- 2026-07-22：GREENとしてパス付き `apm install` の完全一致を許容する最小のcase分岐を追加し、`bash test/block_direct_apm_commands_test.sh` が終了コード0で成功した。
- 2026-07-22：REDとして `&&` 後方の `apm update` を追加し、`bash test/block_direct_apm_commands_test.sh` が拒否出力なしの終了コード1で失敗した。
- 2026-07-22：GREENとして `&& apm update` だけを許容する最小のcase分岐を追加し、`bash test/block_direct_apm_commands_test.sh` が終了コード0で成功した。
- 2026-07-22：REDとしてパイプ前方の `apm install` を追加し、`bash test/block_direct_apm_commands_test.sh` が拒否出力なしの終了コード1で失敗した。
- 2026-07-22：GREENとしてテスト済みのオプション、パス、複合コマンド境界を正規表現へ統合し、`bash test/block_direct_apm_commands_test.sh` が終了コード0で成功した。
- 2026-07-22：指定の引用符ケース2件は正規表現の前後境界を満たさず追加直後から成功したため、両側空白の引用文字列を追加したところ、REDとして `bash test/block_direct_apm_commands_test.sh` が終了コード1で失敗した。
- 2026-07-22：GREENとして引用符とコメントを空白化する `shell_code_only` を追加し、`bash test/block_direct_apm_commands_test.sh` が終了コード0で成功した。
- 2026-07-22：`apm compile` の許可ケースを追加し、`bash test/block_direct_apm_commands_test.sh` が終了コード0で成功した。
- 2026-07-22：`apm --version` の許可ケースを追加し、`bash test/block_direct_apm_commands_test.sh` が終了コード0で成功した。
- 2026-07-22：コメント内の `apm update` 許可ケースを追加し、`bash test/block_direct_apm_commands_test.sh` が終了コード0で成功した。
- 2026-07-22：単一引用符内の `apm update` 許可ケースを追加し、`bash test/block_direct_apm_commands_test.sh` が終了コード0で成功した。
- 2026-07-22：`./install.sh` の許可ケースを追加し、`bash test/block_direct_apm_commands_test.sh` が終了コード0で成功した。
- 2026-07-22：空の標準入力を許可するケースを追加し、`bash test/block_direct_apm_commands_test.sh` が終了コード0で成功した。
- 2026-07-22：commandなしの `{}` を許可するケースを追加し、`bash test/block_direct_apm_commands_test.sh` が終了コード0で成功した。
- 2026-07-22：Refactor前に対象テストが終了コード0であることを確認し、拒否JSON出力を `deny_direct_apm` へ抽出した。
- 2026-07-22：Refactor後に `bash test/block_direct_apm_commands_test.sh` を実行し、終了コード0で成功した。
- 2026-07-22：最終検証としてHookと対象テストの `bash -n` および `test/*_test.sh` 7本を実行し、すべて終了コード0で成功した。
- 2026-07-22：追加レビューで二重引用符内のコマンド置換を見逃すことを実測し、REDとして対象ケース追加後のテストが終了コード1で失敗した。
- 2026-07-22：GREENとして二重引用符内の `$()` だけを検査コードへ戻し、対象テストが終了コード0で成功した。
- 2026-07-22：REDとしてバッククォート内の `apm install` を追加し、対象テストが拒否出力なしの終了コード1で失敗した。
- 2026-07-22：GREENとしてバッククォート内を検査コードとして扱う最小状態を追加し、対象テストが終了コード0で成功した。
- 2026-07-22：REDとして単語中の `#` 後方にある `apm update` を追加し、対象テストが拒否出力なしの終了コード1で失敗した。
- 2026-07-22：GREENとして単語境界の `#` だけをコメント開始とみなすようにし、対象テストが終了コード0で成功した。
- 2026-07-22：REDとしてリダイレクト直前の `apm update` を追加し、対象テストが拒否出力なしの終了コード1で失敗した。
- 2026-07-22：GREENとしてサブコマンド後方境界へリダイレクト演算子を追加し、対象テストが終了コード0で成功した。
- 2026-07-22：REDとしてバックスラッシュ改行を挟む `apm update` を追加し、対象テストが拒否出力なしの終了コード1で失敗した。
- 2026-07-22：GREENとして字句処理でバックスラッシュ改行を除去し、対象テストが終了コード0で成功した。
- 2026-07-22：REDとして引数の `apm update` を許可するケースを追加し、誤った拒否出力により対象テストが終了コード1で失敗した。
- 2026-07-22：GREENとしてAPMの前方境界をコマンド開始位置に限定し、対象テストが終了コード0で成功した。
- 2026-07-22：REDとして単一引用符内の末尾バックスラッシュ後に続く `apm update` を追加し、対象テストが拒否出力なしの終了コード1で失敗した。
- 2026-07-22：GREENとして単一引用符内のバックスラッシュを通常文字として扱い、対象テストが終了コード0で成功した。
- 2026-07-22：REDとして引用符付きコマンド語 `"apm" update` を追加し、対象テストが拒否出力なしの終了コード1で失敗した。
- 2026-07-22：GREENとしてコマンド開始位置の引用内容だけを検査コードへ保持し、対象テストが終了コード0で成功した。
- 2026-07-22：Refactorとして `assert_denied` をイベント名、拒否判断、案内文まで検証するよう強化した。
- 2026-07-22：追加修正後の最終検証として構文検査、`git diff --check`、対象テスト、残り6本のシェルテストを実行し、すべて終了コード0で成功した。
- 2026-07-22：正式レビュー対応のREDとして二重引用符内のバッククォート置換を追加し、拒否出力なしの終了コード1で失敗した。
- 2026-07-22：GREENとしてバッククォート置換の外側quote状態を保存・復元し、対象テストが終了コード0で成功した。
- 2026-07-22：REDとして `apm "update"` を追加し、引用内容が除去されるため終了コード1で失敗した。
- 2026-07-22：GREENとして対象サブコマンドと一致する引用トークン値を保持し、対象テストが終了コード0で成功した。
- 2026-07-22：REDとして `FOO=bar apm update` を追加し、前置代入後をコマンド位置として認識できず終了コード1で失敗した。
- 2026-07-22：GREENとしてコマンド位置の前置代入トークンを読み飛ばし、対象テストが終了コード0で成功した。
- 2026-07-22：REDとして `x=/tmp/apm update` の許可ケースを追加し、代入値中のパスを対象コマンドと誤認して終了コード1で失敗した。
- 2026-07-22：GREENとしてAPM実行パスから `=` を除外し、前置代入と実行パスの判定を分離して対象テストが終了コード0で成功した。
- 2026-07-22：Refactorとして単独 `apm install` も `assert_denied` へ統一し、非空、JSON構造、イベント名、拒否判断、案内文を検証するようにした。
- 2026-07-22：正式レビュー修正後の最終検証として構文検査、`git diff --check`、対象テスト、残り6本のシェルテストを実行し、すべて終了コード0で成功した。
- 2026-07-22：再レビュー対応のREDとして `apm "update"x` の許可ケースを追加し、引用符が空白境界になるため終了コード1で失敗した。
- 2026-07-22：GREENとして保持対象の引用符を空白へ変換せずトークン内容を連結し、対象テストが終了コード0で成功した。
- 2026-07-22：REDとして `apm "up""date"` を追加し、引用断片が対象サブコマンド値へ再構成されず終了コード1で失敗した。
- 2026-07-22：GREENとしてAPM直後の引用断片を同じサブコマンドトークンへ連結し、対象テストが終了コード0で成功した。
- 2026-07-22：REDとして `a"pm" update` を追加し、コマンド語途中の引用断片が除去されて終了コード1で失敗した。
- 2026-07-22：GREENとしてコマンド語の途中状態を追跡し、引用前後を同じ実行トークン値へ連結して対象テストが終了コード0で成功した。
- 2026-07-22：REDとして `/tmp/a=b/apm update` を追加し、実行パスの `=` を除外していたため終了コード1で失敗した。
- 2026-07-22：GREENとしてコマンド開始位置の代入トークンを字句処理で空白化し、実行パスでは `=` を許容して対象テストが終了コード0で成功した。
- 2026-07-22：再レビュー修正後の最終検証として構文検査、`git diff --check`、対象テスト、残り6本のシェルテストを実行し、すべて終了コード0で成功した。
- 2026-07-22：3回のレビュー修正で手製パーサの限界が判明し、ユーザー判断で保守的検出へ変更した。
- 2026-07-22：保守的な拒否期待へテストを更新し、REDとして `bash test/block_direct_apm_commands_test.sh` が終了コード1で失敗した。
- 2026-07-22：手製パーサを引用符除去と行継続連結の `normalize_command` および全文grepへ置換し、GREENとして対象テストが終了コード0で成功した。
- 2026-07-22：保守的検出への変更後に対象テスト、`test/*_test.sh` 7本、Hookとテストの構文検査、settingsのJSON検査、`git diff --check`を実行し、すべて終了コード0で成功した。
- 2026-07-23：REDとしてHook登録テストを追加し、`bash test/block_direct_apm_commands_test.sh` が未登録の設定により終了コード4で失敗した。
- 2026-07-23：GREENとしてBash用PreToolUseにAPM直接実行拒否Hookを登録し、全シェルテスト、構文検査、settingsのJSON検査、差分検査がすべて終了コード0で成功した。
- 2026-07-23：REDとして `capm update` の許可ケースを追加し、`apm` の前方境界がないため対象テストが終了コード1で失敗した。
- 2026-07-23：GREENとして `apm` の前方に文字列先頭または英数字・underscore以外を要求し、対象テストが終了コード0で成功した。
- 2026-07-23：`myapm install` の許可ケースを追加し、対象テストが終了コード0のままGreenを維持した。
- 2026-07-23：前方境界修正後に対象テスト、`test/*.sh` 7本、Hookとテストの構文検査、settingsのJSON検査、`git diff --check`を実行し、すべて終了コード0で成功した。
