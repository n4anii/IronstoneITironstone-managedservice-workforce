<#
    .SYNOPSIS
        Checks if Google Chrome is installed.
#>


# Input parameters
[OutputType($null)]
Param()


# PowerShell preferences
$ErrorActionPreference = 'Continue'


# Check if installed
$IsInstalled = [bool](
    $(
        [string[]](
            ('{0}\Google\Chrome\Application\chrome.exe' -f ${env:ProgramFiles(x86)}),
            ('{0}\Google\Chrome\Application\chrome.exe' -f $env:ProgramW6432)
        )
    ).ForEach{
        [System.IO.File]::Exists($_)
    } -contains $true
)


# Exit based on install status
if ($IsInstalled) {
    Write-Output -InputObject 'Installed'
    Exit 0
}
else {
    Write-Error -ErrorAction 'Continue' -Message 'Not installed'
    Exit 1
}
