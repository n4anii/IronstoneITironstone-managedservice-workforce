<#
    .NAME
        User_Check-TeamsBackgroundsFromIronSync.ps1

    .SYNOPSIS
        Installs Teams backgrounds from Ironstone IronSync folder.
#>



# Input parameters
[OutputType($null)]
Param ()



# PowerShell Preferences
## Output encoding
$OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['*:Encoding'] = 'UTF8'
## Output streams
$DebugPreference       = 'SilentlyContinue'
$InformationPreference = 'Continue'
$VerbosePreference     = 'SilentlyContinue'
$WarningPreference     = 'Continue'
## Interaction
$ConfirmPreference     = 'None'
$ProgressPreference    = 'SilentlyContinue'
## Behavior
$ErrorActionPreference = 'Stop'
$WhatIfPreference      = $false



# Assets
## Static
$Source      = [string]('{0}\IronSync' -f ($env:PUBLIC))
$Destination = [string]('{0}\Microsoft\Teams\Backgrounds\Uploads' -f ($env:APPDATA))
$Include     = [string[]]('*.jpeg','*.jpg','*.png')

## Dynamic - Look for a dedicated Teams background folder
if ([System.IO.Directory]::Exists($Source)) {
    $TeamsFolders = [array](Get-ChildItem -Path $Source -Force -Directory -Filter '*teams*' -Depth 0)
    if ($TeamsFolders.'Count' -eq 1 -and $([array](Get-ChildItem -Path ('{0}\*'-f$TeamsFolders[0].'FullName') -Include $Include -Recurse -Force)).'Count' -gt 0) {
        $Source = $TeamsFolders[0].'FullName'
    }
}


# Check
$Success = [bool]$(
    # If Source and Destination folders exist
    if ($([string[]]($Source,$Destination)).ForEach{[System.IO.Directory]::Exists($_)} -notcontains $false) {
        [bool]$(
            $FromFiles = [array](Get-ChildItem -Path ('{0}\*'-f$Source) -Include $Include -Recurse)
            # For each $FromFiles
            [bool[]]$(
                foreach ($FromFile in $FromFiles) {
                    Try {
                        # Get info on $ToFile
                        $ToFile = Get-Item -Path ('{0}\{1}' -f ($Destination,$FromFile.'Name'))
                        # Check
                        [bool](
                            ## File does not exist, or
                            [System.IO.File]::Exists($ToFile.'FullName') -or
                            ## File sizes are different, or
                            $FromFile.'Length' -ne $ToFile.'Length' -or
                            ## Last Write Time is different
                            $FromFile.'LastWriteTime' -ne $ToFile.'LastWriteTime'
                        )
                    }
                    Catch {
                        [bool] $false
                    }
                }
            ) -notcontains $false
        )
    }
    # Else, if Source and Destination folders does not exist
    else {
        [bool] $false
    }
)


# Exit
if ($Success) {
    Write-Output -InputObject 'Up to date.'
    Exit 0
}
else {
    Write-Error -Message 'Not up to date, or failed.' -ErrorAction 'Continue'
    Exit 1
}
