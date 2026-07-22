# crit固有ルールの削除設計

## 背景

`.apm/instructions/crit.instructions.md` は、critのレビューURLを特定のChromeプロファイルで開く規則を定義している。
APMはこのファイルをAGENTS.mdとCLAUDE.mdへ展開するため、生成物だけを編集しても次回の `apm compile` で規則が復活する。

規則が参照する `~/bin/crit-open.sh` はGit管理外である。
現在のLinux環境には存在せず、macOS側では `/Users/asonas/bin/crit-open.sh` に置かれている。

## 目的

AIエージェント向けの生成済み指示からcrit固有のURLオープン規則を削除する。
規則専用の `crit-open.sh` もmacOS環境から削除する。

## 採用する方式

生成元の `.apm/instructions/crit.instructions.md` を削除し、`apm compile` を実行する。
これにより、AGENTS.mdとCLAUDE.mdから同じcrit節を削除し、以後のコンパイルでも再生成されない状態にする。

`apm update` と `apm install` は実行しない。
これらを単独実行するとCodex用SessionStart Hookが再生成されるためである。

macOS側の `/Users/asonas/bin/crit-open.sh` は一度だけ削除する。
このファイルはリポジトリ管理外なので、`install.sh` へ恒久的な削除処理は追加しない。
現在のLinux環境からmacOSのファイルシステムへアクセスできない場合は、未実施事項として正確なパスを報告する。

## 検証

削除後は、`.apm/instructions`、AGENTS.md、CLAUDE.mdに次の文字列が存在しないことを確認する。

- `crit-open.sh`
- `# crit（コードレビュー）`
- `Profile 2`

`.apm/instructions` は特定の削除済みファイルだけでなくディレクトリ全体を検査する。
AGENTS.mdとCLAUDE.mdは存在して読取可能であることを先に確認し、grepの検査エラーを「禁止文字列なし」として扱わない。

`apm compile` が終了コード0で成功すること、生成物以外へ意図しない差分がないこと、`git diff --check` が成功することも確認する。

macOS側では `/Users/asonas/bin/crit-open.sh` が存在しないことを確認する。
現在の環境から確認できない場合は、リポジトリ側の完了条件と分けて報告する。

## 対象範囲

対象には、crit指示の生成元、AGENTS.md、CLAUDE.md、macOS側の `crit-open.sh` を含む。
critプラグインの有効化設定、crit本体、他のレビュー規則は変更しない。

## 変更対象

- Delete: `.apm/instructions/crit.instructions.md`
- Modify: `AGENTS.md`
- Modify: `CLAUDE.md`
- Delete outside repository: `/Users/asonas/bin/crit-open.sh`

## Current Status

リポジトリ側の削除と生成物の更新は完了した。macOS側のGit管理外スクリプトは、現在のLinux環境から未実施である。

### Checklist

- [x] crit指示の生成元を削除する。
- [x] AGENTS.mdとCLAUDE.mdを再生成する。
- [x] crit固有文字列が残っていないことを確認する。
- [ ] macOS側の `crit-open.sh` を削除する。

### Updates

- 2026-07-23：生成元、生成物、Git管理外スクリプトの削除境界を確定した。
- 2026-07-23：`.apm/instructions/crit.instructions.md` を削除し、`apm compile` によりAGENTS.mdとCLAUDE.mdを再生成した。
- 2026-07-23：リポジトリ側の検証を完了した。macOS側の `/Users/asonas/bin/crit-open.sh` はLinux環境から未実施として残す。
- 2026-07-23：生成物の存在・可読性とgrepエラーを明示検証し、`.apm/instructions` 全体へのcrit固有文字列の再導入を拒否する契約テストを追加した。
