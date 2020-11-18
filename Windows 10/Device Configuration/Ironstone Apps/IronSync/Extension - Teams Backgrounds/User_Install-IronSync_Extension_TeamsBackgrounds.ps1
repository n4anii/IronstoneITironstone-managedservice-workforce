<#
    .NAME
        User_Install-TeamsBackgroundsFromIronSync.ps1

    .SYNOPSIS
        Installs Teams backgrounds from Ironstone IronSync folder.

    .NOTES
        Install from Intune
            # Default input parameters
            "%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy "Bypass" -NoLogo -NonInteractive -NoProfile -WindowStyle "Hidden" -Command "& '.\User_Install-TeamsBackgroundsFromIronSync.ps1'; exit $LASTEXITCODE"
            # Keep log even if success
            "%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy "Bypass" -NoLogo -NonInteractive -NoProfile -WindowStyle "Hidden" -Command "& '.\User_Install-TeamsBackgroundsFromIronSync.ps1' -KeepLogIfSuccess; exit $LASTEXITCODE"
        Install from PowerShell ISE
            # Default input parameters
            & $psISE.'CurrentFile'.'FullPath'
            # Keep log even if success
            & $psISE.'CurrentFile'.'FullPath' -KeepLogIfSuccess
#>



# Input parameters
[OutputType($null)]
Param (
    [Parameter(Mandatory = $false)]
    [ValidateScript({[System.IO.Directory]::Exists($_)})]
    [string] $Source = [string]('{0}\IronSync' -f ($env:PUBLIC)),

    [Parameter(Mandatory = $false, HelpMessage = 'If used, logs will not get deleted if script runs without errors.')]
    [switch] $KeepLogIfSuccess,
    
    [Parameter(Mandatory = $false, HelpMessage = 'If used, script will keep both files if "imagename.png" already exist on destination, and source has "imagename.jpg".')]
    [switch] $SkipIgnoreFileExtension
)



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



# Logging
## Assets
$ScriptSuccess = [bool] $true
$ScriptChanges = [bool] $false
$ScriptName    = [string]('User_Install-TeamsBackgroundsFromIronSync')
$ScriptLogPath = [string]('{0}\IronstoneIT\Logs\ClientApps\{1}-{2}.txt' -f ($env:ProgramData,$ScriptName,[datetime]::Now.ToString('yyyyMMdd-HHmmss')))
$ScriptLogDir  = [string]([System.IO.Directory]::GetParent($ScriptLogPath).'FullName')
## Create path if not exist
if (-not[System.IO.Directory]::Exists($ScriptLogDir)) {
    $null = [System.IO.Directory]::CreateDirectory($ScriptLogDir)
}
## Start logging
$null = Start-Transcript -Path $ScriptLogPath -Force



