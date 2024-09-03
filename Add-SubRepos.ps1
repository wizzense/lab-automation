# Authenticate with GitHub
if (-not (gh auth status --hostname github.com)) {
    Write-Host "Authenticating with GitHub..."
    gh auth login
}

# Define the correct URLs for existing repositories
$submodules = @(
    @{ Name = "Hyper-V-Automation"; Url = "https://github.com/other-username/hyper-v-automation.git" },
    @{ Name = "TaniumLabDeployment"; Url = "https://github.com/other-username/taniumlabdeployment.git" },
    @{ Name = "terraform-provider-hyperv"; Url = "https://github.com/other-username/terraform-provider-hyperv.git" },
    @{ Name = "opentofu"; Url = "https://github.com/wizzense/opentofu.git" },
    @{ Name = "WinImaging"; Url = "https://github.com/wizzense/WinImaging.git" }
)

# Create new repositories if they don't exist on GitHub
foreach ($submodule in $submodules) {
    if ($submodule.Owner -eq "wizzense") {
        $repoCheck = gh repo view $submodule.Name --json name --repo "wizzense/$($submodule.Name)"

        if (-not $repoCheck) {
            Write-Host "Repository $($submodule.Name) does not exist. Creating a new repository on GitHub..."
            gh repo create "wizzense/$($submodule.Name)" --public --confirm
        }
    }
}

# Add submodules to the main repo
foreach ($submodule in $submodules) {
    if (-not (Test-Path $submodule.Name)) {
        Write-Host "Adding submodule $($submodule.Name)..."
        git submodule add $submodule.Url $submodule.Name
    }
}

# Detect the current branch
$branchName = git rev-parse --abbrev-ref HEAD

# Commit the submodule addition
git add .
git commit -m "Added submodules: Hyper-V-Automation, TaniumLabDeployment, terraform-provider-hyperv, opentofu, WinImaging"

# Push the changes to the current branch
git push origin $branchName

Write-Host "All repositories have been set up as submodules and initialized."
