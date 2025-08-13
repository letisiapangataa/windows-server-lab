
# Windows Server Lab - Network Diagram

```
         ┌─────────────────────────────┐
         │         Internet            │
         └─────────────┬───────────────┘
                  │
         ┌─────────────▼───────────────┐
         │      Firewall/Router        │
         └─────────────┬───────────────┘
                  │
         ┌─────────────▼───────────────┐
         │        Core Switch          │
         └─────────────┬───────────────┘
                  │
   ┌─────────────────────────────┴─────────────────────────────┐
   │                                                           │
┌───────▼────────┐                                      ┌───────────▼─────────┐
│ Management VLAN│                                      │   User VLAN         │
└───────┬────────┘                                      └───────────┬─────────┘
   │                                                           │
┌───────▼─────────────┐                                 ┌────────────▼────────────┐
│ DC01 (Domain Ctrlr) │                                 │ Workstations (WS01-03)  │
│ MON01 (Monitoring)  │                                 │ Laptops (optional)      │
│ BACKUP01 (Backup)   │                                 └─────────────────────────┘
└───────┬─────────────┘
   │
   │
┌───────▼─────────────┐
│ FILE01 (File Server)│
│ APP01 (App Server)  │
└─────────────────────┘
```

**Legend:**
- All servers and clients are in the `192.168.1.0/24` subnet.
- Management VLAN: Domain Controller, Monitoring, Backup, File, and Application servers.
- User VLAN: Workstations and laptops.
- Firewall/Router separates internal lab from the Internet.

**Key Relationships:**
- All authentication and directory services flow through DC01.
- MON01 monitors all servers and workstations.
- BACKUP01 handles scheduled backups of critical servers.
- FILE01 and APP01 provide file and application services to users.


