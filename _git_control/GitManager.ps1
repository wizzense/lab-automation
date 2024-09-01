param(
    [string]$BranchName = "",
    [string]$CommitMessage = "",
    [string]$ConfigFile = "..\_0.0 GitHub Install and Setup/0.0_setup-github-vscode.conf"
)

# Verify that the configuration file exists
if (-not (Test-Path -Path $ConfigFile)) {
    Write-Host "Error: Configuration file not found at path $ConfigFile"
    exit 1
}

# Load configuration file
Write-Host "Loading configuration file..."
$config = Get-Content -Raw -Path $ConfigFile | ConvertFrom-Json

# Extract the repository name from RepoUrl
$RepoUrl = $config.RepoUrl
$RepoName = ($RepoUrl.Split('/')[-1]).Replace(".git", "")

# Combine LocalPath and RepoName to get the full repository path
$RepoDirectory = Join-Path -Path $config.LocalPath -ChildPath $RepoName

Write-Host "Constructed repository path: $RepoDirectory"

# Ensure the directory from the config file exists
if (-not (Test-Path -Path $RepoDirectory)) {
    Write-Host "Error: The directory specified in the config file does not exist: $RepoDirectory"
    exit 1
}

# Change to the Git repository directory
Set-Location $RepoDirectory
Write-Host "Changed directory to $RepoDirectory"

# Ensure the script is run from a Git repository
try {
    git.exe rev-parse --is-inside-work-tree
} catch {
    Write-Host "Error: This directory is not a Git repository."
    exit 1
}

# Check if a branch name was provided
if ($BranchName -eq "") {
    Write-Host "Error: A branch name must be provided."
    exit 1
}

# Check if the branch already exists
$branchExists = git.exe branch --list $BranchName

if ($branchExists) {
    # Branch exists, checkout the branch
    git.exe checkout $BranchName
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Failed to checkout existing branch '$BranchName'."
        exit 1
    }
    Write-Host "Checked out existing branch '$BranchName'."
} else {
    # Branch does not exist, create and checkout a new branch
    git.exe checkout -b $BranchName
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Failed to create or checkout branch '$BranchName'."
        exit 1
    }
    Write-Host "Branch '$BranchName' created and checked out."
}

# Step 2: Stage all changes
git.exe add .
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to stage changes."
    exit 1
}
Write-Host "All changes staged."

# Step 3: Commit changes
git.exe commit -m $CommitMessage
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to commit changes."
    exit 1
}
Write-Host "Changes committed with message: '$CommitMessage'."

# Step 4: Push branch to remote repository
git.exe push origin $BranchName
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to push branch '$BranchName' to origin."
    exit 1
}
Write-Host "Branch '$BranchName' pushed to origin."

# Step 5: Create a pull request using GitHub CLI
try {
    gh pr create --title "$CommitMessage" --body "Automated PR for branch '$BranchName'" --base main --head $BranchName
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Pull request created successfully for branch '$BranchName'."
    } else {
        Write-Host "Error: Failed to create pull request."
    }
} catch {
    Write-Host "Error: GitHub CLI (gh) command failed. Ensure GitHub CLI is installed and authenticated."
    exit 1
}

#.\GitManager.ps1 -BranchName "dev-branch" -CommitMessage "GIT CLI install automation"
