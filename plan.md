# Codexグローバル指示ファイル配布のテストリスト

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
- [x] 利用可能な構文検査と全`test/*.sh`が成功する
