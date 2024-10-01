# Enable Verbose output
$VerbosePreference = "Continue"

# Define parameters
[CmdletBinding()]
param(
    [switch]$Clean
)

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

# Function to check if running as administrator
function Test-IsAdmin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

# Function to check if the script is run from the GUI
function Test-IsGUI {
    return -not $Host.Name -eq 'ConsoleHost'
}

# Function to refresh environment variables
function Refresh-EnvironmentVariables {
    Write-Log "Refreshing environment variables..."
    # Refresh the PATH variable
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    Write-Log "Environment variables refreshed."
}

# Function to install Git
function Install-Git {
    Write-Log "Git is not installed. Downloading Git installer..."

    # Fetch the latest Git for Windows installer URL
    $gitApiUrl = "https://api.github.com/repos/git-for-windows/git/releases/latest"
    $headers = @{
        'User-Agent' = 'Kickstart-Script'
    }

    try {
        $gitReleaseInfo = Invoke-RestMethod -Uri $gitApiUrl -Headers $headers -UseBasicParsing
        $gitInstallerAsset = $gitReleaseInfo.assets | Where-Object { $_.name -like "*64-bit.exe" }

        if ($gitInstallerAsset) {
            $gitInstallerUrl = $gitInstallerAsset.browser_download_url
            Write-Log "Latest Git installer URL: $gitInstallerUrl"

            $gitInstaller = Join-Path -Path $env:TEMP -ChildPath "GitInstaller.exe"

            # Download the Git installer
            Invoke-WebRequest -Uri $gitInstallerUrl -OutFile $gitInstaller -UseBasicParsing -Verbose
            Write-Log "Git installer downloaded to $gitInstaller."

            # Install Git silently
            Write-Log "Installing Git silently..."
            Start-Process -FilePath $gitInstaller -ArgumentList "/VERYSILENT" -Wait
            Write-Log "Git installation completed."

            # Remove the installer
            Remove-Item -Path $gitInstaller -Force
            Write-Log "Git installer removed."

            # Refresh environment variables
            Refresh-EnvironmentVariables

            # Configure Git (Optional)
            # You can set default username and email here if desired
            # git config --global user.name "YourName"
            # git config --global user.email "YourEmail@example.com"

        } else {
            Write-Log "Could not find a 64-bit Git installer. Exiting."
            $global:ScriptError = $true
            exit 1
        }
    } catch {
        Write-Log "Error installing Git: $_"
        $global:ScriptError = $true
        exit 1
    }
}

# ... [Other functions remain unchanged, but ensure all exit paths set $global:ScriptError if an error occurs] ...

# Function to prompt for the repository URL
function Get-RepositoryUrl {
    # Prompt for the repository URL
    $repoUrl = Read-Host -Prompt "Please enter the repository URL"

    # Validate the URL
    if ([string]::IsNullOrWhiteSpace($repoUrl)) {
        Write-Log "Repository URL is required. Exiting."
        $global:ScriptError = $true
        exit 1
    }

    return $repoUrl
}

# Function to clone the repository
function Clone-Repository {
    Write-Log "Cloning the repository..."

    # Get the repository URL
    $repoUrl = Get-RepositoryUrl

    $clonePath = $PSScriptRoot  # Clone into the current script directory

    if (-not (Test-Path -Path (Join-Path -Path $clonePath -ChildPath ".git"))) {
        Write-Log "Repository not found at $clonePath. Cloning repository..."
        try {
            git clone $repoUrl $clonePath 2>&1 | Tee-Object -FilePath $logFilePath -Append
            Write-Log "Repository cloned to $clonePath."
        } catch {
            Write-Log "Error cloning repository: $_"
            $global:ScriptError = $true
            exit 1
        }
    } else {
        Write-Log "Repository already exists at $clonePath. Pulling latest changes..."
        try {
            Set-Location $clonePath
            git pull 2>&1 | Tee-Object -FilePath $logFilePath -Append
            Set-Location $PSScriptRoot
        } catch {
            Write-Log "Error pulling latest changes: $_"
            $global:ScriptError = $true
            exit 1
        }
    }
}

# ... [Rest of the script remains unchanged] ...

# Modify the elevation code to keep the window open if run from the GUI
# Check for administrative privileges
if (-Not (Test-IsAdmin)) {
    Write-Log "This script requires elevated privileges. Restarting as administrator..."
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""

    # If run from GUI, keep the window open
    if (Test-IsGUI) {
        $arguments = "-NoExit " + $arguments
    }

    Start-Process -FilePath "powershell.exe" -ArgumentList $arguments -Verb RunAs
    exit
}

# Main Execution
Write-Log "Starting kickstart script..."

$global:ScriptError = $false  # Flag to check if an error occurred

try {
    if ($Clean) {
        Write-Log "Clean parameter specified. Performing cleanup..."

        # Uninstall components
        Uninstall-Git
        Uninstall-Python
        Remove-Repository

        Write-Log "Cleanup completed successfully."
    } else {
        # Check if Git is installed (needed to clone the repository)
        if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
            Install-Git
        } else {
            Write-Log "Git is already installed."
            # Refresh environment variables in case Git was installed but not recognized
            Refresh-EnvironmentVariables
        }

        # Clone the repository
        Clone-Repository

        # Check and install Python
        Check-Python

        # Run the controller script
        Run-Controller

        Write-Log "Kickstart script completed successfully."
    }
} catch {
    Write-Log "An unexpected error occurred: $_"
    $global:ScriptError = $true
}

# If run from the GUI, wait for user input before exiting
if (Test-IsGUI) {
    if ($global:ScriptError) {
        Write-Host "An error occurred during execution. Please check the log file at $logFilePath."
    } else {
        Write-Host "Script completed successfully."
    }
    Write-Host "Press Enter to exit..."
    Read-Host
}