#region Try
#####################################
Try {
#####################################



# Failproof
## Running as system user
if ([System.Security.Principal.WindowsIdentity]::GetCurrent().'User'.'Value' -eq 'S-1-5-18') {
    Throw 'Running as NT AUTHORITY\SYSTEM'
}



# Assets
## Static
$Destination = [string]('{0}\Microsoft\Teams\Backgrounds\Uploads' -f ($env:APPDATA))
$Include     = [string[]]('*.jpeg','*.jpg','*.png')

## Dynamic - Look for a dedicated teams background folder
if ([System.IO.Directory]::Exists($Source)) {
    $TeamsFolders = [array](Get-ChildItem -Path $Source -Directory -Filter '*teams*' -Depth 0)
    if ($TeamsFolders.'Count' -eq 1 -and $([array](Get-ChildItem -Path ('{0}\*'-f$TeamsFolders[0].'FullName') -Include $Include -Recurse -Force)).'Count' -gt 0) {
        $Source = $TeamsFolders[0].'FullName'
    }
}



# Copy files
if ([System.IO.Directory]::Exists($Source)) {
    # Create $To if not exist
    if (-not [System.IO.Directory]::Exists($Destination)) {        
        $null = New-Item -Path $Destination -ItemType 'Directory' -Force
    }

    # Get list of files
    ## Source
    $FromFiles = [array](Get-ChildItem -Path ('{0}\*'-f$Source) -Include $Include -Recurse -Force)    
    ## Destination
    $ToFiles = [array](Get-ChildItem -Path ('{0}\*'-f$Destination) -Include $Include -Recurse -Force)
    ## Destination files without file extension
    if (-not $SkipIgnoreFileExtension) {
        $ToFileNames = [string[]]($ToFiles.'Name'.ForEach{$_.Replace(('.{0}'-f($_.Split('.')[-1])),'').Trim()})
    }

    # Compare with $To, copy over if not exist or modified date or size is different
    foreach ($FromFile in $FromFiles) {
        # Assets
        $ToPath = [string]('{0}\{1}' -f ($Destination,$FromFile.'Name'))
        $ToFile = [System.IO.FileInfo]$(
            if ([System.IO.File]::Exists($ToPath)) {
                Get-Item -Path $ToPath
            }
            else {
                [System.IO.FileInfo]::new($ToPath)
            }
        ) 
        

        # Remove same filename different extension if not $SkipIgnoreFileExtension
        if (-not $SkipIgnoreFileExtension) {
            # Generate name for FromFile without extension
            $FromFileName = $FromFile.'Name'.Replace(('.{0}'-f($FromFile.'Name'.Split('.')[-1])),'')            

            # If destination already has a file with the same name
            if ($ToFileNames -contains $FromFileName) {
                # Get existing file no matter extension
                $ExistingToFileName = [string]((Get-ChildItem -Path $Destination -Filter ('{0}.*' -f ($FromFileName))).'FullName')
            
                # If extension is different - Delete
                if ($FromFile.'Name'.Split('.')[-1] -ne $ExistingToFileName.Split('.')[-1]) {          
                    $null = [System.IO.File]::Delete($ExistingToFileName)
                }
            }
        }


        # Copy new item if:
        if (
            # File does not exist already, or
            [System.IO.File]::Exists($DestinationPath) -or
            # File sizes are different, or
            $FromFile.'Length' -ne $ToFile.'Length' -or
            # Last Write Time is different
            $FromFile.'LastWriteTime' -ne $ToFile.'LastWriteTime'
        ) {
            Write-Output -InputObject ('Copying "{0}" to "{1}".' -f ($FromFile.'FullName',$ToFile.'FullName'))
            $null = Copy-Item -Path $FromFile.'FullName' -Destination $ToFile.'FullName' -Force
            $ScriptChanges = [bool] $true
        }
    }
}



#####################################
}
#####################################
#endregion Try


Catch {
    # Set ScriptSuccess to false
    $ScriptSuccess = [bool] $false
    
    # Construct error message
    ## Generic content
    $ErrorMessage = [string]$('{0}Catched error:' -f ([System.Environment]::NewLine))    
    ## Last exit code if any
    if (-not[string]::IsNullOrEmpty($LASTEXITCODE)) {
        $ErrorMessage += ('{0}# Last exit code ($LASTEXITCODE):{0}{1}' -f ([System.Environment]::NewLine,$LASTEXITCODE))
    }
    ## Exception
    $ErrorMessage += [string]$('{0}# Exception:{0}{1}' -f ([System.Environment]::NewLine,$_.'Exception'))
    ## Dynamically add info to the error message
    foreach ($ParentProperty in [string[]]$($_.GetType().GetProperties().'Name')) {
        if ($_.$ParentProperty) {
            $ErrorMessage += ('{0}# {1}:' -f ([System.Environment]::NewLine,$ParentProperty))
            foreach ($ChildProperty in [string[]]$($_.$ParentProperty.GetType().GetProperties().'Name')) {
                ### Build ErrorValue
                $ErrorValue = [string]::Empty
                if ($_.$ParentProperty.$ChildProperty -is [System.Collections.IDictionary]) {
                    foreach ($Name in [string[]]$($_.$ParentProperty.$ChildProperty.GetEnumerator().'Name')) {
                        if (-not[string]::IsNullOrEmpty([string]$($_.$ParentProperty.$ChildProperty.$Name))) {
                            $ErrorValue += ('{0} = {1}{2}' -f ($Name,[string]$($_.$ParentProperty.$ChildProperty.$Name),[System.Environment]::NewLine))
                        }
                    }
                }
                else {
                    $ErrorValue = [string]$($_.$ParentProperty.$ChildProperty)
                }
                if (-not[string]::IsNullOrEmpty($ErrorValue)) {
                    $ErrorMessage += ('{0}## {1}\{2}:{0}{3}' -f ([System.Environment]::NewLine,$ParentProperty,$ChildProperty,$ErrorValue.Trim()))
                }
            }
        }
    }
    # Write Error Message
    Write-Error -Message $ErrorMessage -ErrorAction 'Continue'
}


Finally {
    # Output information    
    Write-Output -InputObject ('Success? {0}.' -f ($ScriptSuccess.ToString()))
    Write-Output -InputObject ('Was changes made? {0}.' -f ($ScriptChanges.ToString()))

    
    # Stop logging
    $null = Stop-Transcript

    # Remove logging if success and
    if ($Success -and -not $KeepLogIfSuccess) {
        $null = [System.IO.File]::Delete($ScriptLogPath)
    }
}
