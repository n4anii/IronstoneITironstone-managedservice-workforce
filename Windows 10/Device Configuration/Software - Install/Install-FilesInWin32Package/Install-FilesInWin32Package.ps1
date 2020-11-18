<#
    .NAME
        Install-FilesInWin32Package

    
    .SYNOPSIS
        Installs files to given directory. Thats it.


    .DESCRIPTION
        Installs files to given directory. Thats it.

        Exit codes
            00   =  Success  =  Success.
            01   =  Failed   =  Unhandeled error.
            10   =  Failed   =  Not running as 64 bit on 64 bit OS.
            11   =  Failed   =  Source directory does not exist.
            12   =  Failed   =  Source directory does not contain any items.
            13   =  Failed   =  Did not find RoboCopy.
            14   =  Failed   =  Output path is too close to root.
            20   =  Failed   =  Output path already exist, and input parameter $Overwrite is set to $false.
            21   =  Failed   =  Robocopy failed to sync files over to destination directory. Permissions?
            30   =  Failed   =  Failed to add output path to environmental variables.


    .EXAMPLE
        # Run from PowerShell ISE, install AzCopy
        & ('{0}\Install-FilesInWin32Package.ps1' -f ([System.IO.Directory]::GetParent($psISE.'CurrentFile'.'FullPath').'FullName')) -OutputPath ('{0}\IronstoneIT\Binaries\AzCopy'-f($env:ProgramData)) -Overwrite -AddToEnvVariables


    .EXAMPLE
        # Run from Intune Win32 Package, install AzCopy
        "%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy "Bypass" -NoLogo -NonInteractive -NoProfile -WindowStyle "Hidden" -Command "& '.\Install-FilesInWin32Package.ps1' -OutputPath ('{0}\IronstoneIT\Binaries\AzCopy'-f($env:ProgramData)) -Overwrite -AddToEnvVariables; exit $LASTEXITCODE"
#>


# Input parameters
[OutputType($null)]
Param(
    # Mandatory
    [Parameter(Mandatory = $true, HelpMessage = 'What folder to install to.')]
    [string] $OutputPath,

    # Optional
    [Parameter(Mandatory = $false, HelpMessage = 'Whether to remove existing files in $OutputPath.')]
    [switch] $Overwrite,

    [Parameter(Mandatory = $false, HelpMessage = 'Whether to add output path to env variables if install succeeds.')]
    [switch] $AddToEnvVariables
)



# PowerShell Preferences
$ConfirmPreference     = 'None'
$ErrorActionPreference = 'Stop'
$InformationPreference = 'SilentlyContinue'
$ProgressPreference    = 'SilentlyContinue'
$WarningPreference     = 'Continue'
$WhatIfPreference      = $false



# Assets
## Help variables
$SystemContext = [bool]([string][System.Security.Principal.WindowsIdentity]::GetCurrent().'User'.'Value' -eq 'S-1-5-18')
$ExitCode = [byte] 0
## Working directory
$WorkingDirectory = [string]$(if([string]::IsNullOrEmpty($PSScriptRoot)){[System.IO.Directory]::GetParent($MyInvocation.'MyCommand'.'Path').'FullName'}else{$PSScriptRoot})
## Source directory
$SourceDirectory = [string]('{0}\Files' -f ($WorkingDirectory))
## Robocopy
$PathRoboCopy = [string]('{0}\Robocopy.exe' -f ([System.Environment]::GetFolderPath('System')))
$RoboCopyExitCodes = [hashtable]@{
    0  = 'No errors occurred, and no copying was done. The source and destination directory trees are completely synchronized.'
    1  = 'One or more files were copied successfully (that is, new files have arrived).'
    2  = 'Some Extra files or directories were detected. No files were copied. Examine the output log for details.'
    3  = '(2+1) Some files were copied. Additional files were present. No failure was encountered.'
    4  = 'Some Mismatched files or directories were detected. Examine the output log. Housekeeping might be required.'
    5  = '(4+1) Some files were copied. Some files were mismatched. No failure was encountered.'
    6  = '(4+2) Additional files and mismatched files exist. No files were copied and no failures were encountered. This means that the files already exist in the destination directory'
    7  = '(4+1+2) Files were copied, a file mismatch was present, and additional files were present.'
    8  = 'Some files or directories could not be copied (copy errors occurred and the retry limit was exceeded). Check these errors further.'
    16 = 'Serious error. Robocopy did not copy any files. Either a usage error or an error due to insufficient access privileges on the source or destination directories.'
}



