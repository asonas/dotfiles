# Codex Global AGENTS.md Distribution Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** APMが生成した `AGENTS.md` を、macOSとLinuxではシンボリックリンク、WindowsではコピーとしてCodexのホームディレクトリへ配布します。

**Architecture:** POSIX版とWindows版の既存インストーラーへ、それぞれのファイル配置規則に合う小さな配布処理を追加します。どちらもAPMによる生成後に配布し、APMがない場合は既存の生成物を再利用します。

**Tech Stack:** Bash、PowerShell 7、APM、シェルベースの契約テスト

## Global Constraints

- macOSとLinuxでは `$HOME/.codex/AGENTS.md` をリポジトリ直下の `AGENTS.md` へのシンボリックリンクにします。
- Windowsでは `$HOME\.codex\AGENTS.md` へ常にコピーし、Developer Modeや管理者権限に依存させません。
- ユーザーごとの絶対パスをスクリプトへ埋め込みません。
- APMがなくても既存の `AGENTS.md` があれば配布します。
- 配布元がない場合は警告してインストールを継続します。
- 配布元がある状態で配置に失敗した場合はインストールを失敗させます。
- テストは一つずつRed、Green、Refactorを進めます。
- コミットには `commit` スキルと `git ai-commit` を使います。

---

### Task 1: POSIX向けシンボリックリンク配布

**Files:**
- Create: `test/codex_global_agents_distribution_test.sh`
- Modify: `install.sh`
- Modify: `plan.md`

**Interfaces:**
- Consumes: `install.sh` が設定する `$PWD` と `$HOME/.codex`
- Produces: `$HOME/.codex/AGENTS.md` から `$PWD/AGENTS.md` へのシンボリックリンク

- [x] **Step 1: POSIX配布契約の失敗するテストを書く**

`test/codex_global_agents_distribution_test.sh` を作成し、まずPOSIXの1項目だけを有効にします。

```bash
#!/bin/bash
set -eu

assert_line_count() {
    expected="$1"
    pattern="$2"
    file="$3"
    actual=$(grep -Ec -- "$pattern" "$file" || true)

    if [ "$actual" -ne "$expected" ]; then
        echo "expected $file to contain $pattern $expected time(s), got $actual" >&2
        return 1
    fi
}

test_posix_links_global_agents_file() {
    assert_line_count 1 '^codex_agents_source="\$PWD/AGENTS.md"$' install.sh
    assert_line_count 1 '^codex_agents_target="\$HOME/.codex/AGENTS.md"$' install.sh
    assert_line_count 1 '^    ln -sfn "\$codex_agents_source" "\$codex_agents_target"$' install.sh
    assert_line_count 1 '^    echo "warning: \$codex_agents_source not found; skipping Codex global guidance\."$' install.sh
}

test_posix_links_global_agents_file
```

`plan.md` の先頭項目を進行中にします。

- [x] **Step 2: テストを実行してRedを確認する**

Run: `bash test/codex_global_agents_distribution_test.sh`

Expected: FAIL。`install.sh` に `codex_agents_source` が0回しかないと表示されます。

- [x] **Step 3: POSIX向けの最小実装を書く**

`install.sh` のAPM分岐直後へ次を追加します。

```bash
codex_agents_source="$PWD/AGENTS.md"
codex_agents_target="$HOME/.codex/AGENTS.md"
if [ -f "$codex_agents_source" ]; then
    ln -sfn "$codex_agents_source" "$codex_agents_target"
else
    echo "warning: $codex_agents_source not found; skipping Codex global guidance."
fi
```

- [x] **Step 4: テストを実行してGreenを確認する**

Run: `bash test/codex_global_agents_distribution_test.sh`

Expected: PASS、終了コード0。

- [x] **Step 5: POSIXの構文と既存契約を検証する**

Run: `bash -n install.sh && bash test/apm_codex_support_test.sh && bash test/codex_global_agents_distribution_test.sh`

Expected: 全コマンドが終了コード0。

- [x] **Step 6: テストリストを更新する**

`plan.md` のPOSIX項目を完了にし、Windowsコピー項目を進行中にします。

- [x] **Step 7: POSIX配布をコミットする**

`commit` スキルを使い、次のファイルだけを一つの論理単位としてステージします。

```bash
git add test/codex_global_agents_distribution_test.sh install.sh plan.md
git ai-commit --context "Add tested POSIX distribution for Codex global AGENTS.md guidance. Use an English commit message starting with a capital letter and do not use Conventional Commits."
```

