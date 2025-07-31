# Active Directory Lab Environment - Architecture Documentation

## Network Architecture

```
                    ┌─────────────────────────────────────────────────────────┐
                    │                   LAB.LOCAL DOMAIN                      │
                    │                                                         │
                    │  ┌─────────────────────────────────────────────────────┤
                    │  │              MANAGEMENT LAYER                       │
                    │  │                                                     │
                    │  │  ┌─────────────┐    ┌─────────────┐                │
                    │  │  │   DOMAIN    │    │  MONITORING │                │
                    │  │  │ CONTROLLER  │    │   SERVER    │                │
                    │  │  │   DC01      │    │   MON01     │                │
                    │  │  │             │    │             │                │
                    │  │  └─────────────┘    └─────────────┘                │
                    │  └─────────────────────────────────────────────────────┤
                    │                                                         │
                    │  ┌─────────────────────────────────────────────────────┤
                    │  │               COMPUTE LAYER                         │
                    │  │                                                     │
                    │  │  ┌─────────────┐    ┌─────────────┐                │
                    │  │  │APPLICATION  │    │    FILE     │                │
                    │  │  │   SERVER    │    │   SERVER    │                │
                    │  │  │   APP01     │    │   FILE01    │                │
                    │  │  │             │    │             │                │
                    │  │  └─────────────┘    └─────────────┘                │
                    │  └─────────────────────────────────────────────────────┤
                    │                                                         │
                    │  ┌─────────────────────────────────────────────────────┤
                    │  │               CLIENT LAYER                          │
                    │  │                                                     │
                    │  │  ┌───────────┐ ┌───────────┐ ┌───────────┐         │
                    │  │  │WORKSTATION│ │WORKSTATION│ │WORKSTATION│         │
                    │  │  │   WS01    │ │   WS02    │ │   WS03    │         │
                    │  │  │           │ │           │ │           │         │
                    │  │  └───────────┘ └───────────┘ └───────────┘         │
                    │  └─────────────────────────────────────────────────────┤
                    └─────────────────────────────────────────────────────────┘
```

## Active Directory Structure

### Domain Forest Structure
```
lab.local (Forest Root Domain)
├── Domain Controllers
│   └── DC01.lab.local (Primary DC)
├── Sites and Services
│   └── Default-First-Site-Name
│       ├── DC01.lab.local
│       └── Subnets: 192.168.1.0/24
└── Trusts: None (Single Domain)
```

### Organizational Unit (OU) Structure
```
DC=lab,DC=local
├── OU=Staff
│   ├── OU=IT
│   │   ├── Users: IT Administrators, Helpdesk Staff
│   │   └── Computers: IT Workstations
│   ├── OU=HR
│   │   ├── Users: HR Staff, HR Managers
│   │   └── Computers: HR Workstations
│   ├── OU=Finance
│   │   ├── Users: Finance Staff, Finance Managers
│   │   └── Computers: Finance Workstations
│   └── OU=General
│       ├── Users: General Staff
│       └── Computers: General Workstations
├── OU=ServiceAccounts
│   ├── SQL Service Accounts
│   ├── IIS Application Pool Accounts
│   └── Monitoring Service Accounts
├── OU=Computers
│   ├── OU=Workstations
│   │   ├── OU=IT-Workstations
│   │   ├── OU=HR-Workstations
│   │   └── OU=Finance-Workstations
│   ├── OU=Servers
│   │   ├── OU=Domain-Controllers
│   │   ├── OU=Application-Servers
│   │   ├── OU=File-Servers
│   │   └── OU=Monitoring-Servers
│   └── OU=Laptops
├── OU=Groups
│   ├── OU=Security-Groups
│   └── OU=Distribution-Groups
└── CN=Users (Default container - limited use)
```

## Group Policy Object (GPO) Structure

### Domain-Level GPOs
```
1. Default Domain Policy
   ├── Password Policy
   ├── Account Lockout Policy
   └── Kerberos Policy

2. Security Baseline - Domain
   ├── Audit Policy
   ├── User Rights Assignment
   └── Security Options
```

### OU-Specific GPOs
```
Staff OU:
├── Security Baseline - Staff
│   ├── User Rights Assignment
│   ├── Security Options
│   └── Software Restriction Policies
├── Remote Access Policy
│   ├── VPN Access Settings
│   └── RDP Restrictions
└── Software Deployment Policy
    ├── Standard Software Package
    └── Security Updates

IT OU:
├── IT Department Policy
│   ├── Administrative Tools Access
│   ├── PowerShell Execution Policy
│   └── Remote Management Settings
└── IT Security Policy
    ├── Privileged Access Workstation Settings
    └── Enhanced Audit Settings

Workstations OU:
├── Workstation Security Policy
│   ├── Windows Firewall Settings
│   ├── BitLocker Configuration
│   └── Application Whitelisting
└── User Experience Policy
    ├── Desktop Restrictions
    └── Start Menu Configuration

Servers OU:
├── Server Security Policy
│   ├── Enhanced Audit Settings
│   ├── Service Hardening
│   └── Network Security
└── Server Management Policy
    ├── Remote Management
    └── Backup Configuration
```

## Security Group Structure

### Administrative Groups
```
Domain Admins
├── Primary Domain Administrator
└── Emergency Break-Glass Account

IT_Admins
├── Senior System Administrators
├── Network Administrators
└── Security Administrators

Helpdesk
├── Tier 1 Support Staff
├── Tier 2 Support Staff
└── Password Reset Operators

IT_Operations
├── Monitoring Staff
├── Backup Operators
└── GPO Managers
```

