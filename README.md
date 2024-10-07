This PowerShell script automates the process of downloading and installing software packages from the web. It supports various installer formats including EXE, MSI, MSIX, and ZIP. The script ensures that the application is installed before and after and performs cleanup operations after installation.

#### Features:
- **Dynamic URL Handling**: Automatically appends `download=1` to SharePoint URLs to facilitate direct downloads.
- **Installer Download**: Downloads the installer from the specified URL if it does not already exist locally.
- **Installation Support**: Supports installation of EXE, MSI, MSIX, and ZIP packages.
- **ZIP Extraction**: Extracts ZIP files and runs the nested installer if specified.
- **Cleanup**: Deletes the installer and extracted files after installation.
- **Installation Check**: Verifies if the application is already installed to avoid redundant installations.

#### Usage:
1. **Set Variables**:
    - `$program`: Name of the program.
    - `$urlPath`: URL to the installer (EXE, MSI, MSIX, or ZIP).
    - `$nestedInstallerFolderAndFile`: Path to the nested installer within the ZIP file (if applicable).
    - `$arguments`: Arguments to pass to the installer.
    - `$fileToCheck`: Path to a file that indicates the application is installed.

2. **Run the Script**:
    - The script will create a temporary folder, download the installer, and execute the installation process based on the file type.
    - If the application is already installed, the script will skip the installation.

#### Notes:
- Ensure that PowerShell is run with administrative privileges to allow installation.
- Modify the variables as needed to suit your specific installation requirements.

This script simplifies the deployment of applications by automating the download and installation process, making it ideal for IT professionals and system administrators.

# Onboarding - Offboarding - Intune - Assets - Reporting

# THIS IS A WORK IN PROGRESS!!!

For documentation, please visit: [Onboarding - Offboarding - Intune - Assets - Reporting](https://xxxmtixxx.github.io/Onboarding-Offboarding-Intune-Assets-Reporting/)

This is an evolving project, and there are multiple modules that work together, including:

## [OnboardingOffboardingForm](https://github.com/xxxmtixxx/OnboardingOffboardingForm)

## [AnyAppInstaller](https://github.com/xxxmtixxx/AnyAppInstaller)

## [IntuneWin32App-MultiTenant](https://github.com/xxxmtixxx/IntuneWin32App-MultiTenant)
