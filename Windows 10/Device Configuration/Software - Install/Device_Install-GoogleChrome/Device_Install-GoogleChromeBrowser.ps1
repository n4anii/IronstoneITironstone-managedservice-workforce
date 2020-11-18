#Requires -Version 5.1 -RunAsAdministrator
<#
    .NAME
        Device_Install-GoogleChromeBrowser.ps1


    .SYNAPSIS
        Installs latest Google Chrome browser.


    .NOTES
        Author:   Olav Rønnestad Birkeland @ Ironstone IT
        Created:  191011
        Modified: 201118
        
        Run from Intune
            Install
                "%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy "Bypass" -NoLogo -NonInteractive -NoProfile -WindowStyle "Hidden" -Command "& '.\Device_Install-GoogleChromeBrowser.ps1'; exit $LASTEXITCODE"
            Uninstall
                "%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy "Bypass" -NoLogo -NonInteractive -NoProfile -WindowStyle "Hidden" -Command "& '.\Device_Uninstall-GoogleChromeBrowser.ps1'; exit $LASTEXITCODE"

        Exit codes
            0  = Success.
            1  = Error - Failed, unknown reason.
            10 = Failproof - Already installed.
            11 = Failproof - Already installed, non-default location. Install path is mentioned in error message.
            12 = Error - Failed to remove existing installer before downloading new.
            13 = Error - Failed to download installer.
            14 = Error - Installer failed.
            15 = Error - Failed to remove installer after script is done.

    .EXAMPLE
        # Run from PowerShell ISE
        & $psISE.'CurrentFile'.'FullPath'
#>

# Input parameters
[OutputType($null)]
[CmdletBinding()]
Param()

# Settings - PowerShell
## Output Preferences
$DebugPreference        = 'SilentlyContinue'
$VerbosePreference      = 'SilentlyContinue'
$WarningPreference      = 'Continue'
## Interaction
$ConfirmPreference      = 'None'
$InformationPreference  = 'SilentlyContinue'
$ProgressPreference     = 'SilentlyContinue'
## Behaviour
$ErrorActionPreference  = 'Stop'

