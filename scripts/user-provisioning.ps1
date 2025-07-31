# Automated User Provisioning Script
# Bulk-create users, assign to OUs and security groups
# Usage: Run as Domain Admin on Windows Server 2022
# Author: System Administrator
# Version: 2.0

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$CSVPath = ".\users.csv",
    
    [Parameter(Mandatory=$false)]
    [string]$LogPath = ".\logs\user-provisioning.log",
    
    [Parameter(Mandatory=$false)]
    [switch]$WhatIf
)

# Import required modules
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

# Function to generate secure random password
function New-RandomPassword {
    param([int]$Length = 12)
    
    $chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*"
    $password = ""
    for ($i = 0; $i -lt $Length; $i++) {
        $password += $chars[(Get-Random -Maximum $chars.Length)]
    }
    return $password
}

# Function to create organizational units if they don't exist
function New-OUIfNotExists {
    param([string]$OUPath)
    
    try {
        Get-ADOrganizationalUnit -Identity $OUPath -ErrorAction Stop
        Write-Log "OU already exists: $OUPath"
    }
    catch {
        try {
            # Extract OU name and parent path
            $OUName = ($OUPath -split ',')[0] -replace 'OU=', ''
            $ParentPath = ($OUPath -split ',', 2)[1]
            
            New-ADOrganizationalUnit -Name $OUName -Path $ParentPath
            Write-Log "Created OU: $OUPath"
        }
        catch {
            Write-Log "Failed to create OU: $OUPath - $($_.Exception.Message)" -Level "ERROR"
        }
    }
}

# Function to create security group if it doesn't exist
function New-GroupIfNotExists {
    param(
        [string]$GroupName,
        [string]$GroupScope = "Global",
        [string]$GroupCategory = "Security",
        [string]$Path = "CN=Users,DC=lab,DC=local"
    )
    
    try {
        Get-ADGroup -Identity $GroupName -ErrorAction Stop
        Write-Log "Group already exists: $GroupName"
    }
    catch {
        try {
            New-ADGroup -Name $GroupName -GroupScope $GroupScope -GroupCategory $GroupCategory -Path $Path
            Write-Log "Created group: $GroupName"
        }
        catch {
            Write-Log "Failed to create group: $GroupName - $($_.Exception.Message)" -Level "ERROR"
        }
    }
}

# Start logging
Write-Log "Starting user provisioning script"
Write-Log "CSV Path: $CSVPath"
Write-Log "WhatIf Mode: $($WhatIf.IsPresent)"

# Check if CSV file exists
if (!(Test-Path $CSVPath)) {
    Write-Log "CSV file not found: $CSVPath" -Level "ERROR"
    Write-Log "Creating sample CSV file..."
    
    # Create sample CSV
    $SampleCSV = @"
Name,SamAccountName,UserPrincipalName,FirstName,LastName,Department,Title,Manager,OU,Group,Description,Office,Phone
John Smith,jsmith,jsmith@lab.local,John,Smith,IT,System Administrator,,OU=IT,OU=Staff,DC=lab,DC=local,IT_Admins,System Administrator for lab environment,Room 101,555-0101
Jane Doe,jdoe,jdoe@lab.local,Jane,Doe,HR,HR Manager,,OU=HR,OU=Staff,DC=lab,DC=local,HR_Users,Human Resources Manager,Room 201,555-0201
Bob Wilson,bwilson,bwilson@lab.local,Bob,Wilson,Finance,Financial Analyst,,OU=Finance,OU=Staff,DC=lab,DC=local,Finance_Users,Financial Analyst,Room 301,555-0301
"@
    $SampleCSV | Out-File -FilePath $CSVPath -Encoding UTF8
    Write-Log "Sample CSV created at: $CSVPath"
    Write-Log "Please update the CSV file with your user data and run the script again."
    return
}

# Import users from CSV
try {
    $users = Import-Csv -Path $CSVPath
    Write-Log "Imported $($users.Count) users from CSV"
}
catch {
    Write-Log "Failed to import CSV: $($_.Exception.Message)" -Level "ERROR"
    return
}

