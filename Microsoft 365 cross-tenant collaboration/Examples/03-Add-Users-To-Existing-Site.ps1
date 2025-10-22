<#
.SYNOPSIS
    Example 3: Add Users to Existing Site

.DESCRIPTION
    This example shows how to add new users to an already-configured site.
    Useful when you need to onboard additional team members or guest users
    without recreating the entire setup.

.SCENARIO
    - Site already exists
    - B2B already configured
    - Just adding 5 new users
    - No new client folders needed
#>

Write-Host "Add Users to Existing Site - Example" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host ""

# Step 1: Create CSV with only new users
Write-Host "Step 1: Create CSV with new users only..." -ForegroundColor Cyan

$newUsers = @"
Email,Tenant,Role,DisplayName,Department,ClientAccess
newuser1@your-company.com,Host,Member,New User 1,Compliance,"Client A;Client B"
newuser2@your-company.com,Host,Member,New User 2,Operations,Client A
contractor1@partner-company.com,Guest,Member,External Contractor,Consulting,Client B
contractor2@partner-company.com,Guest,Visitor,External Viewer,Analysis,Client A
manager@partner-company.com,Guest,Owner,External Manager,Management,"Client A;Client B"
"@

$newUsers | Out-File ".\Examples\new-users-only.csv" -Encoding UTF8
Write-Host "✓ Created .\Examples\new-users-only.csv with 5 new users" -ForegroundColor Green

# Step 2: Review the CSV
Write-Host "`nStep 2: Review new users CSV..." -ForegroundColor Cyan
Import-Csv ".\Examples\new-users-only.csv" | Format-Table -AutoSize

# Step 3: Run with site creation skipped
Write-Host "`nStep 3: Add users to existing site..." -ForegroundColor Cyan
Write-Host ""
Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  • Existing Site: Client Projects" -ForegroundColor White
Write-Host "  • Skip B2B Config: Yes (already done)" -ForegroundColor White
Write-Host "  • Skip Site Creation: Yes (already exists)" -ForegroundColor White
Write-Host "  • Add 5 new users only" -ForegroundColor White
Write-Host ""

# Test with WhatIf
Write-Host "Testing with WhatIf first..." -ForegroundColor Cyan
.\Setup-CrossTenantCollaboration.ps1 `
    -HostTenantDomain "your-company.com" `
    -GuestTenantDomain "partner-company.com" `
    -SharePointSiteTitle "Client Projects" `
    -SharePointSiteAlias "ClientProjects" `
    -UsersCsvPath ".\Examples\new-users-only.csv" `
    -AdminEmail "admin@your-company.com" `
    -SkipB2BConfig `
    -SkipSiteCreation `
    -WhatIf

# Confirm and execute
Write-Host ""
$confirm = Read-Host "Add these users for real? (Y/N)"

if ($confirm -eq 'Y' -or $confirm -eq 'y') {
    .\Setup-CrossTenantCollaboration.ps1 `
        -HostTenantDomain "your-company.com" `
        -GuestTenantDomain "partner-company.com" `
        -SharePointSiteTitle "Client Projects" `
        -SharePointSiteAlias "ClientProjects" `
        -UsersCsvPath ".\Examples\new-users-only.csv" `
        -AdminEmail "admin@your-company.com" `
        -SkipB2BConfig `
        -SkipSiteCreation `
        -GenerateHtmlReport

    Write-Host ""
    Write-Host "✅ Users added successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Guest users will receive invitation emails." -ForegroundColor Cyan
    Write-Host "Check the HTML report for details." -ForegroundColor Cyan
} else {
    Write-Host "Cancelled." -ForegroundColor Yellow
}
