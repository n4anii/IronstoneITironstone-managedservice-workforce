<#
    .SYNOPSIS
        Checks if Zoom MSIs are installed
#>


# PowerShell Preferences
$ConfirmPreference     = 'None'
$ErrorActionPreference = 'Stop'
$InformationPreference = 'SilentlyContinue'
$ProgressPreference    = 'SilentlyContinue'
$WarningPreference     = 'Continue'
$WhatIfPreference      = $false


# Assets
## MSIs
$MSIs = [hashtable][ordered]@{
    'Adobe Flash Player PPAPI'          = '02FDB6BF-5846-4DC6-8992-AFC11AA384C4'
}
$MSIUninstallerPath = ('Registry::HKEY_LOCAL_MACHINE\SOFTWARE\{0}Microsoft\Windows\CurrentVersion\Uninstall' -f ([string]$(if([System.Environment]::Is64BitProcess){'WOW6432Node\'})))


# Check if installed
$Installed = [bool[]]$(
    foreach ($MSI in $MSIs.GetEnumerator().'Name') {
        if (Test-Path -Path ('{0}\{1}{2}{3}' -f ($MSIUninstallerPath,'{',$MSIs.$MSI,'}'))) {
            $true
        }
        else {
            $false
        }
    }
)


# Return result
if ($Installed -notcontains $false) {
    Write-Output -InputObject 'All Adobe MSIs are installed.'
    Exit 0
}
elseif ($Installed -contains $true) {
    Write-Output -InputObject 'At least one Adobe is installed.'
    Exit 0
}
else {
    Throw 'No Adobe MSIs are installed.'
    Exit 1
}