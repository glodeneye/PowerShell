# Microsoft 365 Cross-Tenant Collaboration Setup

Comprehensive automation for B2B collaboration between two Microsoft 365 tenants with advanced features including rollback, reporting, and email notifications.

## ✨ Features

- 🔐 **Automated Setup**: Configure Azure AD B2B cross-tenant access
- 📂 **SharePoint Integration**: Create team sites with organized folder structures
- 👥 **User Management**: Import users from CSV, invite guests, manage permissions
- 📝 **Comprehensive Logging**: Text logs, JSON audit trails, execution tracking
- 🔄 **Rollback Capability**: Automatic or manual rollback on errors
- 📊 **Rich Reporting**: HTML and Excel reports with detailed statistics
- 📧 **Email Notifications**: Automated completion notifications with attachments
- ⚠️ **Error Handling**: Graceful error recovery with detailed logging

## 📋 Prerequisites

- PowerShell 7.x or higher
- Microsoft.Graph PowerShell module
- PnP.PowerShell module
- ImportExcel module (for Excel reports)
- Global Administrator or appropriate admin roles in host tenant

## 🚀 Installation

```powershell
# Install required modules
Install-Module -Name Microsoft.Graph -Scope CurrentUser
Install-Module -Name PnP.PowerShell -Scope CurrentUser
Install-Module -Name ImportExcel -Scope CurrentUser  # Optional, for Excel reports
```

## 🎯 Quick Start

> **📘 New User?** Check out our comprehensive [Getting Started Guide](GETTING-STARTED.md) for step-by-step instructions!

### Option 1: Dry-Run Test (Recommended First Step)

```powershell
# Always test first with -WhatIf to see what will happen
.\Setup-CrossTenantCollaboration.ps1 `
    -HostTenantDomain "compliancerisk.io" `
    -GuestTenantDomain "pelican3.net" `
    -SharePointSiteTitle "Client Projects" `
    -SharePointSiteAlias "ClientProjects" `
    -UsersCsvPath ".\users.csv" `
    -AdminEmail "admin@compliancescorecard.com" `
    -WhatIf
```

### Option 2: Basic Setup with Rollback Protection

```powershell
.\Setup-CrossTenantCollaboration.ps1 `
    -HostTenantDomain "compliancerisk.io" `
    -GuestTenantDomain "pelican3.net" `
    -SharePointSiteTitle "Client Projects" `
    -SharePointSiteAlias "ClientProjects" `
    -ClientFolders @("Client A", "Client B") `
    -GuestUserEmails @("user1@pelican3.net") `
    -AdminEmail "admin@compliancescorecard.com" `
    -EnableRollback
```

### Option 2: Full Featured Setup

```powershell
.\Setup-CrossTenantCollaboration.ps1 `
    -HostTenantDomain "compliancerisk.io" `
    -GuestTenantDomain "pelican3.net" `
    -SharePointSiteTitle "Client Projects" `
    -SharePointSiteAlias "ClientProjects" `
    -UsersCsvPath ".\users.csv" `
    -AdminEmail "admin@compliancescorecard.com" `
    -NotificationEmail "admin@compliancescorecard.com" `
    -EnableRollback `
    -GenerateHtmlReport `
    -GenerateExcelReport
```

### Option 3: Using CSV Template

1. Generate template:
```powershell
.\New-UserTemplate.ps1 -OutputPath ".\my-users.csv"
```

2. Edit the CSV file

3. Run setup:
```powershell
.\Setup-CrossTenantCollaboration.ps1 `
    -HostTenantDomain "compliancerisk.io" `
    -GuestTenantDomain "pelican3.net" `
    -SharePointSiteTitle "Client Projects" `
    -SharePointSiteAlias "ClientProjects" `
    -UsersCsvPath ".\my-users.csv" `
    -AdminEmail "admin@compliancescorecard.com" `
    -EnableRollback
```

## 📊 Reporting

### HTML Report
Generates a comprehensive HTML report with:
- Execution summary and statistics
- Status indicators (success/warning/error)
- Created resources table
- User additions tracking
- Visual dashboard

### Excel Report
Creates a multi-sheet Excel workbook:
- **Summary**: Overall statistics and metadata
- **Sites**: All SharePoint sites created
- **Users**: All users added (host and guest)
- **Folders**: All folders created

## 🔄 Rollback Functionality

### Automatic Rollback
Enable with `-EnableRollback` flag. Automatically rolls back changes if critical errors occur.

```powershell
# Script will automatically rollback on errors
.\Setup-CrossTenantCollaboration.ps1 `
    -HostTenantDomain "compliancerisk.io" `
    ... `
    -EnableRollback
```

### Manual Rollback
Use the manual rollback script to undo changes from a previous execution:

```powershell
# See what would be rolled back
.\Invoke-ManualRollback.ps1 `
    -AuditLogPath ".\Logs\Audit_20241022.json" `
    -WhatIf

# Actually perform rollback
.\Invoke-ManualRollback.ps1 `
    -AuditLogPath ".\Logs\Audit_20241022.json" `
    -ExecutionId "your-execution-id"
```

## 📧 Email Notifications

Automatically send completion emails with:
- Execution status and statistics
- HTML report attachment
- Color-coded status indicators
- Direct links to resources

```powershell
.\Setup-CrossTenantCollaboration.ps1 `
    ... `
    -NotificationEmail "team@compliancescorecard.com" `
    -GenerateHtmlReport
```

## 📁 File Structure

