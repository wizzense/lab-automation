param(
    [string]$GeneralSettingsFile = "general-settings.conf",
    [string]$HostsFile = "hosts.conf",
    [string]$VMspecsFile = "vmspecs.conf",
    [string]$ImageInfoFile = "imageinfo.conf",
    [string]$VMConfigFolder = ".\"
)

# Load the JSON configuration files
#$generalSettings = Get-Content $GeneralSettingsFile | ConvertFrom-Json
$hosts = Get-Content $HostsFile | ConvertFrom-Json
$vmspecs = Get-Content $VMspecsFile | ConvertFrom-Json
$imageinfo = Get-Content $ImageInfoFile | ConvertFrom-Json

# Process each VM config file in the folder
$vmConfigs = Get-ChildItem -Path $VMConfigFolder -Filter "vm-*.conf"

foreach ($vmConfigFile in $vmConfigs) {
    $vm = Get-Content $vmConfigFile.FullName | ConvertFrom-Json

    # Get the VM specifications and image details
    $vmspec = $vmspecs.vmspecs | Where-Object { $_.PSObject.Properties.Name -eq $vm.vmspec } | Select-Object -ExpandProperty $vm.vmspec
    $image = $imageinfo.imageinfo | Where-Object { $_.PSObject.Properties.Name -eq $vm.image } | Select-Object -ExpandProperty $vm.image

    # Create the VM as before using the specs and image details
    New-VM -Name $vm.hostname `
           -MemoryStartupBytes ($vmspec.Memory * 1GB) `
           -NewVHDPath "$($vmspec.Datastore)\$($vm.hostname).vhdx" `
           -NewVHDSizeBytes 60GB `
           -SwitchName "Default Switch" `
           -Path $vmspec.Datastore `
           -Generation 2

    Set-VMProcessor -VMName $vm.hostname -Count ($vmspec.CPUSockets * $vmspec.CPUCores)
    Add-VMDvdDrive -VMName $vm.hostname -Path "$($hosts.HostInfo[1]['Hyper-V'].ISOLocation)\$($image.ISO)"
    Add-VMNetworkAdapter -VMName $vm.hostname -SwitchName "Default Switch"

    Start-VM -Name $vm.hostname
    Write-Output "VM '$($vm.hostname)' created and started successfully."
}
