<#
    .SYNOPSIS
        Detects whether Montel Excel plugin is installed.
#>

# PowerShell Preferences
$ErrorActionPreference = 'Stop'

# Assets
$FilePath = [string] '{0}\Montel\XLF\211\xlf.xll' -f $env:LOCALAPPDATA
$RegValue = [string] '/R "{0}"' -f $FilePath.Replace('\','\\')

# Exit based on results
if (
    [System.IO.File]::Exists($FilePath) -and
    $(Get-ItemProperty -Path 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Office\16.0\Excel\Options' -Name 'Open').'Open' -eq $RegValue
) {
    Write-Output -InputObject 'Installed.'
}
else {
    Write-Error -Message 'Not installed.' -ErrorAction 'Continue'
    Exit 1
}    
