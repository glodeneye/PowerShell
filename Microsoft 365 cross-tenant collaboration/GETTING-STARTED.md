# Getting Started - M365 Cross-Tenant Collaboration Setup

This guide will walk you through setting up cross-tenant collaboration between two Microsoft 365 tenants step-by-step.

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Initial Setup](#initial-setup)
3. [Dry-Run Test](#dry-run-test)
4. [Full Execution](#full-execution)
5. [Verification](#verification)
6. [Rollback (if needed)](#rollback-if-needed)
7. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Information

Before you begin, gather the following information:

- **Host Tenant Domain**: e.g., `your-company.com`
- **Guest Tenant Domain**: e.g., `partner-company.com`
- **Admin Email**: Your Global Administrator email (e.g., `admin@your-company.com`)
- **SharePoint Site Name**: Desired site title (e.g., `Client Projects`)
- **Site Alias**: URL-friendly name (e.g., `ClientProjects`)
- **Client Names**: List of client folders to create (e.g., `Client A`, `Client B`)
- **User List**: Either CSV file or individual email addresses

### Required Permissions

Your admin account needs:
- ✅ **Global Administrator** OR
- ✅ **SharePoint Administrator** + **User Administrator** + **Application Administrator**

### Required PowerShell Modules

**Step 1:** Open PowerShell 7+ as Administrator

```powershell
# Check PowerShell version (must be 7.0 or higher)
$PSVersionTable.PSVersion
```

**Step 2:** Install required modules

```powershell
# Install Microsoft Graph module
Install-Module -Name Microsoft.Graph -Scope CurrentUser -Force

# Install PnP PowerShell module
Install-Module -Name PnP.PowerShell -Scope CurrentUser -Force

# Install ImportExcel module (optional, for Excel reports)
Install-Module -Name ImportExcel -Scope CurrentUser -Force
```

**Step 3:** Verify installation

```powershell
Get-Module -ListAvailable -Name Microsoft.Graph, PnP.PowerShell, ImportExcel
```

---

## Initial Setup

### Option A: Using CSV for Bulk Users (Recommended)

**Step 1:** Generate a CSV template

```powershell
cd "E:\github\PowerShell\Microsoft 365 cross-tenant collaboration"
.\New-UserTemplate.ps1 -OutputPath ".\my-users.csv"
```

**Step 2:** Edit the CSV file

Open `my-users.csv` in Excel or your favorite editor and fill in your users:

| Email | Tenant | Role | DisplayName | Department | ClientAccess |
|-------|--------|------|-------------|------------|--------------|
| admin@your-company.com | Host | Owner | Admin User | IT | |
| john@your-company.com | Host | Member | John Doe | Compliance | Client A;Client B |
| jane@partner-company.com | Guest | Member | Jane Smith | Consulting | Client A |

**Column Definitions:**
- **Email** (Required): User's email address
- **Tenant** (Required): `Host` or `Guest`
- **Role** (Required): `Owner`, `Member`, or `Visitor`
- **DisplayName** (Optional): User's full name
- **Department** (Optional): User's department
- **ClientAccess** (Optional): Semicolon-separated list of client folders they can access

**Step 3:** Save the CSV file

Save as UTF-8 CSV format.

### Option B: Using PowerShell Arrays (Simple Setup)

If you have just a few users, you can specify them directly:

```powershell
$clientFolders = @("Client A", "Client B", "Client C")
$guestEmails = @("user1@partner-company.com", "user2@partner-company.com")
```

---

## Dry-Run Test

**IMPORTANT:** Always run a dry-run first to see what will happen without making changes!

### Step 1: Run with -WhatIf Parameter

```powershell
cd "E:\github\PowerShell\Microsoft 365 cross-tenant collaboration"

.\Setup-CrossTenantCollaboration.ps1 `
    -HostTenantDomain "your-company.com" `
    -GuestTenantDomain "partner-company.com" `
    -SharePointSiteTitle "Client Projects" `
    -SharePointSiteAlias "ClientProjects" `
    -UsersCsvPath ".\my-users.csv" `
    -AdminEmail "admin@your-company.com" `
    -WhatIf
```

### Step 2: Review Dry-Run Output

You'll see output like:

```
What if: Performing the operation "Configure cross-tenant access" on target "B2B Policy for partner-company.com (Tenant ID: xxx-xxx-xxx)".
What if: Performing the operation "Create team site" on target "SharePoint site: Client Projects at https://...".
What if: Performing the operation "Create folders" on target "Folder structure for client: Client A".
What if: Performing the operation "Send invitation with role Edit" on target "Guest user: jane@partner-company.com".
```

### Step 3: Verify Everything Looks Correct

Check that:
- ✅ Correct tenant domains
- ✅ Correct SharePoint site name and URL
- ✅ All expected users listed
- ✅ All expected client folders listed
- ✅ No unexpected changes

---

## Full Execution

### Basic Execution (No Rollback)

**WARNING:** This will make real changes to your M365 environment!

```powershell
.\Setup-CrossTenantCollaboration.ps1 `
    -HostTenantDomain "your-company.com" `
    -GuestTenantDomain "partner-company.com" `
    -SharePointSiteTitle "Client Projects" `
    -SharePointSiteAlias "ClientProjects" `
    -UsersCsvPath ".\my-users.csv" `
    -AdminEmail "admin@your-company.com"
```

### Recommended Execution (With Rollback & Reporting)

```powershell
.\Setup-CrossTenantCollaboration.ps1 `
    -HostTenantDomain "your-company.com" `
    -GuestTenantDomain "partner-company.com" `
    -SharePointSiteTitle "Client Projects" `
    -SharePointSiteAlias "ClientProjects" `
    -UsersCsvPath ".\my-users.csv" `
    -AdminEmail "admin@your-company.com" `
    -EnableRollback `
    -GenerateHtmlReport `
    -GenerateExcelReport `
    -NotificationEmail "admin@your-company.com"
```

### What Happens During Execution

**Phase 1: Authentication (MFA-Enabled)**

1. Browser window opens for Microsoft Graph authentication
2. Sign in with your admin account
3. Complete MFA if required
4. Grant requested permissions
5. Browser window opens for SharePoint authentication
6. Sign in again (may auto-authenticate)

**Phase 2: Configuration**

1. ✓ Validates PowerShell modules
2. ✓ Imports users from CSV
3. ✓ Connects to Microsoft Graph
4. ✓ Connects to SharePoint Online

**Phase 3: B2B Setup**

1. ✓ Looks up guest tenant ID
2. ✓ Configures cross-tenant access policy
3. ✓ Allows all users from guest tenant
4. ✓ Enables Office365 applications

**Phase 4: SharePoint Site Creation**

1. ✓ Creates Team Site with specified name
2. ✓ Waits for provisioning (15 seconds)
3. ✓ Connects to new site

**Phase 5: Folder Structure**

1. ✓ Creates "Clients" parent folder
2. ✓ For each client creates:
   - Client Name folder
   - Documents subfolder
   - Deliverables subfolder
   - Working Files subfolder

**Phase 6: User Management**

1. ✓ Processes each user from CSV
2. ✓ For guest users: Sends invitation email
3. ✓ For host users: Grants permissions
4. ✓ Applies specified roles (Owner/Member/Visitor)

**Phase 7: Reporting & Notifications**

1. ✓ Generates HTML report with statistics
2. ✓ Generates Excel workbook with multiple sheets
3. ✓ Sends email notification with report attached
4. ✓ Displays summary on screen

### Execution Time

Typical execution time:
- **Small setup** (1 site, 5 users, 3 clients): 3-5 minutes
- **Medium setup** (1 site, 20 users, 10 clients): 8-12 minutes
- **Large setup** (1 site, 50+ users, 20+ clients): 15-25 minutes

---

## Verification

### Step 1: Check Log Files

Navigate to the Logs directory:

```powershell
cd ".\Logs"
Get-ChildItem | Sort-Object LastWriteTime -Descending | Select-Object -First 5
```

**Log Files Created:**
- `CrossTenantSetup_YYYYMMDD_HHMMSS.log` - Detailed text log
- `Audit_YYYYMMDD.json` - JSON audit trail
- `Report_YYYYMMDD_HHMMSS.html` - HTML report
- `Report_YYYYMMDD_HHMMSS.xlsx` - Excel report

**Review the main log:**

```powershell
Get-Content ".\Logs\CrossTenantSetup_*.log" -Tail 50
```

Look for:
- ✅ `[SUCCESS]` entries for each operation
- ⚠️ `[WARNING]` entries (note but may be okay)
- ❌ `[ERROR]` entries (need attention)

### Step 2: Open HTML Report

Double-click the HTML report to open in your browser. Review:

- **Execution Statistics**: Sites, folders, users created
- **Status Badge**: Should show "✓ COMPLETED SUCCESSFULLY"
- **Created Resources Table**: Verify all sites and users listed
- **Errors/Warnings Count**: Should be 0 or minimal

### Step 3: Verify in Azure AD Portal

**Check B2B Configuration:**

1. Go to [Azure AD Portal](https://portal.azure.com)
2. Navigate to **Azure Active Directory** → **External Identities** → **Cross-tenant access settings**
3. Verify guest tenant appears in the list
4. Click on tenant → **B2B collaboration** → **Inbound access**
5. Confirm "Allow all users" is enabled

**Check Guest Users:**

1. Navigate to **Azure Active Directory** → **Users** → **All users**
2. Filter by **User type** = **Guest**
3. Verify guest users from partner-company.com are listed
4. Check **Invitation state** = **PendingAcceptance** or **Accepted**

### Step 4: Verify in SharePoint

**Check Site Creation:**

1. Go to SharePoint Admin Center: `https://[tenant]-admin.sharepoint.com`
2. Navigate to **Sites** → **Active sites**
3. Find your site (e.g., "Client Projects")
4. Verify **URL**, **Template** (Team site), **Status** (Active)

**Check Folder Structure:**

1. Navigate to the SharePoint site: `https://[tenant].sharepoint.com/sites/ClientProjects`
2. Go to **Documents** → **Clients**
3. Verify all client folders exist
4. Click into a client folder
5. Verify subfolders: Documents, Deliverables, Working Files

**Check Permissions:**

1. In the SharePoint site, click **⚙️ Settings** → **Site permissions**
2. Verify:
   - Host users appear with correct roles
   - "External Users" group exists (for guests)
3. Click **Documents** → **Clients** → [Client folder]
4. Check who has access

### Step 5: Test Guest Access

**As a Guest User:**

1. Check email for invitation from Microsoft
2. Click **Accept invitation**
3. Sign in with guest account credentials
4. Navigate to the shared site
5. Try accessing assigned client folders
6. Verify can view/edit based on role

### Step 6: Review Audit Log

For compliance, review the JSON audit log:

```powershell
# View audit entries
Get-Content ".\Logs\Audit_*.json" | ConvertFrom-Json | Format-Table -AutoSize

# Filter to specific operation
Get-Content ".\Logs\Audit_*.json" | ConvertFrom-Json | Where-Object { $_.Operation -eq "GuestInvitation" }
```

---

## Rollback (if needed)

### Automatic Rollback

If you used `-EnableRollback` and an error occurred, rollback happens automatically.

Check the log for:
```
[ROLLBACK] INITIATING ROLLBACK PROCEDURE
[ROLLBACK] Rolling back: [operation]
[ROLLBACK] ROLLBACK COMPLETED
```

### Manual Rollback

If you need to undo changes after successful execution:

**Step 1: Find Execution ID**

```powershell
# List recent executions
Get-Content ".\Logs\Audit_*.json" | ConvertFrom-Json | Select-Object ExecutionId, Timestamp -Unique
```

**Step 2: Dry-Run Rollback (WhatIf)**

```powershell
.\Invoke-ManualRollback.ps1 `
    -AuditLogPath ".\Logs\Audit_20241022.json" `
    -ExecutionId "your-execution-id-here" `
    -WhatIf
```

**Step 3: Execute Rollback**

```powershell
.\Invoke-ManualRollback.ps1 `
    -AuditLogPath ".\Logs\Audit_20241022.json" `
    -ExecutionId "your-execution-id-here"
```

Type `YES` when prompted to confirm.

**What Gets Rolled Back:**
- ✓ All guest users removed from site
- ✓ SharePoint site deleted (moved to recycle bin)
- ✓ B2B configuration removed
- ✓ Host user permissions reverted

**What Does NOT Get Rolled Back:**
- ❌ Folders (deleted with site)
- ❌ Email invitations already sent (users can still accept)
- ❌ Log files and reports

---

## Troubleshooting

### Issue: "Module not found"

**Error:**
```
✗ Microsoft.Graph is not installed
```

**Solution:**
```powershell
Install-Module -Name Microsoft.Graph -Scope CurrentUser -Force
```

### Issue: "Permission Denied"

**Error:**
```
Error connecting to services: Insufficient privileges
```

**Solution:**
- Verify you have Global Administrator role
- Or ensure you have SharePoint Administrator + User Administrator
- Check in Azure AD Portal → Roles and administrators

### Issue: "Failed to connect to SharePoint"

**Error:**
```
Error connecting to services: Could not connect to SharePoint
```

**Solution:**
```powershell
# Disconnect and reconnect
Disconnect-PnPOnline
Connect-PnPOnline -Url "https://[tenant]-admin.sharepoint.com" -Interactive
```

### Issue: "Site already exists"

**Warning:**
```
Site already exists at https://[tenant].sharepoint.com/sites/ClientProjects
```

**Solution:**
- Choose a different `SharePointSiteAlias`
- Or type `Y` when prompted to use existing site
- Or delete the existing site first

### Issue: "Guest invitation failed"

**Error:**
```
Error processing user user@partner-company.com: Invitation failed
```

**Possible Causes & Solutions:**

1. **External sharing disabled:**
   - Go to SharePoint Admin Center → Policies → Sharing
   - Set to "Anyone" or "New and existing guests"

2. **Domain blocked:**
   - Go to Azure AD → External Identities → External collaboration settings
   - Check **Collaboration restrictions**
   - Remove guest domain from blocklist

3. **User already exists:**
   - Check if user is already a guest
   - If so, skip invitation or remove and re-add

### Issue: "Email notification not sent"

**Error:**
```
Failed to send completion email
```

**Solution:**
```powershell
# Check Graph permissions
Connect-MgGraph -Scopes "Mail.Send"

# Verify admin email is correct
Get-MgUser -UserId "admin@your-company.com"
```

### Issue: "Excel report generation failed"

**Error:**
```
Failed to generate Excel report: ImportExcel module not found
```

**Solution:**
```powershell
Install-Module -Name ImportExcel -Scope CurrentUser -Force
```

### Issue: "MFA Authentication Timeout"

**Error:**
```
Error connecting to services: Timeout waiting for authentication
```

**Solution:**
- Complete MFA promptly when browser opens
- If browser doesn't open, check popup blockers
- Try using device code flow:
  ```powershell
  Connect-MgGraph -Scopes "User.ReadWrite.All" -UseDeviceCode
  ```

### Issue: "Rollback Failed"

**Error:**
```
Failed to delete site: Access denied
```

**Solution:**
- Ensure you're still authenticated
- Reconnect with admin credentials
- Check site isn't locked or under retention policy
- Contact SharePoint admin if site is protected

---

## Next Steps

After successful setup:

1. **✅ Document Configuration**
   - Save execution ID
   - Archive HTML/Excel reports
   - Document any customizations

2. **✅ Train Users**
   - Show guest users how to access
   - Demonstrate folder structure
   - Explain permission levels

3. **✅ Monitor Activity**
   - Review SharePoint site analytics
   - Check guest user access logs
   - Monitor for suspicious activity

4. **✅ Regular Maintenance**
   - Review guest permissions monthly
   - Remove inactive guests
   - Update client folders as needed
   - Archive old audit logs

5. **✅ Set Up Alerts**
   - Configure SharePoint alerts for new files
   - Set up Azure AD alerts for guest sign-ins
   - Monitor B2B policy changes

---

## Additional Resources

- **Script Documentation**: See [README.md](README.md)
- **Microsoft Docs**: [B2B Collaboration](https://docs.microsoft.com/azure/active-directory/external-identities/)
- **SharePoint Docs**: [Team Sites](https://docs.microsoft.com/sharepoint/team-sites)
- **Issues**: [GitHub Issues](https://github.com/goldeneye/PowerShell/issues)

---

**Need Help?**

- Review the logs first
- Check troubleshooting section above
- Search existing GitHub issues
- Create new issue with logs attached

**Happy Collaborating! 🚀**
