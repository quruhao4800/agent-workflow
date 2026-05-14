#Requires -Version 5.1
<#
.SYNOPSIS
    Install agent-workflow as a Claude Code plugin on Windows via Junction.
.PARAMETER RepoPath
    Path to the cloned repo. Defaults to the directory containing this script.
#>
param(
    [string]$RepoPath = $PSScriptRoot
)

$pluginName    = "agent-workflow"
$pluginVersion = "1.0.0"
$targetDir     = Join-Path $env:USERPROFILE ".claude\plugins\cache\local\$pluginName\$pluginVersion"

# Resolve repo path to absolute
$RepoPath = (Resolve-Path $RepoPath).Path

# Ensure parent directory exists
$parentDir = Split-Path $targetDir -Parent
if (-not (Test-Path $parentDir)) {
    New-Item -ItemType Directory -Force -Path $parentDir | Out-Null
}

# Remove existing junction (abort if it's a real directory to avoid data loss)
if (Test-Path $targetDir) {
    $existing = Get-Item $targetDir -Force
    if ($existing.LinkType -eq 'Junction') {
        Remove-Item $targetDir -Force
    } else {
        Write-Error "Path '$targetDir' exists and is not a Junction. Remove it manually before re-running."
        exit 1
    }
}

# Create junction
New-Item -ItemType Junction -Path $targetDir -Target $RepoPath | Out-Null

Write-Host ""
Write-Host "agent-workflow installed successfully."
Write-Host "  Junction : $targetDir"
Write-Host "  -> Target: $RepoPath"
Write-Host ""
Write-Host "Restart Claude Code to activate the plugin."
