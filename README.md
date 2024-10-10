# AnyAppInstaller

**AnyAppInstaller** is a versatile PowerShell script designed to download, install, and manage the cleanup of software installers. It supports downloading from a URL, UNC path, or using a local path for EXE, MSI, MSIX, and ZIP files. The script handles silent installations and verifies the software installation afterward. Additionally, it can extract ZIP files and handle nested installers within them.

## Features

- **File Name Extraction**: Automatically extracts the file name from URLs, including support for **SharePoint** links using the `Content-Disposition` header. This ensures correct file downloads even with query strings or complex links.
- **Prevent Cleanup on Failure**: Option to skip cleanup of downloaded or extracted files if the installation fails, making it easier to retry with different arguments without re-downloading.
- **SharePoint URL Support**: Automatically detects **SharePoint URLs** and appends `"download=1"` to ensure correct handling of shared links for direct downloads.
- Supports **EXE**, **MSI**, **MSIX**, and **ZIP** files.
- Downloads installers from **URLs**, **UNC paths**, or uses **local paths**.
- **Allow Update**: Forces an update by skipping the file check, even if the application is already installed.
- Verifies if the application is installed before downloading, saving bandwidth (unless forced to update).
- Silent installation with customizable arguments.
- Automatic cleanup of downloaded or extracted files, with the option to skip cleanup on failure.
- Logs key actions for transparency and troubleshooting.

## Usage
### Modify the following variables:

1. **Program Name**: The name of the application you are installing.
    ```powershell
    $program = "7Zip"
    ```

2. **Installer Path (URL, UNC, or Local)**: Specify the path to the installer, which can be a URL, UNC path, or a local file path.
    ```powershell
    $downloadPath = "https://www.7-zip.org/a/7z2408-x64.exe"
    ```

3. **Installation Arguments**: Define any arguments to run the installer silently or with specific options.
    ```powershell
    $arguments = "/S"
    ```

4. **File to Check if Installed**: Path to a file that verifies if the software is already installed. If the file exists, the installation will be skipped (unless `$allowUpdate` is set to `$true`).
    ```powershell
    $fileToCheck = "C:\Program Files\7-Zip\7z.exe"
    ```

5. **Allow Update**: Set this variable to `$true` to force the installer to run even if the software is already installed. Set it to `$false` to skip the installation if the software is already present.
    ```powershell
    $allowUpdate = $false
    ```

6. **Prevent Cleanup on Failure**: Set this variable to `$true` to skip the cleanup of downloaded/extracted files if the installation fails, making it easier to retry the installation without downloading the installer again.
    ```powershell
    $preventCleanupOnFailure = $false
    ```

## How It Works

1. **Check for Installation**: The script first checks if the application is already installed by looking for the specified `$fileToCheck`. If found, it skips the download and installation steps unless `$allowUpdate` is set to `$true`.

2. **Download Installer**: If the application is not installed or if the `$allowUpdate` variable is set to `$true`, it downloads the installer from the provided `$downloadPath` if it's a URL or UNC path.

3. **File Name Handling**:
   - For **regular URLs**, the file name is extracted directly from the URL.
   - For **SharePoint URLs**, the script detects the `Content-Disposition` header to retrieve the file name or appends `"download=1"` to ensure direct downloads.

4. **Install Application**:
    - If the installer is an **EXE**, **MSI**, or **MSIX**, the script runs the installer with the provided arguments.
    - If the installer is a **ZIP** file, the script extracts it and runs any nested installer if specified.

5. **Cleanup**: After installation, the script cleans up any downloaded or extracted files unless the `$preventCleanupOnFailure` is set to `$true` and the installation failed.

## Example

```powershell
### Modify these Variables ###
$program = "7Zip"
$downloadPath = "https://www.7-zip.org/a/7z2408-x64.exe"
$arguments = "/S"
$fileToCheck = "C:\Program Files\7-Zip\7z.exe"
$allowUpdate = $false
$preventCleanupOnFailure = $false

### Run the script ###
```

This will install **7Zip** from the provided URL, verify the installation, and perform cleanup afterward. If the application is already installed and `$allowUpdate` is set to `$false`, the script will skip the installation.

## Notes
- The script requires **PowerShell**.
- For ZIP files, you may specify a nested installer path inside the archive for automatic execution.
- Use the `$allowUpdate` feature to force installation regardless of whether the application is already installed.
- If the installer fails and `$preventCleanupOnFailure` is `$true`, the downloaded files won't be deleted to allow easier retries.

## Troubleshooting
- **Log Outputs**: The script provides verbose output for every step, including downloading, installation, and cleanup. This helps identify where issues occur.
- **Error Handling**: If the installation fails, the script will output the error message and exit. The cleanup process can be skipped based on the `$preventCleanupOnFailure` setting.
