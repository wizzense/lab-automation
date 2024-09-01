# Function to check if running as administrator
function Test-IsAdmin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

# Check if the script is running as an administrator
if (-Not (Test-IsAdmin)) {
    Write-Warning "This script requires elevated privileges. Attempting to restart as administrator..."

    # Re-launch the script with elevated privileges
    $newProcess = Start-Process -FilePath "powershell.exe" -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"" + $MyInvocation.MyCommand.Path + "`"") -Verb RunAs -PassThru

    # Wait for the new process to exit
    $newProcess.WaitForExit()

    # Exit the current process
    exit
}

# Place your script's main code here
Write-Host "Running with elevated privileges. Proceeding with script execution."

# Function to uninstall Git
function Uninstall-Git {
    $gitUninstallPath = "C:\Program Files\Git\unins000.exe"
    
    if (Test-Path $gitUninstallPath) {
        Write-Host "Uninstalling Git..."
        Start-Process -FilePath $gitUninstallPath -ArgumentList "/SILENT" -Wait
        Write-Host "Git uninstallation completed."

    } else {
        Write-Host "Git is not installed or the uninstaller was not found."
    }
}

# Function to uninstall Visual Studio Code
# doesn't work, but that's okay, kind of don't want it to yet
function Uninstall-VSCode {
    # Check the user-specific installation directory under LOCALAPPDATA
    $vscodeInstallDir = "$env:LOCALAPPDATA\Programs\Microsoft VS Code"
    $vscodeUninstaller = "$vscodeInstallDir\unins000.exe"
    
    if (Test-Path $vscodeUninstaller) {
        Write-Host "Uninstalling Visual Studio Code from $vscodeInstallDir..."
        Start-Process -FilePath $vscodeUninstaller -ArgumentList "/silent" -Wait
        Write-Host "Visual Studio Code uninstallation completed."
    } else {
        Write-Host "Uninstaller not found in the installation directory $vscodeInstallDir."
    }
}

# Run the uninstallation functions
Uninstall-Git
Uninstall-VSCode

Write-Host "Uninstallation process completed."
