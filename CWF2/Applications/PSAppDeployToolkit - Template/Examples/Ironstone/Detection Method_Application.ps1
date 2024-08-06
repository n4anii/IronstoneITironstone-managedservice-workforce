$ErrorActionPreference = 'SilentlyContinue'
# Define the application details as a hashtable
$appDetails = @{
    DisplayName = "*7-Zip*"
    DesiredVersion = "24.07.0.0"
}

# Function to check if the application is installed with the desired version
function Check-AppInstalled {
    param (
        [Hashtable]$AppDetails
    )

    # Attempt to get the package by display name
    $package = Get-Package -Name $AppDetails["DisplayName"] -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

    # If the package is found, check the version
    if ($package) {
        # Convert the installed version string to a Version object
        $installedVersion = [version]$package.Version
        $desiredVersion = [version]$AppDetails["DesiredVersion"]

        # Compare the installed version with the desired version
        if ($desiredVersion -ge $installedVersion) {
            Write-Output $true
        }
    }
}

# Invoke the function with the application details
Check-AppInstalled -AppDetails $appDetails