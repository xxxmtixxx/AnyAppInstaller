### Modify these Variables ###
### Program Name ###
$program = ""
### URL to EXE, MSI, MSIX, or ZIP ###
$urlPath = ""
#### If ZIP, Must Specify Name of Sub-Folder\File After Extraction (Primary folder not required) ###
$nestedInstallerFolderAndFile = ""
#### Specify Arguments ###
$arguments = ""
#### Specify File to Check if Installed ###
$fileToCheck = ""

### Static Variables ###
if ($urlPath -match "sharepoint") { # Check if URL contains "sharepoint" and append "download=1" if true
    $urlPath = "$urlPath&download=1"
}
$head = Invoke-WebRequest -UseBasicParsing -Method Head $urlPath # Gets URL Header Info
$downloadFileName = $head.BaseResponse.ResponseUri.Segments[-1] # Extracts File Name from Header
$downloadPath = "C:\Temp" # Local Temp Folder
$installer = "$downloadPath\$downloadFileName" # Local Installer Path
$extension = [IO.Path]::GetExtension($downloadFileName) # Get File Extension
$fileNamePrefix = [IO.Path]::GetFileNameWithoutExtension($downloadFileName) # Get File Name without Extension
$extractedPath = "$downloadPath\$fileNamePrefix" # Extracted ZIP Path
$nestedExtension = [IO.Path]::GetExtension($nestedInstallerFolderAndFile) # Get Nested File Extension
$nestedInstaller = "$extractedPath\$nestedInstallerFolderAndFile" # Get Nested File Name without Extension

function Cleanup($installer, $extractedPath) {
    Write-Output "Starting Cleanup."
    Start-Sleep -Seconds 5 # Give Time for Installer to Close
    Remove-Item -Path $installer -Force # Delete Installer
    if (Test-Path $extractedPath) { # Check for Extracted Folder
        Remove-Item -Path $extractedPath -Recurse -Force # Delete Extracted Folder
    }
        Write-Output "Finished Cleanup."
}

### Create Local Temp Folder ###
if (!(Test-Path $downloadPath)) { # Check for Temp Folder
[void](New-Item -ItemType Directory -Force -Path $downloadPath) # Create Temp Folder
Write-Output "Temp folder created."
}

### Install Application ###
if (!(Test-Path $fileToCheck)) { # Check if application is installed
    ### Download from Web if the installer does not exist locally ###
    if (!(Test-Path $installer)) { # Check if the installer file exists
        Write-Output "Downloading installer."
        $ProgressPreference = 'SilentlyContinue' # Disable Download Status Bar
        Invoke-WebRequest -Uri $urlPath -OutFile $installer # Download File from Web
    }
    try {
        if ($extension -eq ".exe") { # Check if EXE
            Write-Output "Running installer as EXE."
            Start-Process -FilePath $installer -ArgumentList $arguments -Verb RunAs -Wait # Install EXE
        } elseif ($extension -eq ".msi") { # Check if MSI
            Write-Output "Running installer as MSI."
            Start-Process msiexec.exe -ArgumentList "/I ""$installer"" $arguments" -Verb RunAs -Wait # Install MSI
        } elseif ($extension -eq ".msix") { # Check if MSIX
            Write-Output "Running installer as MSIX."
            Add-AppPackage -Path $installer # Install MSIX
        } elseif ($extension -eq ".zip") { # Check if ZIP
            Write-Output "Extracting ZIP."
            Expand-Archive -LiteralPath $installer -DestinationPath $extractedPath -Force # Extract ZIP
            if (Test-Path $extractedPath) { # Check for Extracted Folder
                if ($nestedExtension -eq ".exe") { # Check if EXE
                    Write-Output "Running installer as EXE."
                    Start-Process -FilePath $nestedInstaller -ArgumentList $arguments -Verb RunAs -Wait # Install EXE
                } elseif ($nestedExtension -eq ".msi") { # Check if MSI
                    Write-Output "Running installer as MSI."
                    Start-Process msiexec.exe -ArgumentList "/I ""$nestedInstaller"" $arguments" -Verb RunAs -Wait # Install MSI
                } elseif ($nestedExtension -eq ".msix") { # Check if MSIX
                    Write-Output "Running installer as MSIX."
                    Add-AppPackage -Path $nestedInstaller # Install MSIX
                }
            }
        }
        # Check if application is installed
        if (Test-Path $fileToCheck) {
            # Exit with success code
            Write-Output "Successful installation."
            Cleanup $installer $extractedPath
            exit 0
        } else {
            # Exit with error code
            Write-Output "Installation failed."
            Cleanup $installer $extractedPath
            exit 1
        }
    } catch {
        # Exit with error code
        Write-Output "Installation failed."
        Cleanup $installer $extractedPath
        exit 1
    }
} else {
    # Exit with success code (since this is expected behavior)
    Write-Output "$program already installed. Skipping installation."
    exit 0
}
