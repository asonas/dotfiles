# Server Profile

## Hardware
- GPU: NVIDIA GeForce GTX 1080 Ti (Pascal GP102)
- Storage: ZFS raidz1プール "bigdata" (4x WD 8TB HDD + NVMe log/cache), 約29TB

## OS
- Arch Linux (rolling release)
- ブートカーネル: linux-lts (サーバー用途のため安定性重視)
- mainlineカーネル (linux) もインストール済み

## DKMS Modules
- **zfs-dkms**: archzfsリポジトリから導入 (zfs-dkms, zfs-utils)
- **nvidia-580xx-dkms**: AURパッケージ。GTX 1080 Ti (Pascal) 対応の最終ドライバ系列
  - NVIDIA 590+/open-dkmsはPascalのサポートを終了しているため580xxで固定
  - AURのためpacman -Syuでは更新されない。pikaur等で別途管理

## ZFS
- リポジトリ: archzfs (pacman.confに設定済み)
- プール構成: bigdata (raidz1)
- スナップショット命名規則: `bigdata@pre-upgrade-YYYYMMDD`

## Key Services (systemd)
- docker.service - Docker Engine (Coolifyで多数のコンテナを管理)
- mariadb.service - MariaDB
- sshd.service - OpenSSH
- cloudflared.service - Cloudflare Tunnel
- nfs関連 (nfs-idmapd, nfs-mountd, nfsdcld, rpc-statd)
- zfs-zed.service - ZFS Event Daemon

## Docker/Coolify
- Coolify 4.x でコンテナ管理
- 主要コンテナ: PostgreSQL x3 (15, 16, 17), Jellyfin, Stump, RSS-Bridge, MeiliSearch, Ollama, Traefik (proxy)
- Coolifyプロキシ: Traefik v3

## AUR Packages (pacman -Qm)
- nvidia-580xx-dkms, nvidia-580xx-utils
- r8125-dkms
- pikaur (AURヘルパー)
- dropbox, dropbox-cli
- nodenv
- その他

## pacman設定の注意点
- `/etc/pacman.conf` にarchzfsリポジトリが追加されている
- pacman.conf.pacnewが出た場合、archzfs設定を手動マージする必要がある

## 権限
- Claude Codeはsudo権限を持たない。sudo付きコマンドはユーザーが手動で実行する
- Runbookにsudoコマンドを記載し、ユーザーがコピペで実行する運用

## 更新時の注意
- nvidia-580xxはAURパッケージのため、新カーネルとの互換性をAUR/フォーラムで事前確認が必要
- ZFSのLinux-Maximumを必ずMETAファイルで確認
- SSHで接続中の場合、systemd更新後のセッション切断に注意
- Coolify管理下のコンテナが多いため、docker更新時のダウンタイムを考慮
