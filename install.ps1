#!/usr/bin/env pwsh
#requires -Version 7.0
<#
.SYNOPSIS
    Windows installer for asonas/dotfiles — Claude / Cursor focused subset.

.DESCRIPTION
    install.sh is the full macOS / Linux setup. This is a deliberately small
    Windows counterpart that links only the cross-platform Claude assets:

        .claude/commands/gemini-search.md
        .claude/commands/talk-review
        .claude/user-skills/*   -> ~/.claude/skills/<name>
        CLAUDE.md               -> ~/.claude/CLAUDE.md   (only if present)

    It intentionally SKIPS vim / emacs / zsh / tmux and the macOS-only configs
    (yabai, skhd, karabiner, nvim), plus the APM (Agent Package Manager) and zsh
    completion machinery from install.sh, none of which apply on Windows.

    .claude/settings.json is NOT linked by default: it is tuned for macOS (hooks
    call POSIX .sh scripts and a superpowers .cmd, statusLine is a .py, and the
    cman MCP server uses a /Users/... path), so linking it would point Windows
    Claude Code at scripts that do not exist. Pass -LinkSettings to link it anyway.

    Real symlinks on Windows need Developer Mode (Settings > For developers) or
    an elevated shell. This script prefers symlinks; when they are unavailable it
    falls back to junctions for directories and copies for files (copies do not
    sync edits back to the repo — enable Developer Mode for the real experience).

.PARAMETER LinkSettings
    Also symlink .claude/settings.json into ~/.claude. Off by default; see above.

.EXAMPLE
    pwsh ./install.ps1
.EXAMPLE
    pwsh ./install.ps1 -LinkSettings
#>
[CmdletBinding()]
param(
    [switch]$LinkSettings
)

$ErrorActionPreference = 'Stop'
$RepoRoot  = $PSScriptRoot
$HomeDir   = $HOME   # in PowerShell 7 this resolves to %USERPROFILE%
$ClaudeDir = Join-Path $HomeDir '.claude'

# --- Can we create real symlinks here? (Developer Mode or elevation required) ---
function Test-SymlinkCapability {
    $target = Join-Path $env:TEMP ('dotfiles-symlink-target-' + [guid]::NewGuid().ToString('N'))
    $probe  = Join-Path $env:TEMP ('dotfiles-symlink-probe-'  + [guid]::NewGuid().ToString('N'))
    try {
        New-Item -ItemType File -Path $target -Force | Out-Null
        New-Item -ItemType SymbolicLink -Path $probe -Target $target -ErrorAction Stop | Out-Null
        return $true
    } catch {
        return $false
    } finally {
        Remove-Item -LiteralPath $probe  -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $target -Force -ErrorAction SilentlyContinue
    }
}

# --- Link $Target (in the repo) to $Link (under $HOME), replacing whatever is there. ---
function New-DotLink {
    param(
        [Parameter(Mandatory)] [string]$Target,
        [Parameter(Mandatory)] [string]$Link,
        [Parameter(Mandatory)] [bool]$CanSymlink
    )

    if (-not (Test-Path -LiteralPath $Target)) {
        Write-Warning "skip (missing source): $Target"
        return
    }

    $parent = Split-Path -Parent $Link
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    # Remove an existing entry, including dangling symlinks (Get-Item -Force finds
    # reparse points even when their target is gone). Delete the link itself, not
    # its contents, when it is a symlink/junction.
    $existing = Get-Item -LiteralPath $Link -Force -ErrorAction SilentlyContinue
    if ($existing) {
        if ($existing.LinkType) { $existing.Delete() }
        else { Remove-Item -LiteralPath $Link -Recurse -Force }
    }

    $isDir = (Get-Item -LiteralPath $Target).PSIsContainer
    if ($CanSymlink) {
        New-Item -ItemType SymbolicLink -Path $Link -Target $Target | Out-Null
        Write-Host "  symlink   $Link"
    } elseif ($isDir) {
        New-Item -ItemType Junction -Path $Link -Target $Target | Out-Null
        Write-Host "  junction  $Link"
    } else {
        Copy-Item -LiteralPath $Target -Destination $Link -Force
        Write-Warning "  copied    $Link  (no symlink permission; edits will NOT sync back to the repo)"
    }
}

# --- Run -------------------------------------------------------------------

$CanSymlink = Test-SymlinkCapability
if (-not $CanSymlink) {
    Write-Warning 'Real symlinks are unavailable. Enable Developer Mode'
    Write-Warning '(Settings > System > For developers) or run this from an elevated shell.'
    Write-Warning 'Falling back to junctions for directories and copies for files.'
}

if (-not (Test-Path -LiteralPath $ClaudeDir)) {
    New-Item -ItemType Directory -Path $ClaudeDir -Force | Out-Null
}

Write-Host "==> Linking Claude commands"
$commands = @(
    '.claude\commands\gemini-search.md',
    '.claude\commands\talk-review'
)
foreach ($rel in $commands) {
    New-DotLink -Target (Join-Path $RepoRoot $rel) -Link (Join-Path $HomeDir $rel) -CanSymlink $CanSymlink
}

Write-Host "==> Linking global CLAUDE.md"
# CLAUDE.md is APM-generated and gitignored, so a fresh clone may not have it.
# New-DotLink warns and skips when the source is absent.
New-DotLink -Target (Join-Path $RepoRoot 'CLAUDE.md') -Link (Join-Path $ClaudeDir 'CLAUDE.md') -CanSymlink $CanSymlink

Write-Host "==> Linking user skills into ~/.claude/skills"
# Keep ~/.claude/skills a real directory so plugin/marketplace skills coexist;
# link each entry from the repo individually.
$skillsDst = Join-Path $ClaudeDir 'skills'
if (-not (Test-Path -LiteralPath $skillsDst)) {
    New-Item -ItemType Directory -Path $skillsDst -Force | Out-Null
}
$userSkills = Join-Path $RepoRoot '.claude\user-skills'
if (Test-Path -LiteralPath $userSkills) {
    foreach ($skill in Get-ChildItem -LiteralPath $userSkills -Directory) {
        New-DotLink -Target $skill.FullName -Link (Join-Path $skillsDst $skill.Name) -CanSymlink $CanSymlink
    }
}

if ($LinkSettings) {
    Write-Host "==> Linking .claude/settings.json (-LinkSettings)"
    New-DotLink -Target (Join-Path $RepoRoot '.claude\settings.json') `
                -Link   (Join-Path $ClaudeDir 'settings.json') -CanSymlink $CanSymlink
    Write-Warning 'settings.json is macOS-tuned: its hooks call POSIX .sh/.cmd scripts, the'
    Write-Warning 'statusLine is a .py, and the cman MCP server uses a /Users/... path.'
    Write-Warning 'These will not work on Windows without adapting the paths.'
} else {
    Write-Host "==> Skipping .claude/settings.json (macOS-tuned; re-run with -LinkSettings to link it)"
}

Write-Host ""
Write-Host "Done. Notes:"
Write-Host "  * Cursor rules are per-project (.cursorrules / .cursor/rules); there is no"
Write-Host "    global equivalent to link from here."
Write-Host "  * Keep the repo at a stable ghq path so the symlinks survive (e.g."
Write-Host "    `$env:USERPROFILE\ghq\github.com\asonas\dotfiles)."
