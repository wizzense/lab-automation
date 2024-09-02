param(
    [string]$ConfigFilePath = "_2.0 Control Node VM Install and Configure\hosts.conf" # Path to the config file containing the ISOLocation
)

function Resolve-ConfigPath {
    param(
        [string]$Path
    )

    # Check if the provided path is already an absolute path
    if (-not [System.IO.Path]::IsPathRooted($Path)) {
        # Use PSScriptRoot to determine the directory of the script
        $scriptDirectory = $PSScriptRoot
        if (-not $scriptDirectory) {
            $scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
        }

        $fullPath = Join-Path -Path $scriptDirectory -ChildPath $Path
    } else {
        $fullPath = $Path
    }

    # Resolve to absolute path
    try {
        $resolvedPath = Resolve-Path -Path $fullPath -ErrorAction Stop
    }
    catch {
        Write-Host "Configuration file not found: $fullPath"
        exit
    }

    return $resolvedPath
}

function Get-ISOLocation {
    param(
        [string]$ConfigFilePath
    )

    # Resolve the path to an absolute path
    $ConfigFilePath = Resolve-ConfigPath -Path $ConfigFilePath

    Write-Host "Resolved Config File Path: $ConfigFilePath"

    # Read the configuration file
    $configContent = Get-Content -Path $ConfigFilePath | ConvertFrom-Json

    # Extract the ISOLocation
    $isoLocation = $configContent.HostInfo | Where-Object { $_.'Hyper-V' } | Select-Object -ExpandProperty 'Hyper-V' | Select-Object -ExpandProperty 'ISOLocation'

    return $isoLocation
}

function FindISOsWithoutConf {
    param(
        [string]$Directory
    )

    $isos = Get-ChildItem -Path $Directory -Filter *.iso

    $isosWithoutConf = @()

    foreach ($iso in $isos) {
        $confFile = [System.IO.Path]::ChangeExtension($iso.FullName, ".conf")
        if (-not (Test-Path -Path $confFile)) {
            $isosWithoutConf += $iso
        }
    }

    return $isosWithoutConf
}

function PromptForConfigInfo {
    param(
        [string]$ISOName
    )

    Write-Host "Provide the following details for the new ISO: `'$ISOName`'"

    $edition = Read-Host "Enter the edition name (e.g., 'Windows 10 Enterprise')"
    $key = Read-Host "Enter the product key"
    $guestOsIdentifier = Read-Host "Enter the ESX Guest OS Identifier (e.g., 'windows9_64Guest')"

    # Create the config structure
    $config = @{
        "imageinfo" = @(
            @{
                $edition = @{
                    "ISO" = $ISOName
                    "Edition" = $edition
                    "Key" = $key
                    "ESXGuestOsIdentifier" = $guestOsIdentifier
                }
            }
        )
    }

    return $config
}

function SaveConfigFile {
    param(
        [hashtable]$Config,
        [string]$ConfigFilePath
    )

    # Convert the hashtable to JSON
    $jsonConfig = $Config | ConvertTo-Json -Depth 4

    # Save the JSON to a file
    $jsonConfig | Out-File -FilePath $ConfigFilePath -Encoding UTF8

    Write-Host "Configuration file saved to: $ConfigFilePath"
}

# Main script

# Step 1: Get the ISO location from the configuration file
$isoLocation = Get-ISOLocation -ConfigFilePath $ConfigFilePath

if (-not (Test-Path -Path $isoLocation)) {
    Write-Host "ISO location path not found: $isoLocation"
    exit
}

# Step 2: Find ISOs without corresponding .conf files
$isosWithoutConf = FindISOsWithoutConf -Directory $isoLocation

if ($isosWithoutConf.Count -eq 0) {
    Write-Host "All ISOs in the directory have corresponding .conf files."
    exit
}

# Step 3: Display the list of ISOs without .conf files and prompt user to select one
Write-Host "The following ISO files do not have corresponding .conf files:"
for ($i = 0; $i -lt $isosWithoutConf.Count; $i++) {
    Write-Host "[$($i+1)] $($isosWithoutConf[$i].Name)"
}

$selection = Read-Host "Enter the number corresponding to the ISO you want to configure (or press Enter to exit)"

if ([string]::IsNullOrWhiteSpace($selection) -or -not ($selection -match '^\d+$') -or ($selection -le 0) -or ($selection -gt $isosWithoutConf.Count)) {
    Write-Host "Invalid selection. Exiting setup."
    exit
}

# Step 4: Get the selected ISO name based on the user's choice
$selectedISO = $isosWithoutConf[$selection - 1].Name

# Step 5: Prompt for additional config information
$configInfo = PromptForConfigInfo -ISOName $selectedISO

# Step 6: Save the config file
$configFileName = [System.IO.Path]::ChangeExtension($selectedISO, ".conf")
$configFilePath = Join-Path -Path $isoLocation -ChildPath $configFileName

SaveConfigFile -Config $configInfo -ConfigFilePath $configFilePath

Write-Host "ISO Onboarding Completed Successfully!"
