param(
    [string]$BranchName = "my-new-branch"
)

# Check if a branch name was provided
if ($BranchName -eq "my-new-branch") {
    Write-Host "No branch name provided. Using default: my-new-branch"
}

# Create and checkout the new branch
git checkout -b $BranchName
Write-Host "Branch '$BranchName' created and checked out."
