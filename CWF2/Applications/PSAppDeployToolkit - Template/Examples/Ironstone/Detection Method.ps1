$ErrorActionPreference = 'SilentlyContinue'
Get-Variable | Where-Object Name -Match 'DetectionDetails[0-9]' | Remove-Variable -Force

# Define the application details as hashtables
$DetectionDetails1 = @{
    DisplayName = "Lenovo Vantage Service"
    DesiredVersion = "4.0.52.0"
    Type = "EXE" # Use EXE also for MSI
}

$DetectionDetails2 = @{
    DisplayName = "*E046963F.LenovoSettingsforEnterprise*"
    DesiredVersion = "10.2401.29.0"
    Type = "AppX"
}

$DetectionDetails3 = @{
    RegistryPath = "HKLM:\SOFTWARE\WOW6432Node\Lenovo\SystemUpdateAddin\Logs"
    ValueName = "EnableLogs"
    ExpectedValue = "True"
    Type = "Registry"
}

function Test-EXEInstalled {
    param ([Hashtable]$DetectionDetails)
    $package = Get-Package -Name $DetectionDetails["DisplayName"] -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    if ($package) {
        $installedVersion = [version]$package.Version | Sort-Object | Select-Object -First 1 # Some products might be both MSI and EXE with multiple versions. Example: Vstor_2010
        $desiredVersion = [version]$DetectionDetails["DesiredVersion"]
        return $installedVersion -ge $desiredVersion
    }
}

function Test-AppXInstalled {
    param ([Hashtable]$DetectionDetails)
    $isSystemContext = $env:USERNAME -like "$env:COMPUTERNAME*"
    if ($isSystemContext -eq $true) {
        $package = Get-AppxPackage -AllUsers $DetectionDetails["DisplayName"]
    } else {
        $package = Get-AppxPackage $DetectionDetails["DisplayName"]
    }
    if ($package) {
        $installedVersion = [version]$package.Version
        $desiredVersion = [version]$DetectionDetails["DesiredVersion"]
        return $installedVersion -ge $desiredVersion
    }
}

function Test-RegistryKey {
    param (
        [Hashtable]$DetectionDetails
    )

    try {
        $key = Get-ItemProperty -Path $DetectionDetails["RegistryPath"] -ErrorAction SilentlyContinue
        if ($key) {
            $installedValue = $key.$DetectionDetails["ValueName"]
            if ([version]::TryParse($installedValue, [ref]$null) -and [version]::TryParse($DetectionDetails["ExpectedValue"], [ref]$null)) {
                return [version]$installedValue -ge [version]$DetectionDetails["ExpectedValue"]
            } elseif ([int]::TryParse($installedValue, [ref]$null) -and [int]::TryParse($DetectionDetails["ExpectedValue"], [ref]$null)) {
                return [int]$installedValue -ge [int]$DetectionDetails["ExpectedValue"]
            } else {
                return $installedValue -eq $DetectionDetails["ExpectedValue"]
            }
        } else {
            return $false
        }
    } catch {
        return $false
    }
}
function Test-AppsInstalled {
    # Find all $DetectionDetails variables
    $DetectionDetailsVariables = Get-Variable | Where-Object { $_.Name -match 'DetectionDetails[0-9]' }
    $result = $true
    # Iterate over each $DetectionDetails variable
    foreach ($appVar in $DetectionDetailsVariables) {
        $DetectionDetails = $appVar.Value
        if ($DetectionDetails["Type"] -eq "EXE") {
            $result = $result -and (Test-EXEInstalled -DetectionDetails $DetectionDetails)
        } elseif ($DetectionDetails["Type"] -eq "AppX") {
            $result = $result -and (Test-AppXInstalled -DetectionDetails $DetectionDetails)
        } elseif ($DetectionDetails["Type"] -eq "Registry") {
            $result = $result -and (Test-RegistryKey -DetectionDetails $DetectionDetails)
        }
    }

    # Return the final result
    return $result
}

# Invoke the function to Test all applications
if (Test-AppsInstalled) { return $true }
