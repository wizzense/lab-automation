# Load the configuration
$config = Get-Content -Raw -Path "C:\Path\To\Your\HyperV_Example.json" | ConvertFrom-Json

# Create the VM using configuration
foreach ($vm in $config.virtual_machines) {
    $vmName = $vm.hostname
    $vhdPath = "C:\HyperV\$vmName\$vmName.vhdx"
    $isoPath = "$($config.HostInfo[1].'10.187.1.10'.ISOLocation)\$($vm.image)"

    # Create the new VM
    New-VM -Name $vmName -MemoryStartupBytes ($vm.vmspec.Memory * 1GB) -Generation 2 -NewVHDPath $vhdPath -NewVHDSizeBytes 60GB -Path "C:\HyperV\$vmName"

    # Configure CPU
    Set-VMProcessor -VMName $vmName -Count $vm.vmspec.CPUCores

    # Attach the ISO
    Add-VMDvdDrive -VMName $vmName -Path $isoPath

    # Set network adapter
    Add-VMNetworkAdapter -VMName $vmName -SwitchName "Default Switch"

    # Set static IP, DNS, and other network settings (Optional)
    # You can modify the following according to your network setup
    # Set-VMNetworkAdapterVlan -VMName $vmName -Access -VlanId 100

    # Start the VM
    Start-VM -Name $vmName
}
