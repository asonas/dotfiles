# Update History

## 2026-04-05 (部分完了、カーネル更新は後日)

- 165パッケージ対象、うちインフラ+一般パッケージを適用済み
- docker: 29.2.1 → 29.3.1
- containerd: 2.2.1 → 2.2.2
- runc: 1.4.0 → 1.4.2
- curl: 8.18.0 → 8.19.0
- postgresql: 18.2 → 18.3
- systemd: 259.1 → 260.1
- 未実施: linux-lts 6.12.74 → 6.18.21, linux 6.18.9 → 6.19.11, dkms, firmware
- Runbook: ~/workbench/server-updates/2026-04-05/ (step4, step5が残り)
- スナップショット: bigdata@pre-upgrade

## 2026-02-26

- 167パッケージ更新
- linux-lts: 6.12.67 → 6.12.74
- linux: 6.18.6 → 6.18.9
- zfs-dkms: 2.4.0 → 2.4.1
- docker: 29.1.4 → 29.2.1
- glibc: 2.42 → 2.43
- openssl: 3.6.0 → 3.6.1
- systemd: 259-2 → 259.1-1
- DKMSビルド: 全て正常
- ZFS: healthy
- スナップショット: bigdata@pre-upgrade-20260226
- 未対応: .pacnew 12個, 孤立パッケージ39個
