#Requires -Version 5.1
<#
    .SYNOPSIS
        Adds reference to IronSync folder for the Microsoft Office suite, if the folder exists and holds templates.

    .EXAMPLE
        # From Intune Win32
        "%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy "Bypass" -NoLogo -NonInteractive -NoProfile -WindowStyle "Hidden" -Command "& '.\User_Install-IronSync_Extension_OfficeTemplates.ps1'; exit $LASTEXITCODE"
    
    .EXAMPLE
        # From PowerShell ISE
        & $psISE.'CurrentFile'.'FullPath'
#>



# Input parameters
[OutputType($null)]
Param(
    [Parameter(Mandatory = $false)]
    [ValidateScript({[System.IO.Directory]::Exists($_)})]
    [string] $Path = '{0}\IronSync' -f $env:PUBLIC,

    [Parameter(Mandatory = $false, HelpMessage = 'If used, logs will not get deleted if script runs without errors.')]
    [switch] $KeepLogIfSuccess
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
$ScriptName    = [string]('User_Install-IronSyncExtension_OfficeTemplates')
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
## Path exists
if (-not[System.IO.Directory]::Exists($Path)) {
    Throw ('ERROR: Path "{0}" does not exist.' -f $Path)
}

## Not running as system
if ([System.Security.Principal.WindowsIdentity]::GetCurrent().'User'.'Value' -eq 'S-1-5-18') {
    Throw 'ERROR: Running as NT AUTHORITY\SYSTEM (S-1-5-18)'
}



# Assets
## Write information
Write-Information -MessageData '# Create registry values'

## Create registry values
$RegValues = [PSCustomObject[]]$(
    $([string[]]('Excel','PowerPoint','Word')).ForEach{
        # Assets
        $ChildDirectories = [string[]]((Get-ChildItem -Path $Path -Force -Directory -Filter ('*{0}*'-f$_) -ErrorAction 'SilentlyContinue').'FullName')
        $ChildDirectory   = [string]$(
            if ($? -and $ChildDirectories.Where{$_}.'Count' -eq 1) {
                $ChildDirectories
            }
            else {
                $Path
            }
        )
        # Output
        [PSCustomObject]@{
            'Path'  = [string]'Registry::HKEY_CURRENT_USER\Software\Microsoft\Office\16.0\{0}\Options' -f $_
            'Name'  = [string]'PersonalTemplates'
            'Value' = $ChildDirectory
            'Type'  = [string]'ExpandString'
        }
    }
)

## Failproof
if ($RegValues.ForEach{[System.IO.Directory]::Exists($_.'Value')} -contains $false) {
    Throw 'ERROR: One of the paths specified in $RegValues does not exist.'
}



# Set registry values
## Write information
Write-Information -MessageData '# Set registry values'
            
## Set registry values
foreach ($Item in $RegValues) {
    # Information
    Write-Information -MessageData ('Path: "{0}".' -f $Item.'Path')

    # Check if $Item.Path exist, create it if not
    if (-not(Test-Path -Path $Item.'Path')){
        Write-Information -MessageData ('{0}Path did not exist, creating it.' -f "`t")
        $null = New-Item -Path $Item.'Path' -ItemType 'Directory' -Force
        if ($?) {
            $ScriptChanges = [bool] $true
        }
    }
        
    # Set Value / ItemPropery
    Write-Verbose -Message ('{0}Name: {1} | Value: {2} | Type: {3}' -f "`t", $Item.'Name', $Item.'Value', $Item.'Type')
    $null = Set-ItemProperty -Path $Item.'Path' -Name $Item.'Name' -Value $Item.'Value' -Type $Item.'Type' -Force
    if ($?) {
        $ScriptChanges = [bool] $true
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
