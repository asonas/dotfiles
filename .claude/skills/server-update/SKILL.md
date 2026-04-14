---
name: server-update
description: Arch Linuxサーバーのパッケージアップデートを調査・計画・実行する。pacman -Syuの前に依存関係(ZFS/NVIDIA/DKMS)の互換性をWebで調べ、安全な段階的更新手順を提示する。
allowed-tools: Bash(pacman:*), Bash(dkms:*), Bash(zpool:*), Bash(zfs:*), Bash(uname:*), Bash(systemctl:*), Bash(docker:*), Bash(curl:*), Bash(cat:*), Bash(find:*), Bash(wc:*), Bash(grep:*), Bash(git:*), Bash(mkdir:*), Bash(chmod:*), Read, Write, Glob, Grep, Agent, WebSearch, WebFetch, AskUserQuestion
---

# /server-update - Arch Linux Server Update Skill

サーバーのパッケージアップデートを安全に行うためのスキル。
現状調査、依存関係の互換性チェック、段階的更新手順の提案を行い、
日付ディレクトリにシェルスクリプト群とREADMEを生成する。

## IMPORTANT

- 各Phaseを順番に実行すること。スキップ禁止
- sudoコマンドはユーザーが手動で実行する (Claude Codeにsudo権限はない)
- DKMSモジュール(ZFS, NVIDIA)とカーネルの互換性は必ずWebで最新情報を確認すること
- 全ての調査結果をユーザーに見せること

## References

スキルディレクトリ内の `references/` にサーバー固有の情報がある。Phase 1の前にこれらを読み込むこと:

- `~/.claude/skills/server-update/references/server-profile.md` - ハードウェア、OS、サービス構成、DKMS情報、注意点
- `~/.claude/skills/server-update/references/update-history.md` - 過去のアップデート履歴

## Runbook Output

調査完了後、以下の構成で成果物を生成する:

```
/home/asonas/workbench/server-updates/YYYY-MM-DD/
  README.md                # 概要、パッケージリスト、実行手順の説明
  step1-snapshot.sh        # ZFSスナップショット取得
  step2-update-general.sh  # カテゴリD: 一般パッケージ更新 (低リスク)
  step3-update-infra.sh    # カテゴリC: インフラ更新 (中リスク)
  step4-update-kernel.sh   # カテゴリA: カーネル/DKMS更新 (高リスク)
  step5-verify.sh          # 再起動後の検証
```

- 各スクリプトは `chmod +x` で実行可能にする
- スクリプトには `set -euo pipefail` を設定する
- 各スクリプトにはヘッダコメントで何をするか、対象パッケージ数、リスクレベルを記載する
- ユーザーはスクリプトを順番に実行して作業を進める

## Workflow

### Phase 0: References読み込み

`references/server-profile.md` と `references/update-history.md` を読み込み、
サーバー構成と前回のアップデート状況を把握する。

### Phase 1: 現状調査

以下を並列に実行し、現在の状態を把握する:

1. **OS/カーネル情報**: `uname -r`, `cat /etc/os-release | head -3`
2. **更新パッケージ一覧**: `pacman -Qu` (件数と全リスト)
3. **DKMSモジュール状態**: `dkms status`
4. **ZFS状態**: `zpool status -x`, `zfs version`
5. **NVIDIAドライバ**: `pacman -Q | grep nvidia`
6. **稼働中サービス**: `systemctl list-units --type=service --state=running` から重要サービスを抽出
7. **Dockerコンテナ**: `docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"`
8. **未処理の.pacnewファイル**: `find /etc -name "*.pacnew" 2>/dev/null`

### Phase 2: リスク分析と依存関係チェック

更新パッケージを以下のカテゴリに分類する:

#### カテゴリA: カーネル/DKMS関連 (高リスク - 要再起動)
- `linux`, `linux-lts`, `linux-headers`, `linux-lts-headers`
- `linux-firmware*`
- `dkms`

```bash
pacman -Qu | grep -iE "^linux|^dkms"
```

#### カテゴリB: DKMS依存モジュール (カーネルと連動)
- `zfs-dkms`, `zfs-utils`
- `nvidia-*-dkms`, `nvidia-*-utils`

#### カテゴリC: インフラ/セキュリティ (中リスク - サービス再起動が必要な場合あり)
- `docker`, `containerd`, `runc`, `docker-compose`
- `systemd`, `systemd-libs`
- `openssl`, `curl`, `nss`, `ca-certificates-mozilla`
- `postgresql`, `postgresql-libs`
- `nftables`, `openssh`

```bash
pacman -Qu | grep -iE "docker|containerd|runc|systemd|openssl|curl|nss|ca-cert|postgresql|nftables|openssh|ssh"
```

