param(
    [string]$BranchName = "my-new-branch",
    [string]$PRTitle = "Default PR Title",
    [string]$PRBody = "Description of the changes."
)

# Create a pull request
gh pr create --title "$PRTitle" --body "$PRBody" --head "$BranchName" --base main
Write-Host "Pull request created for branch '$BranchName'."
