# Paths to your configuration files
$configPath = Join-Path -Path $PSScriptRoot -ChildPath "vm-PrimaryControlNode.conf"
$hostsConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "hosts.conf"

# Read the VM configuration file
$vmConfig = Get-Content -Raw -Path $configPath | ConvertFrom-Json

# Read the hosts configuration file
$hostsConfig = Get-Content -Raw -Path $hostsConfigPath | ConvertFrom-Json

# Extract variables from the configuration file
$hostname = $vmConfig.hostname
$adminUsername = $vmConfig.administrator_username
$adminPassword = $vmConfig.administrator_password

# Extract the ISOLocation from the hosts configuration
$isoLocation = $hostsConfig.HostInfo[1].'Hyper-V'.ISOLocation

# Set the destination path on the VM
$destinationPath = "C:\Temp"

# Create a PSCredential object for the VM connection
$securePassword = ConvertTo-SecureString $adminPassword -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($adminUsername, $securePassword)

# Find TaniumClient files in the ISOLocation
$taniumClientFiles = Get-ChildItem -Path $isoLocation -Filter "*TaniumClient*" -Recurse

if ($taniumClientFiles.Count -eq 0) {
    Write-Host "No TaniumClient files found in $isoLocation."
    exit
} else {
    Write-Host "TaniumClient files found:"
    for ($i = 0; $i -lt $taniumClientFiles.Count; $i++) {
        Write-Host "[$i] $($taniumClientFiles[$i].FullName)"
    }

    # Prompt the user to select a file
    do {
        $selection = Read-Host "Enter the number corresponding to the TaniumClient file you want to use"
    } while (-not ($selection -match '^\d+$') -or $selection -lt 0 -or $selection -ge $taniumClientFiles.Count)

    $selectedFile = $taniumClientFiles[$selection].FullName
    Write-Host "You selected: $selectedFile"
}

# Connect to the VM using PowerShell Remoting
$session = New-PSSession -ComputerName $hostname -Credential $credential

# Check if connection was successful
if ($null -eq $session) {
    Write-Host "Failed to connect to $hostname"
    exit
} else {
    Write-Host "Successfully connected to $hostname"
}

# Ensure the destination path exists on the VM
Invoke-Command -Session $session -ScriptBlock {
    $destinationPath = "C:\Temp"
    if (-Not (Test-Path -Path $destinationPath)) {
        New-Item -Path $destinationPath -ItemType Directory
        Write-Host "Created directory: $destinationPath"
    } else {
        Write-Host "Directory already exists: $destinationPath"
    }
}

# Copy the selected TaniumClient file to the destination path on the VM
Copy-Item -Path $selectedFile -Destination $destinationPath -ToSession $session

# Install the TaniumClient on the VM (modify this command to match your installation process)
Invoke-Command -Session $session -ScriptBlock {
    $installerPath = "C:\Temp\$(Split-Path -Leaf $using:selectedFile)"
    Start-Process -FilePath $installerPath -ArgumentList "/quiet /norestart" -Wait
}

# Close the session
Remove-PSSession -Session $session

Write-Host "TaniumClient installation completed on $hostname"
