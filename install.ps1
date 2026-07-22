#!/usr/bin/env pwsh
#requires -Version 7.0
<#
.SYNOPSIS
    Windows installer for asonas/dotfiles — Windows-focused subset.

.DESCRIPTION
    install.sh is the full macOS / Linux setup. This is the Windows counterpart.
    It does three things:

    1. Links WezTerm config to the Windows-recommended ~/.wezterm.lua path.

    2. Links the cross-platform hand-authored Claude assets:
         .claude/commands/gemini-search.md
         .claude/commands/talk-review
         .claude/user-skills/*   -> ~/.claude/skills/<name>
         CLAUDE.md               -> ~/.claude/CLAUDE.md   (only if present)

    3. Distributes APM (Agent Package Manager) dependencies into ~/.claude via
       'apm install -g' (skills, agents, commands from apm.yml), mirroring the
       APM section of install.sh. See Invoke-ApmDistribution below. Skip with
       -SkipApm, or it is skipped automatically when 'apm' is not on PATH.

    It intentionally SKIPS vim / emacs / zsh / tmux and the macOS-only configs
    (yabai, skhd, karabiner, nvim) and the zsh completion machinery, none of
    which apply on Windows.

    .claude/settings.json is NOT linked: it is tuned for macOS (statusLine is a
    .py, the cman MCP server uses a /Users/... path). The APM step instead writes
    only the SessionStart hook into the existing ~/.claude/settings.json and
    normalizes it (see Repair-ClaudeSettingsHooks). Pass -LinkSettings to link the
    repo's macOS settings.json wholesale anyway (not recommended on Windows).

    Real symlinks on Windows need Developer Mode (Settings > For developers) or
    an elevated shell. This script prefers symlinks; when they are unavailable it
    falls back to junctions for directories and copies for files (copies do not
    sync edits back to the repo — enable Developer Mode for the real experience).

.PARAMETER LinkSettings
    Also symlink the repo's macOS-tuned .claude/settings.json into ~/.claude.
    Off by default; see above.

.PARAMETER SkipApm
    Skip the APM distribution step (only do the symlink/junction wiring).

.EXAMPLE
    pwsh ./install.ps1
.EXAMPLE
    pwsh ./install.ps1 -SkipApm
#>
[CmdletBinding()]
param(
    [switch]$LinkSettings,
    [switch]$SkipApm
)

$ErrorActionPreference = 'Stop'
$RepoRoot  = $PSScriptRoot
$HomeDir   = $HOME   # in PowerShell 7 this resolves to %USERPROFILE%
$ClaudeDir = Join-Path $HomeDir '.claude'
$CodexDir = Join-Path $HomeDir '.codex'

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
        [Parameter(Mandatory)] [bool]$CanSymlink,
        [switch]$BackupExisting
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
    $isDir = (Get-Item -LiteralPath $Target).PSIsContainer
    $existing = Get-Item -LiteralPath $Link -Force -ErrorAction SilentlyContinue
    if ($existing) {
        if ($existing.LinkType) { $existing.Delete() }
        elseif (
            $BackupExisting -and
            -not $CanSymlink -and
            -not $isDir -and
            ((Get-FileHash -LiteralPath $Target).Hash -eq (Get-FileHash -LiteralPath $Link).Hash)
        ) {
            Write-Host "  unchanged $Link"
        }
        elseif ($BackupExisting) {
            $backup = '{0}.bak-{1}' -f $Link, (Get-Date -Format 'yyyyMMdd-HHmmss')
            Move-Item -LiteralPath $Link -Destination $backup -Force
            Write-Host "  backup    $backup"
        } else {
            Remove-Item -LiteralPath $Link -Recurse -Force
        }
    }

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

# --- Bridge obra/superpowers' SessionStart hook into ~/.claude. ------------
# APM has a long-standing bug (the doubled hooks/hooks/ path) where it deploys
# run-hook.cmd but not the 'session-start' bash script or the skills/ tree the
# script reads. install.sh works around it with symlinks; we copy the script
# (no Developer Mode needed) and junction the skills dir. Returns the path to
# run-hook.cmd, or $null when superpowers is not installed.
function Set-SuperpowersHookBridge {
    param([Parameter(Mandatory)][string]$ApmModules,
          [Parameter(Mandatory)][string]$ClaudeDir)

    $src = Join-Path $ApmModules 'obra\superpowers'
    if (-not (Test-Path -LiteralPath $src)) { return $null }

    $dst = Join-Path $ClaudeDir 'hooks\superpowers'
    New-Item -ItemType Directory -Path (Join-Path $dst 'hooks') -Force | Out-Null

    foreach ($f in 'session-start', 'session-start-codex') {
        $s = Join-Path $src "hooks\$f"
        if (Test-Path -LiteralPath $s) { Copy-Item -LiteralPath $s (Join-Path $dst "hooks\$f") -Force }
    }

    # session-start reads ${PLUGIN_ROOT}/skills/using-superpowers/SKILL.md
    $skillsTarget = Join-Path $src 'skills'
    if (Test-Path -LiteralPath $skillsTarget) {
        $link = Join-Path $dst 'skills'
        $existing = Get-Item -LiteralPath $link -Force -ErrorAction SilentlyContinue
        if ($existing) {
            if ($existing.LinkType) { $existing.Delete() } else { Remove-Item -LiteralPath $link -Recurse -Force }
        }
        New-Item -ItemType Junction -Path $link -Target $skillsTarget | Out-Null
    }

    return (Join-Path $dst 'hooks\run-hook.cmd')
}

# --- Normalize the SessionStart hook in ~/.claude/settings.json. -----------
# APM writes a duplicate, casing-broken hooks block (an invalid lowercase
# 'sessionStart' key plus a redundant Codex entry). Mirror the jq normalization
# in install.sh: drop 'sessionStart', and pin 'SessionStart' to a single entry
# that runs our bridged run-hook.cmd — or remove it entirely if the hook script
# is missing, so Claude Code never calls a non-existent command.
function Repair-ClaudeSettingsHooks {
    param([Parameter(Mandatory)][string]$SettingsPath,
          [string]$RunHookCmd)

    if (-not (Test-Path -LiteralPath $SettingsPath)) { return }
    # -AsHashtable: APM leaves both 'SessionStart' and an invalid lowercase
    # 'sessionStart' key; the object parser rejects case-only-differing keys,
    # the hashtable parser keeps them distinct (case-sensitive) so we can prune.
    $json = Get-Content -LiteralPath $SettingsPath -Raw | ConvertFrom-Json -AsHashtable
    $hooks = $json['hooks']
    if (-not $hooks) { return }

    $hooks.Remove('sessionStart')

    if ($RunHookCmd -and (Test-Path -LiteralPath $RunHookCmd)) {
        $hooks['SessionStart'] = @(@{
            matcher = 'startup|clear|compact'
            hooks   = @(@{
                type    = 'command'
                command = '"{0}" session-start' -f $RunHookCmd
                async   = $false
            })
        })
    } else {
        $hooks.Remove('SessionStart')
    }

    if ($hooks.Count -eq 0) { $json.Remove('hooks') }

    $json | ConvertTo-Json -Depth 32 | Set-Content -LiteralPath $SettingsPath -Encoding utf8
}

# --- Distribute APM dependencies globally into ~/.claude. ------------------
# Mirrors the APM section of install.sh: stage the manifest under ~/.apm,
# refresh refs, install globally for the claude+cursor targets, copy the
# refreshed lockfile back to the repo, then bridge + normalize the hook.
function Invoke-ApmDistribution {
    param([Parameter(Mandatory)][string]$RepoRoot,
          [Parameter(Mandatory)][string]$HomeDir,
          [Parameter(Mandatory)][string]$ClaudeDir)

    if (-not (Get-Command apm -ErrorAction SilentlyContinue)) {
        Write-Warning 'apm not found on PATH; skipping APM distribution.'
        Write-Warning "Install it with: scoop install apm   (or: irm https://aka.ms/apm-windows | iex)"
        return
    }

    $apmDir = Join-Path $HomeDir '.apm'
    New-Item -ItemType Directory -Path $apmDir -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $RepoRoot 'apm.yml') (Join-Path $apmDir 'apm.yml') -Force
    if (Test-Path -LiteralPath (Join-Path $RepoRoot 'apm.lock.yaml')) {
        Copy-Item -LiteralPath (Join-Path $RepoRoot 'apm.lock.yaml') (Join-Path $apmDir 'apm.lock.yaml') -Force
    }

    Push-Location $apmDir
    try {
        # 'apm update' refreshes #main refs so the lockfile matches upstream;
        # without it 'apm install' aborts on a content-hash mismatch. Both are
        # tolerant of non-zero exits (a single unavailable dependency must not
        # abort the whole distribution, same rationale as install.sh).
        Write-Host "==> apm update --yes (refresh refs)"
        & apm update --yes --target claude,cursor
        Write-Host "==> apm install -g --target claude,cursor"
        & apm install -g --target claude,cursor
    } finally {
        Pop-Location
    }

    # Keep the refreshed pins version-controlled alongside apm.yml.
    $stagedLock = Join-Path $apmDir 'apm.lock.yaml'
    if (Test-Path -LiteralPath $stagedLock) {
        Copy-Item -LiteralPath $stagedLock (Join-Path $RepoRoot 'apm.lock.yaml') -Force
    }

    Write-Host "==> Repairing superpowers SessionStart hook"
    $runHook = Set-SuperpowersHookBridge -ApmModules (Join-Path $apmDir 'apm_modules') -ClaudeDir $ClaudeDir
    Repair-ClaudeSettingsHooks -SettingsPath (Join-Path $ClaudeDir 'settings.json') -RunHookCmd $runHook
}

# --- Copy global Codex guidance into ~/.codex. -----------------------------
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

Write-Host "==> Linking WezTerm config"
New-DotLink -Target (Join-Path $RepoRoot '.config\wezterm\wezterm.lua') `
            -Link   (Join-Path $HomeDir '.wezterm.lua') `
            -CanSymlink $CanSymlink `
            -BackupExisting

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
} elseif ($SkipApm) {
    Write-Host "==> Skipping .claude/settings.json (macOS-tuned; -LinkSettings to link it)"
}

if ($SkipApm) {
    Write-Host "==> Skipping APM distribution (-SkipApm)"
} else {
    Write-Host "==> APM distribution (claude, cursor)"
    Invoke-ApmDistribution -RepoRoot $RepoRoot -HomeDir $HomeDir -ClaudeDir $ClaudeDir
}

Write-Host "==> Copying global Codex AGENTS.md"
Copy-CodexGlobalAgents -RepoRoot $RepoRoot -CodexDir $CodexDir

Write-Host ""
Write-Host "Done. Notes:"
Write-Host "  * Cursor rules are per-project (.cursorrules / .cursor/rules); there is no"
Write-Host "    global equivalent to link from here."
Write-Host "  * Keep the repo at a stable ghq path so the links survive (e.g."
Write-Host "    `$env:USERPROFILE\ghq\github.com\asonas\dotfiles)."
Write-Host "  * APM refreshed apm.lock.yaml in the repo; commit it to keep pins tracked."
