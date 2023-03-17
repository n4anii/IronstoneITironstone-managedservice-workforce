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
    'Zoom'          = 'D6F22A6D-66DA-436A-B3D0-F8713DC0DAC2'
    'LyncPlugin'    = 'C4E53D40-CE0B-471E-B636-DA3D507565C6'
    'NotesPlugin'   = '354AF7D6-9070-4865-9ABF-1B30CEBFFD7E'
    'OutlookPlugin' = '11F41C33-81CB-40DE-86A2-98E391BC16A0'    
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
    Write-Output -InputObject 'All Zoom MSIs are installed.'
    Exit 0
}
elseif ($Installed -contains $true) {
    Write-Output -InputObject 'At least one Zoom MSI is installed.'
    Exit 0
}
else {
    Throw 'No Zoom MSIs are installed.'
    Exit 1
}