### Task 2: Windows向けコピー配布

**Files:**
- Modify: `test/codex_global_agents_distribution_test.sh`
- Modify: `install.ps1`
- Modify: `plan.md`

**Interfaces:**
- Consumes: `$RepoRoot`、PowerShellの `$HomeDir`、APMコマンド
- Produces: `$HomeDir\.codex\AGENTS.md` の通常ファイル

- [x] **Step 1: Windowsコピー配布の失敗するテストを一つ追加する**

テストファイルへ次を追加し、末尾から呼び出します。

```bash
test_windows_copies_global_agents_file() {
    assert_line_count 1 '^\$CodexDir = Join-Path \$HomeDir '\''\.codex'\''$' install.ps1
    assert_line_count 1 '^    Copy-Item -LiteralPath \$source -Destination \$target -Force$' install.ps1
    assert_line_count 1 '^        Write-Warning "\$source not found; skipping Codex global guidance\."$' install.ps1
    assert_line_count 1 '^Copy-CodexGlobalAgents -RepoRoot \$RepoRoot -CodexDir \$CodexDir$' install.ps1

    if grep -Eq '^New-DotLink .*AGENTS\.md' install.ps1; then
        echo 'expected Windows Codex AGENTS.md distribution not to use New-DotLink' >&2
        return 1
    fi
}
```

Run: `bash test/codex_global_agents_distribution_test.sh`

Expected: FAIL。`install.ps1` に `$CodexDir` が0回しかないと表示されます。

- [x] **Step 2: Windows向けの最小コピー関数を書く**

`install.ps1` の実行部より前へ次を追加します。

```powershell
function Copy-CodexGlobalAgents {
    param([Parameter(Mandatory)][string]$RepoRoot,
          [Parameter(Mandatory)][string]$CodexDir)

    $source = Join-Path $RepoRoot 'AGENTS.md'
    if (-not (Test-Path -LiteralPath $source)) {
        Write-Warning "$source not found; skipping Codex global guidance."
        return
    }

    New-Item -ItemType Directory -Path $CodexDir -Force | Out-Null
    $target = Join-Path $CodexDir 'AGENTS.md'
    Copy-Item -LiteralPath $source -Destination $target -Force
    Write-Host "  copied    $target"
}
```

変数定義とAPM処理後の呼び出しを追加します。

```powershell
$CodexDir = Join-Path $HomeDir '.codex'
```

```powershell
Write-Host "==> Copying global Codex AGENTS.md"
Copy-CodexGlobalAgents -RepoRoot $RepoRoot -CodexDir $CodexDir
```

- [x] **Step 3: テストを実行してGreenを確認する**

Run: `bash test/codex_global_agents_distribution_test.sh`

Expected: PASS、終了コード0。

- [x] **Step 4: Windows関連テストを再実行する**

Run: `bash test/codex_global_agents_distribution_test.sh`

Expected: PASS、終了コード0。

- [x] **Step 5: テストリストを更新する**

`plan.md` のWindowsコピー項目を完了にし、APM生成順序項目を進行中にします。

- [x] **Step 6: Windowsコピー配布をコミットする**

`commit` スキルを使い、次のファイルだけを一つの論理単位としてステージします。

```bash
git add test/codex_global_agents_distribution_test.sh install.ps1 plan.md
git ai-commit --context "Add tested Windows copy distribution for Codex global AGENTS.md guidance. Use an English commit message starting with a capital letter and do not use Conventional Commits."
```

### Task 3: WindowsのAPM生成順序とCodex target

**Files:**
- Modify: `test/codex_global_agents_distribution_test.sh`
- Modify: `install.ps1`
- Modify: `plan.md`

**Interfaces:**
- Consumes: `Invoke-ApmDistribution` が受け取る `$RepoRoot`
- Produces: 配布前に生成済みの `AGENTS.md`、`claude,cursor,codex` で統一されたAPM target

- [x] **Step 1: Codex targetの失敗するテストを追加する**

テストファイルへ次を追加し、末尾から呼び出します。

```bash
test_windows_apm_targets_include_codex() {
    assert_line_count 1 '^        & apm update --yes --target claude,cursor,codex$' install.ps1
    assert_line_count 1 '^        & apm install -g --target claude,cursor,codex$' install.ps1
}
```

Run: `bash test/codex_global_agents_distribution_test.sh`

Expected: FAIL。WindowsのAPM targetが `claude,cursor` のままであることを示します。

