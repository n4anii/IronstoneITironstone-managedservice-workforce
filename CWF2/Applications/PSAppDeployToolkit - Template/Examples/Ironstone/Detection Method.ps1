$ErrorActionPreference = 'SilentlyContinue'
Get-Variable | Where-Object Name -Match 'DetectionDetails[0-9]' | Remove-Variable -Force

# Define the application details as hashtables
# Delete the $DetectionDetails-variables that are not needed
$DetectionDetails1 = @{
    DisplayName = "Lenovo Vantage Service"
    DesiredVersion = "4.0.52.0"
    Type = "Programs" # Type is either Programs or msi. Check with (Get-Package -Name "*Application Name*") and look at "ProviderName". "Application Name" as visible in appwiz.cpl
}

$DetectionDetails2 = @{
    DisplayName = "*E046963F.LenovoSettingsforEnterprise*"
    DesiredVersion = "10.2401.29.0"
    Type = "AppX" # (Get-AppxPackage -AllUsers "*Application Name*" | select name,version) (Only visible in "Installed Apps" and not in appwiz.cpl)
}

$DetectionDetails3 = @{
    RegistryPath = "HKLM:\SOFTWARE\WOW6432Node\Lenovo\SystemUpdateAddin\Logs"
    ValueName = "EnableLogs"
    ExpectedValue = "True"
    Type = "Registry"
}

$DetectionDetails4 = @{
    FilePath = "C:\Users\*\Desktop\short.rdp" # Wildcards are supported
    #DesiredVersion = "1.0.0.0" # Uncomment if you need to check for a specific version
    #DesiredDate = (Get-Date "2024-10-07T00:00:00Z").ToUniversalTime() # Uncomment if you need to check for a specific date
    Type = "File" #File or Folder
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
    # Find all $DetectionDetails variables
    $DetectionDetailsVariables = Get-Variable | Where-Object { $_.Name -match 'DetectionDetails[0-9]' }
    $result = $true
    # Iterate over each $DetectionDetails variable
    foreach ($appVar in $DetectionDetailsVariables) {
        $DetectionDetails = $appVar.Value
        if (($DetectionDetails["Type"] -eq "Programs") -or ($DetectionDetails["Type"] -eq "MSI")) {
            $result = $result -and (Test-EXEInstalled -DetectionDetails $DetectionDetails)
        } elseif ($DetectionDetails["Type"] -eq "AppX") {
            $result = $result -and (Test-AppXInstalled -DetectionDetails $DetectionDetails)
        } elseif ($DetectionDetails["Type"] -eq "Registry") {
            $result = $result -and (Test-RegistryKey -DetectionDetails $DetectionDetails)
        } elseif (($DetectionDetails["Type"] -eq "File") -or ($DetectionDetails["Type"] -eq "Folder")) {
            $result = $result -and (Test-FileExists -DetectionDetails $DetectionDetails)
        }
    }

    # Return the final result
    return $result
}

# Invoke the function to Test all applications
if (Test-AppsInstalled) { return $true }