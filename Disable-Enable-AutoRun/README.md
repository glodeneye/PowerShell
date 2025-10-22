# Disable-Enable-AutoRun.ps1

[← Back to Main Repository](../)

## Overview

Manages Windows AutoRun settings to prevent malware execution from removable media and network drives. This security hardening script modifies registry settings to disable or enable AutoRun functionality across all drive types.

## Features

- **Security Hardening**: Prevents malware autorun from USB drives
- **Registry-Based**: Modifies Windows AutoRun registry settings
- **Simple Functions**: Easy-to-use Disable-AutoRun and Enable-AutoRun functions
- **Compliance**: Meets CIS and NIST security benchmarks
- **Audit Support**: Check current AutoRun configuration

## Security Context

### What is AutoRun?

AutoRun is a Windows feature that automatically executes programs from removable media when inserted. While convenient, it's a common malware infection vector.

### Why Disable AutoRun?

- **Malware Prevention**: Stops USB-based malware from auto-executing
- **Security Best Practice**: Recommended by security frameworks (CIS, NIST)
- **Compliance**: Required for many security standards (PCI-DSS, HIPAA)
- **User Control**: Requires explicit user action to run programs

### Common Attack Scenarios

1. **USB Drop Attack**: Attacker leaves infected USB drives in parking lot
2. **Social Engineering**: User receives "promotional" USB drive
3. **Insider Threat**: Malicious insider plugs in infected device
4. **Supply Chain**: Pre-infected devices in supply chain

## Prerequisites

### Requirements

- **Administrator Privileges**: Required to modify registry
- **PowerShell 5.1+**: Built into Windows 10/11
- **Windows OS**: Works on Windows 7/8/10/11/Server

### Permissions

Run PowerShell as Administrator:
```powershell
# Right-click PowerShell
# Select "Run as Administrator"
```

## Installation

### Option 1: Clone Repository

```powershell
git clone https://github.com/goldeneye/PowerShell.git
cd PowerShell\Disable-Enable-AutoRun
```

### Option 2: Direct Download

```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/goldeneye/PowerShell/main/Disable-Enable-AutoRun/Disable-Enable-AutoRun.ps1" -OutFile "Disable-Enable-AutoRun.ps1"
```

## Usage

### Disable AutoRun (Recommended)

```powershell
# Load the script functions
. .\Disable-Enable-AutoRun.ps1

# Disable AutoRun
Disable-AutoRun
```

### Enable AutoRun (Not Recommended)

```powershell
# Load the script functions
. .\Disable-Enable-AutoRun.ps1

# Enable AutoRun (restore default behavior)
Enable-AutoRun
```

### Check Current Status

```powershell
# Check if AutoRun is disabled
$item = Get-Item "REGISTRY::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\IniFileMapping\AutoRun.inf" -ErrorAction SilentlyContinue

if ($item) {
    Write-Host "AutoRun is DISABLED (Secure)" -ForegroundColor Green
} else {
    Write-Host "AutoRun is ENABLED (Insecure)" -ForegroundColor Red
}
```

## How It Works

### Disable-AutoRun Function

Creates a registry key that redirects AutoRun.inf files to a non-existent location:

```
Registry Path: HKLM\Software\Microsoft\Windows NT\CurrentVersion\IniFileMapping\AutoRun.inf
Value: (default) = "@SYS:DoesNotExist"
```

This prevents Windows from reading AutoRun.inf files on any drive.

### Enable-AutoRun Function

Removes the registry key, restoring default Windows behavior:

```
Deletes: HKLM\Software\Microsoft\Windows NT\CurrentVersion\IniFileMapping\AutoRun.inf
```

## Affected Drive Types

This script affects AutoRun behavior on:

- USB flash drives
- External hard drives
- CD/DVD drives
- Network drives
- Any removable media

## Use Cases

### Enterprise Security Hardening

```powershell
# Deploy via Group Policy or SCCM
# Run on all workstations as part of baseline configuration
. .\Disable-Enable-AutoRun.ps1
Disable-AutoRun

# Log the change
Write-EventLog -LogName "Security" -Source "PowerShell" -EventId 1000 -Message "AutoRun disabled by security script"
```

### SOC/Incident Response

```powershell
# When malware outbreak detected
# Quickly disable AutoRun on all systems

# Example: Remote execution via PSExec or Invoke-Command
Invoke-Command -ComputerName (Get-ADComputer -Filter *).Name -ScriptBlock {
    # Create registry key
    New-Item "REGISTRY::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\IniFileMapping\AutoRun.inf" -Force
    Set-ItemProperty "REGISTRY::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\IniFileMapping\AutoRun.inf" "(default)" "@SYS:DoesNotExist"
}
```

