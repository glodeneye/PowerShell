<#
.SYNOPSIS
    Configure Microsoft 365 cross-tenant collaboration for SharePoint and shared resources.

.DESCRIPTION
    This script automates the setup of B2B collaboration between two M365 tenants,
    creates a SharePoint site with client folder structure, and configures permissions.
    Includes logging, CSV import, rollback functionality, email notifications, and reporting.

.PARAMETER HostTenantDomain
    The primary tenant domain (e.g., your-company.com)

.PARAMETER GuestTenantDomain
    The secondary tenant domain to invite users from (e.g., partner-company.com)

.PARAMETER SharePointSiteTitle
    Title for the SharePoint site (e.g., "Client Projects")

.PARAMETER SharePointSiteAlias
    URL-friendly alias for the site (e.g., "ClientProjects")

.PARAMETER ClientFolders
    Array of client folder names to create

.PARAMETER GuestUserEmails
    Array of email addresses from the guest tenant to invite

.PARAMETER AdminEmail
    Admin email for the host tenant

.PARAMETER UsersCsvPath
    Path to CSV file containing users from both tenants (optional)

.PARAMETER LogPath
    Path to log file directory (default: .\Logs)

.PARAMETER NotificationEmail
    Email address(es) to send completion notifications to (comma-separated)

.PARAMETER EnableRollback
    Enable automatic rollback on critical errors

.PARAMETER GenerateHtmlReport
    Generate HTML report of execution

.PARAMETER GenerateExcelReport
    Generate Excel report of execution

.PARAMETER WhatIf
    Show what actions would be performed without actually executing them (dry-run mode)

.EXAMPLE
    .\Setup-CrossTenantCollaboration.ps1 -HostTenantDomain "your-company.com" `
        -GuestTenantDomain "partner-company.com" `
        -SharePointSiteTitle "Client Projects" `
        -SharePointSiteAlias "ClientProjects" `
        -UsersCsvPath ".\users.csv" `
        -AdminEmail "admin@your-company.com" `
        -NotificationEmail "admin@your-company.com" `
        -EnableRollback `
        -GenerateHtmlReport

.EXAMPLE
    # Dry-run mode to see what would happen without making changes
    .\Setup-CrossTenantCollaboration.ps1 -HostTenantDomain "your-company.com" `
        -GuestTenantDomain "partner-company.com" `
        -SharePointSiteTitle "Client Projects" `
        -SharePointSiteAlias "ClientProjects" `
        -UsersCsvPath ".\users.csv" `
        -AdminEmail "admin@your-company.com" `
        -WhatIf
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$true)]
    [string]$HostTenantDomain,

    [Parameter(Mandatory=$true)]
    [string]$GuestTenantDomain,

    [Parameter(Mandatory=$true)]
    [string]$SharePointSiteTitle,

    [Parameter(Mandatory=$true)]
    [string]$SharePointSiteAlias,

    [Parameter(Mandatory=$false)]
    [string[]]$ClientFolders = @(),

    [Parameter(Mandatory=$false)]
    [string[]]$GuestUserEmails = @(),

    [Parameter(Mandatory=$true)]
    [string]$AdminEmail,

    [Parameter(Mandatory=$false)]
    [string]$UsersCsvPath,

    [Parameter(Mandatory=$false)]
    [string]$LogPath = ".\Logs",

    [Parameter(Mandatory=$false)]
    [string]$NotificationEmail,

    [Parameter(Mandatory=$false)]
    [switch]$EnableRollback,

    [Parameter(Mandatory=$false)]
    [switch]$GenerateHtmlReport,

    [Parameter(Mandatory=$false)]
    [switch]$GenerateExcelReport,

    [Parameter(Mandatory=$false)]
    [switch]$SkipB2BConfig,

    [Parameter(Mandatory=$false)]
    [switch]$SkipSiteCreation
)

# Global variables
$script:LogFile = $null
$script:StartTime = Get-Date
$script:ExecutionId = [guid]::NewGuid().ToString()
$script:RollbackStack = [System.Collections.ArrayList]@()
$script:CreatedResources = @{
    Sites = @()
    Users = @()
    Folders = @()
    Permissions = @()
    B2BConfigs = @()
}

# Required modules
$requiredModules = @(
    'Microsoft.Graph',
    'PnP.PowerShell'
)

#region Logging Functions

function Initialize-Logging {
    param(
        [string]$LogDirectory
    )

    try {
        if (-not (Test-Path $LogDirectory)) {
            New-Item -Path $LogDirectory -ItemType Directory -Force | Out-Null
        }

        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $script:LogFile = Join-Path $LogDirectory "CrossTenantSetup_$timestamp.log"

        $header = @"
========================================================================================================
Microsoft 365 Cross-Tenant Collaboration Setup Log
========================================================================================================
Execution ID: $script:ExecutionId
Start Time: $script:StartTime
Host Tenant: $HostTenantDomain
Guest Tenant: $GuestTenantDomain
Admin User: $AdminEmail
Rollback Enabled: $EnableRollback
========================================================================================================

"@
        Add-Content -Path $script:LogFile -Value $header

        Write-Host "✓ Logging initialized: $script:LogFile" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "✗ Failed to initialize logging: $_" -ForegroundColor Red
        return $false
    }
}

function Write-Log {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [ValidateSet('INFO', 'WARNING', 'ERROR', 'SUCCESS', 'DEBUG', 'ROLLBACK')]
        [string]$Level = 'INFO',

        [Parameter(Mandatory=$false)]
        [switch]$NoConsole
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"

    if ($script:LogFile) {
        Add-Content -Path $script:LogFile -Value $logEntry
    }

    if (-not $NoConsole) {
        $color = switch ($Level) {
            'ERROR'    { 'Red' }
            'WARNING'  { 'Yellow' }
            'SUCCESS'  { 'Green' }
            'DEBUG'    { 'Gray' }
            'ROLLBACK' { 'Magenta' }
            default    { 'White' }
        }
        Write-Host $logEntry -ForegroundColor $color
    }
}

