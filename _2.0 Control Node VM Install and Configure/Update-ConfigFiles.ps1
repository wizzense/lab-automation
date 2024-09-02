param(
    [switch]$GeneralSettings,
    [switch]$Hosts,
    [switch]$VMspecs,
    [switch]$ImageInfo,
    [switch]$ArrayInfo,
    [switch]$pfSense,
    [switch]$VMConfig,
    [string]$VMConfigFileName
)

function Update-GeneralSettings {
    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "general-settings.conf"
    $config = Get-Content $configFile | ConvertFrom-Json

    $config.accept_eula_with_email_address = Read-Host "Enter EULA email address"
    $config.initial_password = Read-Host "Enter initial password"
    $config.authorized_key = Read-Host "Enter SSH authorized key"
    $config.DNSForwarder = Read-Host "Enter DNS Forwarder"

    $config | ConvertTo-Json | Set-Content $configFile
    Write-Output "General settings updated successfully."
}

function Update-Hosts {
    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "hosts.conf"
    $config = Get-Content $configFile | ConvertFrom-Json

    # Assuming you want to access the Hyper-V configuration
    $hyperVConfig = $config.HostInfo[1].'Hyper-V'

    # Check if the Hyper-V configuration exists
    if (-not $hyperVConfig) {
        Write-Error "Host information for 'Hyper-V' not found in configuration."
        return
    }

    # Access the IP Address field
    $hostIP = $hyperVConfig.'IP Address'

    # Prompt for IP address if it is not set
    if (-not $hostIP) {
        $hostIP = Read-Host "Enter IP Address for Hyper-V host"
        $hyperVConfig.'IP Address' = $hostIP
    }

    if (-not $hostIP) {
        Write-Error "Host IP not found in configuration."
        return
    }

    # Prompt the user to update the Hyper-V host settings
    $hyperVConfig.UserID = Read-Host "Enter User ID for host $hostIP"
    $hyperVConfig.Password = Read-Host "Enter Password for host $hostIP"
    $hyperVConfig.ISOLocation = Read-Host "Enter ISO Location for host $hostIP"

    # Save the updated configuration back to the file
    $config | ConvertTo-Json -Depth 3 | Set-Content $configFile
    Write-Output "Hosts settings updated successfully."
}

function Update-VMspecs {
    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "vmspecs.conf"
    $config = Get-Content $configFile | ConvertFrom-Json

    # Display available VM specs to the user
    $vmspecsList = $config.vmspecs | ForEach-Object { $_.PSObject.Properties.Name }
    $i = 0
    $vmspecsList | ForEach-Object { 
        $i++
        Write-Output "$i. $_" 
    }
    
    $specIndex = Read-Host "Select VM spec by entering the corresponding number"
    
    # Validate input
    if ($specIndex -match '^\d+$' -and $specIndex -le $vmspecsList.Count -and $specIndex -ge 1) {
        $specName = $vmspecsList[$specIndex - 1]
        $spec = $config.vmspecs | Where-Object { $_.PSObject.Properties.Name -eq $specName } | Select-Object -ExpandProperty $specName

        $spec.CPUSockets = Read-Host "Enter CPU Sockets for $specName"
        $spec.CPUCores = Read-Host "Enter CPU Cores for $specName"
        $spec.Memory = Read-Host "Enter Memory (GB) for $specName"
        $spec.Host = Read-Host "Enter Host IP for $specName"
        $spec.Datastore = Read-Host "Enter Datastore for $specName"

        $config | ConvertTo-Json | Set-Content $configFile
        Write-Output "$specName VM specs updated successfully."
    } else {
        Write-Output "Invalid selection. Please try again."
    }
}

function Update-ImageInfo {
    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "imageinfo.conf"
    $config = Get-Content $configFile | ConvertFrom-Json

    # Display available images to the user
    $imageList = $config.imageinfo | ForEach-Object { $_.PSObject.Properties.Name }
    $i = 0
    $imageList | ForEach-Object { 
        $i++
        Write-Output "$i. $_" 
    }

    $imageIndex = Read-Host "Select Image by entering the corresponding number"
    
    # Validate input
    if ($imageIndex -match '^\d+$' -and $imageIndex -le $imageList.Count -and $imageIndex -ge 1) {
        $imageName = $imageList[$imageIndex - 1]
        $image = $config.imageinfo | Where-Object { $_.PSObject.Properties.Name -eq $imageName } | Select-Object -ExpandProperty $imageName

        $image.ISO = Read-Host "Enter ISO file name for $imageName"
        $image.Edition = Read-Host "Enter Edition (if applicable) for $imageName"
        $image.Key = Read-Host "Enter Product Key for $imageName"
        $image.ESXGuestOsIdentifier = Read-Host "Enter ESX Guest OS Identifier for $imageName"

        $config | ConvertTo-Json | Set-Content $configFile
        Write-Output "$imageName image info updated successfully."
    } else {
        Write-Output "Invalid selection. Please try again."
    }
}

