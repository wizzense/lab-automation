# Enable Hyper-V on the system
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart

# Optionally, restart the machine to complete the installation
Restart-Computer -Force