#### カテゴリD: 一般パッケージ (低リスク)
- 上記以外の全パッケージ

### Phase 3: 互換性のWeb調査

**カーネルのメジャーバージョンが変わる場合は必ず実施すること。**
パッチバージョンのみの変更の場合は簡略化してよい。

#### ZFS互換性チェック
1. 現在のZFSバージョンのMETAファイルで `Linux-Maximum` を確認:
   ```bash
   curl -s "https://raw.githubusercontent.com/openzfs/zfs/zfs-{VERSION}/META" | head -20
   ```
2. `Linux-Maximum` >= 新カーネルバージョンであることを確認
3. archzfsリポジトリに新カーネル対応パッケージがあるか確認:
   ```bash
   pacman -Ss zfs | grep archzfs
   ```
4. 問題がある場合、Agentを使ってOpenZFS GitHub / Arch Wikiで詳細調査

#### NVIDIAドライバ互換性チェック
1. `server-profile.md` のNVIDIA情報を参照 (AURパッケージ、GPUアーキテクチャ等)
2. AURパッケージの場合、WebSearchで新カーネルとの互換性を調査:
   - 検索例: `nvidia-580xx-dkms linux 6.18 compatibility`
   - AUR comments / Arch forums を確認
3. ビルド不可の場合の代替策も調査

#### 調査結果の判定
- 全て互換性OK → Phase 4へ
- 問題あり → ユーザーに報告し、対処方針を相談

### Phase 4: Runbook生成

日付ディレクトリとシェルスクリプト群を生成する。

```bash
mkdir -p /home/asonas/workbench/server-updates/YYYY-MM-DD
```

#### README.md

以下の情報を含める:

```markdown
# Server Update Runbook - YYYY-MM-DD

## Overview
- Total packages: N
- Last update: YYYY-MM-DD (N days ago)
- Kernel: X.Y.Z -> A.B.C

## Compatibility Check Results
- ZFS: [OK/NG] - [details]
- NVIDIA: [OK/NG] - [details]

## Risk Assessment
| Category | Count | Risk | Notes |
|---|---|---|---|

## Package List by Category
[Category A/B/C/D with version changes]

## Procedure
[List of scripts with one-line descriptions]
```

#### step1-snapshot.sh
- 既存の `bigdata@pre-upgrade` を確認し、存在すればエラー終了(ユーザーに判断を委ねる)
- `sudo zfs snapshot bigdata@pre-upgrade` を実行

#### step2-update-general.sh
- `sudo pacman -Syu` にカテゴリA/B/Cの全パッケージを `--ignore` で指定
- `--ignore` は複数行に `\` で分割して可読性を確保する

#### step3-update-infra.sh
- カテゴリCのパッケージを `sudo pacman -S` で個別指定
- 更新後に `docker ps` と `systemctl --failed` で確認

#### step4-update-kernel.sh
- カテゴリA(+B)のパッケージを `sudo pacman -S` で個別指定
- 更新後に `dkms status` で全モジュールが `installed` であることを確認
- 失敗時は再起動しないよう警告を表示

#### step5-verify.sh
- 再起動後に実行する検証スクリプト
- `uname -r`, `zpool status`, `zfs version`, `dkms status`
- `docker ps`, `systemctl --failed`, `nvidia-smi`
- `find /etc -name "*.pacnew"`, `pacman -Qu` (残りの更新確認)

全スクリプトに `chmod +x` を付与する。

生成後、ユーザーにディレクトリパスを伝える。

### Phase 5: アップデート実行支援

ユーザーがスクリプトを順番に実行して作業を進める。
各Step完了後、ユーザーから報告を受けて次のStepの案内をする。
問題が発生した場合は調査・対処方針を提案する。

### Phase 6: 後処理

1. `references/update-history.md` に今回のアップデート記録を追記
2. memory内の `pacman-update-log.md` も更新 (存在する場合)
3. 主要な更新内容を記録: カーネル、ZFS、NVIDIA、Docker、PostgreSQL等のバージョン変更
4. 未対応事項 (.pacnew、孤立パッケージ等) を記録

## Notes

- ZFSプールが degraded の場合はアップデート前に対処すること
- SSHで接続中の場合、systemdの更新後はセッション切断のリスクがある
- Dockerコンテナが多数稼働している場合、docker更新によるダウンタイムを考慮すること
- AURパッケージ (`pacman -Qm`) は `pacman -Syu` では更新されない。別途 `pikaur` 等で対応が必要
- スナップショット名 `bigdata@pre-upgrade` は常に同じ名前を使用する。前回のスナップショットが残っている場合はユーザーに確認する