# Validate CSV headers
$RequiredHeaders = @('Name', 'SamAccountName', 'UserPrincipalName', 'OU', 'Group')
$CSVHeaders = $users[0].PSObject.Properties.Name
$MissingHeaders = $RequiredHeaders | Where-Object { $_ -notin $CSVHeaders }

if ($MissingHeaders) {
    Write-Log "Missing required CSV headers: $($MissingHeaders -join ', ')" -Level "ERROR"
    return
}

# Initialize counters
$SuccessCount = 0
$ErrorCount = 0
$SkippedCount = 0

# Create OUs and Groups first
Write-Log "Creating OUs and Groups..."
$UniqueOUs = $users | Select-Object -ExpandProperty OU -Unique
$UniqueGroups = $users | Select-Object -ExpandProperty Group -Unique

foreach ($OU in $UniqueOUs) {
    if ($OU -and !$WhatIf) {
        New-OUIfNotExists -OUPath $OU
    }
}

foreach ($Group in $UniqueGroups) {
    if ($Group -and !$WhatIf) {
        New-GroupIfNotExists -GroupName $Group
    }
}

# Process each user
Write-Log "Processing users..."
foreach ($user in $users) {
    try {
        # Check if user already exists
        $ExistingUser = $null
        try {
            $ExistingUser = Get-ADUser -Identity $user.SamAccountName -ErrorAction Stop
        }
        catch {
            # User doesn't exist, which is what we want
        }
        
        if ($ExistingUser) {
            Write-Log "User already exists, skipping: $($user.SamAccountName)" -Level "WARN"
            $SkippedCount++
            continue
        }
        
        # Generate password if not provided
        $Password = if ($user.Password) { $user.Password } else { New-RandomPassword }
        $SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
        
        # Prepare user parameters
        $UserParams = @{
            Name = $user.Name
            SamAccountName = $user.SamAccountName
            UserPrincipalName = $user.UserPrincipalName
            AccountPassword = $SecurePassword
            Path = $user.OU
            Enabled = $true
            ChangePasswordAtLogon = $true
        }
        
        # Add optional parameters if they exist in CSV
        if ($user.FirstName) { $UserParams.GivenName = $user.FirstName }
        if ($user.LastName) { $UserParams.Surname = $user.LastName }
        if ($user.Department) { $UserParams.Department = $user.Department }
        if ($user.Title) { $UserParams.Title = $user.Title }
        if ($user.Description) { $UserParams.Description = $user.Description }
        if ($user.Office) { $UserParams.Office = $user.Office }
        if ($user.Phone) { $UserParams.OfficePhone = $user.Phone }
        
        if ($WhatIf) {
            Write-Log "WHATIF: Would create user: $($user.SamAccountName)"
        }
        else {
            # Create the user
            New-ADUser @UserParams
            Write-Log "Created user: $($user.SamAccountName)"
            
            # Add to group if specified
            if ($user.Group) {
                Add-ADGroupMember -Identity $user.Group -Members $user.SamAccountName
                Write-Log "Added $($user.SamAccountName) to group: $($user.Group)"
            }
            
            # Set manager if specified
            if ($user.Manager) {
                try {
                    Set-ADUser -Identity $user.SamAccountName -Manager $user.Manager
                    Write-Log "Set manager for $($user.SamAccountName): $($user.Manager)"
                }
                catch {
                    Write-Log "Failed to set manager for $($user.SamAccountName): $($_.Exception.Message)" -Level "WARN"
                }
            }
            
            # Output password for manual distribution (in production, use secure method)
            Write-Log "Password for $($user.SamAccountName): $Password" -Level "INFO"
            
            $SuccessCount++
        }
    }
    catch {
        Write-Log "Failed to create user $($user.SamAccountName): $($_.Exception.Message)" -Level "ERROR"
        $ErrorCount++
    }
}

# Summary
Write-Log "User provisioning completed"
Write-Log "Successfully created: $SuccessCount users"
Write-Log "Errors: $ErrorCount"
Write-Log "Skipped (already exist): $SkippedCount"
Write-Log "Log file saved to: $LogPath"

if (!$WhatIf -and $SuccessCount -gt 0) {
    Write-Log "IMPORTANT: Passwords have been logged. Please distribute securely and delete log after use."
}
