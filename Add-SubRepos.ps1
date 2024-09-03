# Define the path to your repositories
$repoPaths = @(
    ".\Hyper-V-Automation",
    ".\TaniumLabDeployment",
    ".\terraform-provider-hyperv",
    ".\opentofu",
    ".\WinImaging"
)

# Check if GitHub CLI is available
if (-not (Get-Command "gh" -ErrorAction SilentlyContinue)) {
    Write-Error "GitHub CLI (gh) is not installed. Please install it before running this script."
    exit 1
}

# Function to get the remote URL of the repository
function Get-RepoDetails {
    param (
        [string]$RepoPath
    )

    # Navigate to the repository directory
    Set-Location -Path $RepoPath

    # Get the remote URL
    $remoteUrl = git remote get-url origin

    # Extract the owner and repository name
    if ($remoteUrl -match "github\.com[:\/](.*)\/(.*)\.git") {
        return @{
            Owner = $matches[1]
            Name = $matches[2]
            Url = $remoteUrl
        }
    } else {
        Write-Host "Unable to parse the remote URL for $RepoPath."
        return $null
    }
}

# Function to create a new repository on GitHub
function Create-NewRepo {
    param (
        [string]$RepoName,
        [string]$RepoPath
    )

    # Check if the repository exists on GitHub
    $repoCheck = gh repo view $globalGitConfig/$RepoName --json name

    if (-not $repoCheck) {
        Write-Host "Repository $RepoName does not exist. Creating a new repository on GitHub..."
        gh repo create $globalGitConfig/$RepoName --public --confirm
    } else {
        Write-Host "Repository $RepoName already exists on GitHub."
    }

    # Initialize the repository locally
    Set-Location -Path $RepoPath
    git init
    git remote add origin "https://github.com/$globalGitConfig/$RepoName.git"
    git add .
    git commit -m "Initial commit"
    git push -u origin master
}

# Retrieve the global GitHub username
$globalGitConfig = git config --global user.name
if (-not $globalGitConfig) {
    $globalGitConfig = Read-Host "GitHub username not found. Please enter your GitHub username"
    git config --global user.name $globalGitConfig
}

# Process each repository
foreach ($repoPath in $repoPaths) {
    if (Test-Path $repoPath) {
        $repoDetails = Get-RepoDetails -RepoPath $repoPath
        if ($repoDetails) {
            Write-Host "Repository: $($repoDetails.Name)"
            Write-Host "Owner: $($repoDetails.Owner)"
            Write-Host "URL: $($repoDetails.Url)"
            Write-Host "-----------------------------------"
        }
    } else {
        # This is for new repositories that need to be created
        $repoName = Split-Path $repoPath -Leaf
        Create-NewRepo -RepoName $repoName -RepoPath $repoPath
    }
}

# Set up submodules
Set-Location -Path ".\tanium-homelab-automation"

$submodules = @(
    @{ Name = "Hyper-V-Automation"; Url = "https://github.com/other-username/hyper-v-automation.git" },
    @{ Name = "TaniumLabDeployment"; Url = "https://github.com/other-username/taniumlabdeployment.git" },
    @{ Name = "terraform-provider-hyperv"; Url = "https://github.com/other-username/terraform-provider-hyperv.git" },
    @{ Name = "opentofu"; Url = "https://github.com/$globalGitConfig/opentofu.git" },
    @{ Name = "WinImaging"; Url = "https://github.com/$globalGitConfig/WinImaging.git" }
)

foreach ($submodule in $submodules) {
    git submodule add $submodule.Url $submodule.Name
}

# Commit the submodule addition
git commit -m "Added submodules: Hyper-V-Automation, TaniumLabDeployment, terraform-provider-hyperv, opentofu, WinImaging"

# Push the changes to the main repository
git push

Write-Host "All repositories have been set up as submodules and initialized."
