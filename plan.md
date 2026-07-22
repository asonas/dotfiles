# APM直接実行拒否のテストリスト

- [x] `apm update` を拒否する
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
- 2026-07-22：REDとして `bash test/block_direct_apm_commands_test.sh` を実行し、Hook未作成により終了コード127で失敗した。
- 2026-07-22：GREENとして `chmod +x .claude/scripts/block-direct-apm-commands.sh` 実行後に `bash test/block_direct_apm_commands_test.sh` を実行し、終了コード0で成功した。
