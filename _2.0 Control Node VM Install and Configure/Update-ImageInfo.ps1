param(
    [string]$HostsFile = "hosts.conf",
    [string]$ImageInfoFile = "imageinfo.conf"
)

function Get-ISOLocation {
    param([string]$hostsFile)

    $hostsConfig = Get-Content -Raw -Path $hostsFile | ConvertFrom-Json
    if (-not $hostsConfig) { exit }

    $isoLocation = $hostsConfig.HostInfo[1].'Hyper-V'.ISOLocation

    if (-not $isoLocation) {
        Write-Error "ISO Location not found in hosts.conf. Please ensure it is configured correctly."
        exit
    }

    Write-Host "ISO Location found: $isoLocation"
    return $isoLocation
}

function Get-ConfFile {
    param([string]$confFile)

    if (-not (Test-Path $confFile)) {
        Write-Error "Conf file not found: $confFile"
        return $null
    }

    $confData = Get-Content -Path $confFile
    return $confData
}

function Update-ImageInfo {
    param([string]$isoLocation, [string]$imageInfoFile)

    $isos = Get-ChildItem -Path $isoLocation -Filter *.iso

    foreach ($iso in $isos) {
        # Adjust the conf file name to include the "imageinfo_" prefix
        $confFileName = "imageinfo_" + $iso.BaseName + ".conf"
        $confFile = Join-Path -Path $iso.DirectoryName -ChildPath $confFileName

        Write-Host "Checking for conf file: $confFile"

        if (Test-Path $confFile) {
            $confData = Get-ConfFile -confFile $confFile

            if ($confData) {
                $imageInfoContent = Get-Content -Path $imageInfoFile

                # Check for each line in the conf file to see if it already exists in imageinfo.conf
                $confDataToAdd = $confData | Where-Object { $imageInfoContent -notcontains $_ }

                if ($confDataToAdd.Count -gt 0) {
                    Add-Content -Path $imageInfoFile -Value $confDataToAdd
                    Write-Host "Added info from $confFile to $imageInfoFile"
                } else {
                    Write-Host "Skipping duplicate entry from $confFile"
                }
            }
        } else {
            Write-Host "No corresponding conf file found for ISO: $iso"
        }
    }
}

# Main Script Execution
$isoLocation = Get-ISOLocation -hostsFile $HostsFile
if ($isoLocation) {
    Update-ImageInfo -isoLocation $isoLocation -imageInfoFile $ImageInfoFile
}
