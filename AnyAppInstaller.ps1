### Modify these Variables ###
### Program Name ###
$program = ""
### URL, UNC, or Local Path to EXE, MSI, MSIX, or ZIP ###
$downloadPath = ""
#### If ZIP, Must Specify Name of Sub-Folder\File After Extraction (Primary folder not required) ###
$nestedInstallerFolderAndFile = ""
#### Specify Arguments ###
$arguments = ""
#### Specify File to Check if Installed ###
$fileToCheck = ""
#### Allow Update (True to allow update. False to prevent it.) ###
$allowUpdate = $false
#### Prevent Cleanup on Failure (True to skip cleanup if installation fails) ###
$preventCleanupOnFailure = $false

### Static Variables ###
$global:installer = ""
$global:extension = ""
$global:fileNamePrefix = ""
$global:extractedPath = ""

# Check for SharePoint URL and append "download=1" if necessary
if ($downloadPath -match "sharepoint") { 
    Write-Output "SharePoint URL detected, appending download=1."
    $downloadPath = "$downloadPath&download=1"
}

# Get the file name from URL
if ($downloadPath -match "^https?://") {
    Write-Output "Checking for file name in URL."

    # For SharePoint URLs, always use HTTP Head request to get the file name
    if ($downloadPath -match "sharepoint") {
        Write-Output "Fetching file name from SharePoint URL."
        $head = Invoke-WebRequest -UseBasicParsing -Method Head $downloadPath

        # Try to get the file name from the Content-Disposition header
        $contentDisposition = $head.Headers["Content-Disposition"]
        if ($contentDisposition -and $contentDisposition -match 'filename="(.+)"') {
            $downloadFileName = $matches[1]
            Write-Output "File name extracted from Content-Disposition header: $downloadFileName"
        } else {
            # Fallback: extract from URL segments
            $downloadFileName = $head.BaseResponse.ResponseUri.Segments[-1]
            Write-Output "File name extracted from URL: $downloadFileName"
        }
    }
    else {
        # For non-SharePoint URLs, extract the file name directly from the URL
        if ($downloadPath -match "^https?://.*\/([^\/?]+)(\?.*)?$") {
            $downloadFileName = $matches[1]
            Write-Output "File name found directly in URL: $downloadFileName"
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
    Write-Output "Preparing installer path for: $path"
    if ($path -match "^https?://") {
        Write-Output "URL detected."
        # Check if the installer already exists in Temp folder
        if (!(Test-Path $global:installer)) {
            Write-Output "Installer not found in Temp. Downloading from URL: $path"
            Invoke-WebRequest -Uri $path -OutFile $global:installer
            Write-Output "Downloaded file to: $global:installer"
        } else {
            Write-Output "Installer already exists in Temp: $global:installer. Skipping download."
        }
    } elseif ($path -match "^\\\\") {
        Write-Output "UNC path detected."
        # Check if the installer already exists in Temp folder
        if (!(Test-Path $global:installer)) {
            Write-Output "Installer not found in Temp. Copying from UNC path."
            Copy-Item -Path $path -Destination $global:installer
        } else {
            Write-Output "Installer already exists in Temp: $global:installer. Skipping copy."
        }
    } elseif (Test-Path $path) {
        Write-Output "Local path detected."
        $global:installer = $path
        Write-Output "Installer path set to: $global:installer"
    } else {
        throw "Invalid path: $path"
    }
}

### Install Application ###
if ($allowUpdate -or !(Test-Path $fileToCheck)) { # Check if application is installed or skip check
    if ($allowUpdate) {
        Write-Output "Skipping file check and forcing update."
    } else {
        Write-Output "$program is not installed. Preparing to download and install."
    }

    # Prepare installer based on path type
    PrepareInstallerPath $downloadPath

    # Ensure installer is set properly
    if (-not $global:installer) {
        throw "Installer path is not set. Please check the path provided."
    }

    try {
        Write-Output "Starting installation process for: $global:installer with arguments: $arguments"
        if ($global:extension -eq ".exe") {
            Write-Output "Running installer as EXE: $global:installer"
            $process = Start-Process -FilePath $global:installer -ArgumentList $arguments -Verb RunAs -Wait -PassThru
        } elseif ($global:extension -eq ".msi") {
            Write-Output "Running installer as MSI: $global:installer"
            $process = Start-Process msiexec.exe -ArgumentList "/I `"$global:installer`" $arguments" -Verb RunAs -Wait -PassThru
        } elseif ($global:extension -eq ".msix") {
            Write-Output "Running installer as MSIX: $global:installer"
            Add-AppPackage -Path $global:installer # Install MSIX
        } elseif ($global:extension -eq ".zip") {
            Write-Output "Extracting ZIP: $global:installer"
            Expand-Archive -LiteralPath $global:installer -DestinationPath $global:extractedPath -Force # Extract ZIP
            if (Test-Path $global:extractedPath) {
                if ($nestedInstallerFolderAndFile) {
                    $nestedInstaller = "$global:extractedPath\$nestedInstallerFolderAndFile"
                    if ($nestedExtension -eq ".exe") {
                        Write-Output "Running nested installer as EXE: $nestedInstaller"
                        Start-Process -FilePath $nestedInstaller -ArgumentList $arguments -Verb RunAs -Wait
                    } elseif ($nestedExtension -eq ".msi") {
                        Write-Output "Running nested installer as MSI: $nestedInstaller"
                        Start-Process msiexec.exe -ArgumentList "/I `"$nestedInstaller`" $arguments" -Verb RunAs -Wait
                    } elseif ($nestedExtension -eq ".msix") {
                        Write-Output "Running nested installer as MSIX: $nestedInstaller"
                        Add-AppPackage -Path $nestedInstaller
                    }
                }
            }
        }

        # Check exit code and decide success/failure based on that
        if (($process.ExitCode -eq 0) -and (Test-Path $fileToCheck)) {
            Write-Output "Successful installation."
            if (-not ($downloadPath -match "^[a-zA-Z]:\\")) {
                Cleanup $global:installer $global:extractedPath  # Cleanup only if not local path
            }
            exit 0
        } else {
            Write-Output "Installation failed: Process Exit Code: $($process.ExitCode)"
            if (-not $preventCleanupOnFailure -and -not ($downloadPath -match "^[a-zA-Z]:\\")) {
                Cleanup $global:installer $global:extractedPath  # Cleanup only if not local path
            } else {
                Write-Output "Cleanup skipped due to failure or local path."
            }
            exit 1
        }
    } catch {
        Write-Output "Installation failed with error: $_"
        if (-not $preventCleanupOnFailure -and -not ($downloadPath -match "^[a-zA-Z]:\\")) {
            Cleanup $global:installer $global:extractedPath  # Cleanup only if not local path
        } else {
            Write-Output "Cleanup skipped due to failure or local path."
        }
        exit 1
    }
} else {
    Write-Output "$program already installed. Skipping download and installation."
    exit 0
}

function Cleanup($installer, $extractedPath) {
    if ($downloadPath -match "^https?://" -or $downloadPath -match "^\\\\") {
        Write-Output "Starting Cleanup."
        Start-Sleep -Seconds 5
        if ($installer) {
            Remove-Item -Path $installer -Force
        }
        if (Test-Path $extractedPath) {
            Remove-Item -Path $extractedPath -Recurse -Force
        }
        Write-Output "Finished Cleanup."
    } else {
        Write-Output "No cleanup needed for local paths."
    }
}
