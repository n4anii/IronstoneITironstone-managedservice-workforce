<#
    .NAME
        Install-FilesInWin32Package
    
    .SYNOPSIS
        Installs files to given directory. Thats it.

    .DESCRIPTION
        Installs files to given directory. Thats it.

        Exit codes
             0   = Success.
            10   = Output path already exist, and input parameter $Overwrite is set to $false.
            11   = Robocopy failed to sync files over to destination directory. Permissions?
            Else = Failproofing exited the script, or unknown error. 

    .EXAMPLE
        # Run from PowerShell ISE
        & ('{0}\Install-FilesInWin32Package.ps1' -f ([System.IO.Directory]::GetParent($psISE.'CurrentFile'.'FullPath').'FullName')) -OutputPath ('{0}\IronstoneIT\Binaries\AzCopy'-f($env:ProgramData))
#>


# Input parameters
[OutputType($null)]
Param(
    [Parameter(Mandatory = $true, HelpMessage = 'What folder to install to.')]
    [string] $OutputPath,

    [Parameter(Mandatory = $false, HelpMessage = 'Whether to remove existing files in $OutputPath.')]
    [string] $Overwrite = $true
)


# PowerShell Preferences
$ConfirmPreference     = 'None'
$ErrorActionPreference = 'Stop'
$InformationPreference = 'SilentlyContinue'
$ProgressPreference    = 'SilentlyContinue'
$WarningPreference     = 'Continue'
$WhatIfPreference      = $false


# Assets
## Working directory
$WorkingDirectory = [string]$(if([string]::IsNullOrEmpty($PSScriptRoot)){[System.IO.Directory]::GetParent($MyInvocation.'MyCommand'.'Path').'FullName'}else{$PSScriptRoot})
## Source directory
$SourceDirectory  = [string]('{0}\Files' -f ($WorkingDirectory))
## Robocopy
$PathRoboCopy = [string]('{0}\Robocopy.exe' -f ([System.Environment]::GetFolderPath('System')))


# Failproof
## Run as 64 bit on a 64 bit Operating system
if ([System.Environment]::Is64BitOperatingSystem -and -not [System.Environment]::Is64BitProcess) {
    Throw ('Not running as 64 bit process on 64 bit OS')
}
## Source does not exist
if (-not [System.IO.Directory]::Exists($SourceDirectory)) {
    Throw ('Source directory "{0}" does not exist.' -f ($SourceDirectory))
}
## Source does not contain any items
if ($([array](Get-ChildItem -Path $SourceDirectory -Recurse)).'Count' -le 0) {
    Throw ('Source directory "{0}" does not contain any items (files or directories).' -f ($SourceDirectory))
}
## Robocopy does not exist
if (-not [System.IO.File]::Exists($PathRoboCopy)) {
    Throw ('Did not find path to RoboCopy.')
}
## Output path is not root or close to root
if ($OutputPath.Split('\').'Count' -le 3) {
    Throw ('Script will not install anything so close to root ("{0}").' -f ($OutputPath))
}


# Prepare output path
if ([System.IO.Directory]::Exists($OutputPath)) {
    if (-not $Overwrite) {
        Write-Error -Message 'Destination folder already exist and input parameter $Overwrite is not $true.' -ErrorAction 'Continue'
        Exit 10  
    }
}
else {
    $null = [System.IO.Directory]::CreateDirectory($OutputPath)
}


# Copy files to $OutputPath
## Sync files over to $OutputPath
$null = & $PathRoboCopy '/MIR' '/W:10' '/R:3' ('"{0}"'-f$SourceDirectory) ('"{0}"'-f$OutputPath)
## Check success - Exit with exit code
if ($LASTEXITCODE -eq 0) {
    Write-Output -InputObject 'Destination directory already had all items from source directory.'
    Exit 0
}
elseif ($LASTEXITCODE -eq 1) {
    Write-Output -InputObject 'Items from source directory where synced to destination directory.'
    Exit 0
}
else {
    Write-Output -InputObject ('Failed with exit code "{0}". Permissions?' -f ($LASTEXITCODE))
    Write-Error -Message 'Robocopy failed to sync.' -ErrorAction 'Continue'
    Exit 11
}
