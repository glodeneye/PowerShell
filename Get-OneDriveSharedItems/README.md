# Get-OneDriveSharedItems.ps1

[← Back to Main Repository](../)

## Overview

Export all OneDrive shared items (both shared with you and shared by you) to CSV files for audit, compliance, and cleanup purposes.

## Features

- **Recursive Scanning**: Scans entire OneDrive including all subfolders
- **Bidirectional Sharing**: Identifies items shared WITH you and BY you
- **Detailed Sharing Information**: Exports recipients, link types, and scopes
- **Cleanup Support**: Separate CSV with permission IDs for easy removal
- **Security Auditing**: Identifies anonymous links and external sharing
- **Automated Reporting**: Timestamped CSV exports for record-keeping

## Prerequisites

### Required Modules

```powershell
Install-Module Microsoft.Graph.Authentication -Scope CurrentUser
Install-Module Microsoft.Graph.Files -Scope CurrentUser
```

### Required Permissions

- Microsoft 365 account with OneDrive
- Files.Read.All scope

### PowerShell Version

- PowerShell 5.1 or higher

## Installation

### Option 1: Clone Repository

```powershell
git clone https://github.com/goldeneye/PowerShell.git
cd PowerShell\Get-OneDriveSharedItems
```

### Option 2: Direct Download

```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/goldeneye/PowerShell/main/Get-OneDriveSharedItems/Get-OneDriveSharedItems.ps1" -OutFile "Get-OneDriveSharedItems.ps1"
```

## Usage

### Basic Usage

```powershell
# Run with default settings (exports to current directory)
.\Get-OneDriveSharedItems.ps1
```

### Custom Output Directory

```powershell
# Specify custom output location
.\Get-OneDriveSharedItems.ps1 -OutputDirectory "C:\Reports\OneDrive"
```

### View Help

```powershell
Get-Help .\Get-OneDriveSharedItems.ps1 -Full
Get-Help .\Get-OneDriveSharedItems.ps1 -Examples
```

## Output Files

The script generates two timestamped CSV files:

### 1. OneDrive_Shared_Items_[timestamp].csv

Detailed sharing report including:
- Item Name
- Item Path
- Item Type (File/Folder)
- Shared With (recipients)
- Sharing Link Type
- Sharing Scope
- Permission Type
- Direct URL

**Use Case**: Comprehensive audit, compliance reporting, security review

### 2. OneDrive_Shared_Items_Cleanup_[timestamp].csv

Simplified cleanup list including:
- Item Name
- Item Path
- Shared With
- Permission ID (for removal)
- Direct URL

**Use Case**: Quick cleanup of old/unnecessary shares

## Use Cases

### Security Audit

Identify potential security risks:
- Anonymous sharing links
- External user access
- Overshared sensitive files
- Orphaned permissions

### Compliance Review

Generate reports for:
- Data governance audits
- GDPR compliance checks
- Information security assessments
- Access control reviews

### Cleanup Operations

Efficiently remove:
- Old sharing links
- External access no longer needed
- Anonymous links created accidentally
- Test shares from development

## Example Scenarios

### Scenario 1: Monthly Security Audit

```powershell
# Export all sharing data
.\Get-OneDriveSharedItems.ps1 -OutputDirectory "\\FileServer\Reports\OneDrive\$(Get-Date -Format 'yyyy-MM')"

# Review CSV for:
# - External users (@external.com)
# - Anonymous links (Anyone with the link)
# - Sensitive folders with broad access
```

### Scenario 2: Pre-Departure Cleanup

```powershell
# When employee is leaving, audit their OneDrive shares
.\Get-OneDriveSharedItems.ps1

# Review cleanup CSV
# Remove shares before account deactivation
```

### Scenario 3: Compliance Reporting

```powershell
# Quarterly compliance check
.\Get-OneDriveSharedItems.ps1 -OutputDirectory "C:\Compliance\Q4-2025"

# Import to Excel for pivot tables and analysis
# Generate charts showing sharing patterns
```

## Troubleshooting

### Authentication Issues

**Problem**: Script fails to authenticate to Microsoft Graph

