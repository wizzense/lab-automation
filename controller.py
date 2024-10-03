import subprocess
import logging
import os
import sys

# Configure logging
logging.basicConfig(
    filename='controller.log',
    level=logging.INFO,
    format='%(asctime)s %(levelname)s: %(message)s'
)

# Function to run a PowerShell script
def run_powershell_script(script_path, args=[]):
    cmd = ["powershell.exe", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", script_path] + args
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            check=True
        )
        logging.info(f"Script '{script_path}' executed successfully.")
        logging.info(result.stdout)
    except subprocess.CalledProcessError as e:
        logging.error(f"Script '{script_path}' failed with return code {e.returncode}.")
        logging.error(e.stderr)
        sys.exit(e.returncode)

def main():
    # Define the paths to your scripts
    script_dir = os.path.dirname(os.path.abspath(__file__))

    update_config_script = os.path.join(script_dir, "0.0_Update-GitHubConf.ps1")
    install_script = os.path.join(script_dir, "0.0_Install-GithubVSCodeFromConfigFile.ps1")
    backup_script = os.path.join(script_dir, "0.0_BackupRestore-VSCodeConfig.ps1")
    uninstall_script = os.path.join(script_dir, "0.0_Uninstall-GitHubVSCode.ps1")

    # Run the scripts in order
    logging.info("Starting environment setup...")

    # Update configuration file with latest URLs
    logging.info("Updating configuration file with latest installer URLs...")
    run_powershell_script(update_config_script)

    # Install Git, GitHub CLI, VSCode, and clone repository
    logging.info("Installing Git, GitHub CLI, VSCode, and cloning repository...")
    run_powershell_script(install_script)

    # Backup VSCode settings and extensions
    logging.info("Backing up VSCode settings and extensions...")
    run_powershell_script(backup_script, ["-operation", "backup"])

    # Additional tasks can be added here...

    logging.info("Environment setup completed successfully.")

if __name__ == "__main__":
    main()
