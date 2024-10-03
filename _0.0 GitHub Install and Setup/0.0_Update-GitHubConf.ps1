# Define the path to the configuration file
$configFilePath = Join-Path -Path $PSScriptRoot -ChildPath "0.0_setup-github-vscode.conf"

# Load the existing configuration file
if (-not (Test-Path $configFilePath)) {
    Write-Error "Configuration file not found at $configFilePath."
    exit 1
}

$config = Get-Content -Raw -Path $configFilePath | ConvertFrom-Json

# Define headers for GitHub API requests
$headers = @{
    'User-Agent' = 'Update-GitHubConf-Script'
}

# Function to update Git installer URL
function Update-GitInstallerUrl {
    Write-Verbose "Fetching the latest Git for Windows installer URL..."

    $gitApiUrl = "https://api.github.com/repos/git-for-windows/git/releases/latest"

    try {
        $gitReleaseInfo = Invoke-RestMethod -Uri $gitApiUrl -Headers $headers -UseBasicParsing

        $gitInstallerAsset = $gitReleaseInfo.assets | Where-Object { $_.name -like "*64-bit.exe" }

        if ($gitInstallerAsset) {
            $latestGitInstallerUrl = $gitInstallerAsset.browser_download_url
            Write-Verbose "Latest Git installer URL: $latestGitInstallerUrl"

            $config.GitInstallerUrl = $latestGitInstallerUrl
        } else {
            Write-Error "Could not find a 64-bit installer in the latest Git release."
        }
    } catch {
        Write-Error "Error fetching Git installer URL: $_"
    }
}

# Function to update GitHub CLI installer URL
function Update-GitHubCLIInstallerUrl {
    Write-Verbose "Fetching the latest GitHub CLI installer URL..."

    $ghCliApiUrl = "https://api.github.com/repos/cli/cli/releases/latest"

    try {
        $ghCliReleaseInfo = Invoke-RestMethod -Uri $ghCliApiUrl -Headers $headers -UseBasicParsing

        $ghCliInstallerAsset = $ghCliReleaseInfo.assets | Where-Object { $_.name -like "*windows_amd64.msi" }

        if ($ghCliInstallerAsset) {
            $latestGhCliInstallerUrl = $ghCliInstallerAsset.browser_download_url
            Write-Verbose "Latest GitHub CLI installer URL: $latestGhCliInstallerUrl"

            $config.GitHubCLIInstallerUrl = $latestGhCliInstallerUrl
        } else {
            Write-Error "Could not find a Windows 64-bit installer in the latest GitHub CLI release."
        }
    } catch {
        Write-Error "Error fetching GitHub CLI installer URL: $_"
    }
}

# Function to update VSCode installer URL
function Update-VSCodeInstallerUrl {
    Write-Verbose "Fetching the latest VSCode installer URL..."

    # VSCode download page (direct link to stable release for Windows 64-bit user setup)
    $vscodeInstallerUrl = "https://aka.ms/win32-x64-user-stable"

    # Update the configuration file
    $config.VSCodeInstallerUrl = $vscodeInstallerUrl

    Write-Verbose "Latest VSCode installer URL: $vscodeInstallerUrl"
}

# Update the configuration with the latest URLs
Update-GitInstallerUrl
Update-GitHubCLIInstallerUrl
Update-VSCodeInstallerUrl

# Save the updated configuration back to the file atomically
try {
    $tempConfigPath = "$configFilePath.tmp"
    $config | ConvertTo-Json -Depth 4 | Set-Content -Path $tempConfigPath
    Move-Item -Path $tempConfigPath -Destination $configFilePath -Force
    Write-Host "Configuration file updated successfully."
} catch {
    Write-Error "Error updating configuration file: $_"
    exit 1
}

# End of the script
exit 0
