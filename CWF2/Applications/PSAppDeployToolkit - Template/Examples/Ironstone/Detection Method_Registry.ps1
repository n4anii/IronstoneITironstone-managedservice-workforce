$ErrorActionPreference = 'SilentlyContinue'
# Define the application details as a hashtable
# HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall | HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall
$appDetails = @{
    Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{7AE19E56-871A-4DC2-A2D3-02044C770947}"
    DesiredVersion = "24.5.3.0"
    DisplayName = "draw.io"
}

# Function to check the installed version against the desired version
function Compare-AppVersion {
    param (
        [Hashtable]$AppDetails
    )

    # Check if the application's uninstall key exists in the registry
    if (Test-Path $AppDetails["Path"]) {
        # Get the display version of the installed application
        $installedVersionString = (Get-ItemProperty $AppDetails["Path"] -ErrorAction SilentlyContinue).DisplayVersion

        # If the application is installed, check the version
        if ($installedVersionString) {
            # Convert the installed version string to a Version object
            $installedVersion = [version]$installedVersionString
            $desiredVersion = [version]$AppDetails["DesiredVersion"]

            # Compare the installed version with the desired version
            if ($desiredVersion -ge $installedVersion) {
                Write-Output $true
            }
        }
    }
}

Compare-AppVersion -AppDetails $appDetails