function Write-M365AuditLog {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Operation,

        [Parameter(Mandatory=$false)]
        [string]$Details,

        [Parameter(Mandatory=$false)]
        [hashtable]$AdditionalData
    )

    try {
        $auditEntry = @{
            ExecutionId = $script:ExecutionId
            Timestamp = (Get-Date).ToUniversalTime().ToString("o")
            Operation = $Operation
            HostTenant = $HostTenantDomain
            GuestTenant = $GuestTenantDomain
            AdminUser = $AdminEmail
            Details = $Details
            Status = "Completed"
        }

        if ($AdditionalData) {
            $auditEntry += $AdditionalData
        }

        $auditLogPath = Join-Path (Split-Path $script:LogFile) "Audit_$(Get-Date -Format 'yyyyMMdd').json"
        $auditJson = $auditEntry | ConvertTo-Json -Compress
        Add-Content -Path $auditLogPath -Value $auditJson

        Write-Log "Audit entry created for operation: $Operation" -Level DEBUG
    }
    catch {
        Write-Log "Failed to write audit log entry: $_" -Level WARNING
    }
}

#endregion

#region Rollback Functions

function Add-RollbackAction {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ActionType,

        [Parameter(Mandatory=$true)]
        [scriptblock]$RollbackScript,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters = @{},

        [Parameter(Mandatory=$false)]
        [string]$Description
    )

    if (-not $EnableRollback) {
        return
    }

    $rollbackAction = @{
        Timestamp = Get-Date
        ActionType = $ActionType
        Script = $RollbackScript
        Parameters = $Parameters
        Description = $Description
        ExecutionId = $script:ExecutionId
    }

    [void]$script:RollbackStack.Add($rollbackAction)
    Write-Log "Rollback action registered: $ActionType - $Description" -Level DEBUG
}

function Invoke-Rollback {
    param(
        [Parameter(Mandatory=$false)]
        [string]$Reason = "Critical error occurred"
    )

    if ($script:RollbackStack.Count -eq 0) {
        Write-Log "No rollback actions to perform" -Level WARNING
        return
    }

    Write-Log "========================================" -Level ROLLBACK
    Write-Log "INITIATING ROLLBACK PROCEDURE" -Level ROLLBACK
    Write-Log "Reason: $Reason" -Level ROLLBACK
    Write-Log "Actions to rollback: $($script:RollbackStack.Count)" -Level ROLLBACK
    Write-Log "========================================" -Level ROLLBACK

    Write-M365AuditLog -Operation "RollbackInitiated" -Details $Reason -AdditionalData @{
        ActionsCount = $script:RollbackStack.Count
    }

    # Reverse the stack to undo in reverse order
    [array]::Reverse($script:RollbackStack)

    $successCount = 0
    $failCount = 0

    foreach ($action in $script:RollbackStack) {
        try {
            Write-Log "Rolling back: $($action.Description)" -Level ROLLBACK

            # Execute the rollback script with parameters
            & $action.Script @($action.Parameters)

            Write-Log "✓ Successfully rolled back: $($action.ActionType)" -Level SUCCESS
            $successCount++

            Write-M365AuditLog -Operation "RollbackAction" -Details "Rolled back: $($action.Description)" -AdditionalData @{
                ActionType = $action.ActionType
                Status = "Success"
            }
        }
        catch {
            Write-Log "✗ Failed to rollback $($action.ActionType): $_" -Level ERROR
            $failCount++

            Write-M365AuditLog -Operation "RollbackAction" -Details "Failed: $($action.Description)" -AdditionalData @{
                ActionType = $action.ActionType
                Status = "Failed"
                Error = $_.Exception.Message
            }
        }
    }

    Write-Log "========================================" -Level ROLLBACK
    Write-Log "ROLLBACK COMPLETED" -Level ROLLBACK
    Write-Log "Successful: $successCount | Failed: $failCount" -Level ROLLBACK
    Write-Log "========================================" -Level ROLLBACK

    Write-M365AuditLog -Operation "RollbackCompleted" -Details "Rollback procedure finished" -AdditionalData @{
        SuccessCount = $successCount
        FailCount = $failCount
    }
}

#endregion

#region CSV Import Functions

function Import-UsersFromCsv {
    param(
        [Parameter(Mandatory=$true)]
        [string]$CsvPath
    )

    Write-Log "Importing users from CSV: $CsvPath" -Level INFO

    try {
        if (-not (Test-Path $CsvPath)) {
            Write-Log "CSV file not found: $CsvPath" -Level ERROR
            return $null
        }

        $users = Import-Csv -Path $CsvPath

        $requiredColumns = @('Email', 'Tenant', 'Role')
        $csvColumns = $users[0].PSObject.Properties.Name

        $missingColumns = $requiredColumns | Where-Object { $_ -notin $csvColumns }
        if ($missingColumns) {
            Write-Log "CSV is missing required columns: $($missingColumns -join ', ')" -Level ERROR
            return $null
        }

        Write-Log "Successfully imported $($users.Count) users from CSV" -Level SUCCESS

        $hostUsers = ($users | Where-Object { $_.Tenant -eq 'Host' }).Count
        $guestUsers = ($users | Where-Object { $_.Tenant -eq 'Guest' }).Count
        Write-Log "  Host Users: $hostUsers" -Level INFO
        Write-Log "  Guest Users: $guestUsers" -Level INFO

        return $users
    }
    catch {
        Write-Log "Failed to import CSV: $_" -Level ERROR
        return $null
    }
}

#endregion

#region Module and Connection Functions

function Test-RequiredModules {
    Write-Log "Checking required PowerShell modules..." -Level INFO

    $allInstalled = $true
    foreach ($module in $requiredModules) {
        if (Get-Module -ListAvailable -Name $module) {
            Write-Log "✓ $module is installed" -Level SUCCESS
        } else {
            Write-Log "✗ $module is not installed" -Level ERROR
            Write-Host "  Install with: Install-Module -Name $module -Scope CurrentUser" -ForegroundColor Yellow
            $allInstalled = $false
        }
    }

    if ($allInstalled) {
        Write-M365AuditLog -Operation "ModuleCheck" -Details "All required modules are installed"
    }

    return $allInstalled
}

