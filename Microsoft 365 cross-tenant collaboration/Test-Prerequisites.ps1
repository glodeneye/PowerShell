<#
.SYNOPSIS
    Validates prerequisites before running M365 Cross-Tenant setup

.DESCRIPTION
    Checks all requirements including PowerShell version, modules, permissions,
    and configuration files. Run this before executing the main setup script.

.PARAMETER SkipConnectionTest
    Skip testing actual connections to M365 services

.EXAMPLE
    .\Test-Prerequisites.ps1

.EXAMPLE
    .\Test-Prerequisites.ps1 -SkipConnectionTest
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$SkipConnectionTest
)

$ErrorActionPreference = 'Continue'
$script:TotalChecks = 0
$script:PassedChecks = 0
$script:FailedChecks = 0
$script:WarningChecks = 0

function Write-CheckResult {
    param(
        [string]$CheckName,
        [string]$Status,  # Pass, Fail, Warning
        [string]$Message,
        [string]$Recommendation = ""
    )

    $script:TotalChecks++

    switch ($Status) {
        'Pass' {
            Write-Host "  ✓ " -ForegroundColor Green -NoNewline
            Write-Host $CheckName -ForegroundColor White -NoNewline
            Write-Host " - " -NoNewline
            Write-Host $Message -ForegroundColor Gray
            $script:PassedChecks++
        }
        'Fail' {
            Write-Host "  ✗ " -ForegroundColor Red -NoNewline
            Write-Host $CheckName -ForegroundColor White -NoNewline
            Write-Host " - " -NoNewline
            Write-Host $Message -ForegroundColor Red
            if ($Recommendation) {
                Write-Host "    → " -ForegroundColor Yellow -NoNewline
                Write-Host $Recommendation -ForegroundColor Yellow
            }
            $script:FailedChecks++
        }
        'Warning' {
            Write-Host "  ⚠ " -ForegroundColor Yellow -NoNewline
            Write-Host $CheckName -ForegroundColor White -NoNewline
            Write-Host " - " -NoNewline
            Write-Host $Message -ForegroundColor Yellow
            if ($Recommendation) {
                Write-Host "    → " -ForegroundColor Cyan -NoNewline
                Write-Host $Recommendation -ForegroundColor Cyan
            }
            $script:WarningChecks++
        }
    }
}

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  M365 Cross-Tenant Setup - Prerequisites Validation       ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# 1. PowerShell Version
Write-Host "🔍 PowerShell Environment" -ForegroundColor Cyan
Write-Host ""

$psVersion = $PSVersionTable.PSVersion
if ($psVersion.Major -ge 7) {
    Write-CheckResult "PowerShell Version" "Pass" "Version $($psVersion.Major).$($psVersion.Minor) (Required: 7.0+)"
} else {
    Write-CheckResult "PowerShell Version" "Fail" "Version $($psVersion.Major).$($psVersion.Minor) (Required: 7.0+)" `
        "Download from: https://aka.ms/powershell"
}

# Check execution policy
$execPolicy = Get-ExecutionPolicy
if ($execPolicy -eq 'Restricted') {
    Write-CheckResult "Execution Policy" "Fail" "Current: $execPolicy" `
        "Run: Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser"
} elseif ($execPolicy -eq 'AllSigned' -or $execPolicy -eq 'RemoteSigned' -or $execPolicy -eq 'Unrestricted') {
    Write-CheckResult "Execution Policy" "Pass" "Current: $execPolicy"
} else {
    Write-CheckResult "Execution Policy" "Warning" "Current: $execPolicy"
}

Write-Host ""

# 2. Required Modules
Write-Host "📦 PowerShell Modules" -ForegroundColor Cyan
Write-Host ""

$requiredModules = @(
    @{ Name = "Microsoft.Graph"; MinVersion = "2.0.0"; Required = $true }
    @{ Name = "PnP.PowerShell"; MinVersion = "2.0.0"; Required = $true }
    @{ Name = "ImportExcel"; MinVersion = "7.8.0"; Required = $false }
)

