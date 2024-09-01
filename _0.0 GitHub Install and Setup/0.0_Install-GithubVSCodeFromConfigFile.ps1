# Load configuration file
Write-Host "Loading configuration file..."
$configFile = ".\0.0_setup-github-vscode.conf"
$config = Get-Content -Raw -Path $configFile | ConvertFrom-Json
Write-Host "Configuration file loaded."

# Check if Git is installed
Write-Host "Checking if Git is installed..."
if (Get-Command git -ErrorAction SilentlyContinue) {
    Write-Host "Git is already installed."
} else {
    Write-Host "Git is not installed. Downloading Git installer from $($config.GitInstallerUrl)..."
    $gitInstaller = "$env:TEMP\GitInstaller.exe"
    Invoke-WebRequest -Uri $config.GitInstallerUrl -OutFile $gitInstaller -Verbose
    Write-Host "Git installer downloaded to $gitInstaller."

    Write-Host "Installing Git..."
    Start-Process -FilePath $gitInstaller -ArgumentList "/VERYSILENT" -Wait
    Write-Host "Git installation completed."

    Remove-Item -Path $gitInstaller
    Write-Host "Git installer removed."

    # Configure Git
    Write-Host "Configuring Git with username '$($config.GitUsername)' and email '$($config.GitEmail)'..."
    git config --global user.name $config.GitUsername
    git config --global user.email $config.GitEmail
    Write-Host "Git configured."
}

# Check if GitHub CLI is installed
Write-Host "Checking if GitHub CLI is installed..."
if (Get-Command gh -ErrorAction SilentlyContinue) {
    Write-Host "GitHub CLI is already installed."
} else {
    Write-Host "GitHub CLI is not installed. Downloading GitHub CLI installer from $($config.GitHubCLIInstallerUrl)..."
    $ghCliInstaller = "$env:TEMP\GitHubCLIInstaller.msi"
    Invoke-WebRequest -Uri $config.GitHubCLIInstallerUrl -OutFile $ghCliInstaller -Verbose
    Write-Host "GitHub CLI installer downloaded to $ghCliInstaller."

    Write-Host "Installing GitHub CLI with elevated privileges..."
    # Run the installer with elevated privileges
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", "`"$ghCliInstaller`"", "/quiet", "/log", "$env:TEMP\ghCliInstall.log" -Wait -Verb RunAs
    Write-Host "GitHub CLI installation completed."

    Remove-Item -Path $ghCliInstaller
    Write-Host "GitHub CLI installer removed."
}

# Check if Visual Studio Code is installed
Write-Host "Checking if Visual Studio Code is installed..."
$vscodePath = "C:\Users\alexa\AppData\Local\Programs\Microsoft VS Code\Code.exe"
if (Test-Path $vscodePath) {
    Write-Host "Visual Studio Code is already installed."
} else {
    Write-Host "Visual Studio Code is not installed. Downloading VSCode installer from $($config.VSCodeInstallerUrl)..."
    $vscodeInstaller = "$env:TEMP\VSCodeInstaller.exe"
    Invoke-WebRequest -Uri $config.VSCodeInstallerUrl -OutFile $vscodeInstaller -Verbose
    Write-Host "VSCode installer downloaded to $vscodeInstaller."

    Write-Host "Installing Visual Studio Code..."
    Start-Process -FilePath $vscodeInstaller -ArgumentList "/VERYSILENT" -Wait
    Write-Host "VSCode installation completed."

    Remove-Item -Path $vscodeInstaller
    Write-Host "VSCode installer removed."
}

# Capture existing VSCode processes
$existingVSCodeProcesses = Get-Process -Name "Code" -ErrorAction SilentlyContinue

# Install VSCode Extensions
Write-Host "Installing VSCode extensions..."
foreach ($extension in $config.VSCodeExtensions) {
    Write-Host "Installing extension $extension..."
    & $vscodePath --install-extension $extension
    Write-Host "Extension $extension installed."
}
Write-Host "All VSCode extensions installed."

# Close newly opened VSCode instances
Write-Host "Closing any newly opened VSCode windows..."
$newVSCodeProcesses = Get-Process -Name "Code" -ErrorAction SilentlyContinue | Where-Object { $_.StartTime -gt (Get-Date).AddMinutes(-5) }
foreach ($process in $newVSCodeProcesses) {
    if (-not $existingVSCodeProcesses -or $null -eq ($existingVSCodeProcesses | Where-Object { $_.Id -eq $process.Id })) {
        Write-Host "Closing VSCode process with ID $($process.Id)..."
        Stop-Process -Id $process.Id -Force
    }
}
Write-Host "New VSCode windows closed."

# Clone Git Repository
Write-Host "Checking if the local path '$($config.LocalPath)' exists..."
if (-not (Test-Path -Path $config.LocalPath)) {
    Write-Host "Local path does not exist. Creating directory..."
    New-Item -ItemType Directory -Path $config.LocalPath
    Write-Host "Directory created."
} else {
    Write-Host "Local path exists."
}

$repoFolderName = [System.IO.Path]::GetFileNameWithoutExtension($config.RepoUrl)
$repoPath = Join-Path -Path $config.LocalPath -ChildPath $repoFolderName

if (-not (Test-Path -Path $repoPath)) {
    Write-Host "Repository does not exist. Cloning repository from $($config.RepoUrl)..."
    git clone $config.RepoUrl
    Write-Host "Repository cloned to $repoPath."
} else {
    Write-Host "Repository already exists at $repoPath. Skipping clone."
}

# Extract the repository name from RepoUrl
$RepoUrl = $config.RepoUrl
$RepoName = ($RepoUrl.Split('/')[-1]).Replace(".git", "")

# Combine LocalPath and RepoName to get the full repository path
$RepoDirectory = Join-Path -Path $config.LocalPath -ChildPath $RepoName

Write-Host "Constructed repository path: $RepoDirectory"

Write-Host "Changing directory to $RepoDirectory..."
Set-Location $RepoDirectory