function Connect-Services {
    param(
        [string]$TenantDomain,
        [string]$AdminEmail
    )

    Write-Log "Connecting to Microsoft 365 services..." -Level INFO

    try {
        Write-Log "Connecting to Microsoft Graph..." -Level INFO
        Connect-MgGraph -Scopes "User.ReadWrite.All", "Directory.ReadWrite.All", "Policy.ReadWrite.CrossTenantAccess", "AuditLog.Read.All", "Mail.Send" -NoWelcome
        Write-Log "Successfully connected to Microsoft Graph" -Level SUCCESS

        Write-Log "Connecting to SharePoint Online..." -Level INFO
        $tenantName = $TenantDomain.Split('.')[0]
        $adminUrl = "https://$tenantName-admin.sharepoint.com"
        Connect-PnPOnline -Url $adminUrl -Interactive
        Write-Log "Successfully connected to SharePoint Online: $adminUrl" -Level SUCCESS

        Write-M365AuditLog -Operation "ServiceConnection" -Details "Connected to Graph and SharePoint" -AdditionalData @{
            GraphScopes = "User.ReadWrite.All, Directory.ReadWrite.All, Policy.ReadWrite.CrossTenantAccess, Mail.Send"
            SharePointUrl = $adminUrl
        }

        return $true
    }
    catch {
        Write-Log "Error connecting to services: $_" -Level ERROR
        return $false
    }
}

#endregion

#region B2B Configuration Functions

function Set-CrossTenantB2BAccess {
    param(
        [string]$GuestTenantDomain
    )

    Write-Log "=== Configuring Cross-Tenant B2B Access ===" -Level INFO

    try {
        Write-Log "Looking up tenant ID for $GuestTenantDomain..." -Level INFO

        $guestTenantId = $null
        try {
            $orgInfo = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/tenantRelationships/findTenantInformationByDomainName(domainName='$GuestTenantDomain')"
            $guestTenantId = $orgInfo.tenantId
            Write-Log "Resolved tenant ID: $guestTenantId" -Level SUCCESS
        }
        catch {
            Write-Log "Unable to automatically resolve tenant ID. Manual entry required." -Level WARNING
            $guestTenantId = Read-Host "Enter the Tenant ID (GUID) for $GuestTenantDomain"
        }

        if ([string]::IsNullOrWhiteSpace($guestTenantId)) {
            Write-Log "No tenant ID provided. Skipping B2B configuration." -Level WARNING
            return
        }

        Write-Log "Configuring cross-tenant access policy for tenant: $guestTenantId" -Level INFO

        $params = @{
            tenantId = $guestTenantId
            b2bCollaborationInbound = @{
                usersAndGroups = @{
                    accessType = "allowed"
                    targets = @(
                        @{
                            target = "AllUsers"
                            targetType = "user"
                        }
                    )
                }
                applications = @{
                    accessType = "allowed"
                    targets = @(
                        @{
                            target = "Office365"
                            targetType = "application"
                        }
                    )
                }
            }
        }

        try {
            if ($PSCmdlet.ShouldProcess("B2B Policy for $GuestTenantDomain (Tenant ID: $guestTenantId)", "Configure cross-tenant access")) {
                $body = $params | ConvertTo-Json -Depth 10
                $result = Invoke-MgGraphRequest -Method PUT -Uri "https://graph.microsoft.com/v1.0/policies/crossTenantAccessPolicy/partners/$guestTenantId" -Body $body -ContentType "application/json"
                Write-Log "Cross-tenant access policy configured successfully" -Level SUCCESS
            }
            else {
                Write-Log "[WHATIF] Would configure B2B policy for $GuestTenantDomain (Tenant ID: $guestTenantId)" -Level INFO
                return
            }

            # Add rollback action
            Add-RollbackAction -ActionType "B2BConfig" -Description "Remove B2B configuration for $GuestTenantDomain" -RollbackScript {
                param($params)
                try {
                    Invoke-MgGraphRequest -Method DELETE -Uri "https://graph.microsoft.com/v1.0/policies/crossTenantAccessPolicy/partners/$($params.TenantId)"
                    Write-Log "B2B configuration removed for tenant: $($params.TenantId)" -Level ROLLBACK
                }
                catch {
                    Write-Log "Failed to remove B2B config: $_" -Level ERROR
                }
            } -Parameters @{ TenantId = $guestTenantId }

            $script:CreatedResources.B2BConfigs += @{
                TenantId = $guestTenantId
                Domain = $GuestTenantDomain
                Timestamp = Get-Date
            }

            Write-M365AuditLog -Operation "B2BConfiguration" -Details "Configured B2B access for $GuestTenantDomain" -AdditionalData @{
                GuestTenantId = $guestTenantId
                AccessType = "Inbound B2B Collaboration"
            }
        }
        catch {
            Write-Log "Error configuring B2B policy via API: $_" -Level ERROR
            Write-Log "Please configure manually in Azure AD Portal → External Identities → Cross-tenant access settings" -Level WARNING
        }

    }
    catch {
        Write-Log "Error in B2B configuration: $_" -Level ERROR

        if ($EnableRollback) {
            throw "B2B configuration failed - rollback may be required"
        }
    }
}

#endregion

#region SharePoint Functions