### Compliance Auditing

```powershell
# Check AutoRun status across domain
$computers = Get-ADComputer -Filter * | Select-Object -ExpandProperty Name

$results = Invoke-Command -ComputerName $computers -ScriptBlock {
    $key = Get-Item "REGISTRY::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\IniFileMapping\AutoRun.inf" -ErrorAction SilentlyContinue
    [PSCustomObject]@{
        ComputerName = $env:COMPUTERNAME
        AutoRunDisabled = [bool]$key
        Compliant = [bool]$key
    }
}

# Export compliance report
$results | Export-Csv "AutoRun_Compliance_Report.csv" -NoTypeInformation
```

### Personal Workstation Security

```powershell
# Run once on personal PC for added security
. .\Disable-Enable-AutoRun.ps1
Disable-AutoRun

Write-Host "AutoRun disabled. USB devices are now safer to use." -ForegroundColor Green
```

## Group Policy Alternative

For enterprise deployments, consider using Group Policy:

```
Computer Configuration
└── Administrative Templates
    └── Windows Components
        └── AutoPlay Policies
            └── Turn off AutoPlay: Enabled (All drives)
```

**Note**: Group Policy provides more granular control but requires Active Directory.

## Security Frameworks

This script helps meet requirements from:

- **CIS Benchmark**: Windows 10/11 security guidelines
- **NIST 800-53**: AC-19 (Access Control for Mobile Devices)
- **PCI-DSS**: Requirement 5 (Malware protection)
- **HIPAA**: Technical safeguards against malware

## Troubleshooting

### Permission Denied

**Problem**: "Access to the registry key is denied"

**Solution**:
```powershell
# Ensure running as Administrator
[Security.Principal.WindowsIdentity]::GetCurrent().Groups -contains 'S-1-5-32-544'

# If False, restart PowerShell as Administrator
```

### Changes Not Taking Effect

**Problem**: AutoRun still works after running script

**Possible Causes**:
- Other Group Policy settings override
- Registry redirection (32-bit vs 64-bit)
- Cached AutoRun behavior

**Solutions**:
```powershell
# Restart Windows Explorer
Stop-Process -Name explorer -Force

# Reboot system (recommended)
Restart-Computer
```

### Script Doesn't Load

**Problem**: Functions not recognized

**Solution**:
```powershell
# Dot-source the script (note the dot and space)
. .\Disable-Enable-AutoRun.ps1

# Then call the function
Disable-AutoRun
```

## Verification

### Verify Registry Change

```powershell
# After running Disable-AutoRun
Get-ItemProperty "REGISTRY::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\IniFileMapping\AutoRun.inf"

# Expected output:
# (default) : @SYS:DoesNotExist
```

### Test with USB Drive

1. Create test USB with AutoRun.inf
2. Insert USB drive
3. AutoRun should NOT execute (if disabled correctly)

## Best Practices

1. **Deploy Enterprise-Wide**: Disable on all managed workstations
2. **Test Before Deployment**: Verify in lab environment
3. **Document Changes**: Log all registry modifications
4. **User Education**: Explain why AutoRun is disabled
5. **Regular Audits**: Verify setting hasn't been reverted
6. **Combine with AV**: Use alongside antivirus software

## Limitations

- Does not affect already-running processes
- Users can still manually run programs from USB
- Does not prevent all USB-based attacks (use Device Control for that)
- Registry changes can be reverted by users with admin rights

## Advanced Configuration

### Disable for Specific Drive Types Only

```powershell
# More granular control via different registry path
$path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"
Set-ItemProperty -Path $path -Name "NoDriveTypeAutoRun" -Value 255

# Value breakdown:
# 4   = Removable drives
# 8   = Fixed drives
# 16  = Network drives
# 32  = CD-ROM drives
# 255 = All drives
```

## Related Scripts

- [CVE-2023-23397 Scanner](../CVE-2023-23397-Scanner/) - Security vulnerability scanner
- [Get-OneDriveSharedItems](../Get-OneDriveSharedItems/) - OneDrive security audit

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

## References

- [Microsoft Security Guidance - AutoRun](https://docs.microsoft.com/en-us/windows/security/)
- [CIS Windows Benchmark](https://www.cisecurity.org/benchmark/microsoft_windows_desktop)
- [NIST 800-53 Controls](https://nvd.nist.gov/800-53)
- [USB Security Best Practices](https://www.us-cert.gov/ncas/tips/ST08-001)

---

*Last Updated: October 2025*
