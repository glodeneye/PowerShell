<#
.SYNOPSIS
    Example 2: Enterprise Bulk Import (50+ users, 10+ clients)

.DESCRIPTION
    This example demonstrates how to set up cross-tenant collaboration for
    a large enterprise with many users and clients using CSV bulk import.

.SCENARIO
    - Host: ComplianceRisk.io (large consulting firm)
    - Guest: Pelican3.net (enterprise client)
    - Users: 50+ users (managed via CSV)
    - Clients: 15 client folders
    - Features: Full reporting, email notifications, rollback enabled
#>

Write-Host "Enterprise Bulk Import Example" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host ""

# Step 1: Create comprehensive CSV file
Write-Host "Step 1: Creating CSV template for bulk users..." -ForegroundColor Cyan
.\New-UserTemplate.ps1 -OutputPath ".\Examples\enterprise-users.csv"

Write-Host ""
Write-Host "📝 IMPORTANT: Edit .\Examples\enterprise-users.csv with your users!" -ForegroundColor Yellow
Write-Host "   Include all 50+ users with their roles and client access" -ForegroundColor Yellow
Write-Host ""
Write-Host "Press any key to continue after editing the CSV..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# Step 2: Validate prerequisites
Write-Host "`nStep 2: Validating prerequisites..." -ForegroundColor Cyan
.\Test-Prerequisites.ps1

if ($LASTEXITCODE -ne 0) {
    Write-Host "`n❌ Prerequisites check failed. Please resolve issues above." -ForegroundColor Red
    exit 1
}

# Step 3: Create config file for easy reuse
Write-Host "`nStep 3: Creating configuration file..." -ForegroundColor Cyan

$config = @{
    Configuration = @{
        Description = "Enterprise Setup - 50+ Users"
        Version = "2.0"
        LastUpdated = (Get-Date -Format "yyyy-MM-dd")
    }
    Tenants = @{
        HostTenantDomain = "compliancerisk.io"
        GuestTenantDomain = "pelican3.net"
    }
    SharePoint = @{
        SiteTitle = "Enterprise Client Collaboration"
        SiteAlias = "EnterpriseCollab"
    }
    Users = @{
        AdminEmail = "admin@compliancescorecard.com"
        UsersCsvPath = ".\Examples\enterprise-users.csv"
    }
    Clients = @{
        ClientFolders = @(
            "Global Manufacturing Corp",
            "Tech Innovations LLC",
            "Financial Services Group",
            "Healthcare Partners",
            "Retail Solutions Inc",
            "Energy Systems Ltd",
            "Transportation Network",
            "Media Group International",
            "Education Foundation",
            "Real Estate Holdings",
            "Hospitality Services",
            "Construction Partners",
            "Insurance Alliance",
            "Telecom Solutions",
            "Agriculture Cooperative"
        )
    }
    Logging = @{
        LogPath = ".\Logs"
    }
    Notifications = @{
        NotificationEmail = "it-team@compliancescorecard.com"
    }
    Features = @{
        EnableRollback = $true
        GenerateHtmlReport = $true
        GenerateExcelReport = $true
        SkipB2BConfig = $false
        SkipSiteCreation = $false
    }
}

$config | ConvertTo-Json -Depth 10 | Out-File ".\Examples\enterprise-config.json" -Encoding UTF8
Write-Host "✓ Configuration saved to: .\Examples\enterprise-config.json" -ForegroundColor Green

# Step 4: Dry-run with WhatIf
Write-Host "`nStep 4: Running dry-run test..." -ForegroundColor Cyan
Write-Host "This will show what will happen without making changes" -ForegroundColor Gray
Write-Host ""

$configData = Get-Content ".\Examples\enterprise-config.json" | ConvertFrom-Json

.\Setup-CrossTenantCollaboration.ps1 `
    -HostTenantDomain $configData.Tenants.HostTenantDomain `
    -GuestTenantDomain $configData.Tenants.GuestTenantDomain `
    -SharePointSiteTitle $configData.SharePoint.SiteTitle `
    -SharePointSiteAlias $configData.SharePoint.SiteAlias `
    -UsersCsvPath $configData.Users.UsersCsvPath `
    -ClientFolders $configData.Clients.ClientFolders `
    -AdminEmail $configData.Users.AdminEmail `
    -WhatIf

# Step 5: Confirm and execute
Write-Host "`n" + ("=" * 60) -ForegroundColor Yellow
Write-Host "Review the WhatIf output above carefully!" -ForegroundColor Yellow
Write-Host ("=" * 60) -ForegroundColor Yellow
Write-Host ""
Write-Host "This will:" -ForegroundColor Cyan
Write-Host "  • Configure B2B access between two tenants" -ForegroundColor White
Write-Host "  • Create a SharePoint team site" -ForegroundColor White
Write-Host "  • Create 15 client folder structures" -ForegroundColor White
Write-Host "  • Process 50+ users from CSV" -ForegroundColor White
Write-Host "  • Send email notifications" -ForegroundColor White
Write-Host "  • Generate HTML and Excel reports" -ForegroundColor White
Write-Host ""
Write-Host "Estimated time: 15-20 minutes" -ForegroundColor Gray
Write-Host ""

$confirm = Read-Host "Execute for real? Type YES to confirm"

if ($confirm -eq 'YES') {
    Write-Host "`nStarting enterprise setup..." -ForegroundColor Green
    Write-Host "Grab a coffee - this will take 15-20 minutes ☕" -ForegroundColor Cyan
    Write-Host ""

    $startTime = Get-Date

    .\Setup-CrossTenantCollaboration.ps1 `
        -HostTenantDomain $configData.Tenants.HostTenantDomain `
        -GuestTenantDomain $configData.Tenants.GuestTenantDomain `
        -SharePointSiteTitle $configData.SharePoint.SiteTitle `
        -SharePointSiteAlias $configData.SharePoint.SiteAlias `
        -UsersCsvPath $configData.Users.UsersCsvPath `
        -ClientFolders $configData.Clients.ClientFolders `
        -AdminEmail $configData.Users.AdminEmail `
        -NotificationEmail $configData.Notifications.NotificationEmail `
        -EnableRollback `
        -GenerateHtmlReport `
        -GenerateExcelReport

    $endTime = Get-Date
    $duration = $endTime - $startTime

    Write-Host ""
    Write-Host "✅ Enterprise setup completed!" -ForegroundColor Green
    Write-Host "⏱️  Duration: $($duration.ToString('mm\:ss'))" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "  1. Check your email for the report" -ForegroundColor White
    Write-Host "  2. Open the HTML report in .\Logs\" -ForegroundColor White
    Write-Host "  3. Verify the SharePoint site" -ForegroundColor White
    Write-Host "  4. Test guest user access" -ForegroundColor White
} else {
    Write-Host "`n❌ Cancelled. No changes made." -ForegroundColor Red
}
