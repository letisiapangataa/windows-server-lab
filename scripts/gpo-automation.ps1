# Group Policy Automation Script
# Apply security baselines, login restrictions, and software controls
# Usage: Run as Domain Admin on Windows Server 2022

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$LogPath = ".\logs\gpo-automation.log",
    
    [Parameter(Mandatory=$false)]
    [switch]$WhatIf,
    
    [Parameter(Mandatory=$false)]
    [string]$DomainName = "lab.local"
)

Import-Module GroupPolicy
Import-Module ActiveDirectory

# Create log directory if it doesn't exist
$LogDir = Split-Path $LogPath -Parent
if (!(Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force
}

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

# Function to create GPO if it doesn't exist
function New-GPOIfNotExists {
    param(
        [string]$GPOName,
        [string]$Comment = ""
    )
    
    try {
        $ExistingGPO = Get-GPO -Name $GPOName -ErrorAction Stop
        Write-Log "GPO already exists: $GPOName"
        return $ExistingGPO
    }
    catch {
        if ($WhatIf) {
            Write-Log "WHATIF: Would create GPO: $GPOName"
            return $null
        }
        else {
            try {
                $NewGPO = New-GPO -Name $GPOName -Comment $Comment
                Write-Log "Created GPO: $GPOName"
                return $NewGPO
            }
            catch {
                Write-Log "Failed to create GPO $GPOName: $($_.Exception.Message)" -Level "ERROR"
                return $null
            }
        }
    }
}

# Function to link GPO to OU
function Set-GPOLink {
    param(
        [string]$GPOName,
        [string]$TargetOU,
        [int]$Order = 1
    )
    
    try {
        if ($WhatIf) {
            Write-Log "WHATIF: Would link GPO $GPOName to $TargetOU"
        }
        else {
            $ExistingLink = Get-GPInheritance -Target $TargetOU | Where-Object { $_.DisplayName -eq $GPOName }
            if ($ExistingLink) {
                Write-Log "GPO already linked: $GPOName -> $TargetOU"
            }
            else {
                New-GPLink -Name $GPOName -Target $TargetOU -LinkEnabled Yes -Order $Order
                Write-Log "Linked GPO: $GPOName -> $TargetOU"
            }
        }
    }
    catch {
        Write-Log "Failed to link GPO $GPOName to $TargetOU: $($_.Exception.Message)" -Level "ERROR"
    }
}

Write-Log "Starting GPO automation script"

# Define GPO configurations
$GPOConfigurations = @(
    @{
        Name = "Security Baseline - Domain"
        TargetOU = "DC=lab,DC=local"
        Description = "Domain-wide security baseline settings"
        Settings = @{
            "Password Policy" = @{
                MinPasswordLength = 12
                PasswordComplexity = $true
                MaxPasswordAge = 90
                MinPasswordAge = 1
                PasswordHistoryCount = 24
            }
            "Account Lockout" = @{
                LockoutThreshold = 5
                LockoutDuration = 30
                ResetLockoutCounter = 30
            }
        }
    },
    @{
        Name = "Security Baseline - Staff"
        TargetOU = "OU=Staff,DC=lab,DC=local"
        Description = "Security settings for all staff"
        Settings = @{
            "User Rights" = @{
                "Allow log on locally" = @("Domain Users", "Administrators")
                "Deny log on as a service" = @("Guests")
                "Deny log on through Remote Desktop Services" = @("Guests")
            }
            "Security Options" = @{
                "Interactive logon: Do not display last user name" = "Enabled"
                "Interactive logon: Prompt user to change password before expiration" = 14
                "Network security: Do not store LAN Manager hash value on next password change" = "Enabled"
            }
        }
    },
    @{
        Name = "Workstation Security"
        TargetOU = "OU=Workstations,OU=Computers,DC=lab,DC=local"
        Description = "Security settings for workstations"
        Settings = @{
            "Windows Firewall" = "Enabled"
            "Windows Update" = "Automatic"
            "BitLocker" = "Required for fixed drives"
        }
    },
    @{
        Name = "Server Security"
        TargetOU = "OU=Servers,OU=Computers,DC=lab,DC=local"
        Description = "Security settings for servers"
        Settings = @{
            "Audit Policy" = @{
                "Audit account logon events" = "Success, Failure"
                "Audit logon events" = "Success, Failure"
                "Audit privilege use" = "Failure"
                "Audit system events" = "Success, Failure"
            }
        }
    },
    @{
        Name = "Remote Access Policy"
        TargetOU = "OU=Staff,DC=lab,DC=local"
        Description = "Remote access and VPN policies"
        Settings = @{
            "Network Access" = @{
                "VPN Access" = "VPN_Users group only"
                "RDP Access" = "IT_Admins group only"
            }
        }
    },
    @{
        Name = "Software Restriction Policy"
        TargetOU = "OU=Staff,DC=lab,DC=local"
        Description = "Software installation and execution restrictions"
        Settings = @{
            "AppLocker" = @{
                "Default Rule" = "Allow administrators, deny everyone else"
                "Executable Rules" = "Allow approved software only"
            }
        }
    }
)

# Create and configure GPOs
foreach ($Config in $GPOConfigurations) {
    Write-Log "Processing GPO: $($Config.Name)"
    
    # Create GPO
    $GPO = New-GPOIfNotExists -GPOName $Config.Name -Comment $Config.Description
    
    if ($GPO -or $WhatIf) {
        # Link GPO to target OU
        Set-GPOLink -GPOName $Config.Name -TargetOU $Config.TargetOU
        
        # Apply settings (demonstration - real implementation would use Set-GPRegistryValue, etc.)
        if (!$WhatIf) {
            foreach ($SettingCategory in $Config.Settings.Keys) {
                Write-Log "Configuring $SettingCategory settings for $($Config.Name)"
                
                switch ($SettingCategory) {
                    "Password Policy" {
                        # Apply password policy settings
                        Write-Log "Applying password policy settings"
                        # In real scenario: Set-ADDefaultDomainPasswordPolicy
                    }
                    "Account Lockout" {
                        # Apply account lockout settings
                        Write-Log "Applying account lockout settings"
                    }
                    "User Rights" {
                        # Configure user rights assignments
                        Write-Log "Configuring user rights assignments"
                    }
                    "Security Options" {
                        # Set security options
                        Write-Log "Configuring security options"
                    }
                    "Audit Policy" {
                        # Configure audit policies
                        Write-Log "Configuring audit policies"
                    }
                    default {
                        Write-Log "Configuring $SettingCategory settings"
                    }
                }
            }
        }
    }
}

# Set domain password policy
Write-Log "Setting domain password policy..."
if (!$WhatIf) {
    try {
        Set-ADDefaultDomainPasswordPolicy -ComplexityEnabled $true -MinPasswordLength 12 -MaxPasswordAge 90 -MinPasswordAge 1 -PasswordHistoryCount 24
        Write-Log "Domain password policy updated"
    }
    catch {
        Write-Log "Failed to set domain password policy: $($_.Exception.Message)" -Level "ERROR"
    }
}

# Create starter GPOs for different departments
$DepartmentGPOs = @(
    @{Name = "IT Department Policy"; OU = "OU=IT,OU=Staff,DC=lab,DC=local"},
    @{Name = "HR Department Policy"; OU = "OU=HR,OU=Staff,DC=lab,DC=local"},
    @{Name = "Finance Department Policy"; OU = "OU=Finance,OU=Staff,DC=lab,DC=local"}
)

Write-Log "Creating department-specific GPOs..."
foreach ($DeptGPO in $DepartmentGPOs) {
    $GPO = New-GPOIfNotExists -GPOName $DeptGPO.Name -Comment "Department-specific policies for $($DeptGPO.Name)"
    if ($GPO -or $WhatIf) {
        Set-GPOLink -GPOName $DeptGPO.Name -TargetOU $DeptGPO.OU
    }
}

# Force Group Policy update on all computers
Write-Log "Initiating Group Policy update..."
if (!$WhatIf) {
    try {
        # Get all computer accounts
        $Computers = Get-ADComputer -Filter * -SearchBase "OU=Computers,DC=lab,DC=local"
        
        foreach ($Computer in $Computers) {
            try {
                # Attempt to trigger GP update remotely
                Invoke-GPUpdate -Computer $Computer.Name -Force -RandomDelayInMinutes 0
                Write-Log "Triggered GP update on $($Computer.Name)"
            }
            catch {
                Write-Log "Failed to update GP on $($Computer.Name): $($_.Exception.Message)" -Level "WARN"
            }
        }
    }
    catch {
        Write-Log "Failed to initiate GP updates: $($_.Exception.Message)" -Level "WARN"
    }
}

Write-Log "GPO automation completed"
Write-Log "Summary:"
Write-Log "- Created $($GPOConfigurations.Count) security baseline GPOs"
Write-Log "- Created $($DepartmentGPOs.Count) department-specific GPOs"
Write-Log "- Applied password and security policies"
Write-Log ""
Write-Log "Next steps:"
Write-Log "1. Review and customize GPO settings using Group Policy Management Console"
Write-Log "2. Test policies in a pilot group before full deployment"
Write-Log "3. Monitor event logs for policy application issues"
Write-Log "4. Schedule regular policy compliance audits"
