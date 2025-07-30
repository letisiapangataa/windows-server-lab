# 🖥️ Windows Server Lab Environment

A fully virtualized lab designed to simulate enterprise-grade infrastructure with Active Directory, PowerShell automation, RBAC, monitoring, and disaster recovery. Built to demonstrate system engineering and cybersecurity fundamentals for roles in national security, infrastructure, and IT operations.

---

## 🔧 Tech Stack

- **Windows Server 2022** (Domain Controller, File Server)
- **Active Directory Domain Services (AD DS)**
- **Group Policy (GPO)**
- **PowerShell (v5+)**
- **Event Viewer, Task Scheduler**
- Optional: BitLocker, WSUS, Windows Admin Center

---

## 📚 Project Goals

- Implement a secure and functional AD domain
- Automate user and group provisioning with PowerShell
- Apply RBAC and least privilege access control
- Monitor critical logs and configure alerting
- Simulate disaster recovery operations

---

## 🛠️ Features

### ✅ Automated User Provisioning
- CSV-based user imports
- Auto-assigned to OUs and security groups
- Password, logon hours, and expiration policies

### ✅ RBAC with Least Privilege
- Role-based group access
- GPO restrictions per department (IT, HR, Finance)
- Delegation of control for helpdesk functions

### ✅ Monitoring & Alerting
- Event log tracking (logon failures, lockouts, privilege use)
- PowerShell scripts for real-time alert emails
- Scheduled Tasks for audit and recovery snapshots

### ✅ Disaster Recovery Testing
- System state backups of Domain Controller
- Bare-metal recovery simulation
- GPO export/import and drift validation

---

## 📁 File Structure

```bash
windows-server-lab/
├── scripts/
│   ├── bulk_user_provisioning.ps1
│   ├── backup_AD_state.ps1
│   └── alert_failed_logins.ps1
├── docs/
│   ├── lab-setup-guide.md
│   ├── rbac-strategy.md
│   └── disaster-recovery-plan.md
├── templates/
│   └── user_import_template.csv
└── README.md
