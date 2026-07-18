[CmdletBinding()]
param(
    [switch]$LaunchCodex,
    [string]$BranchName = "codex/phase-149-total-aaa-review",
    [string]$CodexExecutable = "codex"
)

$ErrorActionPreference = "Stop"

function Get-RepositoryRoot {
    $root = Resolve-Path -LiteralPath $PSScriptRoot
    $gitRoot = git -C $root rev-parse --show-toplevel 2>$null
    if (-not $gitRoot) {
        throw "This script must be run from inside the LondonBelow Git repository."
    }

    return (Resolve-Path -LiteralPath $gitRoot).Path
}

function Get-RobloxStudioInstallations {
    $candidates = @()

    $localAppData = [Environment]::GetFolderPath("LocalApplicationData")
    $programFiles = [Environment]::GetFolderPath("ProgramFiles")
    $programFilesX86 = [Environment]::GetFolderPath("ProgramFilesX86")

    $searchRoots = @(
        (Join-Path $localAppData "Roblox\Versions"),
        (Join-Path $programFiles "Roblox\Versions"),
        (Join-Path $programFilesX86 "Roblox\Versions")
    ) | Where-Object { $_ -and [System.IO.Directory]::Exists($_) }

    foreach ($root in $searchRoots) {
        $candidates += Get-ChildItem -LiteralPath $root -Recurse -Filter RobloxStudioBeta.exe -ErrorAction SilentlyContinue
    }

    return $candidates | Sort-Object LastWriteTimeUtc -Descending
}

function Assert-CleanWorkingTree {
    param([string]$RepositoryRoot)

    $status = git -C $RepositoryRoot status --porcelain
    if ($status) {
        throw "Working tree is not clean. Refusing to launch the total AAA mission."
    }
}

$repoRoot = Get-RepositoryRoot
$missionPath = Join-Path $repoRoot "docs\audits\phase-149-total-review\TOTAL_AAA_MISSION_TASK.md"

if (-not [System.IO.File]::Exists($missionPath)) {
    throw "Mission prompt not found: $missionPath"
}

Write-Host "LondonBelow repository: $repoRoot"
Write-Host "Mission prompt: $missionPath"

$branch = git -C $repoRoot branch --show-current
$head = git -C $repoRoot rev-parse HEAD
$remoteHead = git -C $repoRoot ls-remote origin refs/heads/main
$dirty = git -C $repoRoot status --porcelain

Write-Host "Current branch: $branch"
Write-Host "Local HEAD: $head"
if ($remoteHead) {
    Write-Host "origin/main: $remoteHead"
} else {
    Write-Host "origin/main: unavailable"
}
Write-Host "Working tree clean: $([string]::IsNullOrWhiteSpace($dirty))"

$studioInstallations = @(Get-RobloxStudioInstallations)
if ($studioInstallations.Count -gt 0) {
    $newestStudio = $studioInstallations[0]
    $env:LONDON_AAA_AUDIT_STUDIO_PATH = $newestStudio.FullName
    Write-Host "Newest Roblox Studio: $($newestStudio.FullName)"
    Write-Host "Roblox Studio timestamp UTC: $($newestStudio.LastWriteTimeUtc.ToString('o'))"
} else {
    Write-Host "Roblox Studio: not detected"
}

if (-not $LaunchCodex) {
    Write-Host ""
    Write-Host "Dry run complete. Use -LaunchCodex to start the long-running mission."
    exit 0
}

Assert-CleanWorkingTree -RepositoryRoot $repoRoot

$codexCommand = Get-Command $CodexExecutable -ErrorAction SilentlyContinue
if (-not $codexCommand) {
    throw "Codex executable not found: $CodexExecutable"
}

$currentBranch = git -C $repoRoot branch --show-current
if ($currentBranch -ne $BranchName) {
    $existingBranch = git -C $repoRoot branch --list $BranchName
    if ($existingBranch) {
        git -C $repoRoot switch $BranchName
    } else {
        git -C $repoRoot switch -c $BranchName
    }
}

$runRoot = Join-Path $repoRoot "automation\local-state\runs\phase-149-total-aaa-review"
[System.IO.Directory]::CreateDirectory($runRoot) | Out-Null

$logPath = Join-Path $runRoot "codex-total-aaa-mission.log"
$prompt = [System.IO.File]::ReadAllText($missionPath)

Write-Host "Launching Codex mission on branch: $BranchName"
Write-Host "Codex log: $logPath"

$prompt | & $CodexExecutable exec --full-auto - 2>&1 | Tee-Object -FilePath $logPath
$exitCode = $LASTEXITCODE

Write-Host "Codex exit code: $exitCode"
exit $exitCode
