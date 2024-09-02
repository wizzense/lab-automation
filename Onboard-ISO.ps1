param (
    [string] $ConfigFilePath = "_2.0 Control Node VM Install and Configure\hosts.conf"
)
# Paths to your configuration files
$configPath = Join-Path -Path $PSScriptRoot -ChildPath "vm-PrimaryControlNode.conf"
$hostsConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "hosts.conf"
$ConfigFilePath = $hostsConfigPath
# Check if ConfigFilePath is provided
if (-not $ConfigFilePath) {
Write-Error "ConfigFilePath is null. Please provide a valid path."
exit
}

Write-Host "ConfigFilePath: $ConfigFilePath"

function Get-ConfigFilePath {
    param (
        [string] $Path
    )

    if (-not (Test-Path $Path)) {
        throw "Configuration file not found at path: $Path"
    }

    return (Resolve-Path $Path).Path
}

function Get-ISOPath {
    param (
        [string] $ConfigFile
    )

    $config = Get-Content -Path $ConfigFile | ConvertFrom-Json
    $isoPath = $config.ISOPath

    if (-not (Test-Path $isoPath)) {
        throw "ISO file not found at path: $isoPath"
    }

    return $isoPath
}

function Get-ConfigFiles {
    param (
        [string] $Directory
    )

    $configFiles = Get-ChildItem -Path $Directory -Filter "*.conf"
    $configs = @()

    foreach ($file in $configFiles) {
        $content = Get-Content -Path $file.FullName | ConvertFrom-Json
        $configs += [PSCustomObject]@{
            Name = $content.Name
            FilePath = $file.FullName
            ISOPath = $content.ISOPath
        }
    }

    return $configs
}

function Display-Configs {
    param (
        [array] $Configs
    )

    $Configs | ForEach-Object {
        Write-Host "Name: $($_.Name)"
        Write-Host "File Path: $($_.FilePath)"
        Write-Host "ISO Path: $($_.ISOPath)"
        Write-Host "----------------------"
    }
}

function Update-Config {
    param (
        [PSCustomObject] $Config
    )

    $downloadUrl = Read-Host "Enter the download URL for the ISO file (leave empty to keep current)"
    $checksum = Read-Host "Enter the checksum for the ISO file (leave empty to keep current)"

    if ($downloadUrl) {
        $Config.ISOPath = $downloadUrl
    }

    if ($checksum) {
        $Config.Checksum = $checksum
    }

    return $Config
}

function Save-ConfigFile {
    param (
        [PSCustomObject] $Config,
        [string] $FilePath
    )

    $json = $Config | ConvertTo-Json -Depth 3
    Set-Content -Path $FilePath -Value $json
    Write-Host "Configuration saved successfully."
}

# Main Script Execution
try {
    $configFilePath = Get-ConfigFilePath -Path $ConfigFilePath
    $isoPath = Get-ISOPath -ConfigFile $configFilePath

    $configs = Get-ConfigFiles -Directory (Split-Path $ConfigFilePath)
    Display-Configs -Configs $configs

    $selectedConfig = $configs | Where-Object { $_.FilePath -eq $configFilePath }

    if ($selectedConfig) {
        $updatedConfig = Update-Config -Config $selectedConfig
        Save-ConfigFile -Config $updatedConfig -FilePath $selectedConfig.FilePath
    } else {
        Write-Host "No matching configuration found."
    }
} catch {
    Write-Error "An error occurred: $_"
}
