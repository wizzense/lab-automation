param(
    [string]$CommitMessage = "Default commit message",
    [string]$BranchName = "my-new-branch"
)

# Check if a commit message was provided
if ($CommitMessage -eq "Default commit message") {
    Write-Host "No commit message provided. Using default: Default commit message"
}

# Stage all changes
git add .
Write-Host "All changes staged."

# Commit with the provided message
git commit -m $CommitMessage
Write-Host "Changes committed with message: '$CommitMessage'."

# Push the branch to GitHub
git push origin $BranchName
Write-Host "Branch '$BranchName' pushed to origin."
