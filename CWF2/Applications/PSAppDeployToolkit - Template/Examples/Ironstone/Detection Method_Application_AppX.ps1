﻿$ErrorActionPreference = 'SilentlyContinue'
Get-Variable | Where-Object Name -Match 'DetectionDetails[0-9]' | Remove-Variable -Force

# Define the application details as hashtables
$DetectionDetails1 = @{
    DisplayName = "Lenovo Vantage Service"
    DesiredVersion = "4.0.52.0"
    Type = "EXE"
}

$DetectionDetails2 = @{
    DisplayName = "*E046963F.LenovoSettingsforEnterprise*"
    DesiredVersion = "10.2401.29.0"
    Type = "AppX"
}

function Test-EXEInstalled {
        param ([Hashtable]$DetectionDetails)
        $package = Get-Package -Name $DetectionDetails["DisplayName"] -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        if ($package) {
            $installedVersion = [version]$package.Version
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
        }
    }

    # Return the final result
    return $result
}

# Invoke the function to Test all applications
if (Test-AppsInstalled) { return $true }