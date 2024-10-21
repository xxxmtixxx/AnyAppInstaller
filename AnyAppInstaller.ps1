### Modify these Variables ###
### Program Name ###
$program = ''
### URL, UNC, or Local Path to EXE, MSI, MSIX, or ZIP ###
$downloadPath = ''
### If ZIP, Must Specify Name of Sub-Folder\File After Extraction (Primary folder not required) ###
$nestedInstallerFolderAndFile = ''
### Specify Arguments ###
$arguments = ''
### Specify File to Check if Installed ###
$fileToCheck = ''
### Allow Reboot (True to allow reboot. False to prevent it.) ###
$allowReboot = $false
### Allow Update (True to allow update. False to prevent it.) ###
$allowUpdate = $false
### Prevent Cleanup on Failure (True to skip cleanup if installation fails) ###
$preventCleanupOnFailure = $false
### Allow Log Appending (True to allow appending. False to write a new log file.) ###
$allowLogAppend = $false
### Optional Pre-Installation Task ###
### Specify Pre-Install Sub-Folder\File ###
$preInstallFile = ''
### Specify Pre-Install Arguments ###
$preInstallArguments = ''
### Optional Post-Installation Task ###
### Specify Post-Install Sub-Folder\File ###
$postInstallFile = ''
### Specify Post-Install Arguments ###
$postInstallArguments = ''

### Static Variables ###
$global:installer = ""
$global:extension = ""
$global:fileNamePrefix = ""
$global:extractedPath = ""
$logFile = "C:\Temp\${program}_install.log"

# Ensure Temp folder exists
$tempFolder = "C:\Temp"
if (!(Test-Path -Path $tempFolder)) {
    New-Item -ItemType Directory -Force -Path $tempFolder
    Write-Output "Created Temp folder: $tempFolder"
}

# Initialize or clear log file based on $allowLogAppend
if (!$allowLogAppend -and (Test-Path $logFile)) {
    Clear-Content $logFile
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - Log file cleared. Starting new log." | Out-File -FilePath $logFile
}

