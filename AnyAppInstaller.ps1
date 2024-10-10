### Modify these Variables ###
### Program Name ###
$program = "7Zip"
### URL, UNC, or Local Path to EXE, MSI, MSIX, or ZIP ###
$downloadPath = "https://www.7-zip.org/a/7z2408-x64.exe"
#### If ZIP, Must Specify Name of Sub-Folder\File After Extraction (Primary folder not required) ###
$nestedInstallerFolderAndFile = ""
#### Specify Arguments ###
$arguments = "/S"
#### Specify File to Check if Installed ###
$fileToCheck = "C:\Program Files\7-Zip\7z.exe"
#### Skip File Check (True to force update. False to prevent it.) ###
$skipFileCheck = $false

### Static Variables ###
$global:installer = ""
$global:extension = ""
$global:fileNamePrefix = ""
$global:extractedPath = ""

# Function to check path type and prepare installer accordingly
function PrepareInstallerPath($path) {
    Write-Output "Preparing installer path for: $path"
    if ($path -match "^https?://") {
        Write-Output "URL detected."
        $downloadFileName = [System.IO.Path]::GetFileName($path)  # Get filename from the URL
        $global:installer = "C:\Temp\$downloadFileName"
        $global:extension = [IO.Path]::GetExtension($downloadFileName)
        $global:fileNamePrefix = [IO.Path]::GetFileNameWithoutExtension($downloadFileName)
        $global:extractedPath = "C:\Temp\$fileNamePrefix"
        
        if (!(Test-Path $global:installer)) {
            Write-Output "Downloading from URL: $path"
            Invoke-WebRequest -Uri $path -OutFile $global:installer
            Write-Output "Downloaded file to: $global:installer"
        }
    } elseif ($path -match "^\\\\") {
        Write-Output "UNC path detected."
        $downloadFileName = [IO.Path]::GetFileName($path)
        $global:installer = "C:\Temp\$downloadFileName"
        $global:extension = [IO.Path]::GetExtension($downloadFileName)
        $global:fileNamePrefix = [IO.Path]::GetFileNameWithoutExtension($downloadFileName)
        $global:extractedPath = "C:\Temp\$fileNamePrefix"
        
        if (!(Test-Path $global:installer)) {
            Write-Output "Copying installer from UNC path."
            Copy-Item -Path $path -Destination $global:installer
        }
    } elseif (Test-Path $path) {
        Write-Output "Local path detected."
        $global:installer = $path
        $global:extension = [IO.Path]::GetExtension($global:installer)
        $global:fileNamePrefix = [IO.Path]::GetFileNameWithoutExtension($global:installer)
        $global:extractedPath = "C:\Temp\$fileNamePrefix"
        Write-Output "Installer path set to: $global:installer"
    } else {
        throw "Invalid path: $path"
    }
}

### Install Application ###
if ($skipFileCheck -or !(Test-Path $fileToCheck)) { # Check if application is installed or skip check
    if ($skipFileCheck) {
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
            Write-Output "Process Exit Code: $($process.ExitCode)"
        } elseif ($global:extension -eq ".msi") {
            Write-Output "Running installer as MSI: $global:installer"
            $process = Start-Process msiexec.exe -ArgumentList "/I `"$global:installer`" $arguments" -Verb RunAs -Wait -PassThru
            Write-Output "Process Exit Code: $($process.ExitCode)"
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
        # Check if application is installed
        if (Test-Path $fileToCheck) {
            Write-Output "Successful installation."
            Cleanup $global:installer $global:extractedPath
            exit 0
        } else {
            Write-Output "Installation failed: File check failed."
            Cleanup $global:installer $global:extractedPath
            exit 1
        }
    } catch {
        Write-Output "Installation failed with error: $_"
        Cleanup $global:installer $global:extractedPath
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
