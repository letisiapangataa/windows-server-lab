# Windows Server Lab - Setup Guide

## Overview
This guide provides step-by-step instructions for setting up the Windows Server 2022 lab environment with Active Directory, RBAC, and automated monitoring.

## Prerequisites

### Hardware Requirements
- **CPU**: 2+ cores
- **RAM**: 4GB minimum (8GB recommended)
- **Storage**: 60GB minimum
- **Network**: Static IP capability

### Software Requirements
- Windows Server 2022 (Standard or Datacenter)
- PowerShell 5.1 or later
- Administrator privileges

## Initial Setup

### Step 1: Prepare the Server
1. Install Windows Server 2022
2. Apply latest updates
3. Configure basic network settings
4. Set appropriate hostname

### Step 2: Run Domain Setup Script
```powershell
# Navigate to scripts directory
cd C:\lab-scripts

# Create secure password for DSRM
$Password = Read-Host -AsSecureString "Enter DSRM Password"

# Run domain setup
.\domain-setup.ps1 -DomainName "lab.local" -SafeModePassword $Password -StaticIP "192.168.1.10"
```

**Note**: The server will reboot automatically during this process.

### Step 3: Configure RBAC Structure
After the server reboots and domain is established:

```powershell
# Set up organizational units and security groups
.\rbac-setup.ps1

# Verify OU structure
Get-ADOrganizationalUnit -Filter * | Format-Table Name, DistinguishedName
```

### Step 4: Create Users and Groups
```powershell
# Create sample users (modify users.csv first)
.\user-provisioning.ps1

# Add specific users manually if needed
.\user-provisioning.ps1 -CSVPath "custom-users.csv"
```

### Step 5: Apply Group Policies
```powershell
# Configure security baselines and department policies
.\gpo-automation.ps1

# Verify GPO links
Get-GPInheritance -Target "OU=Staff,DC=lab,DC=local"
```

### Step 6: Set Up Monitoring and Backups
```powershell
# Configure automated monitoring
.\monitoring-alert.ps1 -TestMode

# Set up backup procedures
.\backup-restore.ps1 -TestRestore

# Configure scheduled tasks
.\task-scheduler-setup.ps1
```

## Post-Setup Configuration

### DNS Configuration
1. Verify DNS zones are created correctly
2. Configure conditional forwarders if needed
3. Test name resolution from client machines

### Time Synchronization
```powershell
# Configure as authoritative time source
w32tm /config /manualpeerlist:"time.windows.com" /syncfromflags:manual /reliable:yes /update
Restart-Service w32time
```

### Firewall Configuration
```powershell
# Configure Windows Firewall for AD services
New-NetFirewallRule -DisplayName "AD-Kerberos" -Direction Inbound -Protocol TCP -LocalPort 88
New-NetFirewallRule -DisplayName "AD-LDAP" -Direction Inbound -Protocol TCP -LocalPort 389
New-NetFirewallRule -DisplayName "AD-LDAPS" -Direction Inbound -Protocol TCP -LocalPort 636
New-NetFirewallRule -DisplayName "AD-DNS" -Direction Inbound -Protocol UDP -LocalPort 53
```

## Verification Steps

### 1. Active Directory Health
```powershell
# Check AD replication (for multi-DC environments)
repadmin /showrepl

# Verify FSMO roles
netdom query fsmo

# Test AD connectivity
Test-ComputerSecureChannel -Verbose
```

### 2. DNS Health
```powershell
# Test DNS resolution
nslookup lab.local
nslookup dc01.lab.local

# Check DNS zones
Get-DnsServerZone
```

### 3. Group Policy Health
```powershell
# Check GP processing
gpresult /r

# Verify GP links
Get-GPInheritance -Target "DC=lab,DC=local"
```

### 4. User Authentication
```powershell
# Test user authentication
Test-ADAuthentication -Username "testuser" -Password "password"

# Verify group memberships
Get-ADGroupMember -Identity "IT_Admins"
```

## Troubleshooting

### Common Issues

#### Domain Controller Promotion Fails
- Check DNS configuration
- Verify administrator privileges
- Review event logs (Event ID 1109, 1168)

#### User Creation Fails
- Verify OU exists
- Check password complexity requirements
- Ensure proper permissions

#### Group Policy Not Applying
- Check GP links and inheritance
- Verify security filtering
- Run `gpupdate /force` on client machines

#### Monitoring Alerts Not Working
- Verify SMTP configuration
- Check Task Scheduler service
- Review monitoring script logs

### Log Files Location
- Domain setup: `C:\Setup\domain-setup.log`
- User provisioning: `.\logs\user-provisioning.log`
- RBAC setup: `.\logs\rbac-setup.log`
- GPO automation: `.\logs\gpo-automation.log`
- Monitoring: `.\logs\monitoring.log`
- Backup operations: `.\logs\backup.log`

## Security Considerations

### Immediate Actions
1. Change default administrator password
2. Disable unnecessary services
3. Configure audit policies
4. Enable Windows Firewall
5. Apply security baselines

### Ongoing Maintenance
1. Regular password changes
2. Review group memberships
3. Monitor failed login attempts
4. Update security policies
5. Test backup and restore procedures

## Performance Optimization

### Server Performance
```powershell
# Optimize for background services
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 24

# Configure virtual memory
$ComputerSystem = Get-WmiObject -Class Win32_ComputerSystem
$TotalRAM = [math]::Round($ComputerSystem.TotalPhysicalMemory / 1GB)
$PageFileSize = $TotalRAM * 1.5
```

### AD Database Optimization
```powershell
# Schedule offline defragmentation (monthly)
schtasks /create /tn "AD Database Defrag" /tr "ntdsutil \"activate instance ntds\" \"files\" \"compact to c:\temp\" quit quit" /sc monthly
```

## Next Steps

1. **Join Client Machines**: Configure workstations to join the domain
2. **Certificate Services**: Install and configure ADCS for PKI
3. **File Services**: Set up shared folders with proper permissions
4. **Remote Access**: Configure VPN or DirectAccess
5. **Monitoring Integration**: Connect to SIEM or monitoring platform

## Support and Documentation

- Windows Server 2022 Documentation: [Microsoft Docs](https://docs.microsoft.com/windows-server/)
- Active Directory Best Practices: [AD Best Practices](https://docs.microsoft.com/windows-server/identity/ad-ds/)
- PowerShell Documentation: [PowerShell Docs](https://docs.microsoft.com/powershell/)

---

*This lab environment is designed for educational and testing purposes. Ensure proper security measures are in place before deploying in production environments.*
