param (
    [Parameter(Mandatory=$true)][string]$operation
)

# Load configuration from homelab.conf
$configPath = Join-Path -Path $PSScriptRoot -ChildPath "homelab.conf"
if (-not (Test-Path $configPath)) {
    Write-Host "Configuration file not found at $configPath. Exiting script."
    exit
}

$config = Get-Content $configPath | ConvertFrom-Json

# Define paths from the config file
$vsCodePath = $config.vsCodePath
$backupPath = $config.backupPath

# Function to backup VS Code settings and extensions
function Backup-VSCode {
    param (
        [string]$vsCodePath,
        [string]$backupPath
    )

    # Create backup directory if it doesn't exist
    if (-not (Test-Path $backupPath)) {
        New-Item -ItemType Directory -Path $backupPath
    }

    # Backup extensions
    code --list-extensions > (Join-Path -Path $backupPath -ChildPath "extensions.txt")
    Write-Host "Extensions backed up to $backupPath\extensions.txt"

    # Backup settings.json
    Copy-Item (Join-Path -Path $vsCodePath -ChildPath "settings.json") (Join-Path -Path $backupPath -ChildPath "settings.json") -Force
    Write-Host "settings.json backed up to $backupPath"

    # Backup keybindings.json if it exists
    if (Test-Path (Join-Path -Path $vsCodePath -ChildPath "keybindings.json")) {
        Copy-Item (Join-Path -Path $vsCodePath -ChildPath "keybindings.json") (Join-Path -Path $backupPath -ChildPath "keybindings.json") -Force
        Write-Host "keybindings.json backed up to $backupPath"
    } else {
        Write-Host "No custom keybindings found, skipping keybindings.json backup"
    }
}

# Function to restore VS Code settings and extensions
function Restore-VSCode {
    param (
        [string]$vsCodePath,
        [string]$backupPath
    )

    # Restore extensions
    $extensionsFile = Join-Path -Path $backupPath -ChildPath "extensions.txt"
    if (Test-Path $extensionsFile) {
        Get-Content $extensionsFile | ForEach-Object {
            code --install-extension $_
        }
        Write-Host "Extensions restored from $extensionsFile"
    } else {
        Write-Host "Extensions file not found!"
    }

    # Restore settings.json and keybindings.json
    if (Test-Path (Join-Path -Path $backupPath -ChildPath "settings.json")) {
        Copy-Item (Join-Path -Path $backupPath -ChildPath "settings.json") (Join-Path -Path $vsCodePath -ChildPath "settings.json") -Force
    }
    if (Test-Path (Join-Path -Path $backupPath -ChildPath "keybindings.json")) {
        Copy-Item (Join-Path -Path $backupPath -ChildPath "keybindings.json") (Join-Path -Path $vsCodePath -ChildPath "keybindings.json") -Force
    }
    Write-Host "Settings and keybindings restored"
}

# Main execution
if ($operation -eq "backup") {
    Backup-VSCode -vsCodePath $vsCodePath -backupPath $backupPath
} elseif ($operation -eq "restore") {
    Restore-VSCode -vsCodePath $vsCodePath -backupPath $backupPath
} else {
    Write-Host "Invalid operation. Use 'backup' or 'restore'."
}
