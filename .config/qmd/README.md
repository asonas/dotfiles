# qmd の設定

`index.yml` は qmd のグローバルインデックス設定です。`install.sh` の `required_dirs` 経由で `~/.config/qmd/index.yml` へ symlink されます。

## パスは絶対パスで書く（`~` は使えない）

`collections.<name>.path` に `~/...` を書くと**そのコレクションのファイルが全件消えます**。qmd はコレクションのパスをチルダ展開しません。`store.js` の展開処理（`filepath.startsWith('~/')`）は `findDocument` のクエリ経路にしかなく、インデックス作成側は通りません。

2026-07-26 に実測しました。`ai-cost` の path を `~/ghq/...` にして `qmd update` を実行したところ、

```
Indexed: 0 new, 0 updated, 0 unchanged, 83 removed
```

となり、絶対パスへ戻して再実行すると 83 件が復帰しました。移行時にパスを短くしたくなっても、チルダに書き換えないこと。

したがって `/Users/asonas/...` というホームディレクトリ込みの絶対パスがこのファイルに入ります。ユーザー名が変わるマシンへ移行する場合は、`index.yml` の `path` を手で書き換えてから `qmd update` を実行してください。qmd 側が対応するまでは、これが唯一の方法です。

## このファイルにコメントを書かない

qmd は `collection add` / `collection remove` の際に `index.yml` を読み込んで書き戻します。その過程で YAML はシリアライズし直されるため、**手で書いたコメントも引用符のスタイルも失われます**。設定の意図はこの README に書くこと。

## ignore に運用ファイルを入れている理由

`asonas` コレクションは `wiki/log.md`、`wiki/log-*.md`、`wiki/index.md`、`wiki/deferred.md` を除外しています。これらは `/wiki-update` のブックキーピングで、vault 中で最も固有名詞の密度が高いため、リランキングの候補枠を占有して本来の wiki ページを押しのけていました。

除外の前後を計測した結果は `.claude/user-skills/vault-rag/bench/README.md` にあります（`full` バックエンドの R@3 が 0.800 → 0.900、概観質問に限れば 0.800 → 1.000）。`/wiki-update` に新しい運用ファイルを足すときは、ここの ignore にも追記してください。
