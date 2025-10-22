<#
.SYNOPSIS
    Export all OneDrive shared items (shared with you and shared by you) to CSV files.

.DESCRIPTION
    This script recursively scans your entire OneDrive to find:
    - Items that others have shared with you
    - Items that you have shared with others (including nested folders)
    
    Results are exported to CSV files for easy review and cleanup.

.PARAMETER OutputDirectory
    Directory where CSV files will be saved. Default: C:\OneDriveSharedItems

.PARAMETER IncludeSubfolders
    Recursively scan all subfolders. Default: $true

.PARAMETER ShowProgress
    Display progress every N items. Default: 25

.EXAMPLE
    .\Get-OneDriveSharedItems.ps1
    
.EXAMPLE
    .\Get-OneDriveSharedItems.ps1 -OutputDirectory "D:\Reports" -ShowProgress 50

.NOTES
    Author: Community Script
    Version: 1.0.0
    Requires: Microsoft.Graph.Authentication module
    License: MIT
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$OutputDirectory = "C:\OneDriveSharedItems",
    
    [Parameter(Mandatory=$false)]
    [bool]$IncludeSubfolders = $true,
    
    [Parameter(Mandatory=$false)]
    [int]$ShowProgress = 25
)

#region Configuration Variables
# Microsoft Graph API Scopes required
$RequiredScopes = @("Files.Read.All", "Sites.Read.All")

# Output file naming
$TimestampFormat = "yyyyMMdd_HHmmss"
$AllItemsFileName = "OneDrive_SharedItems_Complete"
$MySharedItemsFileName = "OneDrive_MySharedItems_ToCleanup"

# Display options
$ShowDetailedProgress = $true
$ShowFolderScanning = $true
#endregion

#region Helper Functions
function Get-AllDriveItems {
    <#
    .SYNOPSIS
        Recursively retrieves all items from OneDrive
    #>
    param (
        [string]$FolderId = "root",
        [string]$FolderPath = ""
    )
    
    $allItems = @()
    
    try {
        $response = Invoke-MgGraphRequest -Method GET -Uri "v1.0/me/drive/items/$FolderId/children"
        $items = $response.value
        
        foreach ($item in $items) {
            $itemPath = if ($FolderPath) { "$FolderPath/$($item.name)" } else { $item.name }
            
            # Add current item
            $allItems += [PSCustomObject]@{
                Id = $item.id
                Name = $item.name
                Path = $itemPath
                Type = if ($item.folder) { "Folder" } else { "File" }
                Size = $item.size
                WebUrl = $item.webUrl
                LastModified = $item.lastModifiedDateTime
            }
            
            # If it's a folder and we're including subfolders, recurse into it
            if ($item.folder -and $IncludeSubfolders) {
                if ($ShowFolderScanning) {
                    Write-Host "  Scanning folder: $itemPath" -ForegroundColor Gray
                }
                $subItems = Get-AllDriveItems -FolderId $item.id -FolderPath $itemPath
                $allItems += $subItems
            }
        }
    }
    catch {
        Write-Host "  Error accessing folder: $FolderPath - $($_.Exception.Message)" -ForegroundColor Red
    }
    
    return $allItems
}

function Format-FileSize {
    param([int64]$Size)
    
    if ($Size -eq 0 -or $null -eq $Size) {
        return "N/A"
    }
    elseif ($Size -lt 1KB) {
        return "$Size B"
    }
    elseif ($Size -lt 1MB) {
        return "$([math]::Round($Size / 1KB, 2)) KB"
    }
    elseif ($Size -lt 1GB) {
        return "$([math]::Round($Size / 1MB, 2)) MB"
    }
    else {
        return "$([math]::Round($Size / 1GB, 2)) GB"
    }
}
#endregion

#region Main Script
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  OneDrive Shared Items Export Tool" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Microsoft.Graph.Authentication module is installed
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Write-Host "ERROR: Microsoft.Graph.Authentication module is not installed." -ForegroundColor Red
    Write-Host "Please run: Install-Module Microsoft.Graph.Authentication -Scope CurrentUser" -ForegroundColor Yellow
    exit 1
}

