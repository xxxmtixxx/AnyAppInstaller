### Modify these Variables ###
#### Specify Chocolately Application to Install ###
$ChocolatelyApp = ""
$ChocolatelyAppInstall = ""
#### Specify File to Check if Installed ###
$FileToCheck = ""

# Set error preferences
$ErrorActionPreference = 'SilentlyContinue'

# Check if application is installed by file path
if (-not (Test-Path $FileToCheck)) {
    # Check if application is installed by Chocolatey
    $installedPackages = choco list | Select-String -Pattern "^$ChocolatelyApp"
    if ($installedPackages -eq $null) {
        # Check if Chocolatey is installed
        if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
            # Install Chocolatey
            Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')) > $null
            Write-Host "Chocolatey has been installed."
        } else {
            Write-Host "Chocolatey is already installed!"
        }

        # Refresh environment variables in the current session
        $env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')

        # Install application
        choco install $ChocolatelyApp --force -y > $null

        # Check if application is installed
        $installedPackages = choco list | Select-String -Pattern "^$ChocolatelyApp"
        if ($installedPackages -ne $null) {
            # Exit with success code
            Write-Output "Successful installation."
            exit 0
        } else {
            # Exit with error code
            Write-Output "Installation failed."
            exit 1
        }  
    } else {
        # Uninstall the package
        choco uninstall $ChocolatelyApp --force -y > $null
        choco uninstall $ChocolatelyAppInstall --force -y > $null
        Write-Output "$ChocolatelyApp has been uninstalled."

        # Install the package
        choco install $ChocolatelyApp --force -y > $null

        # Check if application is installed
        $installedPackages = choco list | Select-String -Pattern "^$ChocolatelyApp"
        if ($installedPackages -ne $null) {
            # Exit with success code
            Write-Output "Successful installation."
            exit 0
        } else {
            # Exit with error code
            Write-Output "Installation failed."
            exit 1
        }
    }
} else {
    # Exit with success code (since this is expected behavior)
    Write-Output "$ChocolatelyApp is already installed. Skipping installation."
    exit 0
}
