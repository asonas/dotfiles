---
name: usb-debug
description: "macOSでUSBデバイス（キーボード、マイコンボード等）の接続不良・切断・ブートローダ誤突入を診断する。USB接続経路の特定、切断イベントのタイムライン構築、原因の切り分けまでを体系的に行う。"
argument-hint: "<device name or symptom>"
---

# /usb-debug - macOS USB デバイス診断

macOSでUSBデバイスの接続不良、チャタリング、ブートローダ誤突入などを体系的に調査する。

## Workflow

### Step 1: 対象デバイスの特定

USB接続ツリーからデバイスを探し、接続経路・電源・速度を把握する。

```bash
# USB接続ツリーで対象デバイスを検索（デバイス名で検索）
ioreg -p IOUSB -l -w 0 2>&1 | grep -B5 -A35 "USB Product Name\" = \"<device>\""
```

確認する項目:
- USB Product Name / USB Vendor Name
- idVendor / idProduct（16進数変換して照合）
- USBSpeed（0=Low, 1=Full 12Mbps, 2=High 480Mbps, 3=Super 5Gbps）
- UsbPowerSinkAllocation（mA単位の電源要求）
- locationID（接続ポートの識別子）
- iSerialNumber

### Step 2: 接続経路の可視化

デバイスがMac直挿しか、ハブ/ドック経由かを特定する。

```bash
# デバイスの親（ハブ/コントローラ）を辿る
ioreg -p IOUSB -l -w 0 2>&1 | grep -B200 "USB Product Name\" = \"<device>\"" | grep -E "USB Product Name|locationID|USBSpeed |UsbLinkSpeed|USBPortType|^[[:space:]]+\\+-o"
```

ハブ経由の場合、以下を記録する:
- ハブの製品名・メーカー（例: Microchip USB2816 Smart Hub）
- ハブのUSBSpeed と デバイスのUSBSpeed の差（High Speedハブ経由でFull Speedデバイス等）
- ハブの電源タイプ（セルフパワー/バスパワー）

### Step 3: 切断/再接続イベントのタイムライン構築

macOSのシステムログからUSBイベントを時系列に抽出する。

```bash
# 直近N日でデバイス名を含むicdd(Image Capture Daemon)イベントを検索
# icddは全USBデバイスのAdded/Removedを記録する
command log show --predicate 'eventMessage CONTAINS "<device>" AND process == "icdd"' --last <N>d 2>&1 | grep -iE "Added|Removed"
```

```bash
# GameControllerフレームワーク経由のイベント（ChromeがHIDデバイスを追跡）
command log show --predicate 'eventMessage CONTAINS "<device>"' --last <N>d 2>&1 | grep -iE "Connected devices changed"
```

```bash
# loginwindowのキーボード検出イベント
command log show --predicate 'eventMessage CONTAINS "<device>"' --last <N>d 2>&1 | grep "KeyboardServiceAddedCallback"
```

注意:
- `icdd` の `[Removed]` はUSBレベルの切断を示す
- GameControllerの "added/removed" はアプリレベルのHID列挙で、必ずしもUSB切断を意味しない
- 1回の接続で複数の `Added` が出るのは正常（HIDインターフェース毎に1つ）

### Step 4: ブートローダ/マスストレージイベントの検索

RP2040やATmega等のマイコンがブートローダモードに入った証拠を探す。

```bash
# RP2040 BOOTSEL（RPI-RP2 mass storage）
command log show --predicate 'eventMessage CONTAINS "RPI-RP2"' --last <N>d

# Caterina/DFU等（ATmega32U4系）
command log show --predicate 'eventMessage CONTAINS "Atmel" OR eventMessage CONTAINS "DFU"' --last <N>d

# 汎用的なマスストレージマウント
command log show --predicate 'eventMessage CONTAINS "AUTH_MOUNT" AND eventMessage CONTAINS "msdos"' --last <N>d
```

### Step 5: 発生前後の時間窓の精査

Step 4で時刻が特定できたら、その前後2分のログを全量取得する。

```bash
command log show --predicate 'eventMessage CONTAINS "<device>" OR eventMessage CONTAINS "RPI-RP2"' --start "YYYY-MM-DD HH:MM:00" --end "YYYY-MM-DD HH:MM:00" 2>&1
```

ここで確認すること:
- 切断/再接続の間隔（周期性があるか、ランダムか）
- 最後の切断からブートローダ突入までの経過時間
- 正常復帰したかどうか

### Step 6: ファームウェア/config確認

QMK/Vial対象の場合、リポジトリから設定を引く。

```bash
# QMK公式リポジトリから keyboard.json と config.h を取得
ghro api repos/qmk/qmk_firmware/contents/keyboards/<manufacturer>/<model>/keyboard.json --jq '.content' | base64 -d
ghro api repos/qmk/qmk_firmware/contents/keyboards/<manufacturer>/<model>/config.h --jq '.content' | base64 -d
```

確認する項目:
- `processor` / `bootloader`
- `RP2040_BOOTLOADER_DOUBLE_TAP_RESET` と `_TIMEOUT` の有無
- `USB_VBUS_PIN`（VBUS検出ピンの有無）
- `debounce_type` と `DEBOUNCE` 値
- `split.enabled`（スプリットキーボードか）
- `bootmagic` の設定（意図せずブートローダに入るキーがあるか）

### Step 7: リアルタイム監視の設定

再発を待つ場合、ストリームで監視する。

```bash
# ターミナルでリアルタイム監視
command log stream --predicate 'eventMessage CONTAINS "<device>" OR eventMessage CONTAINS "RPI-RP2"'
```

## 診断チェックリスト

調査結果をまとめる際、以下を埋める:

1. **デバイス情報**: VID/PID、MCU、bootloader、ファームウェア設定
2. **接続経路**: 直挿し or ハブ経由、ハブの種類
3. **イベントパターン**: 切断の頻度、周期性の有無、ブートローダ突入の回数
4. **時間的パターン**: 常時発生 or 断続的/発作的、特定の時間帯に集中するか
5. **環境条件**: 複数拠点で発生するか、ケーブルの違い、ハブの違い
6. **切り分け結果**: 直挿し/ハブ経由、左右入替（split）、ポート変更

## よくある原因パターン

### USB VBUS瞬断 → RP2040ダブルタップリセット
- 症状: 突然マスストレージ(RPI-RP2)としてマウントされる
- ログ特徴: icddで規則的な Added/Removed サイクル → AUTH_MOUNT msdos RPI-RP2
- 原因候補: USB-Cレセプタクル摩耗、ハブの電源品質、USB Selective Suspend不整合
- 対症療法: `RP2040_BOOTLOADER_DOUBLE_TAP_RESET` を無効化

### スイッチチャタリング
- 症状: 特定のキーが2-3回連打される
- 特定キーに集中 → スイッチ接点の劣化
- 全キーで均等 → 電源系の問題（debounceではなくVBUS系を疑う）
- 対策: DEBOUNCE値を5ms→10-15msに引き上げ、またはスイッチ交換

### USB Selective Suspend不整合
- 症状: 一定時間無操作後に入力が受け付けられなくなる、または再接続される
- ログ特徴: 規則的な周期（数秒〜数十秒）での切断/再接続
- 原因: ファームウェアのsuspend/resume処理の不備、ハブとの相性

## Notes

- `command log show` と `command log stream` を使う（zshのエイリアス回避）
- logコマンドは大量のデータを処理するため、時間範囲を絞ること（`--last 1d` から始めて必要に応じて拡大）
- `system_profiler SPUSBDataType` はサンドボックス環境では空を返すことがある。`ioreg -p IOUSB` を優先
