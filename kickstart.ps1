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

# Define script paths relative to the current script location
$scripts = @(
    "_0.0 GitHub Install and Setup\0.0_Update-GitHubConf.ps1",
    "_0.0 GitHub Install and Setup\0.0_Install-GithubVSCodeFromConfigFile.ps1",
    "_0.0 GitHub Install and Setup\0.0_BackupRestore-VSCodeConfig.ps1",
    "_2.0 Control Node VM Install and Configure\Update-ConfigFiles.ps1",
    "_2.0 Control Node VM Install and Configure\Update-ImageInfo.ps1",
    "_1.0 PrimaryWork HyperV Install and Configure\Install-hyperv.ps1",
    "_2.0 Control Node VM Install and Configure\Deploy-ControlNodeVM.ps1",
    "_2.0 Control Node VM Install and Configure\Install-Tanium.ps1"
)

# Check for administrative privileges
if (-not (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Log "This script requires elevated privileges. Restarting as administrator..."
    Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Run each script in order
foreach ($script in $scripts) {
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath $script
    $message = "Executing $scriptPath"
    Start-Script -ScriptPath $scriptPath -Message $message
}

# Log the completion of the script execution
Write-Log "All tasks completed successfully."
