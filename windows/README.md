# Windows Scripts

## WSL SSH Port Forwarding

WSLにSSH接続するためのポートフォワーディング設定スクリプトです。

### ファイル構成

- `wsl-port-forward.ps1` - ポートフォワーディングを設定するメインスクリプト
- `register-wsl-port-forward-task.ps1` - タスクスケジューラに登録するスクリプト

### セットアップ手順

#### 1. WSL側の準備

WSL内でSSHサーバーを起動しておく必要があります：

```bash
# SSHサーバーのインストール（Ubuntu/Debian）
sudo apt update
sudo apt install openssh-server

# SSH設定（必要に応じて）
sudo nano /etc/ssh/sshd_config

# SSHサーバーの起動
sudo service ssh start

# WSL起動時に自動起動させたい場合は .bashrc や .zshrc に追加
# echo "sudo service ssh start" >> ~/.bashrc
```

#### 2. Windows側の設定

PowerShellを**管理者権限**で開いて実行します：

```powershell
# スクリプトの実行ポリシーを変更（初回のみ）
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# dotfilesディレクトリに移動
cd C:\path\to\dotfiles\windows

# タスクスケジューラに登録
.\register-wsl-port-forward-task.ps1
```

#### 3. 動作確認

```powershell
# 手動でスクリプトを実行してテスト
.\wsl-port-forward.ps1

# または登録したタスクを実行
Start-ScheduledTask -TaskName 'WSL SSH Port Forward'
```

### SSH接続

設定後、以下のように接続できます：

```bash
# ローカルネットワークの別マシンから
ssh your-username@<WindowsのIPアドレス>

# 同じWindowsマシンから
ssh your-username@localhost
```

### カスタマイズ

デフォルトのポートを変更したい場合は、スクリプト実行時にパラメータを指定できます：

```powershell
# ポート2222で待ち受ける場合
.\wsl-port-forward.ps1 -ListenPort 2222 -TargetPort 22
```

タスクスケジューラでカスタムポートを使用する場合は、`register-wsl-port-forward-task.ps1` の `$action` の引数を編集してください。

### トラブルシューティング

#### ポートフォワーディング設定の確認

```powershell
netsh interface portproxy show v4tov4
```

#### ファイアウォールルールの確認

```powershell
Get-NetFirewallRule -DisplayName "WSL SSH Port Forward"
```

#### 設定のリセット

```powershell
# ポートプロキシの削除
netsh interface portproxy delete v4tov4 listenport=22 listenaddress=0.0.0.0

# ファイアウォールルールの削除
Remove-NetFirewallRule -DisplayName "WSL SSH Port Forward"

# タスクスケジューラからの削除
Unregister-ScheduledTask -TaskName "WSL SSH Port Forward" -Confirm:$false
```