foreach ($moduleInfo in $requiredModules) {
    $module = Get-Module -ListAvailable -Name $moduleInfo.Name | Sort-Object Version -Descending | Select-Object -First 1

    if ($module) {
        if ($module.Version -ge [version]$moduleInfo.MinVersion) {
            Write-CheckResult $moduleInfo.Name "Pass" "Installed v$($module.Version)"
        } else {
            Write-CheckResult $moduleInfo.Name "Warning" "Installed v$($module.Version), recommended v$($moduleInfo.MinVersion)+" `
                "Update: Update-Module -Name $($moduleInfo.Name)"
        }
    } else {
        if ($moduleInfo.Required) {
            Write-CheckResult $moduleInfo.Name "Fail" "Not installed" `
                "Install: Install-Module -Name $($moduleInfo.Name) -Scope CurrentUser"
        } else {
            Write-CheckResult $moduleInfo.Name "Warning" "Not installed (optional for Excel reports)" `
                "Install: Install-Module -Name $($moduleInfo.Name) -Scope CurrentUser"
        }
    }
}

Write-Host ""

# 3. File Structure
Write-Host "📁 File Structure" -ForegroundColor Cyan
Write-Host ""

$requiredFiles = @(
    @{ Path = "Setup-CrossTenantCollaboration.ps1"; Required = $true }
    @{ Path = "Invoke-ManualRollback.ps1"; Required = $true }
    @{ Path = "New-UserTemplate.ps1"; Required = $true }
    @{ Path = "README.md"; Required = $false }
    @{ Path = "GETTING-STARTED.md"; Required = $false }
)

foreach ($fileInfo in $requiredFiles) {
    $filePath = Join-Path $PSScriptRoot $fileInfo.Path
    if (Test-Path $filePath) {
        $size = (Get-Item $filePath).Length
        $sizeKB = [math]::Round($size / 1KB, 1)
        Write-CheckResult $fileInfo.Path "Pass" "Found ($sizeKB KB)"
    } else {
        if ($fileInfo.Required) {
            Write-CheckResult $fileInfo.Path "Fail" "Not found" `
                "Download from repository"
        } else {
            Write-CheckResult $fileInfo.Path "Warning" "Not found (optional)"
        }
    }
}

# Check for config files
$configPath = Join-Path $PSScriptRoot "config.json"
if (Test-Path $configPath) {
    Write-CheckResult "config.json" "Pass" "Configuration file found"
} else {
    Write-CheckResult "config.json" "Warning" "Not found (optional)" `
        "Copy config.example.json to config.json and customize"
}

# Check for CSV file
$csvPath = Join-Path $PSScriptRoot "users.csv"
if (Test-Path $csvPath) {
    try {
        $users = Import-Csv $csvPath
        Write-CheckResult "users.csv" "Pass" "Found with $($users.Count) users"
    } catch {
        Write-CheckResult "users.csv" "Warning" "Found but may have issues: $_"
    }
} else {
    Write-CheckResult "users.csv" "Warning" "Not found" `
        "Run: .\New-UserTemplate.ps1 to create template"
}

Write-Host ""

# 4. Directory Permissions
Write-Host "🔐 Permissions" -ForegroundColor Cyan
Write-Host ""

