# Monitoring and Alerting Script
# Event log alerting and email notifications
# Usage: Configure with Task Scheduler for automated monitoring

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$LogPath = ".\logs\monitoring.log",
    
    [Parameter(Mandatory=$false)]
    [string]$AlertConfigPath = ".\config\alert-config.json",
    
    [Parameter(Mandatory=$false)]
    [string]$EmailTo = "admin@lab.local",
    
    [Parameter(Mandatory=$false)]
    [string]$SmtpServer = "smtp.lab.local",
    
    [Parameter(Mandatory=$false)]
    [int]$CheckIntervalHours = 1,
    
    [Parameter(Mandatory=$false)]
    [switch]$TestMode
)

# Create necessary directories
$LogDir = Split-Path $LogPath -Parent
$ConfigDir = Split-Path $AlertConfigPath -Parent

if (!(Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force }
if (!(Test-Path $ConfigDir)) { New-Item -ItemType Directory -Path $ConfigDir -Force }

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

# Function to send email alert
function Send-Alert {
    param(
        [string]$Subject,
        [string]$Body,
        [string]$Priority = "Normal"
    )
    
    try {
        if ($TestMode) {
            Write-Log "TEST MODE: Would send email - Subject: $Subject"
            return
        }
        
        $EmailParams = @{
            To = $EmailTo
            From = "monitoring@lab.local"
            Subject = $Subject
            Body = $Body
            SmtpServer = $SmtpServer
            Priority = $Priority
        }
        
        Send-MailMessage @EmailParams
        Write-Log "Alert sent: $Subject"
    }
    catch {
        Write-Log "Failed to send alert: $($_.Exception.Message)" -Level "ERROR"
    }
}

# Create default alert configuration if it doesn't exist
if (!(Test-Path $AlertConfigPath)) {
    Write-Log "Creating default alert configuration..."
    
    $DefaultConfig = @{
        EventLogAlerts = @(
            @{
                LogName = "Security"
                EventID = 4625
                Description = "Failed logon attempts"
                Threshold = 5
                TimeWindowMinutes = 15
                Priority = "High"
                Enabled = $true
            },
            @{
                LogName = "Security"
                EventID = 4648
                Description = "A logon was attempted using explicit credentials"
                Threshold = 10
                TimeWindowMinutes = 30
                Priority = "Medium"
                Enabled = $true
            },
            @{
                LogName = "Security"
                EventID = 4672
                Description = "Special privileges assigned to new logon"
                Threshold = 3
                TimeWindowMinutes = 10
                Priority = "High"
                Enabled = $true
            },
            @{
                LogName = "System"
                EventID = 7034
                Description = "Service crashed unexpectedly"
                Threshold = 1
                TimeWindowMinutes = 5
                Priority = "Critical"
                Enabled = $true
            },
            @{
                LogName = "Application"
                EventID = 1000
                Description = "Application error"
                Threshold = 3
                TimeWindowMinutes = 15
                Priority = "Medium"
                Enabled = $true
            },
            @{
                LogName = "Security"
                EventID = 4740
                Description = "User account was locked out"
                Threshold = 1
                TimeWindowMinutes = 5
                Priority = "High"
                Enabled = $true
            },
            @{
                LogName = "Security"
                EventID = 4728
                Description = "Member was added to security-enabled global group"
                Threshold = 1
                TimeWindowMinutes = 5
                Priority = "High"
                Enabled = $true
            }
        )
        PerformanceCounters = @(
            @{
                Counter = "\Processor(_Total)\% Processor Time"
                Threshold = 90
                Description = "High CPU usage"
                Priority = "Medium"
                Enabled = $true
            },
            @{
                Counter = "\Memory\Available MBytes"
                Threshold = 512
                ThresholdType = "Below"
                Description = "Low available memory"
                Priority = "High"
                Enabled = $true
            },
            @{
                Counter = "\LogicalDisk(C:)\% Free Space"
                Threshold = 10
                ThresholdType = "Below"
                Description = "Low disk space on C: drive"
                Priority = "Critical"
                Enabled = $true
            }
        )
        ServiceMonitoring = @(
            @{
                ServiceName = "ADWS"
                DisplayName = "Active Directory Web Services"
                Priority = "Critical"
                Enabled = $true
            },
            @{
                ServiceName = "DNS"
                DisplayName = "DNS Server"
                Priority = "Critical"
                Enabled = $true
            },
            @{
                ServiceName = "Netlogon"
                DisplayName = "Netlogon"
                Priority = "Critical"
                Enabled = $true
            },
            @{
                ServiceName = "NTDS"
                DisplayName = "Active Directory Domain Services"
                Priority = "Critical"
                Enabled = $true
            }
        )
    }
    
    $DefaultConfig | ConvertTo-Json -Depth 5 | Out-File -FilePath $AlertConfigPath -Encoding UTF8
    Write-Log "Default configuration created at: $AlertConfigPath"
}

# Load alert configuration
try {
    $Config = Get-Content $AlertConfigPath | ConvertFrom-Json
    Write-Log "Loaded alert configuration from: $AlertConfigPath"
}
catch {
    Write-Log "Failed to load configuration: $($_.Exception.Message)" -Level "ERROR"
    return
}

Write-Log "Starting monitoring script - Check interval: $CheckIntervalHours hours"

# Check Event Logs
Write-Log "Checking event logs..."
$StartTime = (Get-Date).AddHours(-$CheckIntervalHours)

foreach ($Alert in $Config.EventLogAlerts | Where-Object { $_.Enabled }) {
    try {
        $TimeWindow = (Get-Date).AddMinutes(-$Alert.TimeWindowMinutes)
        
        $Events = Get-WinEvent -FilterHashtable @{
            LogName = $Alert.LogName
            ID = $Alert.EventID
            StartTime = $TimeWindow
        } -ErrorAction SilentlyContinue
        
        if ($Events.Count -ge $Alert.Threshold) {
            $AlertSubject = "ALERT: $($Alert.Description) - $($Events.Count) events in $($Alert.TimeWindowMinutes) minutes"
            $AlertBody = @"
Alert Details:
- Event ID: $($Alert.EventID)
- Log: $($Alert.LogName)
- Count: $($Events.Count)
- Threshold: $($Alert.Threshold)
- Time Window: $($Alert.TimeWindowMinutes) minutes
- Priority: $($Alert.Priority)

Recent Events:
$($Events | Select-Object -First 5 | Format-Table TimeCreated, Id, LevelDisplayName, Message -AutoSize | Out-String)

Please investigate immediately.
"@
            
            Send-Alert -Subject $AlertSubject -Body $AlertBody -Priority $Alert.Priority
            Write-Log "Event alert triggered: $($Alert.Description) - $($Events.Count) events" -Level "WARN"
        }
        else {
            Write-Log "Event check OK: $($Alert.Description) - $($Events.Count)/$($Alert.Threshold) events"
        }
    }
    catch {
        Write-Log "Failed to check event $($Alert.EventID) in $($Alert.LogName): $($_.Exception.Message)" -Level "ERROR"
    }
}

# Check Performance Counters
Write-Log "Checking performance counters..."
foreach ($PerfAlert in $Config.PerformanceCounters | Where-Object { $_.Enabled }) {
    try {
        $CounterValue = (Get-Counter -Counter $PerfAlert.Counter -SampleInterval 1 -MaxSamples 1).CounterSamples.CookedValue
        
        $AlertTriggered = $false
        if ($PerfAlert.ThresholdType -eq "Below") {
            $AlertTriggered = $CounterValue -lt $PerfAlert.Threshold
        }
        else {
            $AlertTriggered = $CounterValue -gt $PerfAlert.Threshold
        }
        
        if ($AlertTriggered) {
            $AlertSubject = "PERFORMANCE ALERT: $($PerfAlert.Description)"
            $AlertBody = @"
Performance Alert:
- Counter: $($PerfAlert.Counter)
- Current Value: $([math]::Round($CounterValue, 2))
- Threshold: $($PerfAlert.Threshold)
- Threshold Type: $($PerfAlert.ThresholdType)
- Priority: $($PerfAlert.Priority)

Please investigate system performance.
"@
            
            Send-Alert -Subject $AlertSubject -Body $AlertBody -Priority $PerfAlert.Priority
            Write-Log "Performance alert triggered: $($PerfAlert.Description) - Value: $([math]::Round($CounterValue, 2))" -Level "WARN"
        }
        else {
            Write-Log "Performance check OK: $($PerfAlert.Description) - Value: $([math]::Round($CounterValue, 2))"
        }
    }
    catch {
        Write-Log "Failed to check performance counter $($PerfAlert.Counter): $($_.Exception.Message)" -Level "ERROR"
    }
}

# Check Critical Services
Write-Log "Checking critical services..."
foreach ($ServiceAlert in $Config.ServiceMonitoring | Where-Object { $_.Enabled }) {
    try {
        $Service = Get-Service -Name $ServiceAlert.ServiceName -ErrorAction SilentlyContinue
        
        if (!$Service) {
            $AlertSubject = "SERVICE ALERT: Service not found - $($ServiceAlert.DisplayName)"
            $AlertBody = "Critical service '$($ServiceAlert.ServiceName)' was not found on the system."
            Send-Alert -Subject $AlertSubject -Body $AlertBody -Priority $ServiceAlert.Priority
            Write-Log "Service not found: $($ServiceAlert.ServiceName)" -Level "ERROR"
        }
        elseif ($Service.Status -ne "Running") {
            $AlertSubject = "SERVICE ALERT: Service stopped - $($ServiceAlert.DisplayName)"
            $AlertBody = @"
Service Alert:
- Service: $($ServiceAlert.DisplayName) ($($ServiceAlert.ServiceName))
- Status: $($Service.Status)
- Priority: $($ServiceAlert.Priority)

Please investigate and restart the service if necessary.
"@
            
            Send-Alert -Subject $AlertSubject -Body $AlertBody -Priority $ServiceAlert.Priority
            Write-Log "Service alert: $($ServiceAlert.ServiceName) is $($Service.Status)" -Level "WARN"
        }
        else {
            Write-Log "Service check OK: $($ServiceAlert.ServiceName) is running"
        }
    }
    catch {
        Write-Log "Failed to check service $($ServiceAlert.ServiceName): $($_.Exception.Message)" -Level "ERROR"
    }
}

# Generate system health summary
$HealthSummary = @{
    Timestamp = Get-Date
    ServerName = $env:COMPUTERNAME
    Domain = $env:USERDOMAIN
    UptimeHours = [math]::Round(((Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime).TotalHours, 2)
    EventAlerts = ($Config.EventLogAlerts | Where-Object { $_.Enabled }).Count
    PerfCounters = ($Config.PerformanceCounters | Where-Object { $_.Enabled }).Count
    Services = ($Config.ServiceMonitoring | Where-Object { $_.Enabled }).Count
}

Write-Log "System Health Summary:"
Write-Log "- Server: $($HealthSummary.ServerName)"
Write-Log "- Domain: $($HealthSummary.Domain)"
Write-Log "- Uptime: $($HealthSummary.UptimeHours) hours"
Write-Log "- Monitoring $($HealthSummary.EventAlerts) event types"
Write-Log "- Monitoring $($HealthSummary.PerfCounters) performance counters"
Write-Log "- Monitoring $($HealthSummary.Services) critical services"

Write-Log "Monitoring script completed"

# If this is a test run, send a test email
if ($TestMode) {
    $TestSubject = "Test Alert - Monitoring System Active"
    $TestBody = @"
This is a test alert from the monitoring system.

System Information:
$($HealthSummary | ConvertTo-Json -Depth 2)

If you receive this email, the monitoring system is working correctly.
"@
    
    Send-Alert -Subject $TestSubject -Body $TestBody -Priority "Low"
}
