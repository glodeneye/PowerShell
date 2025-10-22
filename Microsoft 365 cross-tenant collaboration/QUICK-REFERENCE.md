# Quick Reference Card - M365 Cross-Tenant Setup

## 🚀 Quick Start Commands

### 1. Check Prerequisites
```powershell
.\Test-Prerequisites.ps1
```

### 2. Generate CSV Template
```powershell
.\New-UserTemplate.ps1 -OutputPath ".\my-users.csv"
```

### 3. Dry-Run (ALWAYS DO THIS FIRST!)
```powershell
.\Setup-CrossTenantCollaboration.ps1 `
    -HostTenantDomain "compliancerisk.io" `
    -GuestTenantDomain "pelican3.net" `
    -SharePointSiteTitle "Client Projects" `
    -SharePointSiteAlias "ClientProjects" `
    -UsersCsvPath ".\my-users.csv" `
    -AdminEmail "admin@compliancescorecard.com" `
    -WhatIf
```

### 4. Execute (Production Run)
```powershell
.\Setup-CrossTenantCollaboration.ps1 `
    -HostTenantDomain "compliancerisk.io" `
    -GuestTenantDomain "pelican3.net" `
    -SharePointSiteTitle "Client Projects" `
    -SharePointSiteAlias "ClientProjects" `
    -UsersCsvPath ".\my-users.csv" `
    -AdminEmail "admin@compliancescorecard.com" `
    -EnableRollback `
    -GenerateHtmlReport `
    -GenerateExcelReport
```

### 5. Using Config File (Easier!)
```powershell
# Setup
Copy-Item config.example.json config.json
# Edit config.json, then run:
.\Run-WithConfig.ps1
```

---

## 📊 Parameter Quick Reference

| Parameter | Required | Example | Notes |
|-----------|----------|---------|-------|
| `-HostTenantDomain` | ✅ | `compliancerisk.io` | Your primary tenant |
| `-GuestTenantDomain` | ✅ | `pelican3.net` | Partner tenant |
| `-SharePointSiteTitle` | ✅ | `"Client Projects"` | Display name |
| `-SharePointSiteAlias` | ✅ | `ClientProjects` | URL part (no spaces) |
| `-AdminEmail` | ✅ | `admin@domain.com` | Your admin account |
| `-UsersCsvPath` | ❌ | `".\users.csv"` | Bulk user import |
| `-ClientFolders` | ❌ | `@("A", "B")` | Client folder names |
| `-GuestUserEmails` | ❌ | `@("u@domain.com")` | Individual guests |
| `-EnableRollback` | ❌ | Switch | Auto-undo on errors |
| `-GenerateHtmlReport` | ❌ | Switch | Pretty HTML report |
| `-GenerateExcelReport` | ❌ | Switch | Excel workbook |
| `-NotificationEmail` | ❌ | `team@domain.com` | Send report via email |
| `-WhatIf` | ❌ | Switch | **DRY-RUN MODE** |

---

## 📝 CSV Format

```csv
Email,Tenant,Role,DisplayName,Department,ClientAccess
admin@compliancerisk.io,Host,Owner,Admin,IT,
john@compliancerisk.io,Host,Member,John Doe,Compliance,"Client A;Client B"
jane@pelican3.net,Guest,Member,Jane Smith,Ops,Client A
```

**Roles:** `Owner`, `Member`, `Visitor`
**Tenants:** `Host`, `Guest`
**ClientAccess:** Semicolon-separated: `"Client A;Client B;Client C"`

---

## 🔄 Rollback Commands

### View Execution History
```powershell
Get-Content ".\Logs\Audit_*.json" | ConvertFrom-Json | Select ExecutionId, Timestamp -Unique
```

### Dry-Run Rollback
```powershell
.\Invoke-ManualRollback.ps1 `
    -AuditLogPath ".\Logs\Audit_20241022.json" `
    -ExecutionId "your-id-here" `
    -WhatIf
```

### Execute Rollback
```powershell
.\Invoke-ManualRollback.ps1 `
    -AuditLogPath ".\Logs\Audit_20241022.json" `
    -ExecutionId "your-id-here"
# Type YES to confirm
```

---

## 🔍 Troubleshooting One-Liners

### Check Recent Logs
```powershell
Get-ChildItem .\Logs\*.log | Sort LastWriteTime -Desc | Select -First 1 | Get-Content -Tail 50
```

### View Errors Only
```powershell
Get-Content ".\Logs\CrossTenantSetup_*.log" | Select-String "\[ERROR\]"
```

### Check What Was Created
```powershell
Get-Content ".\Logs\Audit_*.json" | ConvertFrom-Json | Select Operation, Details | Format-Table
```

### Test Graph Connection
```powershell
Connect-MgGraph -Scopes "User.Read.All"
Get-MgContext
```

### Test SharePoint Connection
```powershell
Connect-PnPOnline -Url "https://compliancerisk-admin.sharepoint.com" -Interactive
Get-PnPTenantSite
```

---

## 📦 Module Installation

```powershell
# All at once
Install-Module Microsoft.Graph, PnP.PowerShell, ImportExcel -Scope CurrentUser -Force

