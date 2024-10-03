param (
    [Parameter(Mandatory = $true)]
    [ValidateSet("backup", "restore")]
    [string]$operation
)

# Enable Verbose output
$VerbosePreference = "Continue"

# Load configuration from homelab.conf
$configPath = Join-Path -Path $PSScriptRoot -ChildPath "homelab.conf"
if (-not (Test-Path $configPath)) {
    Write-Error "Configuration file not found at $configPath. Exiting script."
    exit 1
}

$config = Get-Content $configPath | ConvertFrom-Json

# Define paths from the config file
$vsCodePath = $config.vsCodePath
$backupPath = $config.backupPath

# Function to check if VSCode is installed
function Test-VSCodeInstalled {
    if (-not (Get-Command code -ErrorAction SilentlyContinue)) {
        Write-Error "VSCode is not installed. Exiting."
        exit 1
    }
}

# Function to backup VSCode settings and extensions
function Backup-VSCode {
    param (
        [string]$vsCodePath,
        [string]$backupPath
    )

    try {
        # Create backup directory if it doesn't exist
        if (-not (Test-Path $backupPath)) {
            New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
        }

        # Backup extensions
        code --list-extensions > (Join-Path -Path $backupPath -ChildPath "extensions.txt")
        Write-Verbose "Extensions backed up to $backupPath\extensions.txt"

        # Backup settings.json
        Copy-Item -Path (Join-Path -Path $vsCodePath -ChildPath "settings.json") -Destination (Join-Path -Path $backupPath -ChildPath "settings.json") -Force
        Write-Verbose "settings.json backed up to $backupPath"

        # Backup keybindings.json if it exists
        $keybindingsPath = Join-Path -Path $vsCodePath -ChildPath "keybindings.json"
        if (Test-Path $keybindingsPath) {
            Copy-Item -Path $keybindingsPath -Destination (Join-Path -Path $backupPath -ChildPath "keybindings.json") -Force
            Write-Verbose "keybindings.json backed up to $backupPath"
        } else {
            Write-Verbose "No custom keybindings found, skipping keybindings.json backup"
        }
    } catch {
        Write-Error "An error occurred during backup: $_"
        exit 1
    }
}

# Function to restore VSCode settings and extensions
function Restore-VSCode {
    param (
        [string]$vsCodePath,
        [string]$backupPath
    )

    try {
        # Restore extensions
        $extensionsFile = Join-Path -Path $backupPath -ChildPath "extensions.txt"
        if (Test-Path $extensionsFile) {
            Get-Content $extensionsFile | ForEach-Object {
                code --install-extension $_ --force
            }
            Write-Verbose "Extensions restored from $extensionsFile"
        } else {
            Write-Verbose "Extensions file not found!"
        }

        # Restore settings.json and keybindings.json
        $settingsBackup = Join-Path -Path $backupPath -ChildPath "settings.json"
        if (Test-Path $settingsBackup) {
            Copy-Item -Path $settingsBackup -Destination (Join-Path -Path $vsCodePath -ChildPath "settings.json") -Force
            Write-Verbose "settings.json restored."
        } else {
            Write-Verbose "settings.json backup not found."
        }

        $keybindingsBackup = Join-Path -Path $backupPath -ChildPath "keybindings.json"
        if (Test-Path $keybindingsBackup) {
            Copy-Item -Path $keybindingsBackup -Destination (Join-Path -Path $vsCodePath -ChildPath "keybindings.json") -Force
            Write-Verbose "keybindings.json restored."
        } else {
            Write-Verbose "keybindings.json backup not found."
        }
    } catch {
        Write-Error "An error occurred during restoration: $_"
        exit 1
    }
}

# Main execution
Test-VSCodeInstalled

if ($operation -eq "backup") {
    Backup-VSCode -vsCodePath $vsCodePath -backupPath $backupPath
    Write-Host "VSCode backup completed successfully."
} elseif ($operation -eq "restore") {
    Restore-VSCode -vsCodePath $vsCodePath -backupPath $backupPath
    Write-Host "VSCode restoration completed successfully."
} else {
    Write-Error "Invalid operation. Use 'backup' or 'restore'."
    exit 1
}
