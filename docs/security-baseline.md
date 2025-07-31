# Security Baseline and Best Practices

## Overview
This document outlines the security baseline implemented in the Windows Server lab environment, aligned with industry best practices and security frameworks.

## Security Framework Alignment

### NIST Cybersecurity Framework
- **Identify**: Asset inventory and risk assessment
- **Protect**: Access controls and security baselines
- **Detect**: Monitoring and alerting systems
- **Respond**: Incident response procedures
- **Recover**: Backup and disaster recovery

### CIS Controls
- **Control 1**: Inventory of Authorized and Unauthorized Devices
- **Control 2**: Inventory of Authorized and Unauthorized Software
- **Control 4**: Controlled Use of Administrative Privileges
- **Control 5**: Secure Configuration Management
- **Control 6**: Maintenance, Monitoring, and Analysis of Audit Logs

## Password Policy

### Domain Password Requirements
```
Minimum password length: 12 characters
Password complexity: Enabled
Maximum password age: 90 days
Minimum password age: 1 day
Password history: 24 passwords
Account lockout threshold: 5 failed attempts
Account lockout duration: 30 minutes
Reset account lockout counter: 30 minutes
```

### Implementation
```powershell
Set-ADDefaultDomainPasswordPolicy `
    -ComplexityEnabled $true `
    -MinPasswordLength 12 `
    -MaxPasswordAge 90 `
    -MinPasswordAge 1 `
    -PasswordHistoryCount 24
```

## Account Security

### Administrative Accounts
- **Separate admin accounts**: Never use standard user accounts for administrative tasks
- **Least privilege**: Grant minimum necessary permissions
- **Regular review**: Monthly review of administrative group memberships
- **Strong authentication**: Require complex passwords and consider MFA

### Service Accounts
- **Managed Service Accounts**: Use Group Managed Service Accounts (gMSA) where possible
- **Unique passwords**: Each service account has a unique, complex password
- **Minimal permissions**: Service accounts have only necessary permissions
- **Regular rotation**: Passwords rotated every 90 days

### User Accounts
- **Standard users**: Default assignment to least-privileged groups
- **Account expiration**: Set expiration dates for temporary accounts
- **Disabled accounts**: Disable rather than delete departed user accounts
- **Login restrictions**: Implement time-based and location-based restrictions

## Network Security

### Firewall Configuration
```powershell
# Enable Windows Firewall for all profiles
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True

# Configure specific rules for AD services
New-NetFirewallRule -DisplayName "AD-Kerberos-TCP" -Direction Inbound -Protocol TCP -LocalPort 88
New-NetFirewallRule -DisplayName "AD-LDAP-TCP" -Direction Inbound -Protocol TCP -LocalPort 389
New-NetFirewallRule -DisplayName "AD-LDAPS-TCP" -Direction Inbound -Protocol TCP -LocalPort 636
New-NetFirewallRule -DisplayName "AD-DNS-UDP" -Direction Inbound -Protocol UDP -LocalPort 53
New-NetFirewallRule -DisplayName "AD-DNS-TCP" -Direction Inbound -Protocol TCP -LocalPort 53
New-NetFirewallRule -DisplayName "RPC-Endpoint-Mapper" -Direction Inbound -Protocol TCP -LocalPort 135
```

### Network Segmentation
- **Domain Controllers**: Separate VLAN for DC traffic
- **Management Network**: Isolated network for administrative access
- **User Networks**: Separate VLANs for different departments
- **DMZ**: Demilitarized zone for external-facing services

## Audit and Logging

### Security Audit Policy
```
Account Logon Events: Success, Failure
Account Management: Success, Failure
Directory Service Access: Success, Failure
Logon Events: Success, Failure
Object Access: Failure
Policy Change: Success, Failure
Privilege Use: Success, Failure
Process Tracking: Success (if needed)
System Events: Success, Failure
```

### Event Log Configuration
```powershell
# Configure event log sizes and retention
wevtutil sl Security /ms:1073741824 /rt:false
wevtutil sl System /ms:1073741824 /rt:false
wevtutil sl Application /ms:1073741824 /rt:false
```

### Critical Events to Monitor
- **4625**: Failed logon attempts
- **4648**: Explicit credential logon
- **4672**: Special privileges assigned
- **4728**: Member added to security group
- **4732**: Member added to local group
- **4740**: Account lockout
- **4756**: Member added to universal group
- **1102**: Audit log was cleared

## Group Policy Security Settings

### Computer Configuration
```
Security Settings > Local Policies > Security Options:
- Interactive logon: Do not display last user name: Enabled
- Interactive logon: Prompt user to change password before expiration: 14 days
- Network security: Do not store LAN Manager hash: Enabled
- Network security: LAN Manager authentication level: Send NTLMv2 response only
- Shutdown: Allow system to be shut down without logon: Disabled
```

### User Configuration
```
Administrative Templates > System:
- Prevent access to registry editing tools: Enabled
- Prevent access to the command prompt: Enabled (for non-admin users)
- Remove Run menu from Start Menu: Enabled (for non-admin users)
```

## Service Hardening

### Windows Services
```powershell
# Disable unnecessary services
$ServicesToDisable = @(
    'Fax',
    'TelnetD',
    'RemoteRegistry',
    'Messenger',
    'NetMeeting'
)