function New-ClientSharePointSite {
    param(
        [string]$SiteTitle,
        [string]$SiteAlias,
        [string]$HostTenantDomain
    )

    Write-Log "=== Creating SharePoint Site ===" -Level INFO

    try {
        $tenantName = $HostTenantDomain.Split('.')[0]
        $siteUrl = "https://$tenantName.sharepoint.com/sites/$SiteAlias"

        Write-Log "Creating site: $SiteTitle" -Level INFO
        Write-Log "URL: $siteUrl" -Level INFO

        try {
            $existingSite = Get-PnPTenantSite -Url $siteUrl -ErrorAction SilentlyContinue
            if ($existingSite) {
                Write-Log "Site already exists at $siteUrl" -Level WARNING
                $response = Read-Host "Do you want to use the existing site? (Y/N)"
                if ($response -eq 'Y' -or $response -eq 'y') {
                    Write-Log "Using existing site" -Level INFO
                    return $siteUrl
                } else {
                    Write-Log "Site creation cancelled by user" -Level WARNING
                    return $null
                }
            }
        }
        catch {
            # Site doesn't exist, proceed
        }

        if ($PSCmdlet.ShouldProcess("SharePoint site: $SiteTitle at $siteUrl", "Create team site")) {
            $site = New-PnPSite -Type TeamSite -Title $SiteTitle -Alias $SiteAlias -IsPublic:$false
            Write-Log "Site created successfully" -Level SUCCESS
        }
        else {
            Write-Log "[WHATIF] Would create SharePoint site: $SiteTitle at $siteUrl" -Level INFO
            return $siteUrl  # Return URL for dry-run to continue
        }

        # Add rollback action
        Add-RollbackAction -ActionType "SiteCreation" -Description "Delete SharePoint site: $SiteTitle" -RollbackScript {
            param($params)
            try {
                $adminUrl = "https://$($params.TenantName)-admin.sharepoint.com"
                Connect-PnPOnline -Url $adminUrl -Interactive
                Remove-PnPTenantSite -Url $params.SiteUrl -Force -SkipRecycleBin
                Write-Log "Site deleted: $($params.SiteUrl)" -Level ROLLBACK
            }
            catch {
                Write-Log "Failed to delete site: $_" -Level ERROR
            }
        } -Parameters @{ SiteUrl = $siteUrl; TenantName = $tenantName }

        $script:CreatedResources.Sites += @{
            Url = $siteUrl
            Title = $SiteTitle
            Timestamp = Get-Date
        }

        Write-M365AuditLog -Operation "SiteCreation" -Details "Created SharePoint site: $SiteTitle" -AdditionalData @{
            SiteUrl = $siteUrl
            SiteType = "TeamSite"
        }

        Start-Sleep -Seconds 15
        Connect-PnPOnline -Url $siteUrl -Interactive
        Write-Log "Connected to new site" -Level SUCCESS

        return $siteUrl
    }
    catch {
        Write-Log "Error creating site: $_" -Level ERROR

        if ($EnableRollback) {
            throw "Site creation failed - rollback may be required"
        }

        return $null
    }
}

function New-ClientFolderStructure {
    param(
        [string]$SiteUrl,
        [string[]]$ClientFolders
    )

    Write-Log "=== Creating Client Folder Structure ===" -Level INFO

    $foldersCreated = 0

    try {
        Connect-PnPOnline -Url $SiteUrl -Interactive

        Write-Log "Creating 'Clients' parent folder..." -Level INFO
        try {
            $parentFolder = Add-PnPFolder -Name "Clients" -Folder "Shared Documents" -ErrorAction SilentlyContinue
            Write-Log "'Clients' folder created" -Level SUCCESS
        }
        catch {
            Write-Log "'Clients' folder may already exist" -Level WARNING
        }

        foreach ($clientName in $ClientFolders) {
            Write-Log "Creating folder structure for: $clientName" -Level INFO

            try {
                if ($PSCmdlet.ShouldProcess("Folder structure for client: $clientName", "Create folders")) {
                    $clientFolder = Add-PnPFolder -Name $clientName -Folder "Shared Documents/Clients" -ErrorAction SilentlyContinue

                    $subfolders = @("Documents", "Deliverables", "Working Files")
                    foreach ($subfolder in $subfolders) {
                        Add-PnPFolder -Name $subfolder -Folder "Shared Documents/Clients/$clientName" -ErrorAction SilentlyContinue | Out-Null
                        $foldersCreated++
                    }

                    Write-Log "Created structure for $clientName" -Level SUCCESS
                }
                else {
                    Write-Log "[WHATIF] Would create folder structure for: $clientName (Documents, Deliverables, Working Files)" -Level INFO
                    $foldersCreated += 3  # Count for dry-run
                }

                $script:CreatedResources.Folders += @{
                    Path = "Shared Documents/Clients/$clientName"
                    SiteUrl = $SiteUrl
                    Timestamp = Get-Date
                }

                Write-M365AuditLog -Operation "FolderCreation" -Details "Created folder structure for client: $clientName" -AdditionalData @{
                    SiteUrl = $SiteUrl
                    SubfoldersCreated = $subfolders.Count
                }
            }
            catch {
                Write-Log "Error creating structure for $clientName : $_" -Level ERROR
            }
        }

        Write-Log "All client folders created successfully. Total folders: $foldersCreated" -Level SUCCESS
        return $foldersCreated
    }
    catch {
        Write-Log "Error creating folder structure: $_" -Level ERROR
        return $foldersCreated
    }
}

#endregion

#region User Management Functions

