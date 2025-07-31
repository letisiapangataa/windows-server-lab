# RBAC Implementation Script
# Set up Role-Based Access Control with least-privilege model
# Usage: Run as Domain Admin on Windows Server 2022

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$LogPath = ".\logs\rbac-setup.log",
    
    [Parameter(Mandatory=$false)]
    [switch]$WhatIf
)

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

Write-Log "Starting RBAC setup script"

# Define organizational structure
$OUs = @(
    @{Name="Staff"; Path="DC=lab,DC=local"; Description="All staff members"},
    @{Name="IT"; Path="OU=Staff,DC=lab,DC=local"; Description="IT Department"},
    @{Name="HR"; Path="OU=Staff,DC=lab,DC=local"; Description="Human Resources"},
    @{Name="Finance"; Path="OU=Staff,DC=lab,DC=local"; Description="Finance Department"},
    @{Name="ServiceAccounts"; Path="DC=lab,DC=local"; Description="Service accounts"},
    @{Name="Computers"; Path="DC=lab,DC=local"; Description="Computer accounts"},
    @{Name="Workstations"; Path="OU=Computers,DC=lab,DC=local"; Description="User workstations"},
    @{Name="Servers"; Path="OU=Computers,DC=lab,DC=local"; Description="Server computers"}
)

# Define security groups with RBAC roles
$SecurityGroups = @(
    @{Name="IT_Admins"; Scope="Global"; Category="Security"; Path="OU=IT,OU=Staff,DC=lab,DC=local"; Description="IT Administrators with elevated privileges"},
    @{Name="Helpdesk"; Scope="Global"; Category="Security"; Path="OU=IT,OU=Staff,DC=lab,DC=local"; Description="Helpdesk staff with limited admin rights"},
    @{Name="IT_Operations"; Scope="Global"; Category="Security"; Path="OU=IT,OU=Staff,DC=lab,DC=local"; Description="IT Operations team for monitoring and GPO management"},
    @{Name="HR_Users"; Scope="Global"; Category="Security"; Path="OU=HR,OU=Staff,DC=lab,DC=local"; Description="Human Resources staff"},
    @{Name="HR_Managers"; Scope="Global"; Category="Security"; Path="OU=HR,OU=Staff,DC=lab,DC=local"; Description="HR Managers with additional privileges"},
    @{Name="Finance_Users"; Scope="Global"; Category="Security"; Path="OU=Finance,OU=Staff,DC=lab,DC=local"; Description="Finance department staff"},
    @{Name="Finance_Managers"; Scope="Global"; Category="Security"; Path="OU=Finance,OU=Staff,DC=lab,DC=local"; Description="Finance managers"},
    @{Name="All_Staff"; Scope="Global"; Category="Security"; Path="OU=Staff,DC=lab,DC=local"; Description="All staff members"},
    @{Name="VPN_Users"; Scope="Global"; Category="Security"; Path="OU=Staff,DC=lab,DC=local"; Description="Users allowed VPN access"},
    @{Name="Remote_Workers"; Scope="Global"; Category="Security"; Path="OU=Staff,DC=lab,DC=local"; Description="Remote workers with special policies"}
)

# Create Organizational Units
Write-Log "Creating Organizational Units..."
foreach ($OU in $OUs) {
    try {
        $ExistingOU = $null
        try {
            $ExistingOU = Get-ADOrganizationalUnit -Identity "OU=$($OU.Name),$($OU.Path)" -ErrorAction Stop
        }
        catch {
            # OU doesn't exist
        }
        
        if ($ExistingOU) {
            Write-Log "OU already exists: $($OU.Name)"
        }
        elseif ($WhatIf) {
            Write-Log "WHATIF: Would create OU: $($OU.Name)"
        }
        else {
            New-ADOrganizationalUnit -Name $OU.Name -Path $OU.Path -Description $OU.Description -ProtectedFromAccidentalDeletion $true
            Write-Log "Created OU: $($OU.Name)"
        }
    }
    catch {
        Write-Log "Failed to create OU $($OU.Name): $($_.Exception.Message)" -Level "ERROR"
    }
}

# Create Security Groups
Write-Log "Creating Security Groups..."
foreach ($Group in $SecurityGroups) {
    try {
        $ExistingGroup = $null
        try {
            $ExistingGroup = Get-ADGroup -Identity $Group.Name -ErrorAction Stop
        }
        catch {
            # Group doesn't exist
        }
        
        if ($ExistingGroup) {
            Write-Log "Group already exists: $($Group.Name)"
        }
        elseif ($WhatIf) {
            Write-Log "WHATIF: Would create group: $($Group.Name)"
        }
        else {
            New-ADGroup -Name $Group.Name -GroupScope $Group.Scope -GroupCategory $Group.Category -Path $Group.Path -Description $Group.Description
            Write-Log "Created group: $($Group.Name)"
        }
    }
    catch {
        Write-Log "Failed to create group $($Group.Name): $($_.Exception.Message)" -Level "ERROR"
    }
}

# Set up group nesting for easier management
Write-Log "Setting up group nesting..."
$GroupNesting = @(
    @{Parent="All_Staff"; Child="HR_Users"},
    @{Parent="All_Staff"; Child="Finance_Users"},
    @{Parent="All_Staff"; Child="IT_Admins"},
    @{Parent="All_Staff"; Child="Helpdesk"},
    @{Parent="All_Staff"; Child="IT_Operations"},
    @{Parent="HR_Managers"; Child="HR_Users"},
    @{Parent="Finance_Managers"; Child="Finance_Users"}
)

foreach ($Nesting in $GroupNesting) {
    try {
        if ($WhatIf) {
            Write-Log "WHATIF: Would add $($Nesting.Child) to $($Nesting.Parent)"
        }
        else {
            Add-ADGroupMember -Identity $Nesting.Parent -Members $Nesting.Child
            Write-Log "Added $($Nesting.Child) to $($Nesting.Parent)"
        }
    }
    catch {
        Write-Log "Failed to nest groups $($Nesting.Child) -> $($Nesting.Parent): $($_.Exception.Message)" -Level "WARN"
    }
}

# Delegate permissions for RBAC
Write-Log "Setting up delegated permissions..."

if (!$WhatIf) {
    try {
        # Grant Helpdesk password reset permissions on Staff OU
        $StaffOU = "OU=Staff,DC=lab,DC=local"
        $HelpdeskGroup = Get-ADGroup -Identity "Helpdesk"
        
        # This would typically use dsacls.exe or Set-ACL for more granular permissions
        # For demonstration, we'll log the intended actions
        Write-Log "Would delegate password reset permissions to Helpdesk on $StaffOU"
        Write-Log "Would delegate user account management to Helpdesk on $StaffOU"
        
        # Grant IT_Operations GPO management permissions
        Write-Log "Would delegate GPO management permissions to IT_Operations"
        
        # Note: In a real environment, you would use:
        # dsacls.exe or PowerShell ACL cmdlets to set specific permissions
    }
    catch {
        Write-Log "Failed to set delegated permissions: $($_.Exception.Message)" -Level "ERROR"
    }
}

Write-Log "RBAC setup completed"
Write-Log "Next steps:"
Write-Log "1. Assign users to appropriate groups"
Write-Log "2. Configure Group Policy Objects for each role"
Write-Log "3. Test delegated permissions"
Write-Log "4. Document role assignments and permissions"
