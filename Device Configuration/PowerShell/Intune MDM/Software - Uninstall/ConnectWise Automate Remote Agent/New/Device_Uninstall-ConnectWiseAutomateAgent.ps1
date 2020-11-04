#Requires -Psedition Desktop -Version 5.1 -RunAsAdministrator
<#
    .SYNOPSIS
        Uninstalls ConnectWise Automate agent.

    .NOTES
        Author:   Olav Rønnestad Birkeland @ Ironstone
        Created:  200709
        Modified: 200709

        Run from ISE
            & $psISE.'CurrentFile'.'FullPath'
        
        Run from Intune Win32
            "%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy "Bypass" -NoLogo -NonInteractive -NoProfile -WindowStyle "Hidden" -Command "& '.\Device_Uninstall-ConnectWiseAutomateAgent.ps1'"
#>



# Input parameters
[OutputType($null)]
Param()



# PowerShell Preferences
$ConfirmPreference     = 'None'
$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'
$WarningPreference     = 'Continue'
$WhatIfPreference      = $false



# Assets
$DownloadSuccess = $ExtractSuccess = $UninstallSuccess = $CleanupSuccess = [bool] $false
$Uris = [ordered]@{
    'zip'='https://s3.amazonaws.com/assets-cp/assets/Agent_Uninstaller.zip'
    'exe'='https://ironstoneit.hostedrmm.com/Labtech/Deployment.aspx?ID=-2'
}
$ExtractDirPath = [string]('{0}\Temp' -f ($env:windir))



##################
Try {
##################



# Download
## Write information
Write-Information -MessageData ('Downloading.')
## Download
:ForEachUri foreach ($Uri in $($Uris.GetEnumerator())) {
    # Create download path
    $DownloadPath = [string]('{0}\Uninstaller.{1}' -f ($ExtractDirPath,$Uri.'Name'))
    # Remove if file already exist
    if ([System.IO.File]::Exists($DownloadPath)) {
        [System.IO.File]::Delete($DownloadPath)
    }
    # Download
    $null = [System.Net.WebClient]::new().DownloadFile($Uri.'Value',$DownloadPath)
    # Check success
    $DownloadSuccess = [bool] $? -and [System.IO.File]::Exists($DownloadPath)
    # Continue if success
    if ($DownloadSuccess) {
        Continue ForEachUri
    }
}
## Write information
Write-Information -MessageData ('{0}Success? {1}.' -f ("`t",$DownloadSuccess.ToString()))
## Crash if not success
if (-not $DownloadSuccess) {
    Throw 'Failed to download.'
}



# Extract
## Write information
Write-Information -MessageData ('Extract.')
if ($DownloadPath.Split('.')[-1] -eq 'exe') {
    $ExtractPath    = [string] $DownloadPath
    $ExtractSuccess = [bool] $true
}
else {
    # Add type if neccessary
    if (-not [bool]$(Try{$null=[System.IO.Compression.ZipFile]::OpenRead($DownloadPath);$?}Catch{$false})) {
        Add-Type -AssemblyName 'System.IO.Compression.FileSystem'
    }
    # Get path of output after extraction
    $ExtractPath = [string]('{0}\{1}' -f ($ExtractDirPath,[string][System.IO.Compression.ZipFile]::OpenRead($DownloadPath).Entries.'Name'.Where{$_ -like '*.exe'}))
    # Remove file if already exist
    if ([System.IO.File]::Exists($ExtractPath)) {
        [System.IO.File]::Delete($ExtractPath)
    }
    # Extract
    [System.IO.Compression.ZipFile]::ExtractToDirectory($DownloadPath,$ExtractDirPath)
    # Check success
    $ExtractSuccess = [bool] $? -and [System.IO.File]::Exists($ExtractPath)
}
## Write information
Write-Information -MessageData ('{0}Success? {1}.' -f ("`t",$ExtractSuccess.ToString()))
## Crash if not success
if (-not $ExtractSuccess) {
    Throw 'Failed to extract.'
}



# Run uninstall
## Write information
Write-Information -MessageData ('Uninstall.')
## Run uninstaller
$Process = Start-Process -FilePath $ExtractPath -ArgumentList '/s' -NoNewWindow -Wait -PassThru
## Check success
$UninstallSuccess = [bool] $? -and $Process.'ExitCode' -eq 0
## Write information
Write-Information -MessageData ('{0}Success? {1}.' -f ("`t",$UninstallSuccess.ToString()))
## Crash if not success
if (-not $UninstallSuccess) {
    Throw 'Failed to uninstall.'
}


# Clean up
## Write information
Write-Information -MessageData ('Clean up.')
## Remove
$CleanupSuccess = [bool](
    [bool[]](
        $([string[]]($DownloadPath,$ExtractPath)).ForEach{
            if ([System.IO.File]::Exists($_)) {
                $null = [System.IO.File]::Delete($_)
                [bool] $? -and -not [System.IO.File]::Exists($_)
            }
            else {
                [bool] $true
            }
        }
    ) -notcontains $false
)
## Write information
Write-Information -MessageData ('{0}Success? {1}.' -f ("`t",$CleanupSuccess.ToString()))
## Crash if not success
if (-not $CleanupSuccess) {
    Throw 'Failed to clean up.'
}



##################
} # end Try
##################


Catch {
}



# Exit
if ($DownloadSuccess -and $ExtractSuccess -and $UninstallSuccess -and $CleanupSuccess) {
    Write-Output -InputObject 'Success.'
    Exit 0
}
else {
    Write-Error -ErrorAction 'Continue' -Message 'Failed.'
    Exit 1
}