function Add-UsersToSite {
    param(
        [string]$SiteUrl,
        [array]$Users
    )

    Write-Log "=== Adding Users to Site ===" -Level INFO

    $stats = @{
        GuestsInvited = 0
        HostUsersAdded = 0
        Errors = 0
    }

    try {
        Connect-PnPOnline -Url $SiteUrl -Interactive

        foreach ($user in $Users) {
            $email = $user.Email
            $tenant = $user.Tenant
            $role = if ($user.Role) { $user.Role } else { "Member" }

            Write-Log "Processing user: $email (Tenant: $tenant, Role: $role)" -Level INFO

            try {
                if ($tenant -eq "Guest") {
                    Write-Log "Inviting guest user: $email" -Level INFO

                    $pnpRole = switch ($role) {
                        "Owner" { "Edit" }
                        "Member" { "Edit" }
                        "Visitor" { "Read" }
                        default { "Edit" }
                    }

                    if ($PSCmdlet.ShouldProcess("Guest user: $email", "Send invitation with role $pnpRole")) {
                        $invitation = New-PnPSiteUserInvitation -EmailAddress $email -SendInvitation -Role $pnpRole
                        Write-Log "Guest invitation sent to $email" -Level SUCCESS
                        $stats.GuestsInvited++
                    }
                    else {
                        Write-Log "[WHATIF] Would send invitation to guest user: $email (Role: $role)" -Level INFO
                        $stats.GuestsInvited++  # Count for dry-run
                    }

                    # Add rollback action
                    Add-RollbackAction -ActionType "GuestInvitation" -Description "Remove guest user: $email" -RollbackScript {
                        param($params)
                        try {
                            Connect-PnPOnline -Url $params.SiteUrl -Interactive
                            Remove-PnPUser -Identity $params.Email -Force
                            Write-Log "Guest user removed: $($params.Email)" -Level ROLLBACK
                        }
                        catch {
                            Write-Log "Failed to remove guest user: $_" -Level ERROR
                        }
                    } -Parameters @{ Email = $email; SiteUrl = $SiteUrl }

                    $script:CreatedResources.Users += @{
                        Email = $email
                        Type = "Guest"
                        SiteUrl = $SiteUrl
                        Timestamp = Get-Date
                    }

                    Write-M365AuditLog -Operation "GuestInvitation" -Details "Invited guest user: $email" -AdditionalData @{
                        UserEmail = $email
                        Role = $role
                        SiteUrl = $SiteUrl
                    }
                }
                else {
                    Write-Log "Adding host user: $email" -Level INFO

                    $pnpRole = switch ($role) {
                        "Owner" { "Full Control" }
                        "Member" { "Edit" }
                        "Visitor" { "Read" }
                        default { "Edit" }
                    }

                    if ($PSCmdlet.ShouldProcess("Host user: $email", "Add to site with role $pnpRole")) {
                        Set-PnPWebPermission -User $email -AddRole $pnpRole
                        Write-Log "Host user added: $email" -Level SUCCESS
                        $stats.HostUsersAdded++
                    }
                    else {
                        Write-Log "[WHATIF] Would add host user: $email (Role: $role)" -Level INFO
                        $stats.HostUsersAdded++  # Count for dry-run
                    }

                    $script:CreatedResources.Users += @{
                        Email = $email
                        Type = "Host"
                        SiteUrl = $SiteUrl
                        Timestamp = Get-Date
                    }

                    Write-M365AuditLog -Operation "HostUserAdded" -Details "Added host user: $email" -AdditionalData @{
                        UserEmail = $email
                        Role = $role
                        SiteUrl = $SiteUrl
                    }
                }
            }
            catch {
                Write-Log "Error processing user $email : $_" -Level ERROR
                $stats.Errors++
            }
        }

        Write-Log "User addition completed. Guests: $($stats.GuestsInvited), Host: $($stats.HostUsersAdded), Errors: $($stats.Errors)" -Level SUCCESS
        return $stats
    }
    catch {
        Write-Log "Error adding users to site: $_" -Level ERROR
        return $stats
    }
}

#endregion

#region Reporting Functions

