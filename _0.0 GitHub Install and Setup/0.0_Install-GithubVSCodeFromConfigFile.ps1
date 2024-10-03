# Enable Verbose output
$VerbosePreference = "Continue"

# Load configuration file
Write-Verbose "Loading configuration file..."
$configFile = Join-Path -Path $PSScriptRoot -ChildPath "0.0_setup-github-vscode.conf"
if (-not (Test-Path $configFile)) {
    Write-Error "Configuration file not found at $configFile. Exiting script."
    exit 1
}
$config = Get-Content -Raw -Path $configFile | ConvertFrom-Json
Write-Verbose "Configuration file loaded."

# Function to check if a product is installed
function Test-ProductInstalled {
    param (
        [string[]]$productNames
    )

    $uninstallPaths = @(
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    foreach ($path in $uninstallPaths) {
        $installedApps = Get-ItemProperty $path -ErrorAction SilentlyContinue | Select-Object DisplayName
        foreach ($productName in $productNames) {
            $product = $installedApps | Where-Object { $_.DisplayName -like "*$productName*" }
            if ($null -ne $product) {
                return $true
            }
        }
    }
    return $false
}

# Function to install Git
function Install-Git {
    try {
        Write-Verbose "Downloading Git installer from $($config.GitInstallerUrl)..."
        $gitInstaller = Join-Path -Path $env:TEMP -ChildPath "GitInstaller.exe"
        Invoke-WebRequest -Uri $config.GitInstallerUrl -OutFile $gitInstaller -UseBasicParsing -Verbose

        Write-Verbose "Installing Git..."
        Start-Process -FilePath $gitInstaller -ArgumentList "/VERYSILENT" -Wait

        Remove-Item -Path $gitInstaller -Force
        Write-Verbose "Git installer removed."

        # Configure Git
        Write-Verbose "Configuring Git with username '$($config.GitUsername)' and email '$($config.GitEmail)'..."
        git config --global user.name $config.GitUsername
        git config --global user.email $config.GitEmail
        Write-Verbose "Git configured."
    } catch {
        Write-Error "An error occurred during Git installation: $_"
        exit 1
    }
}

# Function to install GitHub CLI
function Install-GitHubCLI {
    try {
        Write-Verbose "Downloading GitHub CLI installer from $($config.GitHubCLIInstallerUrl)..."
        $ghCliInstaller = Join-Path -Path $env:TEMP -ChildPath "GitHubCLIInstaller.msi"
        Invoke-WebRequest -Uri $config.GitHubCLIInstallerUrl -OutFile $ghCliInstaller -UseBasicParsing -Verbose

        Write-Verbose "Installing GitHub CLI..."
        Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$ghCliInstaller`" /quiet /norestart" -Wait

        Remove-Item -Path $ghCliInstaller -Force
        Write-Verbose "GitHub CLI installer removed."
    } catch {
        Write-Error "An error occurred during GitHub CLI installation: $_"
        exit 1
    }
}

# Function to install VSCode
function Install-VSCode {
    try {
        Write-Verbose "Downloading VSCode installer from $($config.VSCodeInstallerUrl)..."
        $vscodeInstaller = Join-Path -Path $env:TEMP -ChildPath "VSCodeInstaller.exe"
        Invoke-WebRequest -Uri $config.VSCodeInstallerUrl -OutFile $vscodeInstaller -UseBasicParsing -Verbose

        Write-Verbose "Installing Visual Studio Code..."
        Start-Process -FilePath $vscodeInstaller -ArgumentList "/VERYSILENT" -Wait

        Remove-Item -Path $vscodeInstaller -Force
        Write-Verbose "VSCode installer removed."
    } catch {
        Write-Error "An error occurred during VSCode installation: $_"
        exit 1
    }
}

# Function to install VSCode extensions
function Install-VSCodeExtensions {
    try {
        Write-Verbose "Installing VSCode extensions..."
        foreach ($extension in $config.VSCodeExtensions) {
            Write-Verbose "Installing extension $extension..."
            code --install-extension $extension --force
            Write-Verbose "Extension $extension installed."
        }
        Write-Verbose "All VSCode extensions installed."
    } catch {
        Write-Error "An error occurred during VSCode extension installation: $_"
        exit 1
    }
}

# Function to clone Git repository
function Clone-GitRepository {
    try {
        $config.LocalPath = [System.IO.Path]::Combine($env:USERPROFILE, "Documents", "0. Lab")
        $localPath = $config.LocalPath
        
        Write-Verbose "Checking if the local path '$localPath' exists..."
        if (-not (Test-Path -Path $localPath)) {
            Write-Verbose "Local path does not exist. Creating directory..."
            New-Item -ItemType Directory -Path $localPath -Force | Out-Null
            Write-Verbose "Directory created."
        } else {
            Write-Verbose "Local path exists."
        }

        $repoFolderName = [System.IO.Path]::GetFileNameWithoutExtension($config.RepoUrl)
        $repoPath = Join-Path -Path $localPath -ChildPath $repoFolderName

        if (-not (Test-Path -Path $repoPath)) {
            Write-Verbose "Repository does not exist. Cloning repository from $($config.RepoUrl)..."
            git clone $config.RepoUrl $repoPath
            Write-Verbose "Repository cloned to $repoPath."
        } else {
            Write-Verbose "Repository already exists at $repoPath. Pulling latest changes..."
            Set-Location $repoPath
            git pull
            Set-Location $PSScriptRoot
        }
    } catch {
        Write-Error "An error occurred during repository cloning: $_"
        exit 1
    }
}

# Main Execution

# Check and install Git
Write-Verbose "Checking if Git is installed..."
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Verbose "Git is not installed."
    Install-Git
} else {
    Write-Verbose "Git is already installed."
}

# Check and install GitHub CLI
Write-Verbose "Checking if GitHub CLI is installed..."
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Verbose "GitHub CLI is not installed."
    Install-GitHubCLI
} else {
    Write-Verbose "GitHub CLI is already installed."
}

# Check and install VSCode
Write-Verbose "Checking if Visual Studio Code is installed..."
$productNames = @("Visual Studio Code", "Microsoft Visual Studio Code")
if (-not (Test-ProductInstalled -productNames $productNames)) {
    Write-Verbose "Visual Studio Code is not installed."
    Install-VSCode
} else {
    Write-Verbose "Visual Studio Code is already installed."
}

# Install VSCode extensions
Install-VSCodeExtensions

# Clone Git repository
Clone-GitRepository

Write-Host "All tasks completed successfully."
