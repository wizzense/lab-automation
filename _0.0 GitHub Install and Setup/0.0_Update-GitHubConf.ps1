# Define the path to the configuration file
$configFilePath = Join-Path -Path $PSScriptRoot -ChildPath "0.0_setup-github-vscode.conf"

# Load the existing configuration file
if (-not (Test-Path $configFilePath)) {
    Write-Host "Configuration file not found at $configFilePath."
    exit 1
}

$config = Get-Content -Raw -Path $configFilePath | ConvertFrom-Json

# Function to update Git installer URL
function Update-GitInstallerUrl {
    Write-Host "Fetching the latest Git for Windows installer URL..."
    
    # GitHub API endpoint for the latest Git for Windows release
    $gitApiUrl = "https://api.github.com/repos/git-for-windows/git/releases/latest"
    
    # Fetch the latest release information from GitHub
    $gitReleaseInfo = Invoke-RestMethod -Uri $gitApiUrl -UseBasicParsing

    # Filter assets to find the correct installer for Windows 64-bit
    $gitInstallerAsset = $gitReleaseInfo.assets | Where-Object { $_.name -like "*64-bit.exe" }

    if ($gitInstallerAsset) {
        $latestGitInstallerUrl = $gitInstallerAsset.browser_download_url
        Write-Host "Latest Git installer URL: $latestGitInstallerUrl"

        # Update the configuration file
        $config.GitInstallerUrl = $latestGitInstallerUrl
    } else {
        Write-Host "Could not find a 64-bit installer in the latest Git release."
    }
}

# Function to update GitHub CLI installer URL
function Update-GitHubCLIInstallerUrl {
    Write-Host "Fetching the latest GitHub CLI installer URL..."
    
    # GitHub API endpoint for the latest GitHub CLI release
    $ghCliApiUrl = "https://api.github.com/repos/cli/cli/releases/latest"
    
    # Fetch the latest release information from GitHub
    $ghCliReleaseInfo = Invoke-RestMethod -Uri $ghCliApiUrl -UseBasicParsing

    # Filter assets to find the correct installer for Windows 64-bit
    $ghCliInstallerAsset = $ghCliReleaseInfo.assets | Where-Object { $_.name -like "*windows_amd64.msi" }

    if ($ghCliInstallerAsset) {
        $latestGhCliInstallerUrl = $ghCliInstallerAsset.browser_download_url
        Write-Host "Latest GitHub CLI installer URL: $latestGhCliInstallerUrl"

        # Update the configuration file
        $config.GitHubCLIInstallerUrl = $latestGhCliInstallerUrl
    } else {
        Write-Host "Could not find a Windows 64-bit installer in the latest GitHub CLI release."
    }
}

# Function to update VSCode installer URL
function Update-VSCodeInstallerUrl {
    Write-Host "Fetching the latest VSCode installer URL..."
    
    # VSCode download page (direct link to stable release for Windows 64-bit user setup)
    $vscodeInstallerUrl = "https://aka.ms/win32-x64-user-stable"
    
    # VSCode does not have an API for the latest release, the stable link remains constant
    Write-Host "Latest VSCode installer URL: $vscodeInstallerUrl"
    
    # Update the configuration file
    $config.VSCodeInstallerUrl = $vscodeInstallerUrl
}

# Update the configuration with the latest URLs
Update-GitInstallerUrl
Update-GitHubCLIInstallerUrl
Update-VSCodeInstallerUrl

# Save the updated configuration back to the file
$config | ConvertTo-Json -Depth 4 | Set-Content -Path $configFilePath

Write-Host "Configuration file updated successfully."

# End of the script
Write-Output "Configuration file updated successfully."
exit 0