**Solutions**:
```powershell
# Ensure modules are installed
Get-Module Microsoft.Graph.* -ListAvailable

# Manually connect first
Connect-MgGraph -Scopes "Files.Read.All"

# Check current context
Get-MgContext
```

### Permission Errors

**Problem**: "Insufficient privileges" error

**Solutions**:
- Ensure you have Files.Read.All consent
- Admin consent may be required in some tenants
- Contact your Microsoft 365 administrator

### Empty Results

**Problem**: Script runs but finds no shared items

**Possible Causes**:
- OneDrive is empty
- No items are currently shared
- Connected to wrong account

**Verification**:
```powershell
# Check which user you're authenticated as
Get-MgContext | Select-Object Account

# Verify OneDrive has content
Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/me/drive/root/children"
```

### Module Not Found

**Problem**: "Module not found" error

**Solution**:
```powershell
# Install required modules
Install-Module Microsoft.Graph.Authentication -Force -Scope CurrentUser
Install-Module Microsoft.Graph.Files -Force -Scope CurrentUser

# Update existing modules
Update-Module Microsoft.Graph.*
```

## Advanced Usage

### Scripted/Automated Execution

```powershell
# Run as scheduled task (ensure auth token is valid)
$OutputPath = "C:\Reports\OneDrive\$(Get-Date -Format 'yyyy-MM-dd')"
.\Get-OneDriveSharedItems.ps1 -OutputDirectory $OutputPath

# Email results (add your email logic)
Send-MailMessage -To "admin@company.com" -Subject "OneDrive Audit" -Attachments "$OutputPath\*.csv"
```

### Integration with Other Tools

```powershell
# Export and analyze with PowerShell
$shares = Import-Csv ".\OneDrive_Shared_Items_*.csv"

# Find external shares
$external = $shares | Where-Object { $_.'Shared With' -like '*@external.com' }

# Find anonymous links
$anonymous = $shares | Where-Object { $_.'Sharing Scope' -eq 'anonymous' }

# Count shares by type
$shares | Group-Object 'Sharing Link Type' | Select-Object Name, Count
```

## Security Considerations

- **Read-Only**: Script only reads data, never modifies shares
- **Credentials**: Uses secure Microsoft authentication (OAuth)
- **Data Privacy**: CSV files contain sensitive information - store securely
- **Access Control**: Limit script execution to authorized administrators
- **Audit Logging**: Consider logging script executions for compliance

## Best Practices

1. **Regular Audits**: Run monthly or quarterly
2. **Secure Storage**: Store CSV reports in protected location
3. **Retention Policy**: Define how long to keep audit files
4. **Review Process**: Establish workflow for reviewing findings
5. **Remediation**: Act on findings (remove unnecessary shares)
6. **Documentation**: Keep records of actions taken

## FAQ

**Q: Does this script modify any sharing permissions?**
A: No, it's read-only. Use the cleanup CSV to manually review before making changes.

**Q: Can I run this for other users' OneDrives?**
A: Not directly. This script runs in user context. For admin-level audits, modify to use app-only authentication.

**Q: How long does it take to run?**
A: Depends on OneDrive size. Typical execution: 1-5 minutes for average OneDrive.

**Q: Can I schedule this to run automatically?**
A: Yes, but you'll need to handle authentication refresh tokens for unattended execution.

**Q: Does this work with SharePoint?**
A: No, this is OneDrive-specific. A separate SharePoint audit script is on the roadmap.

## Related Scripts

- [CVE-2023-23397 Scanner](../CVE-2023-23397-Scanner/) - Security vulnerability scanner
- [Disable-Enable AutoRun](../Disable-Enable-AutoRun/) - System security hardening

## Support

- **Issues**: [GitHub Issues](https://github.com/goldeneye/PowerShell/issues)
- **Discussions**: [GitHub Discussions](https://github.com/goldeneye/PowerShell/discussions)

## Contributing

Found a bug or have an enhancement? Contributions welcome!

1. Fork the repository
2. Create feature branch
3. Make your changes
4. Submit pull request

## License

MIT License - see [LICENSE](../LICENSE) for details

## Author

**Tim Golden**
- GitHub: [@goldeneye](https://github.com/goldeneye)
- Website: [timgolden.com](https://timgolden.com)

---

*Last Updated: October 2025*