# Logging
## Create log path dynamically
$LogPath = [string]('{0}\IronstoneIT\Logs\ClientApps\{1}_Install-{2}-{3}.txt' -f (
    $env:ProgramData,
    [string]$(if($SystemContext){'Device'}else{'User'}),
    $OutputPath.Split('\')[-1],
    [datetime]::Now.ToString('yyyyMMdd-HHmmss')
))
## Check if log directory exist, create if not
$LogDir = [string][System.IO.Directory]::GetParent($LogPath)
if (-not [System.IO.Directory]::Exists($LogDir)) {
    $null = [System.IO.Directory]::CreateDirectory($LogDir)
}
## Make sure output is UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
## Start logging
$null = Start-Transcript -Path $LogPath -Force



#region Try
############################################
Try {
############################################



# Failproof
## Run as 64 bit on a 64 bit Operating system
if ([System.Environment]::Is64BitOperatingSystem -and -not [System.Environment]::Is64BitProcess) {
    $ExitCode = 10
    Throw ('Not running as 64 bit process on 64 bit OS')
}
## Source does not exist
if (-not [System.IO.Directory]::Exists($SourceDirectory)) {
    $ExitCode = 11
    Throw ('Source directory "{0}" does not exist.' -f ($SourceDirectory))
}
## Source does not contain any items
if ($([array](Get-ChildItem -Path $SourceDirectory -Recurse)).'Count' -le 0) {
    $ExitCode = 12
    Throw ('Source directory "{0}" does not contain any items (files or directories).' -f ($SourceDirectory))
}
## Robocopy does not exist
if (-not [System.IO.File]::Exists($PathRoboCopy)) {
    $ExitCode = 13
    Throw ('Did not find path to RoboCopy.')
}
## Output path is not root or close to root
if ($OutputPath.Split('\').'Count' -le 3) {
    $ExitCode = 14
    Throw ('Script will not install anything so close to root ("{0}").' -f ($OutputPath))
}


# Prepare output path
if ([System.IO.Directory]::Exists($OutputPath)) {
    if (-not $Overwrite) {
        $ExitCode = 20
        Throw 'Destination folder already exist and input parameter $Overwrite is not $true.'
    }
}
else {
    $null = [System.IO.Directory]::CreateDirectory($OutputPath)
}


# Copy files to $OutputPath
## Sync files over to $OutputPath
$null = & $PathRoboCopy '/MIR' '/W:10' '/R:3' ('"{0}"'-f$SourceDirectory) ('"{0}"'-f$OutputPath)
## Output status
Write-Output -InputObject ('Robocopy exit code: {0}' -f ($LASTEXITCODE))
Write-Output -InputObject $RoboCopyExitCodes.$LASTEXITCODE
## Check success - Exit with exit code
if ($LASTEXITCODE -eq 0) {
    Write-Output -InputObject 'Destination directory already had all items from source directory.'
}
elseif ($LASTEXITCODE -eq 1) {
    Write-Output -InputObject 'Items from source directory where synced to destination directory.'
}
else {
    Write-Output -InputObject ('Failed with exit code "{0}". Permissions?' -f ($LASTEXITCODE))
    $ExitCode = 21
    Throw 'Robocopy failed to sync.'
}


# Add to environmental variables
if ($AddToEnvVariables -and $ExitCode -eq 0) {
    # Get context
    $Context = [string]$(
        if ($SystemContext) {
            'Machine'
        }
        else {
            'User'
        }
    )

    # Get current variables    
    $EnvPaths = [string[]]([System.Environment]::GetEnvironmentVariables($Context).'Path'.Split(';') | Sort-Object -Unique)

    # See if $EnvPaths already holds current output path
    if ($EnvPaths -notcontains $OutputPath) {
        # Add $OutputPath
        $EnvPaths += [string[]]($OutputPath)

        # Clean up variables
        ## Remove trailing '\'
        $EnvPaths.ForEach{
            if ($_[-1] -eq '\') {
                $_ = $_.Substring(0,$_.'Length'-1)
            }
        }
        ## Remove duplicates
        $EnvPaths = $EnvPaths | Sort-Object -Unique
        ## Remove paths that do not exist
        $EnvPaths = $EnvPaths.Where{[System.IO.Directory]::Exists($_)}

        # Set new environmental path
        Try {
            $null = [System.Environment]::SetEnvironmentVariable('Path',[string]$($EnvPaths -join ';'),$Context)
        }
        Catch {
            $ExitCode = 30
        }

        # Output
        if ($ExitCode -eq 0) {
            Write-Output -InputObject ('Successfully added $OutputPath to environmental variables in "{0}" context.' -f ($Context))
        }
        else {
            $Message = [string]('Failed to add $OutputPath to environmental variables in "{0}" context.' -f ($Context))
            Write-Output -InputObject $Message
            Write-Error -Message $Message -ErrorAction 'Continue'
        }
    }
    else {
        Write-Output -InputObject ('Environmental variables already contains $OutputPath in "{0}" context.' -f ($Context))
    }
}


############################################
}
############################################
#endregion Try



# Catch error
Catch {
    $ExitCode = 1
}



# Finally
Finally {
    Write-Output -InputObject ('Done, current $ExitCode = "{0}".' -f ($ExitCode))
    $null = Stop-Transcript
}



# Exit
Exit $ExitCode
