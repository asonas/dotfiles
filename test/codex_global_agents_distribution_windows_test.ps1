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

$copyFunction = $ast.Find({
    param($node)
    $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
        $node.Name -eq 'Copy-CodexGlobalAgents'
}, $true)
if (-not $copyFunction) {
    throw 'Copy-CodexGlobalAgents was not found in install.ps1.'
}
. ([scriptblock]::Create($copyFunction.Extent.Text))

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

function Assert-Equal {
    param($Expected, $Actual, [string]$Message)
    if ($Expected -ne $Actual) {
        throw "$Message Expected: <$Expected>. Actual: <$Actual>."
    }
}

function New-TestFixture {
    param([string]$Name, [switch]$WithSource)

    $root = Join-Path $script:TestRoot $Name
    $repo = Join-Path $root 'repo'
    $codex = Join-Path $root 'home\.codex'
    New-Item -ItemType Directory -Path $repo -Force | Out-Null
    if ($WithSource) {
        Set-Content -LiteralPath (Join-Path $repo 'AGENTS.md') -Value 'generated guidance'
    }
    [pscustomobject]@{ Repo = $repo; Codex = $codex; Root = $root }
}

function Assert-CopiedGuidance {
    param([string]$CodexDir)

    $target = Join-Path $CodexDir 'AGENTS.md'
    $item = Get-Item -LiteralPath $target -Force
    Assert-True (-not $item.PSIsContainer) "Expected $target to be a file."
    Assert-True (-not $item.LinkType) "Expected $target not to remain a link."
    Assert-Equal 'generated guidance' (Get-Content -LiteralPath $target -Raw).TrimEnd() `
        "Expected $target to contain the generated guidance."
}

function Test-CopiesToNewTarget {
    $fixture = New-TestFixture new-target -WithSource

    Copy-CodexGlobalAgents -RepoRoot $fixture.Repo -CodexDir $fixture.Codex

    Assert-CopiedGuidance -CodexDir $fixture.Codex
}

function Test-OverwritesExistingFile {
    $fixture = New-TestFixture existing-file -WithSource
    New-Item -ItemType Directory -Path $fixture.Codex -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $fixture.Codex 'AGENTS.md') -Value 'old guidance'

    Copy-CodexGlobalAgents -RepoRoot $fixture.Repo -CodexDir $fixture.Codex

    Assert-CopiedGuidance -CodexDir $fixture.Codex
}

function Test-ReplacesFileSymlinkWithoutChangingLinkTarget {
    $fixture = New-TestFixture file-symlink -WithSource
    $linkTarget = Join-Path $fixture.Root 'linked-file.md'
    Set-Content -LiteralPath $linkTarget -Value 'linked guidance'
    New-Item -ItemType Directory -Path $fixture.Codex -Force | Out-Null
    New-Item -ItemType SymbolicLink -Path (Join-Path $fixture.Codex 'AGENTS.md') `
        -Target $linkTarget | Out-Null

    Copy-CodexGlobalAgents -RepoRoot $fixture.Repo -CodexDir $fixture.Codex

    Assert-CopiedGuidance -CodexDir $fixture.Codex
    Assert-Equal 'linked guidance' (Get-Content -LiteralPath $linkTarget -Raw).TrimEnd() `
        'Expected the file symlink target to remain unchanged.'
}

function Test-ReplacesDanglingFileSymlink {
    $fixture = New-TestFixture dangling-file-symlink -WithSource
    $missingTarget = Join-Path $fixture.Root 'missing-file.md'
    New-Item -ItemType Directory -Path $fixture.Codex -Force | Out-Null
    New-Item -ItemType SymbolicLink -Path (Join-Path $fixture.Codex 'AGENTS.md') `
        -Target $missingTarget | Out-Null

    Copy-CodexGlobalAgents -RepoRoot $fixture.Repo -CodexDir $fixture.Codex

    Assert-CopiedGuidance -CodexDir $fixture.Codex
    Assert-True (-not (Test-Path -LiteralPath $missingTarget)) `
        'Expected the dangling symlink target not to be created.'
}

function Test-ReplacesDirectorySymlinkWithoutChangingLinkTarget {
    $fixture = New-TestFixture directory-symlink -WithSource
    $linkTarget = Join-Path $fixture.Root 'linked-directory'
    New-Item -ItemType Directory -Path $linkTarget -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $linkTarget 'sentinel.txt') -Value 'keep me'
    New-Item -ItemType Directory -Path $fixture.Codex -Force | Out-Null
    New-Item -ItemType SymbolicLink -Path (Join-Path $fixture.Codex 'AGENTS.md') `
        -Target $linkTarget | Out-Null

    Copy-CodexGlobalAgents -RepoRoot $fixture.Repo -CodexDir $fixture.Codex

    Assert-CopiedGuidance -CodexDir $fixture.Codex
    Assert-True (Test-Path -LiteralPath (Join-Path $linkTarget 'sentinel.txt')) `
        'Expected the directory symlink target to remain unchanged.'
}

function Test-RejectsRealDirectory {
    $fixture = New-TestFixture real-directory -WithSource
    $target = Join-Path $fixture.Codex 'AGENTS.md'
    New-Item -ItemType Directory -Path $target -Force | Out-Null
    $caught = $null

    try {
        Copy-CodexGlobalAgents -RepoRoot $fixture.Repo -CodexDir $fixture.Codex
    } catch {
        $caught = $_
    }

    Assert-True ($null -ne $caught) 'Expected a real directory target to be rejected.'
    Assert-Equal "$target is a directory; cannot install Codex global guidance." `
        $caught.Exception.Message 'Expected the directory rejection message.'
    Assert-True (Test-Path -LiteralPath $target -PathType Container) `
        'Expected the rejected directory to remain in place.'
}

function Test-SkipsMissingSource {
    $fixture = New-TestFixture missing-source
    $warnings = @()

    Copy-CodexGlobalAgents -RepoRoot $fixture.Repo -CodexDir $fixture.Codex `
        -WarningVariable +warnings

    Assert-Equal 1 $warnings.Count 'Expected one missing source warning.'
    Assert-True ($warnings[0].Message -like '*AGENTS.md not found; skipping Codex global guidance.') `
        'Expected the missing source warning.'
    Assert-True (-not (Test-Path -LiteralPath $fixture.Codex)) `
        'Expected a missing source not to create the Codex directory.'
}

$script:TestRoot = Join-Path ([System.IO.Path]::GetTempPath()) `
    ('codex-global-agents-test-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $script:TestRoot | Out-Null
try {
    Test-CopiesToNewTarget
    Test-OverwritesExistingFile
    Test-ReplacesFileSymlinkWithoutChangingLinkTarget
    Test-ReplacesDanglingFileSymlink
    Test-ReplacesDirectorySymlinkWithoutChangingLinkTarget
    Test-RejectsRealDirectory
    Test-SkipsMissingSource
    Write-Host 'PASS: 7 Windows Codex global AGENTS.md distribution tests'
} finally {
    Remove-Item -LiteralPath $script:TestRoot -Recurse -Force -ErrorAction SilentlyContinue
}
