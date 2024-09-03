param(
    [string]$BranchName = "",
    [string]$CommitMessage = "",
    [string]$ConfigFile = "..\_0.0 GitHub Install and Setup/0.0_setup-github-vscode.conf",
    [switch]$MergeToMain
)

# Resolve the full path to the configuration file relative to the script location
$ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath $ConfigFile

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

# Ensure the script is run from a Git repository
try {
    git.exe --git-dir "$RepoDirectory\.git" --work-tree "$RepoDirectory" rev-parse --is-inside-work-tree
} catch {
    Write-Host "Error: This directory is not a Git repository."
    exit 1
}

# Check if a branch name was provided
if ($BranchName -eq "") {
    Write-Host "Error: A branch name must be provided."
    exit 1
}

# Function to initialize, commit, and push files to the corresponding repository
function Initialize-Repo {
    param (
        [string]$RepoPath,
        [string]$Username,
        [string]$RepoName
    )

    Set-Location -Path $RepoPath
    git init
    git add .
    git commit -m "Initial commit with local files"
    git branch -M main
    git remote add origin "https://github.com/$Username/$RepoName.git"
    git push -u origin main
    Set-Location -Path ..
}

# List of submodules to handle
$submodules = @(
    @{ Name = "opentofu"; LocalPath = ".\opentofu"; Username = "wizzense" },
    @{ Name = "TaniumLabDeployment"; LocalPath = ".\TaniumLabDeployment"; Username = "wizzense" },
    @{ Name = "WinImaging"; LocalPath = ".\WinImaging"; Username = "wizzense" }
)

# Initialize each submodule if it doesn't exist
foreach ($submodule in $submodules) {
    $repoUrl = Get-RepoUrl -RepoPath $submodule.LocalPath

    if (-not $repoUrl) {
        $repoUrl = Create-GitHubRepo -Username $submodule.Username -RepoName $submodule.Name
    }

    if ($repoUrl) {
        # Initialize the local repo if it's new and hasn't been committed yet
        if (Test-Path "$($submodule.LocalPath)\.git" -eq $false) {
            Initialize-Repo -RepoPath $submodule.LocalPath -Username $submodule.Username -RepoName $submodule.Name
        }

        Write-Host "Adding submodule $($submodule.Name) with URL $repoUrl..."
        Set-Location -Path $RepoDirectory
        git submodule add $repoUrl $submodule.Name
        Set-Location -Path ..
    } else {
        Write-Host "Failed to retrieve or create the repository URL for $($submodule.Name)."
    }
}

# Step 1: Branch Handling
# Check if the branch already exists
$branchExists = git.exe --git-dir "$RepoDirectory\.git" --work-tree "$RepoDirectory" branch --list $BranchName

if ($branchExists) {
    # Branch exists, checkout the branch
    git.exe --git-dir "$RepoDirectory\.git" --work-tree "$RepoDirectory" checkout $BranchName
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Failed to checkout existing branch '$BranchName'."
        exit 1
    }
    Write-Host "Checked out existing branch '$BranchName'."
} else {
    # Branch does not exist, create and checkout a new branch
    git.exe --git-dir "$RepoDirectory\.git" --work-tree "$RepoDirectory" checkout -b $BranchName
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Failed to create or checkout branch '$BranchName'."
        exit 1
    }
    Write-Host "Branch '$BranchName' created and checked out."
}

# Step 2: Pull the latest changes from 'main' into the branch
Write-Host "Pulling latest changes from 'main' into '$BranchName'..."
git.exe --git-dir "$RepoDirectory\.git" --work-tree "$RepoDirectory" pull origin main
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to pull latest changes from 'main' into '$BranchName'."
    exit 1
}
Write-Host "Successfully pulled the latest changes from 'main' into '$BranchName'."

# Step 3: Stage all changes
git.exe --git-dir "$RepoDirectory\.git" --work-tree "$RepoDirectory" add .
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to stage changes."
    exit 1
}
Write-Host "All changes staged."

# Step 4: Commit changes
git.exe --git-dir "$RepoDirectory\.git" --work-tree "$RepoDirectory" commit -m $CommitMessage
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to commit changes."
    exit 1
}
Write-Host "Changes committed with message: '$CommitMessage'."

# Step 5: Push the branch to the remote repository
Write-Host "Pushing branch '$BranchName' to remote repository..."
git.exe --git-dir "$RepoDirectory\.git" --work-tree "$RepoDirectory" push origin $BranchName
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to push branch '$BranchName' to origin."
    exit 1
}
Write-Host "Branch '$BranchName' pushed to origin."

# Step 6: Create a pull request using GitHub CLI
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

# Step 7: Merge the branch into main if requested
if ($MergeToMain) {
    try {
        # Checkout the main branch
        git.exe --git-dir "$RepoDirectory\.git" --work-tree "$RepoDirectory" checkout main
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Error: Failed to checkout the 'main' branch."
            exit 1
        }
        Write-Host "Checked out 'main' branch."

        # Pull the latest changes from the remote main branch
        Write-Host "Pulling latest changes from the remote 'main' branch..."
        git.exe --git-dir "$RepoDirectory\.git" --work-tree "$RepoDirectory" pull origin main
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Error: Failed to pull latest changes from remote 'main' branch."
            exit 1
        }
        Write-Host "Successfully pulled the latest changes."

        # Merge the dev branch into main
        git.exe --git-dir "$RepoDirectory\.git" --work-tree "$RepoDirectory" merge $BranchName
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Error: Merge failed."
            exit 1
        }
        Write-Host "Merged '$BranchName' into 'main'."

        # Push the merged main branch to the remote repository
        Write-Host "Pushing merged 'main' branch to remote repository..."
        git.exe --git-dir "$RepoDirectory\.git" --work-tree "$RepoDirectory" push origin main
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Error: Failed to push the 'main' branch to origin."
            exit 1
        }
        Write-Host "Pushed the 'main' branch to origin."

        # Optionally, push the updated dev-branch as well to ensure both are in sync
        Write-Host "Pushing updated '$BranchName' branch to remote repository..."
        git.exe --git-dir "$RepoDirectory\.git" --work-tree "$RepoDirectory" push origin $BranchName
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Error: Failed to push updated branch '$BranchName' to origin."
            exit 1
        }
        Write-Host "Pushed the updated '$BranchName' branch to origin."
    } catch {
        Write-Host "Error: An issue occurred during the merge process."
        exit 1
    }
}

Write-Host "All operations completed successfully."
