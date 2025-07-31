# Disaster Recovery and Backup Script
# Automated backup of AD and system state
# Usage: Run as Domain Admin, schedule with Task Scheduler

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$BackupPath = "D:\Backups",
    
    [Parameter(Mandatory=$false)]
    [string]$LogPath = ".\logs\backup.log",
    
    [Parameter(Mandatory=$false)]
    [int]$RetentionDays = 30,
    
    [Parameter(Mandatory=$false)]
    [switch]$FullBackup,
    
    [Parameter(Mandatory=$false)]
    [switch]$TestRestore
)

Import-Module ServerManager

# Create directories if they don't exist
$LogDir = Split-Path $LogPath -Parent
if (!(Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force }
if (!(Test-Path $BackupPath)) { New-Item -ItemType Directory -Path $BackupPath -Force }

# Function to write log entries
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] [$Level] $Message"
    Write-Host $LogEntry
    Add-Content -Path $LogPath -Value $LogEntry
}

# Function to clean old backups
function Remove-OldBackups {
    param([string]$Path, [int]$RetentionDays)
    
    try {
        $CutoffDate = (Get-Date).AddDays(-$RetentionDays)
        $OldBackups = Get-ChildItem -Path $Path -Directory | Where-Object { $_.CreationTime -lt $CutoffDate }
        
        foreach ($OldBackup in $OldBackups) {
            Remove-Item -Path $OldBackup.FullName -Recurse -Force
            Write-Log "Removed old backup: $($OldBackup.Name)"
        }
        
        Write-Log "Cleanup completed - Removed $($OldBackups.Count) old backups"
    }
    catch {
        Write-Log "Failed to clean old backups: $($_.Exception.Message)" -Level "ERROR"
    }
}

Write-Log "Starting backup script"
Write-Log "Backup path: $BackupPath"
Write-Log "Retention period: $RetentionDays days"

$BackupDate = Get-Date -Format "yyyyMMdd-HHmm"
$CurrentBackupPath = Join-Path $BackupPath "Backup-$BackupDate"
New-Item -ItemType Directory -Path $CurrentBackupPath -Force

