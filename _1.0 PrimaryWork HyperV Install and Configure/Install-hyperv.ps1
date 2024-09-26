# Function to check if the script is running with administrator privileges
function Test-IsAdmin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $adminRole = [Security.Principal.WindowsBuiltInRole]::Administrator
    $isAdmin = (New-Object Security.Principal.WindowsPrincipal($currentUser)).IsInRole($adminRole)

    if (-not $isAdmin) {
        Write-Host "This script must be run as an administrator. Please restart the script with elevated privileges."
        exit 1
    }
}

# Function to check system requirements for Hyper-V
function Get-SystemRequirements {
    Write-Host "Checking system requirements for Hyper-V..."

    # Check if the system is running on Windows 10, Windows 11, or Windows Server
    $osName = (Get-CimInstance Win32_OperatingSystem).Caption.Trim()
    Write-Host "Detected OS: $osName"  # Debugging output to see the actual OS name

    if ($osName -notmatch "Windows 10|Windows 11|Windows Server") {
        Write-Host "This script only supports Windows 10, Windows 11, or Windows Server. Your OS is: $osName"
        return $false
    }

    # Check if the system has the minimum required RAM (8 GB recommended)
    $minRam = 8 * 1GB
    $systemRam = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory

    if ($systemRam -lt $minRam) {
        Write-Host "The system does not meet the minimum RAM requirement. At least 8 GB of RAM is recommended."
        return $false
    }

    Write-Host "System requirements check passed."
    return $true
}

# Function to check if Hyper-V is already enabled
function Get-HyperVEnabled {
    Write-Host "Checking if Hyper-V is already enabled..."
    
    $hyperVFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V
    Write-Host $hyperVFeature.State
    if ($hyperVFeature.State -eq "Enabled") {
        Write-Host "Hyper-V is already enabled on this system."
        return $true
    } elseif ($hyperVFeature.State -eq "Disabled") {
        Write-Host "Hyper-V is not enabled on this system."
        return $false
    } else {
        Write-Host "Unable to determine the status of Hyper-V. Feature state: $($hyperVFeature.State)"
        return $false
    }
}

# Function to enable Hyper-V if not already enabled
function Enable-HyperV {
    if (-not (Get-HyperVEnabled)) {
        Write-Host "Enabling Hyper-V on this system..."
        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart

        # Check if enabling was successful
        if ($?) {
            Write-Host "Hyper-V was successfully enabled."
            return $true
        } else {
            Write-Host "Failed to enable Hyper-V."
            return $false
        }
    } else {
        Write-Host "Hyper-V is already enabled, skipping..."
        return $true
    }
}

# Main script execution
Test-IsAdmin
$meetRequirements = Get-SystemRequirements
#if (Get-SystemRequirements) {
if ($meetRequirements)  {
    if (Enable-HyperV) {
        # Check if a restart is required after enabling Hyper-V
        if ((Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V).RestartRequired -eq "Yes") {
            $restartPrompt = Read-Host "Would you like to restart the computer now to complete the installation? (Y/N)"
            if ($restartPrompt -eq "Y") {
                Write-Host "Restarting the computer..."
                Restart-Computer -Force
            } else {
                Write-Host "Please restart the computer manually to complete the Hyper-V installation."
            }
        } else {
            Write-Host "No restart is required. Hyper-V is fully enabled."
        }
    }
} else {
    Write-Host "System does not meet the requirements for Hyper-V."
}
