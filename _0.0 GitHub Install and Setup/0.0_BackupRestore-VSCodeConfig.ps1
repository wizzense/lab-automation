# Define paths
$vsCodePath = "C:\Users\alexa\AppData\Roaming\Code\User"
$backupPath = "C:\VSCode_Backup"

# Function to backup VS Code settings and extensions
function Backup-VSCode {
    # Create backup directory if it doesn't exist
    if (-not (Test-Path $backupPath)) {
        New-Item -ItemType Directory -Path $backupPath
    }

    # Backup extensions
    code --list-extensions > "$backupPath\extensions.txt"
    Write-Host "Extensions backed up to $backupPath\extensions.txt"

    # Backup settings.json
    Copy-Item "$vsCodePath\settings.json" "$backupPath\settings.json" -Force
    Write-Host "settings.json backed up to $backupPath"

    # Backup keybindings.json if it exists
    if (Test-Path "$vsCodePath\keybindings.json") {
        Copy-Item "$vsCodePath\keybindings.json" "$backupPath\keybindings.json" -Force
        Write-Host "keybindings.json backed up to $backupPath"
    } else {
        Write-Host "No custom keybindings found, skipping keybindings.json backup"
    }
}

# Function to restore VS Code settings and extensions
function Restore-VSCode {
    # Restore extensions
    $extensionsFile = "$backupPath\extensions.txt"
    if (Test-Path $extensionsFile) {
        Get-Content $extensionsFile | ForEach-Object {
            code --install-extension $_
        }
        Write-Host "Extensions restored from $extensionsFile"
    } else {
        Write-Host "Extensions file not found!"
    }

    # Restore settings.json and keybindings.json
    if (Test-Path "$backupPath\settings.json") {
        Copy-Item "$backupPath\settings.json" "$vsCodePath\settings.json" -Force
    }
    if (Test-Path "$backupPath\keybindings.json") {
        Copy-Item "$backupPath\keybindings.json" "$vsCodePath\keybindings.json" -Force
    }
    Write-Host "Settings and keybindings restored"
}

# Main menu
$choice = Read-Host "Enter 'backup' to backup or 'restore' to restore VS Code configurations"
if ($choice -eq "backup") {
    Backup-VSCode
} elseif ($choice -eq "restore") {
    Restore-VSCode
} else {
    Write-Host "Invalid option. Please run the script again."
}