# Function to write log messages and output to console
function Write-Log {
    param (
        [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $logFile -Append
    Write-Output "$timestamp - $Message"
}

# Log the start of the script and the $allowLogAppend setting
Write-Log "Script started. Log append setting: $(if ($allowLogAppend) { 'Enabled' } else { 'Disabled' })"

# Function for faster ZIP extraction
function Expand-ArchiveFast {
    param (
        [string]$Path,
        [string]$DestinationPath
    )
    
    Write-Log "Starting fast extraction of $Path to $DestinationPath"
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    try {
        $archive = [System.IO.Compression.ZipFile]::OpenRead($Path)
        foreach ($entry in $archive.Entries) {
            $entryTargetPath = [System.IO.Path]::Combine($DestinationPath, $entry.FullName)
            $entryDir = [System.IO.Path]::GetDirectoryName($entryTargetPath)

            # Ensure the directory exists
            if (!(Test-Path $entryDir)) {
                New-Item -ItemType Directory -Path $entryDir -Force | Out-Null
            }

            # Extract and overwrite if the file exists
            if (!$entry.FullName.EndsWith('/')) {
                [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $entryTargetPath, $true)
            }
        }
        $archive.Dispose()
        Write-Log "Fast extraction completed successfully"
    }
    catch {
        Write-Log "Error during fast extraction: $_"
        throw
    }
}

# Check for SharePoint URL and append "download=1" if necessary
if ($downloadPath -match "sharepoint") { 
    Write-Log "SharePoint URL detected, appending download=1."
    $downloadPath = "$downloadPath&download=1"
}

# Check for Dropbox URL and change "dl=0" to "dl=1" if present
if ($downloadPath -match "dropbox.com") {
    Write-Log "Dropbox URL detected, changing dl=0 to dl=1 if present."
    $downloadPath = $downloadPath -replace "dl=0", "dl=1"
}

# Get the file name from URL
if ($downloadPath -match "^https?://") {
    Write-Log "Checking for file name in URL."

    # For SharePoint URLs, always use HTTP Head request to get the file name
    if ($downloadPath -match "sharepoint") {
        Write-Log "Fetching file name from SharePoint URL."
        $head = Invoke-WebRequest -UseBasicParsing -Method Head $downloadPath

        # Try to get the file name from the Content-Disposition header
        $contentDisposition = $head.Headers["Content-Disposition"]
        if ($contentDisposition -and $contentDisposition -match 'filename="(.+)"') {
            $downloadFileName = $matches[1]
            Write-Log "File name extracted from Content-Disposition header: $downloadFileName"
        } else {
            # Fallback: extract from URL segments
            $downloadFileName = $head.BaseResponse.ResponseUri.Segments[-1]
            Write-Log "File name extracted from URL: $downloadFileName"
        }
    }
    else {
        # For non-SharePoint URLs, extract the file name directly from the URL
        if ($downloadPath -match "^https?://.*\/([^\/?]+)(\?.*)?$") {
            $downloadFileName = $matches[1]
            Write-Log "File name found directly in URL: $downloadFileName"
        } else {
            throw "Unable to extract the file name from the provided URL."
        }
    }
}

$global:installer = "C:\Temp\$downloadFileName"
$global:extension = [IO.Path]::GetExtension($downloadFileName)
$global:fileNamePrefix = [IO.Path]::GetFileNameWithoutExtension($downloadFileName)
$global:extractedPath = "C:\Temp\$fileNamePrefix"

# Function to check path type and prepare installer accordingly
function PrepareInstallerPath($path) {
    Write-Log "Preparing installer path for: $path"
    if ($path -match "^https?://") {
        Write-Log "URL detected."
        # Check if the installer already exists in Temp folder
        if (!(Test-Path $global:installer)) {
            Write-Log "Installer not found in Temp. Downloading from URL: $path"
            # Disable progress bar to speed up download
            $ProgressPreference = 'SilentlyContinue'
            Invoke-WebRequest -Uri $path -OutFile $global:installer
            Write-Log "Downloaded file to: $global:installer"
        } else {
            Write-Log "Installer already exists in Temp: $global:installer. Skipping download."
        }
    } elseif ($path -match "^\\\\") {
        Write-Log "UNC path detected."
        # Check if the installer already exists in Temp folder
        if (!(Test-Path $global:installer)) {
            Write-Log "Installer not found in Temp. Copying from UNC path."
            Copy-Item -Path $path -Destination $global:installer
        } else {
            Write-Log "Installer already exists in Temp: $global:installer. Skipping copy."
        }
    } elseif (Test-Path $path) {
        Write-Log "Local path detected."
        $global:installer = $path
        Write-Log "Installer path set to: $global:installer"
    } else {
        throw "Invalid path: $path"
    }
}

function Cleanup($installer, $extractedPath) {
    if ($downloadPath -match "^https?://" -or $downloadPath -match "^\\\\") {
        Write-Log "Starting Cleanup."
        Start-Sleep -Seconds 5
        if ($installer) {
            Remove-Item -Path $installer -Force
        }
        if (Test-Path $extractedPath) {
            Remove-Item -Path $extractedPath -Recurse -Force
        }
        Write-Log "Finished Cleanup."
    } else {
        Write-Log "No cleanup needed for local paths."
    }
}

### Install Application ###
if ($allowUpdate -or !(Test-Path $fileToCheck)) { # Check if application is installed or skip check
    if ($allowUpdate) {
        Write-Log "Skipping file check and forcing update."
    } else {
        Write-Log "$program is not installed. Preparing to download and install."
    }

    # Prepare installer based on path type
    PrepareInstallerPath $downloadPath

    # Ensure installer is set properly
    if (-not $global:installer) {
        throw "Installer path is not set. Please check the path provided."
    }

    try {
        Write-Log "Starting installation process for: $global:installer"
        if ($global:extension -eq ".exe") {
            Write-Log "Running installer as EXE: $global:installer with arguments: $arguments"
            $process = Start-Process -FilePath $global:installer -ArgumentList $arguments -Verb RunAs -Wait -PassThru
        } elseif ($global:extension -eq ".msi") {
            Write-Log "Running installer as MSI: $global:installer with arguments: $arguments"
            $process = Start-Process msiexec.exe -ArgumentList "/I `"$global:installer`" $arguments" -Verb RunAs -Wait -PassThru
        } elseif ($global:extension -eq ".msix") {
            Write-Log "Running installer as MSIX: $global:installer"
            Add-AppPackage -Path $global:installer # Install MSIX
        } elseif ($global:extension -eq ".zip") {
            Write-Log "Extracting ZIP: $global:installer"
            try {
                Expand-ArchiveFast -Path $global:installer -DestinationPath $global:extractedPath
            }
            catch {
                Write-Log "Fast extraction failed, falling back to Expand-Archive"
                Expand-Archive -LiteralPath $global:installer -DestinationPath $global:extractedPath -Force
            }
            if (Test-Path $global:extractedPath) {
                # Pre-install task
                if ($preInstallFile -and (Test-Path "$global:extractedPath\$preInstallFile")) {
                    Write-Log "Running pre-installation task: $preInstallFile"
                    $preExtension = [IO.Path]::GetExtension($preInstallFile)
                    if ($preExtension -eq ".exe") {
                        Start-Process -FilePath "$global:extractedPath\$preInstallFile" -ArgumentList $preInstallArguments -Verb RunAs -Wait
                    } elseif ($preExtension -eq ".msi") {
                        Start-Process msiexec.exe -ArgumentList "/I ""$global:extractedPath\$preInstallFile"" $preInstallArguments" -Verb RunAs -Wait
                    } elseif ($preExtension -eq ".msix") {
                        Add-AppPackage -Path "$global:extractedPath\$preInstallFile"
                    }
                }

                # Main installation
                if ($nestedInstallerFolderAndFile) {
                    $nestedInstaller = "$global:extractedPath\$nestedInstallerFolderAndFile"
                    $nestedExtension = [IO.Path]::GetExtension($nestedInstallerFolderAndFile)
                    
                    try {
                        switch ($nestedExtension) {
                            ".exe" {
                                Write-Log "Running nested installer as EXE: $nestedInstaller with arguments: $arguments"
                                $process = Start-Process -FilePath $nestedInstaller -ArgumentList $arguments -Verb RunAs -Wait -PassThru -ErrorAction Stop
                            }
                            ".msi" {
                                Write-Log "Running nested installer as MSI: $nestedInstaller with arguments: $arguments"
                                $process = Start-Process msiexec.exe -ArgumentList "/I `"$nestedInstaller`" $arguments" -Verb RunAs -Wait -PassThru -ErrorAction Stop
                            }
                            ".msix" {
                                Write-Log "Running nested installer as MSIX: $nestedInstaller"
                                Add-AppPackage -Path $nestedInstaller -ErrorAction Stop
                                $process = $null  # MSIX doesn't return a process object
                            }
                            default {
                                throw "Unsupported file extension: $nestedExtension"
                            }
                        }

                        if ($process) {
                            if ($process.ExitCode -eq 0) {
                                Write-Log "Installer completed successfully with exit code: $($process.ExitCode)"
                            } else {
                                Write-Log "Installer failed with exit code: $($process.ExitCode)"
                                throw "Installation failed with exit code $($process.ExitCode)"
                            }
                        } else {
                            Write-Log "Installation process completed (no exit code available)"
                        }
                    } catch {
                        Write-Log "An error occurred during installation: $_"
                        throw
                    } finally {
                        Write-Log "Installation process finished"
                    }
                } else {
                    Write-Log "No nested installer specified. Skipping nested installation."
                }

                # Post-install task
                if ($postInstallFile -and (Test-Path "$global:extractedPath\$postInstallFile")) {
                    Write-Log "Running post-installation task: $postInstallFile"
                    $postExtension = [IO.Path]::GetExtension($postInstallFile)
                    if ($postExtension -eq ".exe") {
                        Start-Process -FilePath "$global:extractedPath\$postInstallFile" -ArgumentList $postInstallArguments -Verb RunAs -Wait
                    } elseif ($postExtension -eq ".msi") {
                        Start-Process msiexec.exe -ArgumentList "/I ""$global:extractedPath\$postInstallFile"" $postInstallArguments" -Verb RunAs -Wait
                    } elseif ($postExtension -eq ".msix") {
                        Add-AppPackage -Path "$global:extractedPath\$postInstallFile"
                    }
                }
            }
        }

        # Check exit code and decide success/failure based on that
        if (($process.ExitCode -eq 0) -and (Test-Path $fileToCheck)) {
            Write-Log "Successful installation."
            if (-not ($downloadPath -match "^[a-zA-Z]:\\")) {
                Cleanup $global:installer $global:extractedPath  # Cleanup only if not local path
            }
            if ($allowReboot) {
                Write-Log "Reboot is allowed. Initiating system reboot..."
                Restart-Computer -Force
            } else {
                Write-Log "Reboot is not allowed. Installation completed without reboot."
                exit 0
            }
        } else {
            Write-Log "Installation failed: Process Exit Code: $($process.ExitCode)"
            if ($preventCleanupOnFailure) {
                Write-Log "Cleanup prevented due to installation failure and preventCleanupOnFailure setting."
            } else {
                Write-Log "Performing cleanup after installation failure."
                if (-not ($downloadPath -match "^[a-zA-Z]:\\")) {
                    Cleanup $global:installer $global:extractedPath  # Cleanup only if not local path
                }
            }
            exit 1
        }
    } catch {
        Write-Log "Installation failed with error: $_"
        if ($preventCleanupOnFailure) {
            Write-Log "Cleanup prevented due to installation failure and preventCleanupOnFailure setting."
        } else {
            Write-Log "Performing cleanup after installation failure."
            if (-not ($downloadPath -match "^[a-zA-Z]:\\")) {
                Cleanup $global:installer $global:extractedPath  # Cleanup only if not local path
            }
        }
        exit 1
    }
} else {
    Write-Log "$program already installed. Skipping download and installation."
    exit 0
}