try {
    # System State Backup using Windows Server Backup
    Write-Log "Starting system state backup..."
    
    $SystemStateBackupPath = Join-Path $CurrentBackupPath "SystemState"
    New-Item -ItemType Directory -Path $SystemStateBackupPath -Force
    
    # Use wbadmin for system state backup
    $WbadminArgs = @(
        "start", "systemstatebackup"
        "-backupTarget:$SystemStateBackupPath"
        "-quiet"
    )
    
    $BackupProcess = Start-Process -FilePath "wbadmin.exe" -ArgumentList $WbadminArgs -Wait -PassThru -NoNewWindow
    
    if ($BackupProcess.ExitCode -eq 0) {
        Write-Log "System state backup completed successfully"
    }
    else {
        Write-Log "System state backup failed with exit code: $($BackupProcess.ExitCode)" -Level "ERROR"
    }
    
    # AD Database Backup (additional NTDS.dit backup)
    Write-Log "Creating AD database backup..."
    
    $ADBackupPath = Join-Path $CurrentBackupPath "ActiveDirectory"
    New-Item -ItemType Directory -Path $ADBackupPath -Force
    
    # Export AD information
    $ExportPath = Join-Path $ADBackupPath "AD-Export-$BackupDate.ldif"
    
    try {
        # Export domain information
        $Domain = Get-ADDomain
        $DomainDN = $Domain.DistinguishedName
        
        # Use ldifde to export AD data
        $LdifdeArgs = @(
            "-f", $ExportPath
            "-d", $DomainDN
            "-r", "(objectClass=*)"
        )
        
        $LdifdeProcess = Start-Process -FilePath "ldifde.exe" -ArgumentList $LdifdeArgs -Wait -PassThru -NoNewWindow
        
        if ($LdifdeProcess.ExitCode -eq 0) {
            Write-Log "AD export completed: $ExportPath"
        }
        else {
            Write-Log "AD export failed with exit code: $($LdifdeProcess.ExitCode)" -Level "WARN"
        }
    }
    catch {
        Write-Log "Failed to export AD data: $($_.Exception.Message)" -Level "ERROR"
    }
    
    # Backup Group Policy Objects
    Write-Log "Backing up Group Policy Objects..."
    
    $GPOBackupPath = Join-Path $CurrentBackupPath "GroupPolicy"
    New-Item -ItemType Directory -Path $GPOBackupPath -Force
    
    try {
        Import-Module GroupPolicy
        $GPOs = Get-GPO -All
        
        foreach ($GPO in $GPOs) {
            try {
                $GPOBackup = Backup-GPO -Name $GPO.DisplayName -Path $GPOBackupPath
                Write-Log "Backed up GPO: $($GPO.DisplayName) - ID: $($GPOBackup.Id)"
            }
            catch {
                Write-Log "Failed to backup GPO $($GPO.DisplayName): $($_.Exception.Message)" -Level "WARN"
            }
        }
        
        # Create GPO report
        $ReportPath = Join-Path $GPOBackupPath "GPO-Report-$BackupDate.xml"
        Get-GPOReport -All -ReportType Xml -Path $ReportPath
        Write-Log "GPO report created: $ReportPath"
    }
    catch {
        Write-Log "Failed to backup GPOs: $($_.Exception.Message)" -Level "ERROR"
    }
    
    # Backup DHCP configuration (if DHCP role is installed)
    Write-Log "Checking for DHCP role..."
    
    try {
        $DHCPRole = Get-WindowsFeature -Name DHCP
        if ($DHCPRole.InstallState -eq "Installed") {
            Write-Log "DHCP role detected, creating backup..."
            
            $DHCPBackupPath = Join-Path $CurrentBackupPath "DHCP"
            New-Item -ItemType Directory -Path $DHCPBackupPath -Force
            
            $DHCPConfigFile = Join-Path $DHCPBackupPath "DHCP-Config-$BackupDate.xml"
            Export-DhcpServer -File $DHCPConfigFile -Leases
            Write-Log "DHCP configuration backed up: $DHCPConfigFile"
        }
    }
    catch {
        Write-Log "Failed to backup DHCP: $($_.Exception.Message)" -Level "WARN"
    }
    
    # Backup DNS configuration
    Write-Log "Backing up DNS configuration..."
    
    try {
        $DNSBackupPath = Join-Path $CurrentBackupPath "DNS"
        New-Item -ItemType Directory -Path $DNSBackupPath -Force
        
        # Export DNS zones
        $DNSZones = Get-DnsServerZone
        foreach ($Zone in $DNSZones) {
            if ($Zone.ZoneType -eq "Primary") {
                try {
                    $ZoneFile = Join-Path $DNSBackupPath "$($Zone.ZoneName)-$BackupDate.dns"
                    Export-DnsServerZone -Name $Zone.ZoneName -FileName $ZoneFile
                    Write-Log "Exported DNS zone: $($Zone.ZoneName)"
                }
                catch {
                    Write-Log "Failed to export DNS zone $($Zone.ZoneName): $($_.Exception.Message)" -Level "WARN"
                }
            }
        }
    }
    catch {
        Write-Log "Failed to backup DNS: $($_.Exception.Message)" -Level "WARN"
    }
    
    # Create backup manifest
    $ManifestPath = Join-Path $CurrentBackupPath "backup-manifest.json"
    $Manifest = @{
        BackupDate = $BackupDate
        ServerName = $env:COMPUTERNAME
        Domain = $env:USERDOMAIN
        BackupType = if ($FullBackup) { "Full" } else { "Incremental" }
        Components = @{
            SystemState = Test-Path (Join-Path $CurrentBackupPath "SystemState")
            ActiveDirectory = Test-Path (Join-Path $CurrentBackupPath "ActiveDirectory")
            GroupPolicy = Test-Path (Join-Path $CurrentBackupPath "GroupPolicy")
            DHCP = Test-Path (Join-Path $CurrentBackupPath "DHCP")
            DNS = Test-Path (Join-Path $CurrentBackupPath "DNS")
        }
        BackupSize = [math]::Round((Get-ChildItem $CurrentBackupPath -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB, 2)
    }
    
    $Manifest | ConvertTo-Json -Depth 3 | Out-File -FilePath $ManifestPath -Encoding UTF8
    Write-Log "Backup manifest created: $ManifestPath"
    
    # Test backup integrity (basic check)
    Write-Log "Verifying backup integrity..."
    $BackupFiles = Get-ChildItem -Path $CurrentBackupPath -Recurse -File
    Write-Log "Backup contains $($BackupFiles.Count) files totaling $($Manifest.BackupSize) MB"
    
    # Clean old backups
    Remove-OldBackups -Path $BackupPath -RetentionDays $RetentionDays
    
    Write-Log "Backup completed successfully"
    Write-Log "Backup location: $CurrentBackupPath"
}
catch {
    Write-Log "Backup failed: $($_.Exception.Message)" -Level "ERROR"
    exit 1
}

# Test restore procedure (if requested)
if ($TestRestore) {
    Write-Log "Starting test restore procedure..."
    
    try {
        # Test system state restore (simulation)
        Write-Log "TEST: System state restore would use: wbadmin start systemstaterecovery"
        
        # Test AD restore (simulation)
        Write-Log "TEST: AD restore would use: ntdsutil for authoritative restore"
        
        # Test GPO restore
        Write-Log "TEST: GPO restore verification..."
        $GPOBackupPath = Join-Path $CurrentBackupPath "GroupPolicy"
        if (Test-Path $GPOBackupPath) {
            $GPOBackups = Get-ChildItem -Path $GPOBackupPath -Directory
            Write-Log "TEST: Found $($GPOBackups.Count) GPO backups for restore"
        }
        
        Write-Log "Test restore procedure completed"
    }
    catch {
        Write-Log "Test restore failed: $($_.Exception.Message)" -Level "ERROR"
    }
}

Write-Log "Backup script finished"