# Check if Logs directory can be created
$logsPath = Join-Path $PSScriptRoot "Logs"
try {
    if (-not (Test-Path $logsPath)) {
        New-Item -Path $logsPath -ItemType Directory -Force | Out-Null
        Remove-Item -Path $logsPath -Force
        Write-CheckResult "Write Access" "Pass" "Can create Logs directory"
    } else {
        # Test write access
        $testFile = Join-Path $logsPath "test_$(Get-Random).tmp"
        "test" | Out-File $testFile -Force
        Remove-Item $testFile -Force
        Write-CheckResult "Write Access" "Pass" "Can write to Logs directory"
    }
} catch {
    Write-CheckResult "Write Access" "Fail" "Cannot write to Logs directory: $_" `
        "Check folder permissions"
}

Write-Host ""

# 5. Network Connectivity (if not skipped)
if (-not $SkipConnectionTest) {
    Write-Host "🌐 Network Connectivity" -ForegroundColor Cyan
    Write-Host ""

    $endpoints = @(
        @{ Name = "Microsoft Graph"; Url = "https://graph.microsoft.com" }
        @{ Name = "Azure AD"; Url = "https://login.microsoftonline.com" }
        @{ Name = "SharePoint Online"; Url = "https://www.sharepoint.com" }
    )

    foreach ($endpoint in $endpoints) {
        try {
            $response = Invoke-WebRequest -Uri $endpoint.Url -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
            Write-CheckResult $endpoint.Name "Pass" "Reachable (Status: $($response.StatusCode))"
        } catch {
            Write-CheckResult $endpoint.Name "Fail" "Not reachable: $_" `
                "Check firewall/proxy settings"
        }
    }

    Write-Host ""
}

# 6. Module Connection Test (if not skipped)
if (-not $SkipConnectionTest) {
    Write-Host "🔗 M365 Service Connection Test" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Testing connections (this may prompt for authentication)..." -ForegroundColor Gray
    Write-Host ""

    # Test Microsoft Graph
    try {
        Connect-MgGraph -Scopes "User.Read.All" -NoWelcome -ErrorAction Stop
        $context = Get-MgContext
        if ($context) {
            Write-CheckResult "Microsoft Graph" "Pass" "Connected as $($context.Account)"
            Disconnect-MgGraph | Out-Null
        } else {
            Write-CheckResult "Microsoft Graph" "Warning" "Connected but couldn't get context"
        }
    } catch {
        Write-CheckResult "Microsoft Graph" "Warning" "Could not test connection (may require credentials)" `
            "Will be tested during actual execution"
    }

    Write-Host ""
}

# Summary
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  Validation Summary                                        ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$passRate = if ($script:TotalChecks -gt 0) { [math]::Round(($script:PassedChecks / $script:TotalChecks) * 100) } else { 0 }

Write-Host "  Total Checks:    " -NoNewline
Write-Host $script:TotalChecks -ForegroundColor White
Write-Host "  Passed:          " -NoNewline
Write-Host $script:PassedChecks -ForegroundColor Green
Write-Host "  Warnings:        " -NoNewline
Write-Host $script:WarningChecks -ForegroundColor Yellow
Write-Host "  Failed:          " -NoNewline
Write-Host $script:FailedChecks -ForegroundColor Red
Write-Host "  Success Rate:    " -NoNewline
Write-Host "$passRate%" -ForegroundColor $(if ($passRate -ge 80) { 'Green' } elseif ($passRate -ge 60) { 'Yellow' } else { 'Red' })

Write-Host ""

# Recommendations
if ($script:FailedChecks -gt 0) {
    Write-Host "❌ FAILED: You have $script:FailedChecks critical issue(s) that must be resolved." -ForegroundColor Red
    Write-Host "   Please address the failed checks above before running the setup script." -ForegroundColor Red
    Write-Host ""
    exit 1
} elseif ($script:WarningChecks -gt 0) {
    Write-Host "⚠️  WARNINGS: You have $script:WarningChecks warning(s)." -ForegroundColor Yellow
    Write-Host "   The script may work, but consider addressing these warnings." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "✅ Ready to proceed with caution!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "✅ PASSED: All checks passed! You're ready to run the setup script." -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Customize your users.csv or config.json" -ForegroundColor White
    Write-Host "  2. Run with -WhatIf first: .\Setup-CrossTenantCollaboration.ps1 ... -WhatIf" -ForegroundColor White
    Write-Host "  3. Execute for real with rollback enabled" -ForegroundColor White
    Write-Host ""
    exit 0
}
