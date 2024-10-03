# Function to check if running as administrator
function Test-IsAdmin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

# Check if the script is running as an administrator
if (-Not (Test-IsAdmin)) {
    Write-Warning "This script requires elevated privileges. Attempting to restart as administrator..."

    # Re-launch the script with elevated privileges
    Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Enable Verbose output
$VerbosePreference = "Continue"

Write-Verbose "Running with elevated privileges. Proceeding with script execution."

# Function to uninstall applications
function Uninstall-Application {
    param (
        [string]$appName
    )

    $uninstallPaths = @(
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    $found = $false

    foreach ($path in $uninstallPaths) {
        $apps = Get-ItemProperty $path -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*$appName*" }
        foreach ($app in $apps) {
            if ($app.UninstallString) {
                Write-Verbose "Uninstalling $($app.DisplayName)..."
                $uninstallCmd = $app.UninstallString

                # Handle different uninstall command formats
                if ($uninstallCmd -like "msiexec*") {
                    $arguments = $uninstallCmd.Substring($uninstallCmd.IndexOf("msiexec") + 7)
                    Start-Process -FilePath "msiexec.exe" -ArgumentList "$arguments /quiet /norestart" -Wait
                } else {
                    Start-Process -FilePath $uninstallCmd -ArgumentList "/SILENT" -Wait
                }

                Write-Verbose "$($app.DisplayName) uninstalled."
                $found = $true
            }
        }
    }

    if (-not $found) {
        Write-Verbose "Application $appName not found or already uninstalled."
    }
}

# Uninstall Git
Uninstall-Application -appName "Git"

# Uninstall Visual Studio Code
Uninstall-Application -appName "Visual Studio Code"

# Uninstall GitHub CLI
Uninstall-Application -appName "GitHub CLI"

Write-Host "Uninstallation process completed."
