# kickstart.ps1

# Set repository details
$repoUrl = "https://github.com/wizzense/tanium-homelab-automation.git"
$localPath = Join-Path -Path $env:USERPROFILE -ChildPath "Labs"  # Removed leading backslash

# Define the log file path
$logFilePath = Join-Path -Path $PSScriptRoot -ChildPath "kickstart_log.txt"

# Function to write to the log file
function Write-Log {
    param (
        [string]$Message
    )
    $logEntry = "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - $Message"
    Write-Output $logEntry | Tee-Object -FilePath $logFilePath -Append
}

# Function to run a script with optional arguments
function Start-Script {
    param (
        [string]$ScriptPath,
        [string]$Message,
        [hashtable]$Arguments = @{}
    )
    Write-Log "$Message - Executing $ScriptPath"
    try {
        & $ScriptPath @Arguments 2>&1 | Tee-Object -FilePath $logFilePath -Append
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Script failed: $ScriptPath with exit code $LASTEXITCODE"
            exit $LASTEXITCODE
        }
    }
    catch {
        Write-Log "Error executing ${ScriptPath}: $_"
        exit 1
    }
}

# Check for administrative privileges
if (-not (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Log "This script requires elevated privileges. Restarting as administrator..."
    Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Function to uninstall applications based on the uninstall string
function Uninstall-Application {
    param (
        [string]$UninstallString
    )

    # Remove any leading/trailing quotes
    $uninstallCmd = $UninstallString.Trim('"')

    if ($uninstallCmd -match '^(MsiExec\.exe|msiexec\.exe)\s+(?<Args>.+)$') {
        $arguments = $Matches['Args']
        Write-Log "Uninstalling application using MSIExec with arguments: $arguments"
        Start-Process -FilePath "msiexec.exe" -ArgumentList $arguments -Wait
    }
    elseif ($uninstallCmd -match '^(?<Exe>[^ ]+)\s*(?<Args>.*)$') {
        $exe = $Matches['Exe']
        $arguments = $Matches['Args']
        Write-Log "Uninstalling application using executable: $exe with arguments: $arguments"
        Start-Process -FilePath $exe -ArgumentList $arguments -Wait
    }
    else {
        Write-Log "UninstallString format not recognized: $UninstallString"
    }
}

# Function to perform cleanup
function Start-Cleanup {
    Write-Log "Starting cleanup process..."

    # Remove the cloned repository
    $repoName = ($repoUrl.Split('/')[-1]).Replace(".git", "")
    $repoPath = Join-Path -Path $localPath -ChildPath $repoName

    Write-Log "Checking if the repository exists at '$repoPath' for removal..."
    if (Test-Path -Path $repoPath) {
        Write-Log "Repository exists. Removing repository..."
        Remove-Item -Path $repoPath -Recurse -Force
        Write-Log "Repository removed."
    } else {
        Write-Log "Repository does not exist. Skipping repository removal."
    }

    # Uninstall Git if installed
    Write-Log "Checking if Git is installed..."
    $gitInstalled = Get-Command git -ErrorAction SilentlyContinue
    if ($gitInstalled) {
        # Try to find Git in Uninstall registry keys
        $uninstallKeyPaths = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
            "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
            "HKCU:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
        )
        $gitUninstalled = $false
        foreach ($path in $uninstallKeyPaths) {
            $gitProducts = Get-ItemProperty $path -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*Git for Windows*" -or $_.DisplayName -like "*Git*" }
            foreach ($product in $gitProducts) {
                $uninstallString = $product.UninstallString
                if (-not $uninstallString) {
                    $uninstallString = $product.QuietUninstallString
                }
                if ($uninstallString) {
                    Write-Log "Uninstalling Git using uninstall string: $uninstallString"
                    Uninstall-Application -UninstallString $uninstallString
                    Write-Log "Git uninstalled."
                    $gitUninstalled = $true
                    break
                }
            }
            if ($gitUninstalled) { break }
        }
        if (-not $gitUninstalled) {
            Write-Log "Git uninstaller not found in registry."
        }
    } else {
        Write-Log "Git is not installed. Skipping Git uninstallation."
    }

    # Uninstall GitHub CLI if installed
    Write-Log "Checking if GitHub CLI is installed..."
    $ghUninstalled = $false
    foreach ($path in $uninstallKeyPaths) {
        $ghProducts = Get-ItemProperty $path -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*GitHub CLI*" }
        foreach ($product in $ghProducts) {
            $uninstallString = $product.UninstallString
            if (-not $uninstallString) {
                $uninstallString = $product.QuietUninstallString
            }
            if ($uninstallString) {
                Write-Log "Uninstalling GitHub CLI using uninstall string: $uninstallString"
                Uninstall-Application -UninstallString $uninstallString
                Write-Log "GitHub CLI uninstalled."
                $ghUninstalled = $true
                break
            }
        }
        if ($ghUninstalled) { break }
    }
    if (-not $ghUninstalled) {
        Write-Log "GitHub CLI is not installed. Skipping GitHub CLI uninstallation."
    }

    # Uninstall Visual Studio Code if installed
    Write-Log "Checking if Visual Studio Code is installed..."
    $vscodeUninstalled = $false
    foreach ($path in $uninstallKeyPaths) {
        $vscodeProducts = Get-ItemProperty $path -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*Visual Studio Code*" }
        foreach ($product in $vscodeProducts) {
            $uninstallString = $product.UninstallString
            if (-not $uninstallString) {
                $uninstallString = $product.QuietUninstallString
            }
            if ($uninstallString) {
                Write-Log "Uninstalling Visual Studio Code using uninstall string: $uninstallString"
                Uninstall-Application -UninstallString $uninstallString
                Write-Log "Visual Studio Code uninstalled."
                $vscodeUninstalled = $true
                break
            }
        }
        if ($vscodeUninstalled) { break }
    }
    if (-not $vscodeUninstalled) {
        Write-Log "Visual Studio Code is not installed. Skipping VSCode uninstallation."
    }

    # Remove Git global configuration
    Write-Log "Removing Git global configuration..."
    $gitConfigPath = Join-Path -Path $env:USERPROFILE -ChildPath ".gitconfig"
    if (Test-Path -Path $gitConfigPath) {
        Remove-Item -Path $gitConfigPath -Force
        Write-Log "Git global configuration removed."
    } else {
        Write-Log "Git global configuration not found."
    }

    # Remove VSCode user settings and extensions
    Write-Log "Removing VSCode user settings and extensions..."
    $vscodeUserSettingsPath = Join-Path -Path $env:APPDATA -ChildPath "Code"
    if (Test-Path -Path $vscodeUserSettingsPath) {
        Remove-Item -Path $vscodeUserSettingsPath -Recurse -Force
        Write-Log "VSCode user settings and extensions removed."
    } else {
        Write-Log "VSCode user settings not found."
    }

    Write-Log "Cleanup process completed."
}

# Function to perform installation and setup
function Start-Setup {
    Write-Log "Starting setup process..."

    # Check if Git is installed
    Write-Log "Checking if Git is installed..."
    if (Get-Command git -ErrorAction SilentlyContinue) {
        Write-Log "Git is already installed."
    } else {
        Write-Log "Git is not installed. Downloading and installing Git..."
        $gitInstallerUrl = "https://github.com/git-for-windows/git/releases/latest/download/Git-64-bit.exe"
        $gitInstaller = Join-Path -Path $env:TEMP -ChildPath "GitInstaller.exe"
        Invoke-WebRequest -Uri $gitInstallerUrl -OutFile $gitInstaller -UseBasicParsing -Verbose
        Write-Log "Git installer downloaded to $gitInstaller."

        Write-Log "Installing Git..."
        Start-Process -FilePath $gitInstaller -ArgumentList "/VERYSILENT" -Wait
        Write-Log "Git installation completed."

        Remove-Item -Path $gitInstaller
        Write-Log "Git installer removed."
    }

    # Ensure the local path exists
    Write-Log "Ensuring the local path '$localPath' exists..."
    if (-not (Test-Path -Path $localPath)) {
        Write-Log "Local path does not exist. Creating directory..."
        New-Item -ItemType Directory -Path $localPath -Force | Out-Null
        Write-Log "Directory created."
    } else {
        Write-Log "Local path exists."
    }

    # Clone the repository
    $repoName = ($repoUrl.Split('/')[-1]).Replace(".git", "")
    $repoPath = Join-Path -Path $localPath -ChildPath $repoName

    Write-Log "Cloning repository..."
    if (-not (Test-Path -Path $repoPath)) {
        Write-Log "Repository does not exist. Cloning from $repoUrl..."
        git clone $repoUrl $repoPath | Tee-Object -FilePath $logFilePath -Append
        Write-Log "Repository cloned to $repoPath."
    } else {
        Write-Log "Repository already exists at $repoPath. Pulling latest changes..."
        Set-Location $repoPath
        git pull | Tee-Object -FilePath $logFilePath -Append
        Set-Location $PSScriptRoot
    }

    # Optionally, run additional scripts here

    Write-Log "Setup process completed."
}

# Main execution flow

# Confirmation prompt before cleanup
Write-Host "This script will perform a cleanup and then reinstall the setup." -ForegroundColor Yellow
$confirmation = Read-Host "Do you want to proceed? (Y/N)"
if ($confirmation -notin @('Y', 'y')) {
    Write-Host "Operation cancelled by user."
    exit
}

# Perform cleanup
Start-Cleanup

# Perform setup
Start-Setup

# Log the completion of the reset and setup script
Write-Log "All tasks completed successfully."
