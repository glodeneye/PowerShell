<#
.SYNOPSIS
    Run Setup-CrossTenantCollaboration.ps1 using a JSON configuration file

.DESCRIPTION
    Loads settings from a JSON configuration file and executes the main setup script.
    Makes it easier to manage parameters and rerun with consistent settings.

.PARAMETER ConfigPath
    Path to the JSON configuration file (default: .\config.json)

.PARAMETER WhatIf
    Show what would be executed without actually running the script

.EXAMPLE
    .\Run-WithConfig.ps1

.EXAMPLE
    .\Run-WithConfig.ps1 -ConfigPath ".\production-config.json"

.EXAMPLE
    # Test first with WhatIf
    .\Run-WithConfig.ps1 -WhatIf
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$ConfigPath = ".\config.json",

    [Parameter(Mandatory=$false)]
    [switch]$WhatIf
)

Write-Host "M365 Cross-Tenant Setup - Configuration Runner" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host ""

# Check if config file exists
if (-not (Test-Path $ConfigPath)) {
    Write-Host "❌ Configuration file not found: $ConfigPath" -ForegroundColor Red
    Write-Host ""
    Write-Host "To create a configuration file:" -ForegroundColor Yellow
    Write-Host "  1. Copy config.example.json to config.json" -ForegroundColor White
    Write-Host "  2. Edit config.json with your settings" -ForegroundColor White
    Write-Host "  3. Run this script again" -ForegroundColor White
    Write-Host ""
    Write-Host "Quick setup:" -ForegroundColor Yellow
    Write-Host "  Copy-Item config.example.json config.json" -ForegroundColor White
    exit 1
}

# Load configuration
Write-Host "📄 Loading configuration from: $ConfigPath" -ForegroundColor Cyan
try {
    $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
    Write-Host "✓ Configuration loaded successfully" -ForegroundColor Green
}
catch {
    Write-Host "❌ Failed to parse configuration file: $_" -ForegroundColor Red
    exit 1
}

# Display configuration summary
Write-Host ""
Write-Host "Configuration Summary:" -ForegroundColor Cyan
Write-Host "  Host Tenant: $($config.Tenants.HostTenantDomain)" -ForegroundColor White
Write-Host "  Guest Tenant: $($config.Tenants.GuestTenantDomain)" -ForegroundColor White
Write-Host "  SharePoint Site: $($config.SharePoint.SiteTitle)" -ForegroundColor White
Write-Host "  Admin Email: $($config.Users.AdminEmail)" -ForegroundColor White
Write-Host "  Client Folders: $($config.Clients.ClientFolders.Count)" -ForegroundColor White
Write-Host "  Rollback Enabled: $($config.Features.EnableRollback)" -ForegroundColor White
Write-Host "  Generate Reports: HTML=$($config.Features.GenerateHtmlReport), Excel=$($config.Features.GenerateExcelReport)" -ForegroundColor White
Write-Host ""

# Build parameters
$scriptParams = @{
    HostTenantDomain = $config.Tenants.HostTenantDomain
    GuestTenantDomain = $config.Tenants.GuestTenantDomain
    SharePointSiteTitle = $config.SharePoint.SiteTitle
    SharePointSiteAlias = $config.SharePoint.SiteAlias
    AdminEmail = $config.Users.AdminEmail
}

# Add optional parameters
if ($config.Users.UsersCsvPath -and (Test-Path $config.Users.UsersCsvPath)) {
    $scriptParams.UsersCsvPath = $config.Users.UsersCsvPath
    Write-Host "📋 Using CSV file: $($config.Users.UsersCsvPath)" -ForegroundColor Cyan
}
elseif ($config.Users.GuestUserEmails -and $config.Users.GuestUserEmails.Count -gt 0) {
    $scriptParams.GuestUserEmails = $config.Users.GuestUserEmails
    Write-Host "👥 Using guest emails from config: $($config.Users.GuestUserEmails.Count) users" -ForegroundColor Cyan
}

if ($config.Clients.ClientFolders -and $config.Clients.ClientFolders.Count -gt 0) {
    $scriptParams.ClientFolders = $config.Clients.ClientFolders
}

if ($config.Logging.LogPath) {
    $scriptParams.LogPath = $config.Logging.LogPath
}

if ($config.Notifications.NotificationEmail) {
    $scriptParams.NotificationEmail = $config.Notifications.NotificationEmail
}

# Add feature flags
if ($config.Features.EnableRollback) {
    $scriptParams.EnableRollback = $true
}

if ($config.Features.GenerateHtmlReport) {
    $scriptParams.GenerateHtmlReport = $true
}

if ($config.Features.GenerateExcelReport) {
    $scriptParams.GenerateExcelReport = $true
}

if ($config.Features.SkipB2BConfig) {
    $scriptParams.SkipB2BConfig = $true
}

if ($config.Features.SkipSiteCreation) {
    $scriptParams.SkipSiteCreation = $true
}

# Add WhatIf if requested
if ($WhatIf) {
    $scriptParams.WhatIf = $true
    Write-Host "🧪 Running in WHATIF mode (dry-run)" -ForegroundColor Yellow
    Write-Host ""
}

# Confirm before proceeding (unless WhatIf)
if (-not $WhatIf) {
    Write-Host "⚠️  This will make REAL changes to your M365 environment!" -ForegroundColor Yellow
    $confirm = Read-Host "Continue? (Y/N)"
    if ($confirm -ne 'Y' -and $confirm -ne 'y') {
        Write-Host "❌ Cancelled by user" -ForegroundColor Red
        exit 0
    }
}

Write-Host ""
Write-Host "🚀 Starting setup script..." -ForegroundColor Green
Write-Host ""

# Execute the main script
& "$PSScriptRoot\Setup-CrossTenantCollaboration.ps1" @scriptParams
