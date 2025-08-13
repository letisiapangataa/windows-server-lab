# Windows Server Lab Environment

A Windows Server 2022 lab simulating enterprise-grade Active Directory infrastructure with secure administration and automation.

Please visit the following blog post to break down the development : https://letisiapangataa.github.io/posts/windows-server-2022-lab/

---

## Project Overview

This lab environment demonstrates best practices in:

- Windows Server 2022 setup and domain configuration
- Active Directory (AD DS) management
- Role-Based Access Control (RBAC)
- Group Policy Object (GPO) automation
- PowerShell-based scripting
- Monitoring and alerting integration
- Disaster recovery simulation

---

## Key Features

- **Automated User Provisioning**: PowerShell scripts to bulk-create users and assign them to OUs and security groups.
- **RBAC Implementation**: Least-privilege model applied using Active Directory groups and delegated permissions.
- **Group Policy Automation**: Scripts to apply security baselines, login restrictions, and software controls.
- **Monitoring Setup**: Event log alerting and email notifications using PowerShell and Task Scheduler.
- **Disaster Recovery Simulation**: Documented restore procedures for AD services and system state backups.

---

## Technologies Used

| Technology          | Purpose                                  |
|---------------------|------------------------------------------|
| Windows Server 2022 | Core lab environment                     |
| Active Directory    | Identity and access control              |
| PowerShell          | Automation and scripting                 |
| Group Policy        | Centralized security and config control  |
| Task Scheduler      | Alerting and monitoring                  |

---


## Architecture Diagram

![Lab Architecture Diagram](architecture/lab-diagram.png)

---

## Step-by-Step Lab Setup Guide

Follow these steps to set up your Windows Server Lab environment:

### 1. Prepare Virtual Machines
- Create VMs for each server: DC01, FILE01, APP01, MON01, BACKUP01.
- Create VMs for workstations: WS01, WS02, WS03.
- Use Hyper-V, VMware, VirtualBox, or a cloud provider.

### 2. Install Operating Systems
- Install Windows Server 2022 on all server VMs.
- Install Windows 10/11 on workstation VMs.

### 3. Configure Networking
- Assign static IPs to servers (e.g., DC01: 192.168.1.10).
- Set up DHCP for workstations.
- Ensure all VMs are on the same subnet (e.g., 192.168.1.0/24).

### 4. Set Up Domain Controller
- On DC01, install the Active Directory Domain Services (AD DS) role.
- Promote DC01 to a new forest/domain (e.g., `lab.local`).

### 5. Join Devices to Domain
- Join all other servers and workstations to the `lab.local` domain.

### 6. Create OUs, Users, and Groups
- Use the PowerShell scripts in `/scripts/` to create organizational units, users, and security groups.

### 7. Apply Group Policies
- Use scripts to apply security baselines and configure GPOs for password policies, account lockout, etc.

### 8. Set Up Monitoring and Alerts
- Configure monitoring scripts and Task Scheduler for event log alerts and notifications.

### 9. Configure Backups
- Use backup scripts to schedule and test system state and AD backups.

### 10. Review Documentation
- Refer to `/docs/` for detailed guides on disaster recovery, monitoring, and security.

---

## Folder Structure

- `/scripts/` – PowerShell automation for provisioning, GPO, and monitoring
- `/docs/` – Documentation for disaster recovery and monitoring strategy
- `/architecture/` – Network or system topology diagrams

---

## Security Considerations

This lab is designed with security best practices in mind, including:
- Role-based access
- Scripted user management to reduce error
- Logging and alerting for anomaly detection
- Backup and recovery testing

---


## References and Online Resources

The following resources provide authoritative guidance and best practices for Windows Server labs, Active Directory, automation, and security:

- [Microsoft Learn: Windows Server Documentation](https://learn.microsoft.com/en-us/windows-server/)
- [Active Directory Domain Services Overview](https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/get-started/virtual-dc/active-directory-domain-services-overview)
- [Active Directory Security Best Practices](https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/plan/security-best-practices/ad-ds-security-best-practices)
- [Group Policy Overview](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/group-policy-overview)
- [PowerShell Documentation](https://learn.microsoft.com/en-us/powershell/)
- [PowerShell Gallery: ADDS Deployment Scripts](https://www.powershellgallery.com/packages/ADDSDeployment/)
- [Windows Server Lab Guides (Microsoft)](https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/deploy/step-by-step-active-directory-domain-services)
- [Windows Server Backup and Recovery](https://learn.microsoft.com/en-us/windows-server/storage/backup/windows-server-backup)
- [Monitoring Windows Server](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/monitoring-windows-server)
- [Sysinternals Suite](https://learn.microsoft.com/en-us/sysinternals/)
- [Microsoft Security Compliance Toolkit](https://learn.microsoft.com/en-us/windows/security/threat-protection/windows-security-configuration-framework/windows-security-baselines)

For community discussions and troubleshooting:
- [Microsoft Q&A: Windows Server](https://learn.microsoft.com/en-us/answers/topics/windows-server.html)
- [r/sysadmin (Reddit)](https://www.reddit.com/r/sysadmin/)
- [Spiceworks Community](https://community.spiceworks.com/windows-server)

---

## License

MIT License