# Update existing
Update-Module Microsoft.Graph, PnP.PowerShell, ImportExcel

# Check versions
Get-Module -ListAvailable Microsoft.Graph, PnP.PowerShell, ImportExcel
```

---

## 🎯 Common Scenarios

### Scenario 1: Quick Test with 2 Users
```powershell
.\Setup-CrossTenantCollaboration.ps1 `
    -HostTenantDomain "compliancerisk.io" `
    -GuestTenantDomain "pelican3.net" `
    -SharePointSiteTitle "Test Site" `
    -SharePointSiteAlias "TestSite" `
    -ClientFolders @("Test Client") `
    -GuestUserEmails @("user@pelican3.net") `
    -AdminEmail "admin@compliancescorecard.com" `
    -WhatIf
```

### Scenario 2: Bulk Import 50+ Users
```powershell
# Create config
Copy-Item config.example.json config.json
# Edit config.json with all settings
.\Run-WithConfig.ps1 -WhatIf
# If looks good:
.\Run-WithConfig.ps1
```

### Scenario 3: Re-run Without B2B Config
```powershell
.\Setup-CrossTenantCollaboration.ps1 `
    -HostTenantDomain "compliancerisk.io" `
    -GuestTenantDomain "pelican3.net" `
    -SharePointSiteTitle "Projects" `
    -SharePointSiteAlias "Projects" `
    -UsersCsvPath ".\users.csv" `
    -AdminEmail "admin@compliancescorecard.com" `
    -SkipB2BConfig
```

### Scenario 4: Just Add Users (Site Exists)
```powershell
.\Setup-CrossTenantCollaboration.ps1 `
    -HostTenantDomain "compliancerisk.io" `
    -GuestTenantDomain "pelican3.net" `
    -SharePointSiteTitle "Existing Site" `
    -SharePointSiteAlias "ExistingSite" `
    -UsersCsvPath ".\new-users.csv" `
    -AdminEmail "admin@compliancescorecard.com" `
    -SkipB2BConfig `
    -SkipSiteCreation
```

---

## 🔐 Permissions Required

**Minimum Required:**
- Global Administrator OR
- SharePoint Administrator + User Administrator + Application Administrator

**Graph API Scopes:**
- `User.ReadWrite.All`
- `Directory.ReadWrite.All`
- `Policy.ReadWrite.CrossTenantAccess`
- `Mail.Send` (for notifications)

---

## 📂 Generated Files

```
Logs/
├── CrossTenantSetup_20241022_143022.log    # Main log
├── Audit_20241022.json                      # JSON audit trail
├── Report_20241022_143022.html              # Pretty report
└── Report_20241022_143022.xlsx              # Excel report
```

---

## ⚡ Pro Tips

1. **Always use `-WhatIf` first** - See what will happen
2. **Enable rollback in production** - Safety net with `-EnableRollback`
3. **Generate HTML reports** - Great for documentation
4. **Use config files** - Easier than typing parameters
5. **Test prerequisites first** - Run `.\Test-Prerequisites.ps1`
6. **Archive audit logs** - Keep for compliance
7. **Review reports** - Check for warnings/errors
8. **Test in dev first** - Before production
9. **Document execution IDs** - Needed for rollback
10. **Set up notifications** - Team awareness with `-NotificationEmail`

---

## 🆘 Emergency Commands

### Stop All PowerShell Jobs
```powershell
Get-Job | Stop-Job
Get-Job | Remove-Job
```

### Disconnect All Sessions
```powershell
Disconnect-MgGraph
Disconnect-PnPOnline
```

### Force Module Reload
```powershell
Remove-Module Microsoft.Graph, PnP.PowerShell -Force
Import-Module Microsoft.Graph, PnP.PowerShell -Force
```

### Clear Module Cache
```powershell
$env:PSModulePath -split ';' | ForEach-Object { Get-ChildItem $_ -Recurse -Filter "*.dll" -ErrorAction SilentlyContinue | Remove-Item -Force }
```

---

## 📞 Support

- **Documentation**: [README.md](README.md) | [GETTING-STARTED.md](GETTING-STARTED.md)
- **GitHub Issues**: [Report a bug](https://github.com/goldeneye/PowerShell/issues)
- **Microsoft Docs**: [B2B Documentation](https://docs.microsoft.com/azure/active-directory/external-identities/)

---

**Version:** 2.0 | **Last Updated:** October 2024
