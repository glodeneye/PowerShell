# Example Scenarios

This folder contains real-world example scripts demonstrating different use cases for the M365 Cross-Tenant Collaboration setup.

## 📂 Available Examples

### 1. Small Team Setup (`01-Small-Team-Setup.ps1`)

**Use Case:** Pilot project or small consulting firm

**Scenario:**
- 3-5 host users
- 2-3 guest users
- 2-3 client folders
- Basic reporting

**Best For:**
- Testing the setup
- Small teams
- Proof of concept
- Quick deployments

**Run Command:**
```powershell
.\Examples\01-Small-Team-Setup.ps1
```

---

### 2. Enterprise Bulk Import (`02-Enterprise-Bulk-Import.ps1`)

**Use Case:** Large organization with many users and clients

**Scenario:**
- 50+ users via CSV
- 15+ client folders
- Full reporting (HTML + Excel)
- Email notifications
- Rollback enabled

**Best For:**
- Enterprise deployments
- Complex setups
- Production environments
- Large teams

**Run Command:**
```powershell
.\Examples\02-Enterprise-Bulk-Import.ps1
```

**Note:** Edit `enterprise-users.csv` before running!

---

### 3. Add Users to Existing Site (`03-Add-Users-To-Existing-Site.ps1`)

**Use Case:** Adding new team members to existing collaboration

**Scenario:**
- Site already exists
- B2B already configured
- Adding 5 new users
- Skips site and B2B creation

**Best For:**
- Incremental user additions
- Onboarding new team members
- Guest user expansion
- Existing site updates

**Run Command:**
```powershell
.\Examples\03-Add-Users-To-Existing-Site.ps1
```

---

## 🎯 How to Use Examples

### Step 1: Choose Your Scenario

Pick the example that matches your needs:
- Small team? → Example 1
- Enterprise? → Example 2
- Adding users? → Example 3

### Step 2: Review the Script

Open the example script and read through it to understand what it does.

### Step 3: Customize

Edit the script with your actual:
- Tenant domains
- Admin email
- Client names
- User details

### Step 4: Run

Execute the example script:
```powershell
.\Examples\01-Small-Team-Setup.ps1
```

---

## 💡 Tips for Using Examples

1. **Always test with -WhatIf first** - All examples include a dry-run step
2. **Edit CSV files** - Update with your actual users before running
3. **Review output** - Check the WhatIf output carefully
4. **Start small** - Try Example 1 first, then scale up
5. **Save configs** - Keep successful configurations for reuse

---

## 🔧 Customization Guide

### Modifying Example Scripts

You can customize these examples by changing:

**Tenant Domains:**
```powershell
-HostTenantDomain "your-domain.com" `
-GuestTenantDomain "partner-domain.com" `
```

**Site Names:**
```powershell
-SharePointSiteTitle "Your Site Name" `
-SharePointSiteAlias "YourSiteAlias" `
```

**Client Folders:**
```powershell
-ClientFolders @("Your Client 1", "Your Client 2", "Your Client 3") `
```

**Features:**
```powershell
-EnableRollback `           # Enable auto-rollback
-GenerateHtmlReport `       # Generate HTML report
-GenerateExcelReport `      # Generate Excel report
-NotificationEmail "team@domain.com" `  # Send notifications
```

---

## 📊 Example Comparison

| Feature | Example 1 | Example 2 | Example 3 |
|---------|-----------|-----------|-----------|
| **Users** | 5-10 | 50+ | 5 new |
| **Clients** | 2-3 | 15+ | N/A |
| **CSV Import** | Optional | Required | Required |
| **Complexity** | Simple | Complex | Medium |
| **Duration** | 3-5 min | 15-20 min | 2-3 min |
| **Rollback** | Optional | Enabled | Optional |
| **Reports** | HTML | HTML + Excel | HTML |
| **Email** | No | Yes | No |
| **B2B Config** | Yes | Yes | Skipped |
| **Site Creation** | Yes | Yes | Skipped |

---

## 🚀 Quick Start by Role

### IT Administrator (Enterprise)
**Start with:** Example 2 (Enterprise Bulk Import)
- Handles large-scale deployments
- Full reporting for management
- Email notifications for team
- Complete rollback safety

### Small Business Owner
**Start with:** Example 1 (Small Team Setup)
- Quick and simple
- Easy to understand
- Good for testing
- Minimal configuration

### Operations Team (Ongoing)
**Start with:** Example 3 (Add Users)
- Day-to-day user management
- No site recreation needed
- Fast execution
- Incremental changes

---

## 📝 Creating Custom Examples

Want to create your own example? Use this template:

```powershell
<#
.SYNOPSIS
    Your Custom Scenario Name

.DESCRIPTION
    Describe what this does

.SCENARIO
    List your specific setup details
#>

# Step 1: Preparation
Write-Host "Step 1: Your preparation step..." -ForegroundColor Cyan
# Your code

# Step 2: Test with WhatIf
Write-Host "`nStep 2: Testing..." -ForegroundColor Cyan
.\Setup-CrossTenantCollaboration.ps1 `
    -HostTenantDomain "your-domain.com" `
    -GuestTenantDomain "partner-domain.com" `
    # ... other parameters
    -WhatIf

# Step 3: Execute
$confirm = Read-Host "Execute? (Y/N)"
if ($confirm -eq 'Y') {
    .\Setup-CrossTenantCollaboration.ps1 `
        # ... parameters without -WhatIf
}
```

---

## ❓ Frequently Asked Questions

### Q: Can I modify the examples?
**A:** Yes! These are templates. Customize them for your needs.

### Q: Do I need all three examples?
**A:** No. Pick the one that matches your scenario.

### Q: Can I combine features from different examples?
**A:** Absolutely! Mix and match parameters as needed.

### Q: What if my scenario isn't covered?
**A:** Use the closest example as a starting point and modify it.

### Q: Can I save my customized examples?
**A:** Yes! Save them with a different name so updates don't overwrite them.

---

## 🆘 Need Help?

- **Documentation**: [../README.md](../README.md)
- **Getting Started**: [../GETTING-STARTED.md](../GETTING-STARTED.md)
- **Quick Reference**: [../QUICK-REFERENCE.md](../QUICK-REFERENCE.md)
- **Issues**: [GitHub Issues](https://github.com/goldeneye/PowerShell/issues)

---

**Happy Collaborating! 🎉**