function Update-ArrayInfo {
    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "arrayinfo.conf"
    $config = Get-Content $configFile | ConvertFrom-Json

    $arrayName = "MyArray1"  # Assuming one array in this example
    $config.array_info[0].$arrayName.tanium_version = Read-Host "Enter Tanium version for $arrayName"
    $config.array_info[0].$arrayName.solutions_file = Read-Host "Enter Solutions file for $arrayName"
    $config.array_info[0].$arrayName.license_file = Read-Host "Enter License file for $arrayName"

    $config | ConvertTo-Json | Set-Content $configFile
    Write-Output "$arrayName array info updated successfully."
}

function Update-pfSense {
    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "pfsense.conf"
    $config = Get-Content $configFile | ConvertFrom-Json

    $config.pfSense[0].ISO = Read-Host "Enter ISO file for pfSense"
    $config.pfSense[0].Name = Read-Host "Enter Name for pfSense"
    $config.pfSense[0].Host = Read-Host "Enter Host IP for pfSense"
    $config.pfSense[0].Datastore = Read-Host "Enter Datastore for pfSense"

    $config | ConvertTo-Json | Set-Content $configFile
    Write-Output "pfSense settings updated successfully."
}

function Update-VMConfig {
    if (-not $VMConfigFileName) {
        Write-Error "Please specify the VM config file name using -VMConfigFileName parameter."
        return
    }
    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$VMConfigFileName.conf"
    if (-not (Test-Path $configFile)) {
        Write-Error "The specified VM config file does not exist."
        return
    }
    
    $config = Get-Content $configFile | ConvertFrom-Json

    $config.hostname = Read-Host "Enter hostname"
    $config.platform = Read-Host "Enter platform"

    # Display available images to the user
    $imageConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "imageinfo.conf"
    $imageConfig = Get-Content $imageConfigFile | ConvertFrom-Json
    $imageList = $imageConfig.imageinfo | ForEach-Object { $_.PSObject.Properties.Name }

    $i = 0
    $imageList | ForEach-Object { 
        $i++
        Write-Output "$i. $_"
    }

    $imageIndex = Read-Host "Select Image by entering the corresponding number"

    # Validate input
    if ($imageIndex -match '^\d+$' -and $imageIndex -le $imageList.Count -and $imageIndex -ge 1) {
        $config.image = $imageList[$imageIndex - 1]
    } else {
        Write-Output "Invalid selection. Please try again."
        return
    }

    # Display available VM specs to the user
    $vmspecConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "vmspecs.conf"
    $vmspecConfig = Get-Content $vmspecConfigFile | ConvertFrom-Json
    $vmspecsList = $vmspecConfig.vmspecs | ForEach-Object { $_.PSObject.Properties.Name }

    $i = 0
    foreach ($spec in $vmspecsList) { 
        $i++
        Write-Output "$i. $spec"
    }

    $specIndex = Read-Host "Select VM spec by entering the corresponding number"

    # Validate input
    if ($specIndex -match '^\d+$' -and $specIndex -le $vmspecsList.Count -and $specIndex -ge 1) {
        $config.vmspec = $vmspecsList[$specIndex - 1]
    } else {
        Write-Output "Invalid selection. Please try again."
        return
    }

    $config.Core = Read-Host "Enter Core (True/False)"
    $config.domain = Read-Host "Enter domain"
    $config.ipaddr = Read-Host "Enter IP address"
    $config.netmask = Read-Host "Enter netmask"
    $config.gateway = Read-Host "Enter gateway"

    $dnsServers = @()
    do {
        $dnsServer = Read-Host "Enter DNS server (leave blank to finish)"
        if ($dnsServer) {
            $dnsServers += $dnsServer
        }
    } until (-not $dnsServer)
    $config.dns_servers = $dnsServers

    $config | ConvertTo-Json | Set-Content $configFile
    Write-Output "$($config.hostname) VM config updated successfully."
}

if ($GeneralSettings) {
    Update-GeneralSettings
}
elseif ($Hosts) {
    Update-Hosts
}
elseif ($VMspecs) {
    Update-VMspecs
}
elseif ($ImageInfo) {
    Update-ImageInfo
}
elseif ($ArrayInfo) {
    Update-ArrayInfo
}
elseif ($pfSense) {
    Update-pfSense
}
elseif ($VMConfig) {
    Update-VMConfig
}
else {
    Write-Error "Please specify a valid switch to update a config file."
}

<# 
.\Update-ConfigFiles.ps1 -GeneralSettings
.\Update-ConfigFiles.ps1 -Hosts
.\Update-ConfigFiles.ps1 -VMspecs
.\Update-ConfigFiles.ps1 -ImageInfo
.\Update-ConfigFiles.ps1 -VMConfig -VMConfigFileName "vm-primarycontrolnode"
#>