# Import the module
try {
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Write-Host "✓ Microsoft Graph module loaded" -ForegroundColor Green
}
catch {
    Write-Host "ERROR: Failed to import Microsoft.Graph.Authentication module" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# Connect to Microsoft Graph
Write-Host "`nConnecting to Microsoft Graph..." -ForegroundColor Cyan
try {
    Connect-MgGraph -Scopes $RequiredScopes -ErrorAction Stop
    $context = Get-MgContext
    Write-Host "✓ Connected successfully as: $($context.Account)" -ForegroundColor Green
}
catch {
    Write-Host "ERROR: Failed to connect to Microsoft Graph" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

Write-Host "`nFetching shared items from OneDrive..." -ForegroundColor Cyan

# Get items shared with me
try {
    $sharedWithMeResponse = Invoke-MgGraphRequest -Method GET -Uri "v1.0/me/drive/sharedWithMe"
    $sharedWithMe = $sharedWithMeResponse.value
    Write-Host "✓ Found $($sharedWithMe.Count) items shared with you" -ForegroundColor Green
}
catch {
    Write-Host "⚠ Error fetching shared items: $($_.Exception.Message)" -ForegroundColor Yellow
    $sharedWithMe = @()
}

# Get ALL items in your drive (recursive)
Write-Host "`nScanning your OneDrive..." -ForegroundColor Cyan
if ($IncludeSubfolders) {
    Write-Host "(Including all subfolders - this may take a while)" -ForegroundColor Gray
}
$allMyDriveItems = Get-AllDriveItems
Write-Host "✓ Total items found in your drive: $($allMyDriveItems.Count)" -ForegroundColor Green

$results = @()

# Process items shared with me
Write-Host "`nProcessing items shared with you..." -ForegroundColor Yellow
foreach ($item in $sharedWithMe) {
    $results += [PSCustomObject]@{
        Name = $item.name
        Path = $item.name
        Type = if ($item.folder) { "Folder" } else { "File" }
        SharedType = "Shared With Me"
        WebUrl = $item.webUrl
        SizeFormatted = Format-FileSize -Size $item.size
        SizeBytes = $item.size
        LastModified = $item.lastModifiedDateTime
        SharedBy = if ($item.remoteItem.sharedBy.user.displayName) { $item.remoteItem.sharedBy.user.displayName } else { "Unknown" }
        SharedWith = ""
        LinkUrl = ""
        LinkType = ""
        LinkScope = ""
        PermissionId = ""
    }
}

# Process ALL items you've shared (including nested folders)
Write-Host "Checking permissions on all $($allMyDriveItems.Count) items..." -ForegroundColor Yellow
if ($ShowDetailedProgress) {
    Write-Host "(Progress updates every $ShowProgress items)" -ForegroundColor Gray
}

$processedCount = 0
$sharedCount = 0

foreach ($item in $allMyDriveItems) {
    $processedCount++
    if ($ShowDetailedProgress -and ($processedCount % $ShowProgress -eq 0)) {
        Write-Host "  Processed $processedCount of $($allMyDriveItems.Count) items... (Found $sharedCount shared items so far)" -ForegroundColor Gray
    }
    
    try {
        $permResponse = Invoke-MgGraphRequest -Method GET -Uri "v1.0/me/drive/items/$($item.Id)/permissions"
        $permissions = $permResponse.value
        
        foreach ($perm in $permissions) {
            # Check for sharing links
            if ($perm.link) {
                $sharedCount++
                $sharedWith = switch ($perm.link.scope) {
                    "anonymous" { "Anyone with the link" }
                    "organization" { "People in your organization" }
                    "users" { 
                        if ($perm.grantedToIdentitiesV2) {
                            ($perm.grantedToIdentitiesV2 | ForEach-Object { $_.user.displayName }) -join "; "
                        } else { "Specific people" }
                    }
                    default { $perm.link.scope }
                }
                
                $results += [PSCustomObject]@{
                    Name = $item.Name
                    Path = $item.Path
                    Type = $item.Type
                    SharedType = "Shared By Me"
                    WebUrl = $item.WebUrl
                    SizeFormatted = Format-FileSize -Size $item.Size
                    SizeBytes = $item.Size
                    LastModified = $item.LastModified
                    SharedBy = $context.Account
                    SharedWith = $sharedWith
                    LinkType = $perm.link.type
                    LinkScope = $perm.link.scope
                    LinkUrl = $perm.link.webUrl
                    PermissionId = $perm.id
                }
            }
            # Check for direct user/group permissions (not links)
            elseif ($perm.grantedToV2 -or $perm.grantedToIdentitiesV2) {
                $sharedCount++
                $sharedWith = if ($perm.grantedToV2.user) {
                    $perm.grantedToV2.user.displayName
                } elseif ($perm.grantedToIdentitiesV2) {
                    ($perm.grantedToIdentitiesV2 | ForEach-Object { $_.user.displayName }) -join "; "
                } else {
                    "Unknown user"
                }
                
                $results += [PSCustomObject]@{
                    Name = $item.Name
                    Path = $item.Path
                    Type = $item.Type
                    SharedType = "Shared By Me (Direct)"
                    WebUrl = $item.WebUrl
                    SizeFormatted = Format-FileSize -Size $item.Size
                    SizeBytes = $item.Size
                    LastModified = $item.LastModified
                    SharedBy = $context.Account
                    SharedWith = $sharedWith
                    LinkType = ""
                    LinkScope = ""
                    LinkUrl = ""
                    PermissionId = $perm.id
                }
            }
        }
    }
    catch {
        # Silently skip items without permissions or errors
    }
}

Write-Host "✓ Completed scanning all items!" -ForegroundColor Green

# Create output directory if it doesn't exist
if (-not (Test-Path $OutputDirectory)) {
    New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
    Write-Host "✓ Created directory: $OutputDirectory" -ForegroundColor Green
}

# Display and export results
if ($results.Count -gt 0) {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  RESULTS SUMMARY" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    
    # Show items YOU'VE shared (for cleanup)
    $mySharedItems = $results | Where-Object {$_.SharedType -like "Shared By Me*"}
    
    Write-Host "`nTotal shared items found: $($results.Count)" -ForegroundColor Green
    Write-Host "  • Shared with you: $(($results | Where-Object {$_.SharedType -eq 'Shared With Me'}).Count)" -ForegroundColor White
    Write-Host "  • Shared by you: $($mySharedItems.Count)" -ForegroundColor Yellow
    
    # Export to CSV with timestamp
    $timestamp = Get-Date -Format $TimestampFormat
    $csvPath = Join-Path $OutputDirectory "${AllItemsFileName}_${timestamp}.csv"
    $results | Select-Object Name, Path, Type, SharedType, SharedBy, SharedWith, LinkScope, LinkType, LinkUrl, WebUrl, SizeFormatted, LastModified, PermissionId | Export-Csv -Path $csvPath -NoTypeInformation
    
    # Also create a separate CSV just for items YOU'VE shared (easier for cleanup)
    if ($mySharedItems.Count -gt 0) {
        $cleanupCsvPath = Join-Path $OutputDirectory "${MySharedItemsFileName}_${timestamp}.csv"
        $mySharedItems | Select-Object Name, Path, Type, SharedWith, LinkScope, LinkType, LinkUrl, WebUrl, SizeFormatted, LastModified, PermissionId | Export-Csv -Path $cleanupCsvPath -NoTypeInformation
        
        Write-Host "`n>>> ITEMS YOU'VE SHARED (For Cleanup) <<<" -ForegroundColor Yellow
        $mySharedItems | Format-Table Name, SharedWith, LinkScope, LinkType -AutoSize
    }
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  EXPORT COMPLETE" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "`nFiles exported to:" -ForegroundColor Green
    Write-Host "  📄 All items: $csvPath" -ForegroundColor White
    if ($mySharedItems.Count -gt 0) {
        Write-Host "  📄 Your shared items: $cleanupCsvPath" -ForegroundColor Yellow
    }
    
    # Show summary
    Write-Host "`nBreakdown by type:" -ForegroundColor Cyan
    $results | Group-Object SharedType | ForEach-Object {
        Write-Host "  • $($_.Name): $($_.Count) items" -ForegroundColor White
    }
    
    # Show who you've shared with
    if ($mySharedItems.Count -gt 0) {
        Write-Host "`nSharing scope breakdown:" -ForegroundColor Cyan
        $mySharedItems | Group-Object LinkScope | ForEach-Object {
            $scopeName = if ($_.Name) { $_.Name } else { "Direct Share" }
            $itemCount = $_.Count
            Write-Host "  • ${scopeName}: ${itemCount} items" -ForegroundColor White
        }
    }
}
else {
    Write-Host "`n⚠ No shared items found." -ForegroundColor Yellow
    Write-Host "This could mean:" -ForegroundColor Gray
    Write-Host "  • You haven't shared any files/folders" -ForegroundColor Gray
    Write-Host "  • No files/folders have been shared with you" -ForegroundColor Gray
}

# Disconnect
Write-Host "`n========================================" -ForegroundColor Cyan
Disconnect-MgGraph
Write-Host "✓ Disconnected from Microsoft Graph" -ForegroundColor Green
Write-Host "✓ Script completed successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
#endregion