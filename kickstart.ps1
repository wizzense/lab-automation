# Enable Verbose output
$VerbosePreference = "Continue"

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
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

# Check for administrative privileges
if (-Not (Test-IsAdmin)) {
    Write-Log "This script requires elevated privileges. Restart as administrator..."

    exit
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

            # Configure Git (Optional)
            # You can set default username and email here if desired
            # git config --global user.name "YourName"
            # git config --global user.email "YourEmail@example.com"

        } else {
            Write-Log "Could not find a 64-bit Git installer. Exiting."
            exit 1
        }
    } catch {
        Write-Log "Error installing Git: $_"
        exit 1
    }
}

# Function to download and install Python
function Install-Python {
    Write-Log "Python is not installed. Downloading Python installer..."

    # Define the Python installer URL and local path
    $pythonInstallerUrl = "https://www.python.org/ftp/python/3.11.5/python-3.11.5-amd64.exe"  # Replace with the desired version
    $pythonInstaller = Join-Path -Path $env:TEMP -ChildPath "python-installer.exe"

    # Download the Python installer
    try {
        Invoke-WebRequest -Uri $pythonInstallerUrl -OutFile $pythonInstaller -UseBasicParsing -Verbose
        Write-Log "Python installer downloaded to $pythonInstaller."
    } catch {
        Write-Log "Error downloading Python installer: $_"
        exit 1
    }

    # Install Python silently
    Write-Log "Installing Python silently..."
    try {
        Start-Process -FilePath $pythonInstaller -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1 Include_test=0" -Wait
        Write-Log "Python installation completed."
    } catch {
        Write-Log "Error installing Python: $_"
        exit 1
    }

    # Remove the installer
    Remove-Item -Path $pythonInstaller -Force
    Write-Log "Python installer removed."
}

# Function to check if Python is installed
function Check-Python {
    Write-Log "Checking if Python is installed..."

    $pythonInstalled = $false
    # Check common installation paths
    $pythonPaths = @(
        "$env:LOCALAPPDATA\Programs\Python\Python*",  # User-specific installations
        "C:\Python*",                                  # Custom installations
        "$env:ProgramFiles\Python*",                   # 64-bit installations
        "$env:ProgramFiles(x86)\Python*"               # 32-bit installations
    )

    foreach ($path in $pythonPaths) {
        if (Test-Path -Path $path) {
            $pythonInstalled = $true
            break
        }
    }

    if ($pythonInstalled -or (Get-Command python -ErrorAction SilentlyContinue)) {
        Write-Log "Python is already installed."
    } else {
        Install-Python
    }
}

# Function to run the Python controller script
function Run-Controller {
    Write-Log "Running the Python controller script..."

    $controllerScript = Join-Path -Path $PSScriptRoot -ChildPath "controller.py"

    if (-not (Test-Path -Path $controllerScript)) {
        Write-Log "Controller script not found at $controllerScript. Exiting."
        exit 1
    }

    try {
        # Use the full path to the python executable
        $pythonExe = Get-Command python | Select-Object -ExpandProperty Source

        $processInfo = New-Object System.Diagnostics.ProcessStartInfo
        $processInfo.FileName = $pythonExe
        $processInfo.Arguments = "`"$controllerScript`""
        $processInfo.RedirectStandardOutput = $true
        $processInfo.RedirectStandardError = $true
        $processInfo.UseShellExecute = $false
        $processInfo.CreateNoWindow = $true

        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $processInfo
        $process.Start() | Out-Null

        $output = $process.StandardOutput.ReadToEnd()
        $errorOutput = $process.StandardError.ReadToEnd()

        $process.WaitForExit()

        if ($process.ExitCode -eq 0) {
            Write-Log "Controller script executed successfully."
            Write-Log $output
        } else {
            Write-Log "Controller script failed with exit code $($process.ExitCode)."
            Write-Log $errorOutput
            exit $process.ExitCode
        }
    } catch {
        Write-Log "Error running controller script: $_"
        exit 1
    }
}

# Function to clone the repository
function Clone-Repository {
    Write-Log "Cloning the repository..."

    # Define the repository URL and clone path
    $repoUrl = "https://github.com/YourUsername/YourRepository.git"  # Replace with your repository URL
    $clonePath = $PSScriptRoot  # Clone into the current script directory

    if (-not (Test-Path -Path (Join-Path -Path $clonePath -ChildPath ".git"))) {
        Write-Log "Repository not found at $clonePath. Cloning repository..."
        try {
            git clone $repoUrl $clonePath 2>&1 | Tee-Object -FilePath $logFilePath -Append
            Write-Log "Repository cloned to $clonePath."
        } catch {
            Write-Log "Error cloning repository: $_"
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
            exit 1
        }
    }
}

# Main Execution
Write-Log "Starting kickstart script..."

# Check if Git is installed (needed to clone the repository)
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Install-Git
} else {
    Write-Log "Git is already installed."
}

# Clone the repository
Clone-Repository

# Check and install Python
Check-Python

# Run the controller script
Run-Controller

Write-Log "Kickstart script completed successfully."
