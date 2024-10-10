# AnyAppInstaller

**AnyAppInstaller** is a versatile PowerShell script designed to download, install, and manage the cleanup of software installers. It supports downloading from a URL, UNC path, or using a local path for EXE, MSI, MSIX, and ZIP files. The script handles silent installations and verifies the software installation afterward. Additionally, it can extract ZIP files and handle nested installers within them.

## Features
- Supports **EXE**, **MSI**, **MSIX**, and **ZIP** files.
- Downloads installers from **URLs**, **UNC paths**, or uses **local paths**.
- **Skip Installation Check**: Option to skip the local file check, forcing an update if needed.
- Verifies if the application is already installed before downloading to save bandwidth (unless skip is enabled).
- Silent installation with customizable arguments.
- Automatic cleanup of downloaded or extracted files.
- Logs key actions for transparency and troubleshooting.

## Usage
### Modify the following variables:

1. **Program Name**: The name of the application you are installing.
    ```powershell
    $program = "7Zip"
    ```

2. **Installer Path (URL, UNC, or Local)**: Specify the path to the installer, which can be a URL, UNC path, or a local file path.
    ```powershell
    $downloadPath = "https://www.7-zip.org/a/7z2408-x64.msi"
    ```

3. **Nested Installer Path (Optional for ZIPs)**: If the main installer is a ZIP file, specify the relative path of the installer inside the extracted folder.
    ```powershell
    $nestedInstallerFolderAndFile = ""
    ```

4. **Installation Arguments**: Define any arguments to run the installer silently or with specific options.
    ```powershell
    $arguments = "/qn"
    ```

5. **File to Check if Installed**: Path to a file that verifies if the software is already installed. If the file exists, the installation will be skipped (unless `skipFileCheck` is set to true).
    ```powershell
    $fileToCheck = "C:\Program Files\7-Zip\7z.exe"
    ```

6. **Skip Installation Check**: Set this variable to `$true` to force the installer to run regardless of whether the software is already installed. Set it to `$false` to skip the installation if the software is already present.
    ```powershell
    $skipFileCheck = $false # Set to $true to force update
    ```

## How It Works

1. **Check for Installation**: The script first checks if the application is already installed by looking for the specified `$fileToCheck`. If found, it skips the download and installation steps unless `$skipFileCheck` is set to `$true`.

2. **Download Installer**: If the application is not installed or if the `skipFileCheck` variable is set to `$true`, it downloads the installer from the provided `$downloadPath` if it's a URL or UNC path.

3. **Install Application**:
    - If the installer is an **EXE**, **MSI**, or **MSIX**, the script runs the installer with the provided arguments.
    - If the installer is a **ZIP** file, the script extracts it, and if a nested installer is specified, it runs that installer.

4. **Cleanup**: After installation, the script cleans up any downloaded or extracted files.

## Example

```powershell
### Modify these Variables ###
$program = "7Zip"
$downloadPath = "https://www.7-zip.org/a/7z2408-x64.msi"
$nestedInstallerFolderAndFile = ""
$arguments = "/qn"
$fileToCheck = "C:\Program Files\7-Zip\7z.exe"
$skipFileCheck = $false # Set to $true to force update

### Run the script ###
```

This will install **7Zip** from the provided URL, verify the installation, and perform cleanup afterward. If the application is already installed and `$skipFileCheck` is set to `$false`, the script will skip the installation.

## Notes
- The script requires **PowerShell**.
- For ZIP files, you may specify a nested installer path inside the archive for automatic execution.
- Use the `$skipFileCheck` feature to force installation regardless of whether the application is already installed.

## Troubleshooting
- **Log Outputs**: The script provides verbose output for every step, including downloading, installation, and cleanup. This helps identify where issues occur.
- **Error Handling**: If the installation fails, the script will output the error message and exit.