- [x] **Step 2: WindowsのAPM targetへCodexを追加する**

`Invoke-ApmDistribution` 内の2コマンドと表示を `claude,cursor,codex` に変更します。

```powershell
Write-Host "==> apm install -g --target claude,cursor,codex"
& apm update --yes --target claude,cursor,codex
& apm install -g --target claude,cursor,codex
```

- [x] **Step 3: Codex targetのテストをGreenにする**

Run: `bash test/codex_global_agents_distribution_test.sh`

Expected: PASS、終了コード0。

- [x] **Step 4: 配布前compileの失敗するテストを追加する**

テストファイルへ次を追加し、末尾から呼び出します。

```bash
test_windows_compiles_before_copying() {
    compile_line=$(grep -n '^        & apm compile$' install.ps1 | cut -d: -f1)
    copy_line=$(grep -n '^Copy-CodexGlobalAgents -RepoRoot \$RepoRoot -CodexDir \$CodexDir$' install.ps1 | cut -d: -f1)

    if [ -z "$compile_line" ] || [ -z "$copy_line" ] || [ "$compile_line" -ge "$copy_line" ]; then
        echo 'expected Windows apm compile to run before Codex AGENTS.md copy' >&2
        return 1
    fi
}
```

Run: `bash test/codex_global_agents_distribution_test.sh`

Expected: FAIL。`apm compile` が存在しないことを示します。

- [x] **Step 5: WindowsのAPM処理へcompileを追加する**

`Invoke-ApmDistribution` の`Push-Location`でリポジトリを一時的な作業場所にし、生成後に元の場所へ戻します。

```powershell
Push-Location $RepoRoot
try {
    Write-Host "==> apm compile (.apm/instructions -> CLAUDE.md, AGENTS.md)"
    & apm compile
} finally {
    Pop-Location
}
```

このブロックは `$apmDir` で `apm update` を実行するブロックより前へ置きます。

- [x] **Step 6: compile順序のテストをGreenにする**

Run: `bash test/codex_global_agents_distribution_test.sh`

Expected: PASS、終了コード0。

- [x] **Step 7: テストリストを更新する**

`plan.md` のAPM生成順序項目を完了にし、全体検証項目を進行中にします。

- [x] **Step 8: WindowsのAPM更新をコミットする**

`commit` スキルを使い、次のファイルだけを一つの論理単位としてステージします。

```bash
git add test/codex_global_agents_distribution_test.sh install.ps1 plan.md
git ai-commit --context "Generate and distribute Codex guidance from the Windows installer. Use an English commit message starting with a capital letter and do not use Conventional Commits."
```

### Task 4: 全体検証と進捗完了

**Files:**
- Modify: `plan.md`
- Modify: `docs/superpowers/specs/2026-07-22-codex-global-agents-design.md`

**Interfaces:**
- Consumes: Task 1からTask 3で追加した両インストーラーの配布処理
- Produces: 検証済みの実装と完了した進捗記録

- [x] **Step 1: すべてのシェルテストを実行する**

Run:

```bash
for test_file in test/*.sh; do
    bash "$test_file"
done
```

Expected: すべて終了コード0。

- [x] **Step 2: 構文検査を実行する**

Run: `bash -n install.sh`

Expected: 終了コード0、出力なし。

PowerShellが利用可能な場合は次も実行します。

Run: `pwsh -NoProfile -Command '$null = [System.Management.Automation.Language.Parser]::ParseFile("install.ps1", [ref]$null, [ref]$null)'`

Expected: 終了コード0、出力なし。

- [x] **Step 3: 設計書とテストリストを完了状態へ更新する**

`plan.md` の全項目を完了にします。
設計書のCurrent Statusへ実装完了と利用可能な検証の完了を記録し、PowerShellを利用できるWindows環境での実動作検証だけは未完了として残します。2026-07-22の検証結果もUpdatesへ追記します。

- [x] **Step 4: 文書更新後に契約テストを再実行する**

Run: `bash test/codex_global_agents_distribution_test.sh && bash test/apm_codex_support_test.sh`

Expected: 両方とも終了コード0。

- [x] **Step 5: 完了記録をコミットする**

`commit` スキルを使い、進捗文書だけを一つの論理単位としてステージします。

```bash
git add plan.md docs/superpowers/specs/2026-07-22-codex-global-agents-design.md
git ai-commit --context "Record completion and verification of Codex global guidance distribution. Use an English commit message starting with a capital letter and do not use Conventional Commits."
```