### Departmental Groups
```
HR_Users
├── HR Staff
└── HR Administrators

HR_Managers
├── HR Department Head
└── HR Team Leaders

Finance_Users
├── Finance Staff
└── Accounting Staff

Finance_Managers
├── Finance Department Head
├── Accounting Manager
└── Financial Controller

All_Staff
├── HR_Users (nested)
├── Finance_Users (nested)
├── IT_Admins (nested)
└── General_Staff
```

### Access Control Groups
```
VPN_Users
├── Remote Workers
├── Traveling Staff
└── IT Support (for remote assistance)

Remote_Workers
├── Full-time Remote Employees
└── Part-time Remote Workers

File_Access_Groups
├── HR_Files_Access
├── Finance_Files_Access
├── IT_Files_Access
└── Public_Files_Access

Application_Access_Groups
├── ERP_Users
├── CRM_Users
└── Monitoring_Users
```

## Network Configuration

### IP Address Scheme
```
Network Segment: 192.168.1.0/24

Server Infrastructure:
├── Domain Controller (DC01): 192.168.1.10
├── File Server (FILE01): 192.168.1.20
├── Application Server (APP01): 192.168.1.30
├── Monitoring Server (MON01): 192.168.1.40
└── Backup Server (BACKUP01): 192.168.1.50

DHCP Scope:
├── Start IP: 192.168.1.100
├── End IP: 192.168.1.200
├── Subnet Mask: 255.255.255.0
├── Default Gateway: 192.168.1.1
├── DNS Servers: 192.168.1.10
└── Lease Duration: 8 days

Reserved IPs:
├── Network Printers: 192.168.1.210-220
├── Network Equipment: 192.168.1.1-9
└── Management Interfaces: 192.168.1.51-99
```

### DNS Configuration
```
Primary DNS Zone: lab.local
├── SOA Record: DC01.lab.local
├── NS Records: DC01.lab.local
├── A Records:
│   ├── DC01.lab.local → 192.168.1.10
│   ├── FILE01.lab.local → 192.168.1.20
│   ├── APP01.lab.local → 192.168.1.30
│   └── MON01.lab.local → 192.168.1.40
├── SRV Records: (Auto-created by AD)
│   ├── _ldap._tcp.lab.local
│   ├── _kerberos._tcp.lab.local
│   └── _gc._tcp.lab.local
└── Reverse Lookup Zone: 1.168.192.in-addr.arpa
    ├── PTR Records for all servers
    └── Dynamic updates enabled
```

## Service Architecture

### Active Directory Services
```
Domain Controller Services:
├── Active Directory Domain Services (AD DS)
├── Active Directory Certificate Services (AD CS) - Optional
├── DNS Server
├── DHCP Server - Optional
├── File Replication Service (FRS)
├── Distributed File System (DFS) - Optional
└── Group Policy Management
```

### Supporting Services
```
Authentication Services:
├── Kerberos Key Distribution Center (KDC)
├── NTLM Authentication
└── LDAP Directory Services

Network Services:
├── DNS Resolution
├── Time Synchronization (W32Time)
├── Network Location Awareness
└── Windows Firewall

Management Services:
├── Remote Server Administration Tools (RSAT)
├── PowerShell Remoting
├── Windows Remote Management (WinRM)
└── Event Log Service
```

## Data Flow Architecture

### Authentication Flow
```
1. User Logon Request
   ├── Client → Domain Controller
   ├── Kerberos TGT Request
   ├── TGT Issued
   └── Service Ticket Requests

2. Resource Access
   ├── Service Ticket Presentation
   ├── Authorization Check
   ├── Access Granted/Denied
   └── Audit Log Entry
```

### Group Policy Processing
```
1. Computer Startup
   ├── Computer Policy Download
   ├── Computer Policy Application
   └── Service Startup

2. User Logon
   ├── User Policy Download
   ├── User Policy Application
   └── Desktop Presentation

3. Background Refresh
   ├── Policy Change Detection
   ├── Incremental Policy Download
   └── Policy Reapplication
```

### Backup and Replication Flow
```
1. System State Backup
   ├── AD Database (NTDS.dit)
   ├── Registry Hives
   ├── Certificate Store
   └── SYSVOL Contents

2. Data Replication (Multi-DC)
   ├── Intrasite Replication
   ├── Intersite Replication
   └── Conflict Resolution

3. Monitoring Data Flow
   ├── Event Log Collection
   ├── Performance Counter Gathering
   ├── Alert Generation
   └── Notification Delivery
```

## Scalability Considerations

### Horizontal Scaling
```
Additional Domain Controllers:
├── Read-Write Domain Controllers
├── Read-Only Domain Controllers (RODC)
└── Global Catalog Servers

Site Configuration:
├── Multiple Sites for Geographic Distribution
├── Site Links and Replication Schedules
└── Site-Specific Services (DNS, DHCP)
```

### Vertical Scaling
```
Server Resource Optimization:
├── CPU: 4+ cores for production DCs
├── RAM: 8GB+ with additional 1GB per 1000 users
├── Storage: SSD for NTDS.dit and logs
└── Network: Gigabit Ethernet minimum
```

## Security Architecture

### Defense in Depth
```
Perimeter Security:
├── Firewall Rules
├── Network Segmentation
└── VPN Access Controls

Host Security:
├── Windows Firewall
├── Antivirus/Anti-malware
├── Host-based IDS
└── Application Whitelisting

Identity Security:
├── Strong Password Policies
├── Account Lockout Policies
├── Privileged Access Management
└── Multi-Factor Authentication (Future)

Data Security:
├── File System Permissions
├── Share Permissions
├── Encryption at Rest
└── Encryption in Transit
```

---

*This architecture documentation should be updated as the lab environment evolves and new components are added.*
