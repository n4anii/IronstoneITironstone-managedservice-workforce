#Requires -RunAsAdministrator
<#
    .SYNOPSIS
        Checks if GoToMeeting is installed.
#>


# PowerShell preferences
$ErrorActionPreference = 'Stop'


# Assets
$Required = [string[]]('g2mcomm.exe','g2mstart.exe')
$Path     = [string] '{0}\GoToMeeting' -f ${env:ProgramFiles(x86)}


# Get files
$Files    = [string[]]((Get-ChildItem -Path $Path -Recurse -Filter '*.exe' -ErrorAction 'SilentlyContinue').'Name')


# Return results
if ($Required.ForEach{$Files -contains $_} -notcontains $false) {
    Write-Output -InputObject 'Installed.'
}
else {
    Write-Error -Message 'Not installed.' -Exception 'Not installed.' -ErrorAction 'Continue'
    Exit 1
}
