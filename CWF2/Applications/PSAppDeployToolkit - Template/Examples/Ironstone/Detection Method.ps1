$ErrorActionPreference = 'SilentlyContinue'
Get-Variable | Where-Object Name -Match 'DetectionDetails[0-9][A-Z]' | Remove-Variable -Force

# Define the application details as hashtables
# Delete the $DetectionDetails-variables that are not needed
# Group detection method by number. Example: 1A and 1B will be grouped together where both needs to be true. 
# Adding a new group such as 2A and 2B will result in OR logic. Either group 1AB or group 2AB needs to be true.

$DetectionDetails1A = @{
    DisplayName = "Lenovo Vantage Service"
    DesiredVersion = "4.0.52.0"
    Type = "Programs" # Type is either Programs or msi. Check with (Get-Package -Name "*Application Name*") and look at "ProviderName". "Application Name" as visible in appwiz.cpl
}

$DetectionDetails2A = @{
    DisplayName = "*E046963F.LenovoSettingsforEnterprise*"
    DesiredVersion = "10.2401.29.0"
    Type = "AppX" # (Get-AppxPackage -AllUsers "*Application Name*" | select name,version) (Only visible in "Installed Apps" and not in appwiz.cpl)
}

$DetectionDetails3A = @{
    RegistryPath = "HKLM:\SOFTWARE\WOW6432Node\Lenovo\SystemUpdateAddin\Logs"
    ValueName = "EnableLogs"
    ExpectedValue = "True"
    Type = "Registry"
}

$DetectionDetails4A = @{
    FilePath = "C:\Users\*\Desktop\short.rdp" # Wildcards are supported
    #DesiredVersion = "1.0.0.0" # Uncomment if you need to check for a specific version
    #DesiredDate = (Get-Date "2024-10-07T00:00:00Z").ToUniversalTime() # Uncomment if you need to check for a specific date
    Type = "File" #File or Folder
}

# Group detection details by their group number
$groupedDetectionDetails = @{}
Get-Variable | Where-Object { $_.Name -match 'DetectionDetails[0-9][A-Z]' } | ForEach-Object {
    $groupNumber = $_.Name -replace 'DetectionDetails([0-9])[A-Z]', '$1'
    if (-not $groupedDetectionDetails.ContainsKey($groupNumber)) {
        $groupedDetectionDetails[$groupNumber] = @()
    }
    $groupedDetectionDetails[$groupNumber] += Get-Variable -Name $_.Name -ValueOnly
}

function Test-EXEInstalled {
    param ([Hashtable]$DetectionDetails)
    $package = Get-Package -Name $DetectionDetails["DisplayName"] -ProviderName $DetectionDetails["Type"] -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    if ($package) {
        $installedVersion = $package | ForEach-Object { [version]$_.Version } | Sort-Object -Descending | Select-Object -First 1
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
        $key = Get-ItemProperty -Path $DetectionDetails["RegistryPath"] -ErrorAction Stop
        $installedValue = $key.$($DetectionDetails["ValueName"])
        
        if ([version]::TryParse($installedValue, [ref]$null) -and [version]::TryParse($DetectionDetails["ExpectedValue"], [ref]$null)) {
            return [version]$installedValue -ge [version]$DetectionDetails["ExpectedValue"]
        } elseif ([int]::TryParse($installedValue, [ref]$null) -and [int]::TryParse($DetectionDetails["ExpectedValue"], [ref]$null)) {
            return [int]$installedValue -ge [int]$DetectionDetails["ExpectedValue"]
        } else {
            return $installedValue -eq $DetectionDetails["ExpectedValue"]
        }
    } catch {
        return $false
    }
}
function Test-FileExists {
    param ([Hashtable]$DetectionDetails)
    $items = Get-ChildItem -Path $DetectionDetails["FilePath"] -ErrorAction SilentlyContinue
    if ($items) {
        foreach ($item in $items) {
            if ($DetectionDetails["Type"] -eq "Folder" -and $item.PSIsContainer) {
                return $true
            } elseif ($DetectionDetails["Type"] -eq "File" -and -not $item.PSIsContainer) {
                if ($DetectionDetails.ContainsKey("DesiredVersion")) {
                    $fileVersion = $item.VersionInfo.FileVersion
                    $desiredVersion = [version]$DetectionDetails["DesiredVersion"]
                    if ($fileVersion -ge $desiredVersion) {
                        return $true
                    }
                } elseif ($DetectionDetails.ContainsKey("DesiredDate")) {
                    $desiredDate = [datetime]$DetectionDetails["DesiredDate"]
                    if ($item.LastWriteTime -ge $desiredDate) {
                        return $true
                    }
                } else {
                    return $true
                }
            }
        }
        return $false
    }
    return $false
}
function Test-AppsInstalled {
    # Iterate over each group of $DetectionDetails variables
    $overallResult = $false
    foreach ($group in $groupedDetectionDetails.Keys) {
        $groupResult = $true
        foreach ($detectionDetail in $groupedDetectionDetails[$group]) {
            if (($detectionDetail["Type"] -eq "Programs") -or ($detectionDetail["Type"] -eq "MSI")) {
                $groupResult = $groupResult -and (Test-EXEInstalled -DetectionDetails $detectionDetail)
            } elseif ($detectionDetail["Type"] -eq "AppX") {
                $groupResult = $groupResult -and (Test-AppXInstalled -DetectionDetails $detectionDetail)
            } elseif ($detectionDetail["Type"] -eq "Registry") {
                $groupResult = $groupResult -and (Test-RegistryKey -DetectionDetails $detectionDetail)
            } elseif (($detectionDetail["Type"] -eq "File") -or ($detectionDetail["Type"] -eq "Folder")) {
                $groupResult = $groupResult -and (Test-FileExists -DetectionDetails $detectionDetail)
            }
        }
        if ($groupResult) {
            $overallResult = $true
            break
        }
    }

    # Return the final result
    return $overallResult
}

# Invoke the function to Test all applications
if (Test-AppsInstalled) { return $true }