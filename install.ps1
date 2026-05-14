#Requires -Version 5.1
<#
.SYNOPSIS
    Install quruhao-skills as a Claude Code plugin on Windows via Junction.
.PARAMETER RepoPath
    Path to the cloned repo. Defaults to the directory containing this script.
#>
param(
    [string]$RepoPath = $PSScriptRoot
)

$pluginName    = "quruhao-skills"
$pluginVersion = "1.0.0"
$targetDir     = Join-Path $env:USERPROFILE ".claude\plugins\cache\local\$pluginName\$pluginVersion"

# Resolve repo path to absolute
$RepoPath = (Resolve-Path $RepoPath).Path

# Ensure parent directory exists
$parentDir = Split-Path $targetDir -Parent
if (-not (Test-Path $parentDir)) {
    New-Item -ItemType Directory -Force -Path $parentDir | Out-Null
}

# Remove existing link/directory
if (Test-Path $targetDir) {
    Remove-Item $targetDir -Force -Recurse
}

# Create junction
New-Item -ItemType Junction -Path $targetDir -Target $RepoPath | Out-Null

Write-Host ""
Write-Host "quruhao-skills installed successfully."
Write-Host "  Junction : $targetDir"
Write-Host "  -> Target: $RepoPath"
Write-Host ""
Write-Host "Restart Claude Code to activate the plugin."
