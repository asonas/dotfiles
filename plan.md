# Codexグローバル指示ファイル配布のテストリスト

- [x] POSIXインストーラーが `$HOME/.codex/AGENTS.md` をリポジトリの `AGENTS.md` へリンクし、既存ディレクトリなら失敗する
- [x] Windowsインストーラーが `$HOME\.codex\AGENTS.md` へコピーする
- [x] Windowsの配布がシンボリックリンク権限に依存しない
- [x] WindowsのAPM処理がCodexをtargetに含める
- [x] WindowsのAPM処理がコピー前に `AGENTS.md` を生成する
- [x] 両インストーラーが配布元のない環境を警告付きでスキップする
- [x] 構文検査と既存テストが成功する
