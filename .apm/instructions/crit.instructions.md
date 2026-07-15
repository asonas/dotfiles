---
description: How to open crit review URLs in the intended Chrome profile.
---

# crit（コードレビュー）

- crit のレビュー URL（crit が出力する `http://localhost:<port>` 等）をブラウザで開くときは、必ず `~/bin/crit-open.sh <url>` を使うこと。プレーンな `open <url>` は既定ブラウザ（Choosy）に流れ、目的の Chrome プロファイルに入らない
- `~/bin/crit-open.sh` は受け取った URL を Chrome の「aso」プロファイル（`Profile 2` / hzw1258@gmail.com）で開く。crit が採番する動的ポートをそのまま渡すため、ポートが毎回変わっても・複数の crit を同時に起動しても正しいプロファイルで開ける
- 背景: crit はループバック以外の Host ヘッダを 403 で拒否するため `crit.ason.as` 等のホスト名経由アクセスは不可。ポート固定は複数同時起動を妨げるため不可。よって URL 書き換えではなく、開くときにプロファイルを指定する方式で解決している
