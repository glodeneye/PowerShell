# PowerShell Scripts Collection

![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)

A collection of useful PowerShell scripts for system administration, security auditing, and Microsoft 365 management.

## 👤 Author

**Tim Golden**
- GitHub: [@goldeneye](https://github.com/goldeneye)
- Website: [timgolden.com](https://timgolden.com)

---

## 📚 Scripts in This Repository

### 🔐 Security & Vulnerability Management

#### [Microsoft Outlook Vulnerability Scanner (CVE-2023-23397)](./CVE-2023-23397-Scanner)

Scans for the critical Outlook elevation of privilege vulnerability (CVE-2023-23397) that allows attackers to steal NTLM hashes without user interaction.

**Features:**
- Detects vulnerable Outlook versions (32-bit and 64-bit)
- Automated update deployment via OfficeC2RClient
- Interactive and silent mode support
- Enterprise-ready for mass deployment
- Compliance and audit reporting

**Use Case:** Security teams need to quickly identify and remediate this actively exploited critical vulnerability across their organization.

[📖 View Full Documentation](./CVE-2023-23397-Scanner)

---

### 💻 System Configuration

#### [Disable-Enable AutoRun](./Disable-Enable-AutoRun)

Manages Windows AutoRun settings to prevent malware execution from removable media and network drives.

**Features:**
- Enable/disable AutoRun for all drive types
- Registry-based configuration
- Security hardening compliance (CIS, NIST)
- Audit current AutoRun settings
- Enterprise deployment support

**Use Case:** IT administrators implementing security policies to prevent AutoRun-based malware infections from USB drives and removable media.

[📖 View Full Documentation](./Disable-Enable-AutoRun)

---

### ☁️ Microsoft 365 & OneDrive Management

#### [Get-OneDriveSharedItems.ps1](./Get-OneDriveSharedItems)

Exports all OneDrive shared items (both shared with you and shared by you) to CSV files for audit and cleanup.

**Features:**
- Recursive scanning of entire OneDrive including subfolders
- Identifies items shared WITH you and BY you
- Exports sharing details (recipients, link types, scopes)
- Separate CSV for cleanup (includes permission IDs)
- Security audit capabilities (anonymous links, external sharing)

**Requirements:**
- Microsoft.Graph.Authentication module
- Microsoft 365 account with OneDrive

**Use Case:** Security audits, compliance reviews, data governance, and cleanup of old sharing links.

[📖 View Full Documentation](./Get-OneDriveSharedItems)

**Quick Start:**
```powershell
# Install required module
Install-Module Microsoft.Graph.Authentication -Scope CurrentUser

# Run script
.\Get-OneDriveSharedItems.ps1

# Custom output directory
.\Get-OneDriveSharedItems.ps1 -OutputDirectory "D:\Reports"
```

---

## Getting Started

### Prerequisites

- **PowerShell 5.1 or higher** (Windows 10/11 includes this by default)
- **Administrator privileges** (for some scripts)
- **Additional modules** (as specified in individual script documentation)

### Check Your PowerShell Version

```powershell
$PSVersionTable.PSVersion
```

### Execution Policy

You may need to adjust your execution policy to run these scripts:

```powershell
# Check current policy
Get-ExecutionPolicy

# Set policy for current user (recommended)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Or for a single script
powershell.exe -ExecutionPolicy Bypass -File .\ScriptName.ps1
```

---

## Installation

### Clone Repository

```powershell
git clone https://github.com/goldeneye/PowerShell.git
cd PowerShell
```

### Download Individual Scripts

Navigate to the script you need and click "Raw" to download, or use:

```powershell
# Example: Download Get-OneDriveSharedItems.ps1
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/goldeneye/PowerShell/main/Get-OneDriveSharedItems/Get-OneDriveSharedItems.ps1" -OutFile "Get-OneDriveSharedItems.ps1"
```

---

## Script Comparison Matrix

| Script | Category | Requires Admin | External Modules | Output Format | Use Case |
|--------|----------|----------------|------------------|---------------|----------|
| **CVE-2023-23397 Scanner** | Security | Yes | None | Console/Report | Vulnerability Assessment |
| **Disable-Enable AutoRun** | System Config | Yes | None | Registry | Security Hardening |
| **Get-OneDriveSharedItems** | Cloud/M365 | No | Microsoft.Graph | CSV | Data Governance |

---

## Common Installation Steps

### For Microsoft Graph Scripts

```powershell
# Install Microsoft Graph modules
Install-Module Microsoft.Graph.Authentication -Scope CurrentUser -Force
Install-Module Microsoft.Graph.Files -Scope CurrentUser -Force

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "Files.Read.All"
```

### For Security Scripts

```powershell
# Run PowerShell as Administrator
# Right-click PowerShell → "Run as Administrator"

# Navigate to script location
cd C:\Path\To\Scripts

# Execute script
.\ScriptName.ps1
```

---

## Documentation

Each script includes:
- Detailed comment-based help
- Parameter descriptions
- Usage examples
- Requirements and prerequisites
- Troubleshooting guidance

### View Script Help

```powershell
Get-Help .\ScriptName.ps1 -Full
Get-Help .\ScriptName.ps1 -Examples
```

---

## Security Considerations

- **Review scripts before execution**: Always review code from any source before running
- **Use appropriate permissions**: Run with minimum required privileges
- **Test in non-production**: Test scripts in a safe environment first
- **Audit logging**: Many scripts include logging capabilities for compliance
- **Data privacy**: Be aware of what data scripts access and export

---

## Contributing

Contributions, issues, and feature requests are welcome!

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Contribution Guidelines

- Follow PowerShell best practices
- Include comment-based help
- Add examples and documentation
- Test thoroughly before submitting
- Update README.md if adding new scripts

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

### What This Means

- Free to use commercially
- Free to modify and distribute
- No warranty provided
- Attribution appreciated but not required

---

## Disclaimer

These scripts are provided as-is without any warranties. Always:
- Test in non-production environments first
- Backup data before making system changes
- Review and understand code before execution
- Ensure compliance with your organization's policies

The author is not responsible for any data loss, system issues, or other problems arising from the use of these scripts.

---

## Support & Contact

- **Issues**: [GitHub Issues](https://github.com/goldeneye/PowerShell/issues)
- **Discussions**: [GitHub Discussions](https://github.com/goldeneye/PowerShell/discussions)
- **Website**: [timgolden.com](https://timgolden.com)

---

## Acknowledgments

- Microsoft PowerShell Team
- Microsoft Graph API Team
- Security research community
- Open source contributors

---

## Recommended Resources

### PowerShell Learning
- [Microsoft PowerShell Documentation](https://docs.microsoft.com/en-us/powershell/)
- [PowerShell Gallery](https://www.powershellgallery.com/)
- [PowerShell Best Practices](https://docs.microsoft.com/en-us/powershell/scripting/dev-cross-plat/performance/script-authoring-considerations)

### Microsoft Graph
- [Microsoft Graph Documentation](https://docs.microsoft.com/en-us/graph/)
- [Graph Explorer](https://developer.microsoft.com/en-us/graph/graph-explorer)
- [Microsoft Graph PowerShell SDK](https://github.com/microsoftgraph/msgraph-sdk-powershell)

### Security Resources
- [Microsoft Security Response Center](https://msrc.microsoft.com/)
- [CVE Database](https://cve.mitre.org/)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)

---

## Roadmap

### Planned Additions
- [ ] SharePoint permission auditing script
- [ ] Azure AD user lifecycle management
- [ ] Microsoft Teams governance tools
- [ ] Exchange Online mailbox reporting
- [ ] Automated compliance reporting suite

### Feature Enhancements
- [ ] GUI interfaces for complex scripts
- [ ] Enhanced error handling and logging
- [ ] Multi-tenancy support
- [ ] Automated testing framework
- [ ] Progress bars and better UX

---

## Statistics

![GitHub stars](https://img.shields.io/github/stars/goldeneye/PowerShell?style=social)
![GitHub forks](https://img.shields.io/github/forks/goldeneye/PowerShell?style=social)
![GitHub watchers](https://img.shields.io/github/watchers/goldeneye/PowerShell?style=social)

---

## Tags

`powershell` `automation` `security` `microsoft365` `onedrive` `system-administration` `vulnerability-scanning` `compliance` `data-governance` `it-tools`

---

**If these scripts helped you, please consider giving this repository a star!**

**Made with care by [Tim Golden](https://timgolden.com)**

---

*Last Updated: October 2025*