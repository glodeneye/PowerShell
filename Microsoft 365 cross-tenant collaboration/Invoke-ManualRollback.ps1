<#
.SYNOPSIS
    Manual rollback script for M365 Cross-Tenant Setup

.DESCRIPTION
    This script can be used to manually rollback resources created by the setup script
    using the audit log and resource tracking information.

.PARAMETER AuditLogPath
    Path to the audit log JSON file

.PARAMETER ExecutionId
    Specific execution ID to rollback (optional)

.PARAMETER WhatIf
    Show what would be rolled back without actually doing it

.EXAMPLE
    .\Invoke-ManualRollback.ps1 -AuditLogPath ".\Logs\Audit_20241022.json"

.EXAMPLE
    .\Invoke-ManualRollback.ps1 -AuditLogPath ".\Logs\Audit_20241022.json" -ExecutionId "abc-123-def" -WhatIf
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$AuditLogPath,

    [Parameter(Mandatory=$false)]
    [string]$ExecutionId,

    [Parameter(Mandatory=$false)]
    [switch]$WhatIf
)

Write-Host @"
+--------------------------------------------------------------+
|           Manual Rollback Script for M365 Setup              |
+--------------------------------------------------------------+
"@ -ForegroundColor Magenta

if (-not (Test-Path $AuditLogPath)) {
    Write-Host "✗ Audit log not found: $AuditLogPath" -ForegroundColor Red
    exit 1
}

Write-Host "`nReading audit log..." -ForegroundColor Cyan
$auditEntries = Get-Content $AuditLogPath | ForEach-Object { $_ | ConvertFrom-Json }

if ($ExecutionId) {
    $auditEntries = $auditEntries | Where-Object { $_.ExecutionId -eq $ExecutionId }
    Write-Host "Filtered to Execution ID: $ExecutionId" -ForegroundColor Yellow
}

$executions = $auditEntries | Select-Object -Property ExecutionId, @{N='StartTime';E={$_.Timestamp}} -Unique

Write-Host "`nFound $($executions.Count) execution(s) in audit log:" -ForegroundColor Cyan
foreach ($exec in $executions) {
    Write-Host "  - $($exec.ExecutionId) (Started: $($exec.StartTime))" -ForegroundColor White
}

if (-not $ExecutionId -and $executions.Count -gt 1) {
    Write-Host "`nMultiple executions found. Please specify -ExecutionId parameter." -ForegroundColor Yellow
    exit 0
}

$targetExecution = if ($ExecutionId) { $ExecutionId } else { $executions[0].ExecutionId }

Write-Host "`nPreparing rollback for Execution ID: $targetExecution" -ForegroundColor Cyan

# Group operations by type
$operations = $auditEntries | Where-Object { $_.ExecutionId -eq $targetExecution }

$sites = $operations | Where-Object { $_.Operation -eq 'SiteCreation' }
$users = $operations | Where-Object { $_.Operation -eq 'GuestInvitation' -or $_.Operation -eq 'HostUserAdded' }
$b2bConfigs = $operations | Where-Object { $_.Operation -eq 'B2BConfiguration' }

Write-Host "`nResources to rollback:" -ForegroundColor Yellow
Write-Host "  Sites: $($sites.Count)" -ForegroundColor White
Write-Host "  Users: $($users.Count)" -ForegroundColor White
Write-Host "  B2B Configurations: $($b2bConfigs.Count)" -ForegroundColor White

if ($WhatIf) {
    Write-Host "`n[WHATIF] Would perform the following rollback actions:" -ForegroundColor Cyan

    foreach ($site in $sites) {
        Write-Host "  [WHATIF] Delete site: $($site.SiteUrl)" -ForegroundColor Gray
    }

    foreach ($user in $users) {
        Write-Host "  [WHATIF] Remove user: $($user.UserEmail)" -ForegroundColor Gray
    }

    foreach ($config in $b2bConfigs) {
        Write-Host "  [WHATIF] Remove B2B config for tenant: $($config.GuestTenantId)" -ForegroundColor Gray
    }

    Write-Host "`n[WHATIF] No actual changes were made" -ForegroundColor Yellow
    exit 0
}

$confirm = Read-Host "`nAre you sure you want to rollback these resources? (Type 'YES' to confirm)"
if ($confirm -ne 'YES') {
    Write-Host "Rollback cancelled" -ForegroundColor Yellow
    exit 0
}

Write-Host "`n+--------------------------------------------------------------+" -ForegroundColor Magenta
Write-Host "|              STARTING ROLLBACK PROCEDURE                     |" -ForegroundColor Magenta
Write-Host "+--------------------------------------------------------------+" -ForegroundColor Magenta

# Connect to services
Write-Host "`nConnecting to Microsoft 365..." -ForegroundColor Cyan
try {
    Connect-MgGraph -Scopes "User.ReadWrite.All", "Directory.ReadWrite.All", "Policy.ReadWrite.CrossTenantAccess" -NoWelcome
    Write-Host "✓ Connected to Microsoft Graph" -ForegroundColor Green
}
catch {
    Write-Host "✗ Failed to connect: $_" -ForegroundColor Red
    exit 1
}

$successCount = 0
$failCount = 0

# Remove users
Write-Host "`nRemoving users..." -ForegroundColor Cyan
foreach ($user in $users) {
    try {
        $siteUrl = $user.SiteUrl
        $email = $user.UserEmail

        Connect-PnPOnline -Url $siteUrl -Interactive
        Remove-PnPUser -Identity $email -Force

        Write-Host "  ✓ Removed user: $email" -ForegroundColor Green
        $successCount++
    }
    catch {
        Write-Host "  ✗ Failed to remove user $($user.UserEmail): $_" -ForegroundColor Red
        $failCount++
    }
}

# Delete sites
Write-Host "`nDeleting sites..." -ForegroundColor Cyan
foreach ($site in $sites) {
    try {
        $siteUrl = $site.SiteUrl
        $tenantUrl = ($siteUrl -split '/sites/')[0] + "-admin"

        Connect-PnPOnline -Url $tenantUrl -Interactive
        Remove-PnPTenantSite -Url $siteUrl -Force -SkipRecycleBin

        Write-Host "  ✓ Deleted site: $siteUrl" -ForegroundColor Green
        $successCount++
    }
    catch {
        Write-Host "  ✗ Failed to delete site $($site.SiteUrl): $_" -ForegroundColor Red
        $failCount++
    }
}

# Remove B2B configurations
Write-Host "`nRemoving B2B configurations..." -ForegroundColor Cyan
foreach ($config in $b2bConfigs) {
    try {
        $tenantId = $config.GuestTenantId

        Invoke-MgGraphRequest -Method DELETE -Uri "https://graph.microsoft.com/v1.0/policies/crossTenantAccessPolicy/partners/$tenantId"

        Write-Host "  ✓ Removed B2B config for tenant: $tenantId" -ForegroundColor Green
        $successCount++
    }
    catch {
        Write-Host "  ✗ Failed to remove B2B config: $_" -ForegroundColor Red
        $failCount++
    }
}

Write-Host "`n+--------------------------------------------------------------+" -ForegroundColor Magenta
Write-Host "|              ROLLBACK PROCEDURE COMPLETED                    |" -ForegroundColor Magenta
Write-Host "+--------------------------------------------------------------+" -ForegroundColor Magenta

Write-Host "`nRollback Summary:" -ForegroundColor Cyan
Write-Host "  Successful: $successCount" -ForegroundColor Green
Write-Host "  Failed: $failCount" -ForegroundColor Red
