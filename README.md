---

# AnyAppInstaller

**AnyAppInstaller** is a versatile PowerShell script designed to download, install, and manage software installations. It supports downloading from a URL, UNC path, or using a local path for EXE, MSI, MSIX, and ZIP files. The script handles silent installations, verifies the software installation, and includes features for ZIP extraction and nested installers. It is highly customizable, allowing users to run pre- and post-installation tasks, control logging behavior, and handle updates efficiently.

## Key Features

### Existing Features:
- **File Name Extraction**: Automatically extracts the file name from URLs, including support for **SharePoint** links using the `Content-Disposition` header, ensuring accurate file downloads even with query strings or complex URLs.
- **Installer Types Supported**: Supports **EXE**, **MSI**, **MSIX**, and **ZIP** file formats.
- **Silent Installation**: Customizable installation arguments allow for silent or interactive installations.
- **Prevent Cleanup on Failure**: You can choose to skip cleanup of downloaded or extracted files if the installation fails, allowing for easier retries.
- **Reboot Control**: Optionally allows or prevents reboots after the installation.
- **Allow Update**: Forces an update by skipping the file check, even if the application is already installed.
- **Installer Source Flexibility**: Supports downloading installers from **URLs**, **UNC paths**, or using **local paths**.
- **Application Check**: Verifies if the application is installed before proceeding with the installation, saving bandwidth and time.
- **Detailed Logging**: Logs key events and actions, including download, installation, and cleanup steps. Control over log appending or clearing is provided.

### New Features:
- **Pre/Post-Installation Tasks**: You can specify tasks to run before and after the main installation, such as additional scripts or configuration actions.
- **Faster ZIP Extraction**: Includes a custom ZIP extraction function (`Expand-ArchiveFast`) for faster processing, with a fallback to the standard method if necessary.
- **Dropbox URL Support**: Automatically detects Dropbox links and ensures correct downloading by modifying the query parameters (changing `dl=0` to `dl=1`).
- **SharePoint URL Handling**: Automatically appends `"download=1"` to SharePoint links for seamless direct file downloads.
- **Customizable Logging**: Control whether to append to an existing log file or overwrite it with each run for better tracking.

## Usage

### Modify the following variables:

1. **Program Name**: Define the name of the software being installed.
    ```powershell
    $program = "7Zip"
    ```

2. **Installer Path (URL, UNC, or Local)**: Specify the path to the installer, which can be a URL, UNC path, or a local file path.
    ```powershell
    $downloadPath = "https://www.7-zip.org/a/7z2408-x64.exe"
    ```

3. **Nested Installer Path** (Optional for ZIPs): If the main installer is a ZIP file, specify the relative path of the installer inside the extracted folder.
    ```powershell
    $nestedInstallerFolderAndFile = "" # Not needed for EXE, MSI, MSIX
    ```

4. **Installation Arguments**: Define any arguments to run the installer silently or with specific options.
    ```powershell
    $arguments = "/S" # Silent installation for 7Zip
    ```

5. **File to Check if Installed**: Path to a file that verifies if the software is already installed. If the file exists, the installation will be skipped (unless `$allowUpdate` is set to `$true`).
    ```powershell
    $fileToCheck = "C:\Program Files\7-Zip\7z.exe"
    ```

6. **Allow Update**: Set this variable to `$true` to force the installer to run even if the software is already installed. Set it to `$false` to skip the installation if the software is already present.
    ```powershell
    $allowUpdate = $false
    ```

7. **Prevent Cleanup on Failure**: Set this variable to `$true` to skip the cleanup of downloaded/extracted files if the installation fails, making it easier to retry the installation without downloading the installer again.
    ```powershell
    $preventCleanupOnFailure = $false
    ```

8. **Allow Reboot**: Control whether the system should reboot after installation.
    ```powershell
    $allowReboot = $false
    ```

9. **Log File Control**: Choose whether to append to or overwrite the log file.
    ```powershell
    $allowLogAppend = $false
    ```

10. **Optional Pre-Installation Task**: If you need to run a pre-installation task (like an additional installer or setup script), define the file path and arguments.
    ```powershell
    $preInstallFile = "" # Not needed for this example
    $preInstallArguments = "" 
    ```

11. **Optional Post-Installation Task**: If you need to run a post-installation task, define the file path and arguments here. For example, you can set up configuration scripts or additional software after the main installation.
    ```powershell
    $postInstallFile = "C:\ConfigScripts\Configure7Zip.ps1"
    $postInstallArguments = "-ConfigureCompression -Silent"
    ```

### Example Script

This example shows how to install **7Zip** silently, verify the installation, and run a post-installation script.

```powershell
### Modify these Variables ###
$program = "7Zip"
$downloadPath = "https://www.7-zip.org/a/7z2408-x64.exe"
$nestedInstallerFolderAndFile = "" # Not needed for EXE, MSI, MSIX
$arguments = "/S" # Silent installation
$fileToCheck = "C:\Program Files\7-Zip\7z.exe"
$allowUpdate = $false
$allowReboot = $false
$preventCleanupOnFailure = $false
$allowLogAppend = $false
$preInstallFile = "" # No pre-install tasks for this example
$preInstallArguments = ""
$postInstallFile = "C:\ConfigScripts\Configure7Zip.ps1" # Post-install script
$postInstallArguments = "-ConfigureCompression -Silent"
```

### How It Works

1. **Check for Installation**: The script first checks if the application is already installed by looking for the specified `$fileToCheck`. If found, it skips the download and installation steps unless `$allowUpdate` is set to `$true`.

2. **Download Installer**: If the application is not installed or if the `$allowUpdate` variable is set to `$true`, it downloads the installer from the provided `$downloadPath`.

3. **Install Application**: 
   - If the installer is an EXE, MSI, or MSIX, the script runs the installer with the provided arguments (`/S` for silent installation in this case).
   - If the installer is a ZIP file, the script extracts it and runs the installer from within the extracted folder.

4. **Post-Install Task**: After the installation is completed, the script runs any post-installation tasks, such as configuration or additional scripts (`Configure7Zip.ps1` in this example).

5. **Cleanup**: After installation, the script cleans up any downloaded or extracted files unless the `$preventCleanupOnFailure` variable is set to `$true`.

### Example Post-Install Script (Configure7Zip.ps1)

Here’s an example of a post-installation script that could be run after 7Zip is installed:

```powershell
param (
    [switch]$ConfigureCompression,
    [switch]$Silent
)

if ($ConfigureCompression) {
    # Example of post-install task to configure 7Zip settings
    Write-Host "Configuring 7Zip compression settings..."
}

if ($Silent) {
    # Example of silent flag usage
    Write-Host "Running in silent mode..."
}

# Add any additional configurations needed for 7Zip here
```

## Troubleshooting
- **Log Files**: All actions are logged to help identify any issues during the installation process.
- **Error Handling**: If an error occurs during installation, the script will output the error and exit. If `$preventCleanupOnFailure` is set to `$true`, it will retain the downloaded files to allow easier retries.
