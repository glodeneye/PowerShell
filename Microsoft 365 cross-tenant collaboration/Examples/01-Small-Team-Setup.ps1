<#
.SYNOPSIS
    Example 1: Small Team Setup (5-10 users, 2-3 clients)

.DESCRIPTION
    This example shows how to set up cross-tenant collaboration for a small team
    working with a few clients. Perfect for pilot projects or small consulting firms.

.SCENARIO
    - Host: ComplianceRisk.io (consulting firm)
    - Guest: Pelican3.net (client)
    - Users: 3 host users, 2 guest users
    - Clients: 2 client folders
    - Features: Rollback enabled, HTML reports
#>

# Step 1: Generate user CSV template
Write-Host "Step 1: Creating user CSV..." -ForegroundColor Cyan
.\New-UserTemplate.ps1 -OutputPath ".\Examples\small-team-users.csv"

# You would then edit small-team-users.csv with your actual users

# Step 2: Test with WhatIf first
Write-Host "`nStep 2: Testing with WhatIf (dry-run)..." -ForegroundColor Cyan
.\Setup-CrossTenantCollaboration.ps1 `
    -HostTenantDomain "compliancerisk.io" `
    -GuestTenantDomain "pelican3.net" `
    -SharePointSiteTitle "Small Team Collaboration" `
    -SharePointSiteAlias "SmallTeam" `
    -ClientFolders @("ACME Corp", "TechStart Inc") `
    -GuestUserEmails @("consultant1@pelican3.net", "consultant2@pelican3.net") `
    -AdminEmail "admin@compliancescorecard.com" `
    -WhatIf

# Step 3: If dry-run looks good, execute for real
Write-Host "`nStep 3: Ready to execute? (Review WhatIf output first!)" -ForegroundColor Yellow
$confirm = Read-Host "Run for real? (Y/N)"

if ($confirm -eq 'Y' -or $confirm -eq 'y') {
    .\Setup-CrossTenantCollaboration.ps1 `
        -HostTenantDomain "compliancerisk.io" `
        -GuestTenantDomain "pelican3.net" `
        -SharePointSiteTitle "Small Team Collaboration" `
        -SharePointSiteAlias "SmallTeam" `
        -ClientFolders @("ACME Corp", "TechStart Inc") `
        -GuestUserEmails @("consultant1@pelican3.net", "consultant2@pelican3.net") `
        -AdminEmail "admin@compliancescorecard.com" `
        -EnableRollback `
        -GenerateHtmlReport

    Write-Host "`nDone! Check the HTML report in the Logs folder." -ForegroundColor Green
} else {
    Write-Host "Cancelled. No changes made." -ForegroundColor Yellow
}
