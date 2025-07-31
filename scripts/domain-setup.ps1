# Server Setup and Domain Configuration Script
# Initial Windows Server 2022 setup and Active Directory installation
# Usage: Run as local Administrator on a fresh Windows Server 2022 installation

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$DomainName = "lab.local",
    
    [Parameter(Mandatory=$true)]
    [SecureString]$SafeModePassword,
    
    [Parameter(Mandatory=$false)]
    [string]$StaticIP = "192.168.1.10",
    
    [Parameter(Mandatory=$false)]
    [string]$SubnetMask = "255.255.255.0",
    
    [Parameter(Mandatory=$false)]
    [string]$DefaultGateway = "192.168.1.1",
    
    [Parameter(Mandatory=$false)]
    [string]$LogPath = "C:\Setup\domain-setup.log"
)

# Create log directory
$LogDir = Split-Path $LogPath -Parent
if (!(Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force }

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

# Function to test if reboot is required
function Test-RebootRequired {
    $RebootRequired = $false
    
    # Check for pending file operations
    if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired") {
        $RebootRequired = $true
    }
    
    # Check for pending computer rename
    $ComputerName = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName" -Name ComputerName
    $PendingComputerName = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName" -Name ComputerName
    
    if ($ComputerName.ComputerName -ne $PendingComputerName.ComputerName) {
        $RebootRequired = $true
    }
    
    return $RebootRequired
}

Write-Log "Starting Windows Server 2022 domain setup"
Write-Log "Domain Name: $DomainName"
Write-Log "Static IP: $StaticIP"

# Step 1: Configure static IP address
Write-Log "Configuring static IP address..."
try {
    $Adapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1
    
    if ($Adapter) {
        # Remove existing IP configuration
        Remove-NetIPAddress -InterfaceAlias $Adapter.Name -Confirm:$false -ErrorAction SilentlyContinue
        Remove-NetRoute -InterfaceAlias $Adapter.Name -Confirm:$false -ErrorAction SilentlyContinue
        
        # Set static IP
        New-NetIPAddress -InterfaceAlias $Adapter.Name -IPAddress $StaticIP -PrefixLength 24 -DefaultGateway $DefaultGateway
        
        # Set DNS to localhost (will be DC)
        Set-DnsClientServerAddress -InterfaceAlias $Adapter.Name -ServerAddresses $StaticIP
        
        Write-Log "Static IP configured successfully"
    }
    else {
        Write-Log "No active network adapter found" -Level "ERROR"
        return
    }
}
catch {
    Write-Log "Failed to configure static IP: $($_.Exception.Message)" -Level "ERROR"
    return
}

# Step 2: Rename computer if needed
$DesiredComputerName = "DC01"
if ($env:COMPUTERNAME -ne $DesiredComputerName) {
    Write-Log "Renaming computer to $DesiredComputerName..."
    try {
        Rename-Computer -NewName $DesiredComputerName -Force
        Write-Log "Computer renamed successfully - reboot required"
        
        Write-Log "Please reboot the server and run this script again to continue domain setup"
        return
    }
    catch {
        Write-Log "Failed to rename computer: $($_.Exception.Message)" -Level "ERROR"
    }
}

# Step 3: Install Active Directory Domain Services role
Write-Log "Installing AD DS role and management tools..."
try {
    $Features = @(
        "AD-Domain-Services",
        "DNS",
        "GPMC",
        "RSAT-AD-Tools",
        "RSAT-DNS-Server"
    )
    
    foreach ($Feature in $Features) {
        $InstallResult = Install-WindowsFeature -Name $Feature -IncludeManagementTools
        if ($InstallResult.Success) {
            Write-Log "Installed feature: $Feature"
        }
        else {
            Write-Log "Failed to install feature: $Feature" -Level "WARN"
        }
    }
    
    if (Test-RebootRequired) {
        Write-Log "Reboot required after feature installation"
        Write-Log "Please reboot and run this script again to continue"
        return
    }
}
catch {
    Write-Log "Failed to install AD DS role: $($_.Exception.Message)" -Level "ERROR"
    return
}

# Step 4: Promote server to domain controller
Write-Log "Promoting server to domain controller..."
try {
    Import-Module ADDSDeployment
    
    $ForestParams = @{
        DomainName = $DomainName
        SafeModeAdministratorPassword = $SafeModePassword
        InstallDns = $true
        CreateDnsDelegation = $false
        DatabasePath = "C:\Windows\NTDS"
        LogPath = "C:\Windows\NTDS"
        SysvolPath = "C:\Windows\SYSVOL"
        NoRebootOnCompletion = $true
        Force = $true
    }
    
    Install-ADDSForest @ForestParams
    
    Write-Log "Domain controller promotion completed"
    Write-Log "Server will reboot automatically to complete installation"
}
catch {
    Write-Log "Failed to promote to domain controller: $($_.Exception.Message)" -Level "ERROR"
    return
}

# Step 5: Configure DNS forwarders (post-reboot task)
$PostRebootScript = @'
# Post-reboot configuration script
Import-Module DnsServer
Import-Module ActiveDirectory

# Configure DNS forwarders
try {
    Add-DnsServerForwarder -IPAddress "8.8.8.8", "8.8.4.4"
    Write-Host "DNS forwarders configured"
}
catch {
    Write-Host "Failed to configure DNS forwarders: $($_.Exception.Message)"
}

# Create reverse lookup zone
try {
    Add-DnsServerPrimaryZone -NetworkID "192.168.1.0/24" -ReplicationScope "Forest"
    Write-Host "Reverse lookup zone created"
}
catch {
    Write-Host "Failed to create reverse lookup zone: $($_.Exception.Message)"
}

# Configure time synchronization
try {
    w32tm /config /manualpeerlist:"time.windows.com" /syncfromflags:manual /reliable:yes /update
    Restart-Service w32time
    Write-Host "Time synchronization configured"
}
catch {
    Write-Host "Failed to configure time sync: $($_.Exception.Message)"
}

Write-Host "Post-reboot configuration completed"
'@

$PostRebootScriptPath = "C:\Setup\post-reboot-config.ps1"
$PostRebootScript | Out-File -FilePath $PostRebootScriptPath -Encoding UTF8

# Create scheduled task for post-reboot configuration
try {
    $Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File `"$PostRebootScriptPath`""
    $Trigger = New-ScheduledTaskTrigger -AtStartup
    $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    $Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    
    Register-ScheduledTask -TaskName "PostRebootDomainConfig" -Description "Post-reboot domain configuration" -Action $Action -Trigger $Trigger -Settings $Settings -Principal $Principal
    
    Write-Log "Post-reboot configuration task created"
}
catch {
    Write-Log "Failed to create post-reboot task: $($_.Exception.Message)" -Level "WARN"
}

Write-Log "Domain setup script completed"
Write-Log "The server will reboot to complete the domain controller installation"
Write-Log "After reboot, run the RBAC and GPO scripts to complete the lab setup"
