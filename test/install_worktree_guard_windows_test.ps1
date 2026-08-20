#!/usr/bin/env pwsh
#requires -Version 7.0
[CmdletBinding()]
param(
    [string]$InstallerPath = (Join-Path $PSScriptRoot '..\install.ps1')
)

$ErrorActionPreference = 'Stop'
$installer = (Resolve-Path -LiteralPath $InstallerPath).Path
$tokens = $null
$parseErrors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile(
    $installer,
    [ref]$tokens,
    [ref]$parseErrors
)
if ($parseErrors.Count -gt 0) {
    throw "install.ps1 failed to parse: $($parseErrors -join '; ')"
}

$guardFunction = $ast.Find({
    param($node)
    $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
        $node.Name -eq 'Assert-MainWorktree'
}, $true)
if (-not $guardFunction) {
    throw 'Assert-MainWorktree was not found in install.ps1.'
}
. ([scriptblock]::Create($guardFunction.Extent.Text))

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

$testRoot = Join-Path ([System.IO.Path]::GetTempPath()) `
    ('install-worktree-guard-test-' + [guid]::NewGuid().ToString('N'))
$mainRoot = Join-Path $testRoot 'main'
$linkedRoot = Join-Path $testRoot 'linked'
$fakeBin = Join-Path $testRoot 'bin'
New-Item -ItemType Directory -Path $mainRoot, $linkedRoot, $fakeBin -Force | Out-Null

Set-Content -LiteralPath (Join-Path $fakeBin 'git.cmd') -Encoding ascii -Value @(
    '@echo off'
    'if "%1"=="rev-parse" if "%2"=="--show-toplevel" echo %FAKE_CURRENT_ROOT%'
    'if "%1"=="rev-parse" if "%2"=="--show-toplevel" exit /b 0'
    'if "%1"=="worktree" if "%2"=="list" if "%3"=="--porcelain" echo worktree %FAKE_MAIN_ROOT%'
    'if "%1"=="worktree" if "%2"=="list" if "%3"=="--porcelain" echo HEAD 0000000000000000000000000000000000000000'
    'if "%1"=="worktree" if "%2"=="list" if "%3"=="--porcelain" exit /b 0'
    'exit /b 2'
)

$originalPath = $env:PATH
$originalCurrent = $env:FAKE_CURRENT_ROOT
$originalMain = $env:FAKE_MAIN_ROOT
try {
    $env:PATH = "$fakeBin;$originalPath"
    $env:FAKE_MAIN_ROOT = $mainRoot
    $env:FAKE_CURRENT_ROOT = $mainRoot
    Assert-MainWorktree -RepoRoot $mainRoot

    $env:FAKE_CURRENT_ROOT = $linkedRoot
    $caught = $null
    try {
        Assert-MainWorktree -RepoRoot $mainRoot
    } catch {
        $caught = $_
    }

    Assert-True ($null -ne $caught) 'Expected a linked worktree to be rejected.'
    Assert-True ($caught.Exception.Message -like '*main worktree*') `
        'Expected the rejection to mention the main worktree.'
} finally {
    $env:PATH = $originalPath
    $env:FAKE_CURRENT_ROOT = $originalCurrent
    $env:FAKE_MAIN_ROOT = $originalMain
    Remove-Item -LiteralPath $testRoot -Recurse -Force -ErrorAction SilentlyContinue
}