# Script variables
$ScriptWorkingDirectory      = [string]$(if([string]::IsNullOrEmpty($PSScriptRoot)){[string]$($MyInvocation.'MyCommand'.'Path').Replace(('\{0}' -f ($MyInvocation.'MyCommand'.'Name')),'')}else{$PSScriptRoot})
$ScriptIsRunningAsAdmin      = [bool]$(([System.Security.Principal.WindowsPrincipal]$([System.Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator))
$ScriptIsRunningOn64Bit      = [bool]$([System.Environment]::Is64BitOperatingSystem)
$ScriptIsRunningAs64Bit      = [bool]$([System.Environment]::Is64BitProcess)
$ScriptRunningAsArchitecture = [string]$(if([System.Environment]::Is64BitProcess){'64'}else{'86'})
$ScriptRunningAsUserSID      = [string]$([System.Security.Principal.WindowsIdentity]::GetCurrent().'User'.'Value')
$ScriptRunningAsUserName     = [string]$([System.Security.Principal.WindowsIdentity]::GetCurrent().'Name')

# Product specific variables
## Manual
$ProductName            = [string] 'Google Chrome Browser'
$ProcessName            = [string] 'chrome.exe'
$Uri                    = [string] 'https://dl.google.com/chrome/install/latest/chrome_installer.exe'
$UriExpectedMinimumSize = [uint32] 1MB
$ArgumentList           = [string] '/silent /install'
## Dynamic
$Destination            = [string] '{0}\Temp\{1}Setup.exe' -f $env:SystemRoot, $ProductName.Replace(' ','')
$InstallVerifyPaths     = [string[]](
    ('{0}\Google\Chrome\Application\{1}' -f ${env:ProgramFiles(x86)}, $ProcessName),
    ('{0}\Google\Chrome\Application\{1}' -f $env:ProgramW6432, $ProcessName) | Sort-Object -Unique
)

# Logging
## Attributes
$ExitCode    = [byte]$(0)
$PathDirLog  = [string]$('{0}\IronstoneIT\Logs\ClientApps' -f ($env:ProgramData))
$PathFileLog = [string]$('{0}\{1}-Install-{2}-x{3}.txt' -f ($PathDirLog,$ProductName.Replace(' ','_'),[datetime]::Now.ToString('yyyyMMdd-HHmmssffff'),$ScriptRunningAsArchitecture))
## Create log path if not exist
if (-not(Test-Path -Path $PathDirLog -ErrorAction 'Stop')) {$null = New-Item -Path $PathDirLog -ItemType 'Directory' -ErrorAction 'Stop'}
## Start Transcript (Logging)
Start-Transcript -Path $PathFileLog -Force -ErrorAction 'Stop'

# Make sure
## We're running as
### Admin
if (-not $ScriptIsRunningAsAdmin) {
    Write-Error -Message 'Not running as administrator.'
}
### 64 bit process on a 64 bit OS
if (-not [bool]$($ScriptIsRunningOn64Bit -and $ScriptIsRunningAs64Bit)) {
    Write-Error -Message 'Not running as 64 bit process on a 64 bit operating system.'
}
## $ScriptWorkingDirectory is real
if ([string]::IsNullOrEmpty($ScriptWorkingDirectory) -or -not [bool]$(Test-Path -Path $ScriptWorkingDirectory -ErrorAction 'SilentlyContinue')) {
    Write-Error -Message ('$ScriptWorkingDirectory is either empty or does not exist ("{0}").' -f ($ScriptWorkingDirectory))
}

#region    Main
Try {
    # Troubleshooting info
    Write-Output -InputObject ('# Troubleshooting info')
    Write-Output -InputObject ('{0}Working directory:   "{1}"' -f ("`t",$ScriptWorkingDirectory))
    Write-Output -InputObject ('{0}Running as Username: "{1}"' -f ("`t",$ScriptRunningAsUserName))
    Write-Output -InputObject ('{0}Running as SID:      "{1}"' -f ("`t",$ScriptRunningAsUserSID))
    Write-Output -InputObject ('{0}Running as admin:    "{1}"' -f ("`t",$ScriptIsRunningAsAdmin.ToString()))
    Write-Output -InputObject ('{0}Is 64 bit OS?        "{1}"' -f ("`t",$ScriptIsRunningOn64Bit.ToString()))
    Write-Output -InputObject ('{0}Is 64 bit process?   "{1}"' -f ("`t",$ScriptIsRunningAs64Bit.ToString()))   


    # Fail proofing - Already installed
    if ($InstallVerifyPaths.ForEach{[System.IO.File]::Exists($_)} -contains $true) {
        $ExitCode = 10
        Throw ('ERROR - Already installed, default install path.')        
    }


    # Fail proofing - Already installed - Unknown location
    if ([bool]$([array]$(Get-Process -Name $ProcessName.Split('.')[0] -ErrorAction 'SilentlyContinue').'Count' -ge 1)) {
        $ExitCode = 11
        Throw ('ERROR - Already installed, non-default location: "{0}".' -f ([string]$(Get-Process -Name $ProcessName.Split('.')[0] | Select-Object -First 1 -ExpandProperty 'Path')))
    }


    # Remove installer if it exist
    if ([bool]$(-not([string]::IsNullOrEmpty($Destination))) -and [bool]$(Test-Path -Path $Destination)) {
        Write-Output -InputObject ('# Removing existing installer "{0}".' -f ($Destination))
        $null = Remove-Item -Path $Destination -Force -ErrorAction 'SilentlyContinue'
        if (-not$?) {
            $ExitCode = 12
            Throw ('ERROR - Did not manage to delete "{0}" before downlowding installer.' -f ($Destination))
        }
    }


    # Download - Use System.Net.WebClient
    Write-Output -InputObject ('# Downloading "{0}" ({1}).' -f ($ProductName,$Uri))
    $SuccessDownload = [bool]$(Try{[System.Net.WebClient]::new().DownloadFile($Uri,$Destination);$?}Catch{$false})
    if ((-not$?) -or (-not($SuccessDownload)) -or (-not(Test-Path -Path $Destination)) -or [bool]$([uint32]$((Get-Item -Path $Destination).'Length') -lt $UriExpectedMinimumSize)) {
        $ExitCode = 13
        Throw ('ERROR - Failed to download installer from "{0}".' -f ($Uri))
    }
    else {
        Write-Output -InputObject 'Success'
    }


    # Install
    Write-Output -InputObject ('# Installing "{0}"{1}Installer path: "{2}"{1}Argument list:  "{3}".' -f ($ProductName,"`r`n## ",$Destination,$ArgumentList))
    $InstallProcess = Start-Process -FilePath $Destination -ArgumentList $ArgumentList -WindowStyle 'Hidden' -Verb 'RunAs' -Wait -ErrorAction 'SilentlyContinue'


    # Check install success
    if ($? -and $InstallVerifyPaths.ForEach{[System.IO.File]::Exists($_)} -contains $true) {
        Write-Output -InputObject 'Success.'
    }
    else {
        $ExitCode = 14
        Throw ('ERROR - Installer failed: Could not verify that install path exist ("{0}").' -f ($InstallVerifyPath))
    }
}
Catch {
    # Make sure $ExitCode has a non-success value
    if ($ExitCode -eq 0){
        $ExitCode = 1
    }
    
    
    # Construct error message
    ## Generic content
    $ErrorMessage = [string] '{0}Catched error:' -f [System.Environment]::NewLine
    ## Last exit code if any
    if (-not[string]::IsNullOrEmpty($LASTEXITCODE)) {
        $ErrorMessage += [string] '{0}# Last exit code ($LASTEXITCODE):{0}{1}' -f [System.Environment]::NewLine, $LASTEXITCODE
    }
    ## Dynamically add info to the error message
    foreach ($ParentProperty in $_.GetType().GetProperties().'Name') {
        if ($_.$ParentProperty) {
            $ErrorMessage += [string] '{0}# {1}:' -f [System.Environment]::NewLine, $ParentProperty
            foreach ($ChildProperty in $_.$ParentProperty.GetType().GetProperties().'Name') {
                ### Build ErrorValue
                $ErrorValue = [string]::Empty
                if ($_.$ParentProperty.$ChildProperty -is [System.Collections.IDictionary]) {
                    foreach ($Name in [string[]]$($_.$ParentProperty.$ChildProperty.GetEnumerator().'Name')) {
                        if (-not[string]::IsNullOrEmpty([string]$($_.$ParentProperty.$ChildProperty.$Name))) {
                            $ErrorValue += [string] '{0} = {1}{2}' -f $Name, [string]$($_.$ParentProperty.$ChildProperty.$Name), [System.Environment]::NewLine
                        }
                    }
                }
                else {
                    $ErrorValue = [string]$($_.$ParentProperty.$ChildProperty)
                }
                if (-not[string]::IsNullOrEmpty($ErrorValue)) {
                    $ErrorMessage += [string] '{0}## {1}\{2}:{0}{3}' -f [System.Environment]::NewLine, $ParentProperty, $ChildProperty, $ErrorValue.Trim()
                }
            }
        }
    }
    # Write Error Message
    Write-Error -Message $ErrorMessage -ErrorAction 'Continue'
}
Finally {
    # Remove installer if it exist
    if ([bool]$(-not([string]::IsNullOrEmpty($Destination))) -and [bool]$(Test-Path -Path $Destination)) {
        Write-Output -InputObject ('# Removing existing installer "{0}".' -f ($Destination))
        $null = Remove-Item -Path $Destination -Force -ErrorAction 'SilentlyContinue'
        if (-not$?) {
            Write-Output -InputObject 'Failed'
            $ExitCode = 17
        }
    }
    
    # Stop Transcript (Logging)
    Stop-Transcript
    
    # Return Exit Code
    exit $ExitCode
}
#endregion Main
