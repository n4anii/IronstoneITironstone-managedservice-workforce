<#
    .SYNOPSIS
        Gets AzCopy.exe version.

    .EXAMPLE
        # In standing directory
        Get-AzCopyExeVersion
        & ('{0}\Get-AzCopyExeVersion.ps1' -f ([System.IO.Directory]::GetParent($psISE.'CurrentFile'.'FullPath').'FullName'))

    .EXAMPLE
        # Not in standing directory
        Get-AzCopyExeVersion -DirectoryPath ".\Files\"
        & ('{0}\Get-AzCopyExeVersion.ps1' -f ([System.IO.Directory]::GetParent($psISE.'CurrentFile'.'FullPath').'FullName')) -DirectoryPath '.\Files\' -Verbose
#>


# Input parameters
[CmdletBinding()]
[OutputType([System.Version])]
Param (
    [Parameter(Mandatory = $false, HelpMessage = 'Path to directory where AzCopy.exe is located.')]
    [ValidateScript({[System.IO.Directory]::Exists($_)})]
    [string] $DirectoryPath = '.\'
)


# PowerShell Preferences
$ErrorActionPreference = 'Stop'


# Correct $DirectoryPath if needed
if ($DirectoryPath[-1] -eq '\') {
    $DirectoryPath = $DirectoryPath.SubString(0,$DirectoryPath.'Length'-1)
}


# Verbose
Write-Verbose -Message $DirectoryPath


# Create path to AzCopy
$AzCopyPath = [string]('{0}\azcopy.exe' -f ($DirectoryPath))


# Verbose
Write-Verbose -Message $AzCopyPath


# Error if $AzCopyPath does not exist
if (-not [System.IO.File]::Exists($AzCopyPath)) {
    Throw ('Did not find AzCopy.exe on this path: "{0}"' -f ($AzCopyPath))
}


# Get version info
$Version = [string[]](& $AzCopyPath '--version')
if ($Version -is [string[]]) {
    $Version = [string]($Version[0])
}


# Return version
[System.Version]$(
    $Version.Split(' ')[-1]
)
