# WSL SSH Port Forwarding Script
# このスクリプトはWSLのIPアドレスを取得し、SSHポートフォワーディングを設定します
# 管理者権限で実行する必要があります

param(
    [int]$ListenPort = 22,      # Windowsで待ち受けるポート
    [int]$TargetPort = 22       # WSLのSSHポート
)

$ErrorActionPreference = "Stop"

# ログ出力関数
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message"
}

# 管理者権限チェック
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Administrator)) {
    Write-Log "Error: このスクリプトは管理者権限で実行する必要があります"
    exit 1
}

Write-Log "WSL SSH Port Forwarding を設定します..."

# WSLを起動（まだ起動していない場合）
Write-Log "WSLを起動しています..."
wsl --exec /bin/true

# WSLのIPアドレスを取得
Write-Log "WSLのIPアドレスを取得しています..."
$wslIp = (wsl hostname -I).Trim().Split(" ")[0]

if ([string]::IsNullOrEmpty($wslIp)) {
    Write-Log "Error: WSLのIPアドレスを取得できませんでした"
    exit 1
}

Write-Log "WSL IP Address: $wslIp"

# 既存のポートプロキシルールを削除
Write-Log "既存のポートフォワーディングルールを削除しています..."
$existingRule = netsh interface portproxy show v4tov4 | Select-String "$ListenPort"
if ($existingRule) {
    netsh interface portproxy delete v4tov4 listenport=$ListenPort listenaddress=0.0.0.0
    Write-Log "既存のルールを削除しました"
}

# 新しいポートプロキシルールを追加
Write-Log "ポートフォワーディングルールを追加しています..."
netsh interface portproxy add v4tov4 listenport=$ListenPort listenaddress=0.0.0.0 connectport=$TargetPort connectaddress=$wslIp

# ファイアウォールルールの確認と追加
$firewallRuleName = "WSL SSH Port Forward"
$existingFirewallRule = Get-NetFirewallRule -DisplayName $firewallRuleName -ErrorAction SilentlyContinue

if (-not $existingFirewallRule) {
    Write-Log "ファイアウォールルールを追加しています..."
    New-NetFirewallRule -DisplayName $firewallRuleName `
        -Direction Inbound `
        -Protocol TCP `
        -LocalPort $ListenPort `
        -Action Allow `
        -Profile Any
    Write-Log "ファイアウォールルールを追加しました"
} else {
    Write-Log "ファイアウォールルールは既に存在します"
}

# 設定の確認
Write-Log "現在のポートフォワーディング設定:"
netsh interface portproxy show v4tov4

Write-Log ""
Write-Log "設定が完了しました！"
Write-Log "外部から ssh user@<WindowsのIPアドレス> -p $ListenPort で接続できます"
