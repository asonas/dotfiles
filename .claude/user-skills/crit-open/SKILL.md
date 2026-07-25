---
name: crit-open
description: crit のレビュー URL（`http://localhost:<port>` 等）をブラウザで開くときに使う。目的の Chrome プロファイルに入れるための開き方を定める。crit のレビューを人間に見せる直前、または /crit や crit share の出力した URL を開くときに参照する。
---

# crit のレビュー URL を開く

- crit のレビュー URL をブラウザで開くときは、必ず `~/bin/crit-open.sh <url>` を使う。プレーンな `open <url>` は既定ブラウザ（Choosy）に流れ、目的の Chrome プロファイルに入らない
- `~/bin/crit-open.sh` は受け取った URL を Chrome の「aso」プロファイル（`Profile 2` / hzw1258@gmail.com）で開く。crit が採番する動的ポートをそのまま渡すため、ポートが毎回変わっても・複数の crit を同時に起動しても正しいプロファイルで開ける

## なぜ URL 側を書き換えないのか

crit はループバック以外の Host ヘッダを 403 で拒否するため `crit.ason.as` 等のホスト名経由アクセスは不可。ポート固定は複数同時起動を妨げるため不可。よって URL 書き換えではなく、開くときにプロファイルを指定する方式で解決している。