```
your-repo/
+-- Setup-CrossTenantCollaboration.ps1  # Main setup script
+-- Invoke-ManualRollback.ps1           # Manual rollback script
+-- New-UserTemplate.ps1                # CSV template generator
+-- users.csv                           # User list (your data)
+-- config.example.json                 # Configuration example
+-- README.md                           # This file
+-- Logs/                               # Generated logs
    +-- CrossTenantSetup_YYYYMMDD_HHMMSS.log
    +-- Audit_YYYYMMDD.json
    +-- Report_YYYYMMDD_HHMMSS.html
    +-- Report_YYYYMMDD_HHMMSS.xlsx
```

## 📄 CSV Format

| Column | Required | Description | Example |
|--------|----------|-------------|---------|
| Email | Yes | User's email address | user@domain.com |
| Tenant | Yes | Host or Guest | Host, Guest |
| Role | Yes | Permission level | Owner, Member, Visitor |
| DisplayName | No | Display name | John Doe |
| Department | No | Department name | Compliance |
| ClientAccess | No | Client folders (semicolon-separated) | Client A;Client B |

## ⚙️ Parameters Reference

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| HostTenantDomain | Yes | - | Primary tenant domain |
| GuestTenantDomain | Yes | - | Secondary tenant domain |
| SharePointSiteTitle | Yes | - | Display name for site |
| SharePointSiteAlias | Yes | - | URL-friendly alias |
| ClientFolders | No | @() | Array of client folders |
| GuestUserEmails | No | @() | Array of guest emails |
| AdminEmail | Yes | - | Admin email address |
| UsersCsvPath | No | - | Path to users CSV |
| LogPath | No | .\Logs | Log directory path |
| NotificationEmail | No | - | Email for notifications |
| EnableRollback | No | false | Enable auto-rollback |
| GenerateHtmlReport | No | false | Generate HTML report |
| GenerateExcelReport | No | false | Generate Excel report |
| SkipB2BConfig | No | false | Skip B2B configuration |
| SkipSiteCreation | No | false | Skip site creation |
| WhatIf | No | false | Dry-run mode (show actions without executing) |

## 📝 Logging Details

### Log Levels
- **INFO**: General information
- **SUCCESS**: Successful operations
- **WARNING**: Non-critical issues
- **ERROR**: Failed operations
- **DEBUG**: Detailed debugging info
- **ROLLBACK**: Rollback operations

### Audit Log Structure
```json
{
  "ExecutionId": "unique-guid",
  "Timestamp": "2024-10-22T10:30:00Z",
  "Operation": "SiteCreation",
  "HostTenant": "compliancerisk.io",
  "GuestTenant": "pelican3.net",
  "AdminUser": "admin@compliancescorecard.com",
  "Details": "Created SharePoint site: Client Projects",
  "Status": "Completed",
  "SiteUrl": "https://..."
}
```

## 🔧 Troubleshooting

### Common Issues

1. **Module Not Found**
   ```powershell
   Install-Module -Name Microsoft.Graph -Scope CurrentUser -Force
   Install-Module -Name PnP.PowerShell -Scope CurrentUser -Force
   ```

2. **Permission Denied**
   - Ensure Global Administrator rights
   - Check required Graph API permissions

3. **Rollback Fails**
   - Check audit log for execution ID
   - Use manual rollback script
   - Verify permissions

4. **Email Not Sent**
   - Verify Mail.Send permission
   - Check admin email is correct
   - Review error logs

## 💡 Examples

### Create Multiple Client Folders
```powershell
$clients = @("ACME Corp", "TechStart Inc", "Global Finance")

.\Setup-CrossTenantCollaboration.ps1 `
    -HostTenantDomain "compliancerisk.io" `
    -GuestTenantDomain "pelican3.net" `
    -SharePointSiteTitle "Q4 2024 Projects" `
    -SharePointSiteAlias "Q4Projects" `
    -ClientFolders $clients `
    -AdminEmail "admin@compliancescorecard.com" `
    -EnableRollback `
    -GenerateHtmlReport
```

### Import 20+ Users
```powershell
# Use CSV for bulk import
.\Setup-CrossTenantCollaboration.ps1 `
    -HostTenantDomain "compliancerisk.io" `
    -GuestTenantDomain "pelican3.net" `
    -SharePointSiteTitle "Enterprise Collaboration" `
    -SharePointSiteAlias "Enterprise" `
    -UsersCsvPath ".\all-users.csv" `
    -AdminEmail "admin@compliancescorecard.com" `
    -NotificationEmail "it-team@compliancescorecard.com" `
    -EnableRollback `
    -GenerateExcelReport
```

## 🤝 Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Test thoroughly
4. Submit a pull request

## 📄 License

MIT License - Free to use and modify

## 👥 Authors

ComplianceRisk.io Team

## 🆘 Support

- GitHub Issues: [Report a bug](https://github.com/goldeneye/PowerShell/issues)
- Documentation: Review log files and audit trails
- Community: Discussions and Q&A

## 🔒 Security Notes

- Logs may contain sensitive information - store securely
- Review guest permissions regularly
- Monitor audit logs for unauthorized access
- Use least-privilege principles
- Rotate admin credentials periodically

## 🗺️ Roadmap

- [ ] Azure DevOps pipeline integration
- [ ] GitHub Actions workflow
- [ ] Slack notifications
- [ ] Teams integration
- [ ] Advanced permission templates
- [ ] Scheduled sync capabilities

---

**Version**: 2.0
**Last Updated**: October 2024
**Maintained by**: [ComplianceRisk.io](https://github.com/goldeneye)
