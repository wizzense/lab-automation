# Function to prompt for folder and validate
function Get-ISOFolder {
    while ($true) {
        $folderPath = Read-Host "Enter the folder path where ISOs are kept (or type 'No' to use default location)"
        
        if ($folderPath -eq "No") {
            $folderPath = "C:\temp"
            if (-not (Test-Path -Path $folderPath)) {
                New-Item -ItemType Directory -Path $folderPath
            }
            Write-Output "Using default location: $folderPath"
            break
        } elseif (Test-Path -Path $folderPath) {
            Write-Output "Using specified location: $folderPath"
            break
        } else {
            Write-Error "The folder path '$folderPath' does not exist. Please try again."
        }
    }
    return $folderPath
}

# Get the folder path
$isoFolder = Get-ISOFolder

# Read JSON file
$currentDir = Get-Location
$jsonFilePath = Join-Path -Path $currentDir -ChildPath ".\_0.1 ISO Downloads\isos.json"
$isoList = Get-Content -Path $jsonFilePath | ConvertFrom-Json
# Download ISO files
foreach ($iso in $isoList) {
    try {
        $outputPath = Join-Path -Path $isoFolder -ChildPath ($iso.name + ".iso")
        Invoke-WebRequest -Uri $iso.url -OutFile $outputPath
        Write-Output "Downloaded $($iso.name) successfully."
    } catch {
        Write-Error "Failed to download $($iso.name): $_"
    }
}

#not going to check if they are already downloaded for simplicity, but can add this later if we want