function New-HtmlReport {
    param(
        [hashtable]$Statistics,
        [string]$OutputPath
    )

    Write-Log "Generating HTML report..." -Level INFO

    $endTime = Get-Date
    $duration = $endTime - $script:StartTime

    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>M365 Cross-Tenant Setup Report</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 20px;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background-color: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        h1 {
            color: #0078d4;
            border-bottom: 3px solid #0078d4;
            padding-bottom: 10px;
        }
        h2 {
            color: #106ebe;
            margin-top: 30px;
        }
        .summary-box {
            background-color: #e8f4fd;
            border-left: 4px solid #0078d4;
            padding: 15px;
            margin: 20px 0;
        }
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin: 20px 0;
        }
        .stat-card {
            background-color: #f8f9fa;
            padding: 20px;
            border-radius: 8px;
            text-align: center;
            border: 1px solid #dee2e6;
        }
        .stat-number {
            font-size: 32px;
            font-weight: bold;
            color: #0078d4;
        }
        .stat-label {
            color: #666;
            margin-top: 5px;
        }
        .success { color: #107c10; }
        .warning { color: #ff8c00; }
        .error { color: #d13438; }
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
        }
        th, td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #0078d4;
            color: white;
        }
        tr:hover {
            background-color: #f5f5f5;
        }
        .status-badge {
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 12px;
            font-weight: bold;
        }
        .status-success {
            background-color: #dff6dd;
            color: #107c10;
        }
        .status-warning {
            background-color: #fff4ce;
            color: #ff8c00;
        }
        .status-error {
            background-color: #fde7e9;
            color: #d13438;
        }
        .footer {
            margin-top: 40px;
            padding-top: 20px;
            border-top: 1px solid #ddd;
            color: #666;
            font-size: 12px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Microsoft 365 Cross-Tenant Collaboration Setup Report</h1>

        <div class="summary-box">
            <strong>Execution ID:</strong> $($script:ExecutionId)<br>
            <strong>Start Time:</strong> $($script:StartTime.ToString("yyyy-MM-dd HH:mm:ss"))<br>
            <strong>End Time:</strong> $($endTime.ToString("yyyy-MM-dd HH:mm:ss"))<br>
            <strong>Duration:</strong> $($duration.ToString("hh\:mm\:ss"))<br>
            <strong>Host Tenant:</strong> $HostTenantDomain<br>
            <strong>Guest Tenant:</strong> $GuestTenantDomain
        </div>

        <h2>Execution Statistics</h2>
        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-number success">$($Statistics.SitesCreated)</div>
                <div class="stat-label">Sites Created</div>
            </div>
            <div class="stat-card">
                <div class="stat-number success">$($Statistics.FoldersCreated)</div>
                <div class="stat-label">Folders Created</div>
            </div>
            <div class="stat-card">
                <div class="stat-number success">$($Statistics.GuestsInvited)</div>
                <div class="stat-label">Guests Invited</div>
            </div>
            <div class="stat-card">
                <div class="stat-number success">$($Statistics.HostUsersProcessed)</div>
                <div class="stat-label">Host Users Added</div>
            </div>
            <div class="stat-card">
                <div class="stat-number warning">$($Statistics.Warnings)</div>
                <div class="stat-label">Warnings</div>
            </div>
            <div class="stat-card">
                <div class="stat-number error">$($Statistics.Errors)</div>
                <div class="stat-label">Errors</div>
            </div>
        </div>

        <h2>Created Resources</h2>

        <h3>SharePoint Sites</h3>
        <table>
            <tr>
                <th>Site Title</th>
                <th>URL</th>
                <th>Created At</th>
            </tr>
"@

    foreach ($site in $script:CreatedResources.Sites) {
        $html += @"
            <tr>
                <td>$($site.Title)</td>
                <td><a href="$($site.Url)" target="_blank">$($site.Url)</a></td>
                <td>$($site.Timestamp.ToString("yyyy-MM-dd HH:mm:ss"))</td>
            </tr>
"@
    }

    $html += @"
        </table>

        <h3>Users Added</h3>
        <table>
            <tr>
                <th>Email</th>
                <th>Type</th>
                <th>Site</th>
                <th>Added At</th>
            </tr>
"@

    foreach ($user in $script:CreatedResources.Users) {
        $badge = if ($user.Type -eq "Guest") { "status-warning" } else { "status-success" }
        $html += @"
            <tr>
                <td>$($user.Email)</td>
                <td><span class="status-badge $badge">$($user.Type)</span></td>
                <td>$($user.SiteUrl)</td>
                <td>$($user.Timestamp.ToString("yyyy-MM-dd HH:mm:ss"))</td>
            </tr>
"@
    }

    $html += @"
        </table>

        <h2>Overall Status</h2>
        <div class="summary-box">
"@

    if ($Statistics.Errors -eq 0) {
        $html += '<span class="status-badge status-success">✓ COMPLETED SUCCESSFULLY</span>'
    }
    elseif ($Statistics.Errors -gt 0 -and $Statistics.SitesCreated -gt 0) {
        $html += '<span class="status-badge status-warning">⚠ COMPLETED WITH ERRORS</span>'
    }
    else {
        $html += '<span class="status-badge status-error">✗ FAILED</span>'
    }

    $html += @"
        </div>

        <div class="footer">
            Generated by M365 Cross-Tenant Collaboration Setup Script v2.0<br>
            $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        </div>
    </div>
</body>
</html>
"@

    try {
        $html | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-Log "HTML report generated: $OutputPath" -Level SUCCESS
        return $OutputPath
    }
    catch {
        Write-Log "Failed to generate HTML report: $_" -Level ERROR
        return $null
    }
}

function New-ExcelReport {
    param(
        [hashtable]$Statistics,
        [string]$OutputPath
    )

    Write-Log "Generating Excel report..." -Level INFO

    try {
        # Check if ImportExcel module is available
        if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
            Write-Log "ImportExcel module not found. Installing..." -Level WARNING
            Install-Module -Name ImportExcel -Scope CurrentUser -Force
        }

        Import-Module ImportExcel

        # Summary sheet
        $summaryData = [PSCustomObject]@{
            'Execution ID' = $script:ExecutionId
            'Start Time' = $script:StartTime.ToString("yyyy-MM-dd HH:mm:ss")
            'End Time' = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            'Duration' = ((Get-Date) - $script:StartTime).ToString("hh\:mm\:ss")
            'Host Tenant' = $HostTenantDomain
            'Guest Tenant' = $GuestTenantDomain
            'Sites Created' = $Statistics.SitesCreated
            'Folders Created' = $Statistics.FoldersCreated
            'Guests Invited' = $Statistics.GuestsInvited
            'Host Users Added' = $Statistics.HostUsersProcessed
            'Warnings' = $Statistics.Warnings
            'Errors' = $Statistics.Errors
        }

        # Sites sheet
        $sitesData = $script:CreatedResources.Sites | ForEach-Object {
            [PSCustomObject]@{
                'Title' = $_.Title
                'URL' = $_.Url
                'Created At' = $_.Timestamp.ToString("yyyy-MM-dd HH:mm:ss")
            }
        }

        # Users sheet
        $usersData = $script:CreatedResources.Users | ForEach-Object {
            [PSCustomObject]@{
                'Email' = $_.Email
                'Type' = $_.Type
                'Site URL' = $_.SiteUrl
                'Added At' = $_.Timestamp.ToString("yyyy-MM-dd HH:mm:ss")
            }
        }

        # Folders sheet
        $foldersData = $script:CreatedResources.Folders | ForEach-Object {
            [PSCustomObject]@{
                'Path' = $_.Path
                'Site URL' = $_.SiteUrl
                'Created At' = $_.Timestamp.ToString("yyyy-MM-dd HH:mm:ss")
            }
        }

        # Export to Excel with multiple sheets
        $summaryData | Export-Excel -Path $OutputPath -WorksheetName "Summary" -AutoSize -TableStyle Medium2

        if ($sitesData) {
            $sitesData | Export-Excel -Path $OutputPath -WorksheetName "Sites" -AutoSize -TableStyle Medium2 -Append
        }

        if ($usersData) {
            $usersData | Export-Excel -Path $OutputPath -WorksheetName "Users" -AutoSize -TableStyle Medium2 -Append
        }

        if ($foldersData) {
            $foldersData | Export-Excel -Path $OutputPath -WorksheetName "Folders" -AutoSize -TableStyle Medium2 -Append
        }

        Write-Log "Excel report generated: $OutputPath" -Level SUCCESS
        return $OutputPath
    }
    catch {
        Write-Log "Failed to generate Excel report: $_" -Level ERROR
        Write-Log "Error details: $($_.Exception.Message)" -Level ERROR
        return $null
    }
}

function Write-ExecutionSummary {
    param(
        [hashtable]$Statistics
    )

    $endTime = Get-Date
    $duration = $endTime - $script:StartTime

    $summary = @"

========================================================================================================
EXECUTION SUMMARY
========================================================================================================
Execution ID: $script:ExecutionId
Start Time: $script:StartTime
End Time: $endTime
Duration: $($duration.ToString("hh\:mm\:ss"))
--------------------------------------------------------------------------------------------------------
Statistics:
  - SharePoint Sites Created: $($Statistics.SitesCreated)
  - Client Folders Created: $($Statistics.FoldersCreated)
  - Guest Users Invited: $($Statistics.GuestsInvited)
  - Host Users Processed: $($Statistics.HostUsersProcessed)
  - Errors Encountered: $($Statistics.Errors)
  - Warnings: $($Statistics.Warnings)
--------------------------------------------------------------------------------------------------------
Resources Created:
  - Sites: $($script:CreatedResources.Sites.Count)
  - Users: $($script:CreatedResources.Users.Count)
  - Folders: $($script:CreatedResources.Folders.Count)
  - B2B Configurations: $($script:CreatedResources.B2BConfigs.Count)
--------------------------------------------------------------------------------------------------------
Rollback Information:
  - Rollback Enabled: $EnableRollback
  - Rollback Actions Registered: $($script:RollbackStack.Count)
========================================================================================================

"@

    Add-Content -Path $script:LogFile -Value $summary
    Write-Host $summary -ForegroundColor Cyan
}

#endregion

#region Email Notification Functions

