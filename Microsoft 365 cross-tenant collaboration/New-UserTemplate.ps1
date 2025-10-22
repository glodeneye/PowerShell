<#
.SYNOPSIS
    Generate a CSV template for user import

.DESCRIPTION
    Creates a sample CSV file with the correct format for importing users
    into the M365 Cross-Tenant Collaboration setup script

.PARAMETER OutputPath
    Path where the template CSV will be created

.EXAMPLE
    .\New-UserTemplate.ps1 -OutputPath ".\my-users-template.csv"

.EXAMPLE
    .\New-UserTemplate.ps1
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ".\user-template.csv"
)

$template = @(
    [PSCustomObject]@{
        Email = "admin@yourhost.com"
        Tenant = "Host"
        Role = "Owner"
        DisplayName = "Admin User"
        Department = "IT"
        ClientAccess = ""
    },
    [PSCustomObject]@{
        Email = "user1@yourhost.com"
        Tenant = "Host"
        Role = "Member"
        DisplayName = "John Doe"
        Department = "Compliance"
        ClientAccess = "Client A;Client B"
    },
    [PSCustomObject]@{
        Email = "user1@guesttenant.com"
        Tenant = "Guest"
        Role = "Member"
        DisplayName = "Jane Smith"
        Department = "Consulting"
        ClientAccess = "Client A"
    }
)

$template | Export-Csv -Path $OutputPath -NoTypeInformation

Write-Host "✓ User template CSV created: $OutputPath" -ForegroundColor Green
Write-Host "`nCSV Column Descriptions:" -ForegroundColor Cyan
Write-Host "  Email        : User's email address (Required)" -ForegroundColor White
Write-Host "  Tenant       : 'Host' or 'Guest' (Required)" -ForegroundColor White
Write-Host "  Role         : 'Owner', 'Member', or 'Visitor' (Required)" -ForegroundColor White
Write-Host "  DisplayName  : User's display name (Optional)" -ForegroundColor White
Write-Host "  Department   : User's department (Optional)" -ForegroundColor White
Write-Host "  ClientAccess : Semicolon-separated client folder list (Optional)" -ForegroundColor White
Write-Host "                 Example: 'Client A;Client B;Client C'" -ForegroundColor White
Write-Host "`nEdit this file and use it with the -UsersCsvPath parameter" -ForegroundColor Yellow
