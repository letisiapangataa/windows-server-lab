# PowerShell Execution Policy Configuration
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine -Force

# Create logs directory if it doesn't exist
if (!(Test-Path ".\logs")) {
    New-Item -ItemType Directory -Path ".\logs" -Force
    Write-Host "Created logs directory"
}

# Create config directory if it doesn't exist
if (!(Test-Path ".\config")) {
    New-Item -ItemType Directory -Path ".\config" -Force
    Write-Host "Created config directory"
}

Write-Host "Lab environment scripts are ready to use!"
Write-Host ""
Write-Host "To get started:"
Write-Host "1. Run .\domain-setup.ps1 to set up the domain controller"
Write-Host "2. Run .\rbac-setup.ps1 to create the organizational structure"
Write-Host "3. Run .\user-provisioning.ps1 to create users and groups"
Write-Host "4. Run .\gpo-automation.ps1 to apply security policies"
Write-Host "5. Run .\monitoring-alert.ps1 -TestMode to test monitoring"
Write-Host "6. Run .\task-scheduler-setup.ps1 to automate tasks"
Write-Host ""
Write-Host "Remember to run these scripts as Administrator!"