function Send-CompletionEmail {
    param(
        [string]$RecipientEmail,
        [hashtable]$Statistics,
        [string]$HtmlReportPath = $null
    )

    Write-Log "Sending completion email to: $RecipientEmail" -Level INFO

    try {
        $endTime = Get-Date
        $duration = $endTime - $script:StartTime

        $status = if ($Statistics.Errors -eq 0) { "✓ SUCCESS" } elseif ($Statistics.SitesCreated -gt 0) { "⚠ COMPLETED WITH ERRORS" } else { "✗ FAILED" }
        $statusColor = if ($Statistics.Errors -eq 0) { "#107c10" } elseif ($Statistics.SitesCreated -gt 0) { "#ff8c00" } else { "#d13438" }

        $emailBody = @"
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: 'Segoe UI', Arial, sans-serif; }
        .container { max-width: 600px; margin: 0 auto; }
        .header { background-color: #0078d4; color: white; padding: 20px; text-align: center; }
        .content { padding: 20px; background-color: #f5f5f5; }
        .status-box { background-color: white; padding: 15px; margin: 10px 0; border-left: 4px solid $statusColor; }
        .stats { background-color: white; padding: 15px; margin: 10px 0; }
        .stat-item { padding: 8px; border-bottom: 1px solid #eee; }
        .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>M365 Cross-Tenant Setup Complete</h1>
        </div>
        <div class="content">
            <div class="status-box">
                <h2 style="color: $statusColor; margin: 0;">$status</h2>
                <p><strong>Execution ID:</strong> $($script:ExecutionId)</p>
                <p><strong>Duration:</strong> $($duration.ToString("hh\:mm\:ss"))</p>
            </div>

            <div class="stats">
                <h3>Execution Statistics</h3>
                <div class="stat-item"><strong>Sites Created:</strong> $($Statistics.SitesCreated)</div>
                <div class="stat-item"><strong>Folders Created:</strong> $($Statistics.FoldersCreated)</div>
                <div class="stat-item"><strong>Guests Invited:</strong> $($Statistics.GuestsInvited)</div>
                <div class="stat-item"><strong>Host Users Added:</strong> $($Statistics.HostUsersProcessed)</div>
                <div class="stat-item"><strong>Warnings:</strong> $($Statistics.Warnings)</div>
                <div class="stat-item"><strong>Errors:</strong> $($Statistics.Errors)</div>
            </div>

            <div class="stats">
                <h3>Configuration</h3>
                <div class="stat-item"><strong>Host Tenant:</strong> $HostTenantDomain</div>
                <div class="stat-item"><strong>Guest Tenant:</strong> $GuestTenantDomain</div>
                <div class="stat-item"><strong>SharePoint Site:</strong> $SharePointSiteTitle</div>
            </div>
        </div>
        <div class="footer">
            M365 Cross-Tenant Setup Script v2.0<br>
            $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        </div>
    </div>
</body>
</html>
"@

        $messageParams = @{
            Message = @{
                Subject = "M365 Cross-Tenant Setup Report - $status"
                Body = @{
                    ContentType = "HTML"
                    Content = $emailBody
                }
                ToRecipients = @(
                    @{
                        EmailAddress = @{
                            Address = $RecipientEmail
                        }
                    }
                )
            }
            SaveToSentItems = $true
        }

        # Add attachment if HTML report exists
        if ($HtmlReportPath -and (Test-Path $HtmlReportPath)) {
            $fileContent = [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($HtmlReportPath))
            $messageParams.Message.Attachments = @(
                @{
                    "@odata.type" = "#microsoft.graph.fileAttachment"
                    Name = "Setup-Report.html"
                    ContentBytes = $fileContent
                }
            )
        }

        # Send email using Microsoft Graph
        Send-MgUserMail -UserId $AdminEmail -BodyParameter $messageParams

        Write-Log "Completion email sent successfully to $RecipientEmail" -Level SUCCESS

        Write-M365AuditLog -Operation "EmailNotification" -Details "Sent completion email" -AdditionalData @{
            Recipient = $RecipientEmail
            Status = $status
        }

        return $true
    }
    catch {
        Write-Log "Failed to send completion email: $_" -Level ERROR
        Write-Log "Error details: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

#endregion

#region Main Execution

Write-Host @"
+--------------------------------------------------------------+
|   Microsoft 365 Cross-Tenant Collaboration Setup Script     |
|   Version: 2.0 - With Rollback, Reporting & Notifications   |
+--------------------------------------------------------------+
"@ -ForegroundColor Cyan

# Initialize logging
if (-not (Initialize-Logging -LogDirectory $LogPath)) {
    Write-Host "Failed to initialize logging. Continue? (Y/N)" -ForegroundColor Yellow
    $response = Read-Host
    if ($response -ne 'Y' -and $response -ne 'y') {
        exit 1
    }
}

Write-Log "Script execution started" -Level INFO
Write-Log "Execution ID: $script:ExecutionId" -Level INFO

if ($EnableRollback) {
    Write-Log "Rollback functionality ENABLED" -Level INFO
}

# Display configuration
Write-Log "Configuration:" -Level INFO
Write-Log "  Host Tenant: $HostTenantDomain" -Level INFO
Write-Log "  Guest Tenant: $GuestTenantDomain" -Level INFO
Write-Log "  SharePoint Site: $SharePointSiteTitle ($SharePointSiteAlias)" -Level INFO
Write-Log "  Admin Email: $AdminEmail" -Level INFO

if ($NotificationEmail) {
    Write-Log "  Notification Email: $NotificationEmail" -Level INFO
}

# Initialize statistics
$statistics = @{
    SitesCreated = 0
    FoldersCreated = 0
    GuestsInvited = 0
    HostUsersProcessed = 0
    Errors = 0
    Warnings = 0
}

$executionSuccess = $true

try {
    # Handle CSV import if provided
    $usersToProcess = @()
    if ($UsersCsvPath) {
        Write-Log "CSV path provided: $UsersCsvPath" -Level INFO
        $importedUsers = Import-UsersFromCsv -CsvPath $UsersCsvPath

        if ($importedUsers) {
            $usersToProcess = $importedUsers

            if ($ClientFolders.Count -eq 0) {
                $clientsFromCsv = $importedUsers | Where-Object { $_.ClientAccess } | ForEach-Object {
                    $_.ClientAccess -split ';'
                } | Select-Object -Unique

                if ($clientsFromCsv) {
                    $ClientFolders = $clientsFromCsv
                    Write-Log "Extracted $($ClientFolders.Count) unique client folders from CSV" -Level INFO
                }
            }
        }
        else {
            Write-Log "Failed to import users from CSV" -Level ERROR
            $statistics.Errors++
        }
    }
    else {
        if ($GuestUserEmails.Count -gt 0) {
            $usersToProcess = $GuestUserEmails | ForEach-Object {
                [PSCustomObject]@{
                    Email = $_
                    Tenant = "Guest"
                    Role = "Member"
                }
            }
        }
    }

    Write-Log "Users to process: $($usersToProcess.Count)" -Level INFO
    Write-Log "Client folders to create: $($ClientFolders.Count)" -Level INFO

    # Check modules
    if (-not (Test-RequiredModules)) {
        Write-Log "Missing required modules. Installation required." -Level ERROR
        $statistics.Errors++
        throw "Missing required modules"
    }

    # Connect to services
    if (-not (Connect-Services -TenantDomain $HostTenantDomain -AdminEmail $AdminEmail)) {
        Write-Log "Failed to connect to services." -Level ERROR
        $statistics.Errors++
        throw "Failed to connect to services"
    }

    # Configure B2B if not skipped
    if (-not $SkipB2BConfig) {
        Set-CrossTenantB2BAccess -GuestTenantDomain $GuestTenantDomain
    }
    else {
        Write-Log "Skipping B2B configuration (SkipB2BConfig flag set)" -Level WARNING
        $statistics.Warnings++
    }

    # Create SharePoint site if not skipped
    $siteUrl = $null
    if (-not $SkipSiteCreation) {
        $siteUrl = New-ClientSharePointSite -SiteTitle $SharePointSiteTitle -SiteAlias $SharePointSiteAlias -HostTenantDomain $HostTenantDomain

        if ($siteUrl) {
            $statistics.SitesCreated++

            # Create folder structure
            if ($ClientFolders.Count -gt 0) {
                $foldersCreated = New-ClientFolderStructure -SiteUrl $siteUrl -ClientFolders $ClientFolders
                $statistics.FoldersCreated = $foldersCreated
            }

            # Add users
            if ($usersToProcess.Count -gt 0) {
                $userStats = Add-UsersToSite -SiteUrl $siteUrl -Users $usersToProcess
                $statistics.GuestsInvited = $userStats.GuestsInvited
                $statistics.HostUsersProcessed = $userStats.HostUsersAdded
                $statistics.Errors += $userStats.Errors
            }
        }
        else {
            Write-Log "Site creation failed or was cancelled" -Level ERROR
            $statistics.Errors++
            throw "Site creation failed"
        }
    }
    else {
        Write-Log "Skipping site creation (SkipSiteCreation flag set)" -Level WARNING
        $statistics.Warnings++
    }
}
catch {
    Write-Log "Critical error during execution: $_" -Level ERROR
    $executionSuccess = $false

    if ($EnableRollback) {
        Write-Log "Initiating rollback due to error..." -Level WARNING
        Invoke-Rollback -Reason "Critical error: $_"
    }
}

# Write execution summary
Write-ExecutionSummary -Statistics $statistics

# Generate reports
$htmlReportPath = $null
$excelReportPath = $null

if ($GenerateHtmlReport) {
    $reportDir = Split-Path $script:LogFile
    $htmlReportPath = Join-Path $reportDir "Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
    $htmlReportPath = New-HtmlReport -Statistics $statistics -OutputPath $htmlReportPath
}

if ($GenerateExcelReport) {
    $reportDir = Split-Path $script:LogFile
    $excelReportPath = Join-Path $reportDir "Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').xlsx"
    $excelReportPath = New-ExcelReport -Statistics $statistics -OutputPath $excelReportPath
}

# Send email notification if requested
if ($NotificationEmail) {
    Send-CompletionEmail -RecipientEmail $NotificationEmail -Statistics $statistics -HtmlReportPath $htmlReportPath
}

# Display completion message
Write-Host "`n+--------------------------------------------------------------+" -ForegroundColor Green
Write-Host "|                    Setup Complete!                           |" -ForegroundColor Green
Write-Host "+--------------------------------------------------------------+" -ForegroundColor Green

if ($siteUrl) {
    Write-Host "`n📍 SharePoint Site URL:" -ForegroundColor Cyan
    Write-Host "   $siteUrl" -ForegroundColor White
}

Write-Host "`n📄 Log Files:" -ForegroundColor Cyan
Write-Host "   Main Log: $script:LogFile" -ForegroundColor White
$auditLog = Join-Path (Split-Path $script:LogFile) "Audit_$(Get-Date -Format 'yyyyMMdd').json"
if (Test-Path $auditLog) {
    Write-Host "   Audit Log: $auditLog" -ForegroundColor White
}

if ($htmlReportPath) {
    Write-Host "`n📊 HTML Report:" -ForegroundColor Cyan
    Write-Host "   $htmlReportPath" -ForegroundColor White
}

if ($excelReportPath) {
    Write-Host "`n📊 Excel Report:" -ForegroundColor Cyan
    Write-Host "   $excelReportPath" -ForegroundColor White
}

if ($EnableRollback) {
    Write-Host "`n🔄 Rollback Information:" -ForegroundColor Cyan
    Write-Host "   Rollback actions registered: $($script:RollbackStack.Count)" -ForegroundColor White
    if ($script:RollbackStack.Count -gt 0) {
        Write-Host "   Note: Rollback actions are available if needed" -ForegroundColor Yellow
    }
}

Write-Host "`n📝 Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Review log files for any errors or warnings" -ForegroundColor White
Write-Host "  2. Open HTML report for detailed summary" -ForegroundColor White
Write-Host "  3. Verify cross-tenant access in Azure AD Portal" -ForegroundColor White
Write-Host "  4. Check guest user invitations were sent" -ForegroundColor White
Write-Host "  5. Test access from guest tenant accounts" -ForegroundColor White

Write-M365AuditLog -Operation "ScriptCompletion" -Details "Script execution completed" -AdditionalData $statistics

#endregion
