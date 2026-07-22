# WSL Port Forward タスクスケジューラ登録スクリプト
# 管理者権限で実行してください

$ErrorActionPreference = "Stop"

# 管理者権限チェック
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Administrator)) {
    Write-Host "Error: このスクリプトは管理者権限で実行する必要があります" -ForegroundColor Red
    exit 1
}

$taskName = "WSL SSH Port Forward"
$scriptPath = "$PSScriptRoot\wsl-port-forward.ps1"

# スクリプトが存在するか確認
if (-not (Test-Path $scriptPath)) {
    Write-Host "Error: $scriptPath が見つかりません" -ForegroundColor Red
    exit 1
}

Write-Host "タスクスケジューラに登録します..."
Write-Host "スクリプトパス: $scriptPath"

# 既存のタスクを削除
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($existingTask) {
    Write-Host "既存のタスクを削除しています..."
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

# タスクのアクション定義
$action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`""

# トリガー: ログオン時に実行
$trigger = New-ScheduledTaskTrigger -AtLogOn

# プリンシパル: 最高権限で実行
$principal = New-ScheduledTaskPrincipal `
    -UserId $env:USERNAME `
    -RunLevel Highest

# 設定
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 10)

# タスク登録
$task = Register-ScheduledTask `
    -TaskName $taskName `
    -Action $action `
    -Trigger $trigger `
    -Principal $principal `
    -Settings $settings `
    -Description "Windows起動時にWSLを起動し、SSHポートフォワーディングを設定します"

Write-Host ""
Write-Host "タスクの登録が完了しました！" -ForegroundColor Green
Write-Host ""
Write-Host "タスク名: $taskName"
Write-Host "次回ログオン時から自動的に実行されます"
Write-Host ""
Write-Host "今すぐテスト実行する場合は以下のコマンドを実行してください:"
Write-Host "  Start-ScheduledTask -TaskName '$taskName'" -ForegroundColor Cyan
Write-Host ""
Write-Host "タスクを削除する場合は以下のコマンドを実行してください:"
Write-Host "  Unregister-ScheduledTask -TaskName '$taskName' -Confirm:`$false" -ForegroundColor Cyan
