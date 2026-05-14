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

$pluginName = "agent-workflow"
$targetDir  = Join-Path $env:USERPROFILE ".claude\plugins\marketplaces\local\plugins\$pluginName"

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

# Upsert marketplace.json so Claude Code can discover the plugin
$marketplaceDir  = Join-Path $parentDir "..\..\.claude-plugin" | Resolve-Path -ErrorAction SilentlyContinue
if (-not $marketplaceDir) {
    $marketplaceDir = Join-Path (Split-Path $parentDir -Parent) ".claude-plugin"
    New-Item -ItemType Directory -Force -Path $marketplaceDir | Out-Null
}
$marketplaceFile = Join-Path $marketplaceDir "marketplace.json"
$pluginEntry = @{
    name        = $pluginName
    description = "agent-workflow — AI development workflow with process discipline and language expertise"
    version     = "1.0.0"
    author      = @{ name = "quruhao"; email = "" }
    source      = "./plugins/$pluginName"
    category    = "development"
    strict      = $false
}
if (Test-Path $marketplaceFile) {
    $marketplace = Get-Content $marketplaceFile -Raw | ConvertFrom-Json
    $marketplace.plugins = @($marketplace.plugins | Where-Object { $_.name -ne $pluginName }) + $pluginEntry
} else {
    $marketplace = [ordered]@{
        '$schema'   = "https://anthropic.com/claude-code/marketplace.schema.json"
        name        = "local"
        description = "Local plugins linked from filesystem"
        owner       = @{ name = "local"; email = "" }
        plugins     = @($pluginEntry)
    }
}
$marketplace | ConvertTo-Json -Depth 10 | Set-Content $marketplaceFile -Encoding UTF8

# Enable plugin in user settings.json
$settingsFile = Join-Path $env:USERPROFILE ".claude\settings.json"
if (Test-Path $settingsFile) {
    $settings = Get-Content $settingsFile -Raw | ConvertFrom-Json
} else {
    $settings = [PSCustomObject]@{}
}
if (-not $settings.enabledPlugins) {
    $settings | Add-Member -NotePropertyName enabledPlugins -NotePropertyValue ([PSCustomObject]@{})
}
$settings.enabledPlugins | Add-Member -NotePropertyName "$pluginName@local" -NotePropertyValue $true -Force
$settings | ConvertTo-Json -Depth 10 | Set-Content $settingsFile -Encoding UTF8

# Register in installed_plugins.json
$installedFile = Join-Path $env:USERPROFILE ".claude\plugins\installed_plugins.json"
if (Test-Path $installedFile) {
    $installed = Get-Content $installedFile -Raw | ConvertFrom-Json
} else {
    $installed = [PSCustomObject]@{ version = 2; plugins = [PSCustomObject]@{} }
}
$entry = @(
    [PSCustomObject]@{
        scope       = "user"
        installPath = $targetDir
        version     = "1.0.0"
        installedAt = (Get-Date -Format "o")
        lastUpdated = (Get-Date -Format "o")
    }
)
$installed.plugins | Add-Member -NotePropertyName "$pluginName@local" -NotePropertyValue $entry -Force
$installed | ConvertTo-Json -Depth 10 | Set-Content $installedFile -Encoding UTF8

Write-Host ""
Write-Host "agent-workflow installed successfully."
Write-Host "  Junction : $targetDir"
Write-Host "  -> Target: $RepoPath"
Write-Host ""
Write-Host "Restart Claude Code to activate the plugin."
