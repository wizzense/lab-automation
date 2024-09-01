# Define the path to the configuration file
$configFilePath = ".\0.0setup-github-vscode.conf"

# Function to prompt for input if values are not already set
function Get-Conf {
    param (
        [string]$promptMessage,
        [string]$defaultValue
    )

    if ($defaultValue) {
        return $defaultValue
    } else {
        return Read-Host $promptMessage
    }
}

# Check if the configuration file exists
if (-not (Test-Path $configFilePath)) {
    # Create a new configuration object
    $config = [PSCustomObject]@{
        GitInstallerUrl = Get-Conf "Enter the URL for Git installer:" ""
        GitUsername     = Get-Conf "Enter your GitHub username:" ""
        GitEmail        = Get-Conf "Enter your GitHub email:" ""
        VSCodeInstallerUrl = Get-Conf "Enter the URL for VSCode installer:" "https://aka.ms/win32-x64-user-stable"
        RepoUrl         = Get-Conf "Enter the URL for your GitHub repository:" ""
        LocalPath       = Get-Conf "Enter the local path for cloning the repository:" ""
    }

    # Save the configuration to the file
    $config | ConvertTo-Json -Depth 4 | Set-Content -Path $configFilePath
} else {
    # Load the existing configuration file
    $config = Get-Content -Raw -Path $configFilePath | ConvertFrom-Json
}

# Step 1: Install Git (if not already installed)
$gitInstalled = git --version 2>$null
if (!$gitInstalled) {
    Write-Host "Git is not installed. Installing Git..."
    $gitInstallerUrl = $config.GitInstallerUrl
    $gitInstallerPath = "$env:TEMP\GitInstaller.exe"
    Invoke-WebRequest -Uri $gitInstallerUrl -OutFile $gitInstallerPath
    Start-Process -FilePath $gitInstallerPath -ArgumentList "/VERYSILENT" -Wait
    Remove-Item -Path $gitInstallerPath
    Write-Host "Git installation completed."
} else {
    Write-Host "Git is already installed."
}

# Step 2: Set up Git global configuration (username and email)
git config --global user.name $config.GitUsername
git config --global user.email $config.GitEmail
Write-Host "Git global configuration set."

# Step 3: Install VSCode (if not already installed)
$vscodeInstalled = Get-Command "code" -ErrorAction SilentlyContinue
if (!$vscodeInstalled) {
    Write-Host "VSCode is not installed. Installing VSCode..."
    $vscodeInstallerUrl = $config.VSCodeInstallerUrl
    $vscodeInstallerPath = "$env:TEMP\VSCodeInstaller.exe"
    Invoke-WebRequest -Uri $vscodeInstallerUrl -OutFile $vscodeInstallerPath
    Start-Process -FilePath $vscodeInstallerPath -ArgumentList "/silent /mergetasks=!runcode,addcontextmenufiles,addcontextmenufolders" -Wait
    Remove-Item -Path $vscodeInstallerPath
    Write-Host "VSCode installation completed."
} else {
    Write-Host "VSCode is already installed."
}

# Step 4: Install VSCode Extensions (GitHub and GitLens)
$extensions = @("GitHub.vscode-pull-request-github", "eamodio.gitlens")
foreach ($ext in $extensions) {
    code --install-extension $ext
}
Write-Host "VSCode extensions installed."

# Step 5: Clone the GitHub repository (replace with your repo URL)
$repoUrl = $config.RepoUrl
$localPath = $config.LocalPath
if (-not (Test-Path $localPath)) {
    git clone $repoUrl $localPath
    Write-Host "Repository cloned to $localPath."
} else {
    Write-Host "Directory already exists. Skipping clone."
}

# Step 6: Open the repository in VSCode
Start-Process "code" -ArgumentList $localPath

Write-Host "Setup completed. Your GitHub repository is now set up in VSCode."