foreach ($Service in $ServicesToDisable) {
    Set-Service -Name $Service -StartupType Disabled -ErrorAction SilentlyContinue
}
```

### IIS Hardening (if installed)
- Remove unused modules
- Configure custom error pages
- Implement request filtering
- Enable logging and monitoring

## Software Restriction Policies

### AppLocker Configuration
```
Executable Rules:
- Allow Administrators full access
- Allow authenticated users to execute from Program Files
- Allow authenticated users to execute from Windows directory
- Block execution from user profiles and temp directories

Script Rules:
- Allow signed scripts only
- Block PowerShell execution for standard users (except IT staff)
```

## Backup and Recovery Security

### Backup Security
- **Encryption**: All backups encrypted at rest and in transit
- **Access Control**: Backup operators have minimal necessary permissions
- **Offsite Storage**: Critical backups stored offsite or in cloud
- **Testing**: Regular restore testing to verify backup integrity

### Recovery Procedures
- **DSRM Password**: Strong Directory Services Restore Mode password
- **Recovery Documentation**: Step-by-step recovery procedures documented
- **Recovery Testing**: Quarterly disaster recovery tests
- **Recovery Time Objectives**: Defined RTO and RPO for critical services

## Compliance and Reporting

### Regular Security Reviews
- **Monthly**: Review administrative group memberships
- **Monthly**: Analyze security event logs
- **Quarterly**: Review and update security policies
- **Quarterly**: Conduct vulnerability assessments
- **Annually**: Complete security baseline review

### Documentation Requirements
- **Security Policies**: Written security policies and procedures
- **Change Management**: All security changes documented and approved
- **Incident Response**: Security incidents documented and analyzed
- **Training Records**: Security awareness training completion tracked

## Vulnerability Management

### Patch Management
```powershell
# Configure Windows Update for automatic download and scheduled installation
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "AUOptions" -Value 4
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "ScheduledInstallDay" -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "ScheduledInstallTime" -Value 3
```

### Security Scanning
- **Weekly**: Automated vulnerability scans
- **Monthly**: Manual security reviews
- **Quarterly**: Penetration testing (if resources allow)

## Incident Response

### Detection and Analysis
1. **Monitor Security Events**: Automated monitoring of critical security events
2. **Investigate Anomalies**: Immediate investigation of security alerts
3. **Document Incidents**: All security incidents documented with timeline

### Containment and Recovery
1. **Isolate Affected Systems**: Network isolation of compromised systems
2. **Preserve Evidence**: Forensic preservation of evidence
3. **Restore Services**: Coordinated service restoration

### Post-Incident Activities
1. **Lessons Learned**: Post-incident review and documentation
2. **Policy Updates**: Update security policies based on incidents
3. **Training Updates**: Update security training based on lessons learned

## Continuous Improvement

### Security Metrics
- **Failed Login Attempts**: Daily monitoring and trending
- **Privilege Escalation**: Monthly review of privilege changes
- **Policy Compliance**: Quarterly compliance assessments
- **Incident Response Time**: Track and improve response times

### Security Awareness
- **User Training**: Regular security awareness training
- **Phishing Tests**: Periodic phishing simulation exercises
- **Security Communications**: Regular security updates and communications

---

*This security baseline should be reviewed and updated regularly to address new threats and vulnerabilities. Ensure all changes are tested in a non-production environment before implementation.*
