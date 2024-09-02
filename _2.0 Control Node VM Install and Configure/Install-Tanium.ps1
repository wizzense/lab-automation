# Define variables
$vmName = "YourVMName"
$vmAdminUser = "Administrator"
$vmAdminPassword = "YourVMPassword"
$vmIPAddress = "192.168.1.100"  # Replace with your VM's IP address

# Define source and destination paths
$sourcePath = "C:\Path\To\Source\Files"
$destinationPath = "C:\Users\$vmAdminUser\Desktop\InstallFiles"

# Installation script path on the VM
$installScript = "$destinationPath\install.ps1"

# Create a PSCredential object
$securePassword = ConvertTo-SecureString $vmAdminPassword -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($vmAdminUser, $securePassword)

# Test connectivity to the VM
if (Test-Connection -ComputerName $vmIPAddress -Count 1 -Quiet) {
    # Create the destination directory on the VM
    Invoke-Command -ComputerName $vmIPAddress -Credential $credential -ScriptBlock {
        param($destinationPath)
        if (-not (Test-Path -Path $destinationPath)) {
            New-Item -ItemType Directory -Path $destinationPath -Force
        }
    } -ArgumentList $destinationPath

    # Copy files to the VM
    Copy-Item -Path $sourcePath\* -Destination "\\$vmIPAddress\C$\Users\$vmAdminUser\Desktop\InstallFiles" -Recurse -Force -Credential $credential

    # Run the installation script on the VM
    Invoke-Command -ComputerName $vmIPAddress -Credential $credential -ScriptBlock {
        param($installScript)
        
        if (Test-Path -Path $installScript) {
            Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
            & $installScript
        } else {
            Write-Host "Installation script not found at $installScript"
        }
    } -ArgumentList $installScript
} else {
    Write-Host "VM is not reachable at IP $vmIPAddress"
}
