# Disaster Recovery Procedures

## AD Services Restore
1. Restore system state backup using Windows Server Backup.
2. Use authoritative restore for AD objects if needed.
3. Validate AD replication and service health.

## System State Backup
- Schedule regular backups using Task Scheduler and Windows Server Backup.
- Store backups securely and test restores quarterly.

## Recovery Testing
- Document restore steps and test procedures.
- Log all recovery actions for audit.
