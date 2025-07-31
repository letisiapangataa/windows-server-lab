# Task Scheduler Configuration Script
# Set up automated tasks for monitoring, backups, and maintenance
# Usage: Run as Domain Admin

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$LogPath = ".\logs\task-scheduler.log",
    
    [Parameter(Mandatory=$false)]
    [switch]$WhatIf
)

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

# Function to create scheduled task
function New-ScheduledTaskIfNotExists {
    param(
        [string]$TaskName,
        [string]$Description,
        [string]$ScriptPath,
        [string]$Arguments = "",
        [string]$Schedule,
        [string]$StartTime = "02:00",
        [string]$RunAsUser = "SYSTEM"
    )
    
    try {
        $ExistingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        
        if ($ExistingTask) {
            Write-Log "Task already exists: $TaskName"
            return
        }
        
        if ($WhatIf) {
            Write-Log "WHATIF: Would create task: $TaskName"
            return
        }
        
        # Create task action
        $Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File `"$ScriptPath`" $Arguments"
        
        # Create task trigger based on schedule
        switch ($Schedule) {
            "Daily" {
                $Trigger = New-ScheduledTaskTrigger -Daily -At $StartTime
            }
            "Weekly" {
                $Trigger = New-ScheduledTaskTrigger -Weekly -At $StartTime -DaysOfWeek Sunday
            }
            "Hourly" {
                $Trigger = New-ScheduledTaskTrigger -Once -At $StartTime -RepetitionInterval (New-TimeSpan -Hours 1)
            }
            "Every15Minutes" {
                $Trigger = New-ScheduledTaskTrigger -Once -At $StartTime -RepetitionInterval (New-TimeSpan -Minutes 15)
            }
            default {
                $Trigger = New-ScheduledTaskTrigger -Daily -At $StartTime
            }
        }
        
        # Create task settings
        $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
        
        # Create task principal
        $Principal = New-ScheduledTaskPrincipal -UserId $RunAsUser -LogonType ServiceAccount -RunLevel Highest
        
        # Register the task
        Register-ScheduledTask -TaskName $TaskName -Description $Description -Action $Action -Trigger $Trigger -Settings $Settings -Principal $Principal
        
        Write-Log "Created scheduled task: $TaskName"
    }
    catch {
        Write-Log "Failed to create task $TaskName: $($_.Exception.Message)" -Level "ERROR"
    }
}

Write-Log "Starting Task Scheduler configuration..."

# Get script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Define scheduled tasks
$ScheduledTasks = @(
    @{
        Name = "AD-Monitoring-Hourly"
        Description = "Hourly monitoring of Active Directory events and performance"
        Script = Join-Path $ScriptDir "monitoring-alert.ps1"
        Arguments = "-CheckIntervalHours 1"
        Schedule = "Hourly"
        StartTime = "00:00"
    },
    @{
        Name = "AD-Backup-Daily"
        Description = "Daily backup of Active Directory and system state"
        Script = Join-Path $ScriptDir "backup-restore.ps1"
        Arguments = ""
        Schedule = "Daily"
        StartTime = "02:00"
    },
    @{
        Name = "AD-Backup-Weekly-Full"
        Description = "Weekly full backup of all AD components"
        Script = Join-Path $ScriptDir "backup-restore.ps1"
        Arguments = "-FullBackup"
        Schedule = "Weekly"
        StartTime = "01:00"
    },
    @{
        Name = "Security-Monitoring"
        Description = "Security event monitoring and alerting"
        Script = Join-Path $ScriptDir "monitoring-alert.ps1"
        Arguments = "-CheckIntervalHours 1"
        Schedule = "Every15Minutes"
        StartTime = "00:00"
    },
    @{
        Name = "GPO-Compliance-Check"
        Description = "Daily Group Policy compliance verification"
        Script = Join-Path $ScriptDir "gpo-automation.ps1"
        Arguments = "-WhatIf"
        Schedule = "Daily"
        StartTime = "06:00"
    }
)

# Create all scheduled tasks
foreach ($Task in $ScheduledTasks) {
    New-ScheduledTaskIfNotExists @Task
}

# Create maintenance tasks
Write-Log "Creating maintenance tasks..."

# Event log maintenance
$EventLogMaintenance = @{
    Name = "EventLog-Maintenance"
    Description = "Clean and maintain Windows event logs"
    Script = "powershell.exe"
    Arguments = "-Command `"Get-EventLog -List | ForEach-Object { if(`$_.Entries.Count -gt 50000) { Clear-EventLog -LogName `$_.Log } }`""
    Schedule = "Weekly"
    StartTime = "03:00"
}

if (!$WhatIf) {
    try {
        $Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument $EventLogMaintenance.Arguments
        $Trigger = New-ScheduledTaskTrigger -Weekly -At $EventLogMaintenance.StartTime -DaysOfWeek Sunday
        $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
        $Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        
        Register-ScheduledTask -TaskName $EventLogMaintenance.Name -Description $EventLogMaintenance.Description -Action $Action -Trigger $Trigger -Settings $Settings -Principal $Principal
        Write-Log "Created maintenance task: $($EventLogMaintenance.Name)"
    }
    catch {
        Write-Log "Failed to create maintenance task: $($_.Exception.Message)" -Level "ERROR"
    }
}

Write-Log "Task Scheduler configuration completed"
Write-Log "Created $($ScheduledTasks.Count) monitoring and backup tasks"
Write-Log ""
Write-Log "To verify tasks, run: Get-ScheduledTask | Where-Object {`$_.TaskName -like 'AD-*' -or `$_.TaskName -like 'Security-*'}"
