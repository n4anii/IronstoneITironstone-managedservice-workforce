#Requires -Version 5.1
<#
    .NAME
        Install-EXEorMIS.ps1


    .SYNAPSIS
        Installs a EXE or MSI from provided URL in system context by default, user context by input parameter switch.


    .NOTES
        Author:   Olav Rønnestad Birkeland
        Version:  1.0.1.0
        Modified: 200423
        Created:  200329

        Run from Intune
            Install
                "%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy "Bypass" -NoLogo -NonInteractive -NoProfile -WindowStyle "Hidden" -Command "& '.\Device_Install-GoogleChromeBrowser.ps1'; exit $LASTEXITCODE"
            Uninstall
                "%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy "Bypass" -NoLogo -NonInteractive -NoProfile -WindowStyle "Hidden" -Command "& '.\Device_Uninstall-GoogleChromeBrowser.ps1'; exit $LASTEXITCODE"

        Exit codes
            0  = Success.
            1  = Error - Failed, unknown reason.
            10 = Failproof - Already installed.
            11 = Error - Failed to remove existing installer before downloading new.
            12 = Error - Failed to download installer.
            13 = Error - Installer failed.
            14 = Error - Failed to remove installer after script is done.


    .EXAMPLE ConnectWise Automate Control Center
        & '.\Install-EXEorMSI.ps1' -ProductName 'ConnectWise Automate Control Center' -Uri 'https://ironstoneit.hostedrmm.com/LabTech/Updates/ControlCenterInstaller.exe' -InstallerType 'EXE' -InstallVerifyPath ('{0}\LabTech Client\LTClient.exe' -f (${env:ProgramFiles(x86)})) -ArgumentList ('/install /quiet /norestart /log "{0}\IronstoneIT\Intune\ClientApps\ConnectWise Automate Control Center -  Install Log {1}.txt"' -f ($env:ProgramData,[datetime]::Now.ToString('yyyyMMdd-HHmmss')))


    .EXAMPLE Google Chrome
        & '.\Install-EXEorMSI.ps1' -ProductName 'Google Chrome' -Uri 'https://dl.google.com/chrome/install/latest/chrome_installer.exe' -InstallerType 'EXE' -InstallVerifyPath ('{0}\Google\Chrome\Application\chrome.exe' -f (${env:ProgramFiles(x86)})) -ArgumentList '/silent /install'

   
    .EXAMPLE Lenovo System Interface Foundation
        & '.\Install-EXEorMSI.ps1' -ProductName 'Lenovo System Interface Foundation' -Uri 'https://filedownload.lenovo.com/enm/sift/core/SystemInterfaceFoundation.exe' -InstallerType 'EXE' -InstallVerifyPath ('{0}\ImController.InfInstaller.exe' -f ([System.Environment]::GetFolderPath('System'))) -ArgumentList '/SP- /VERYSILENT /NORESTART /SUPPRESSMSGBOXES /TYPE=installpackageswithreboot'
    

    .EXAMPLE Mozilla Firefox en-US
        & '.\Install-EXEorMSI.ps1' -ProductName 'Mozilla Firefox' -Uri 'https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=en-US' -InstallerType 'EXE' -InstallVerifyPath ('{0}\Mozilla Firefox\firefox.exe' -f ($env:ProgramW6432)) -ArgumentList '-ms'


    .EXAMPLE Microsoft Visual Studio Code
        & '.\Install-EXEorMSI.ps1' -ProductName 'Visual Studio Code' -Uri 'https://go.microsoft.com/fwlink/?Linkid=852157' -InstallerType 'EXE' -InstallVerifyPath ('{0}\Microsoft VS Code\Code.exe' -f ($env:ProgramW6432)) -ArgumentList '/VERYSILENT /NORESTART /NOCLOSEAPPLICATIONS /NORESTARTAPPLICATIONS /MERGETASKS=!runcode'

    
    .EXAMPLE Microsoft Visual Studio Code Insiders
        & '.\Install-EXEorMSI.ps1' -ProductName 'Visual Studio Code Insiders' -Uri 'https://go.microsoft.com/fwlink/?Linkid=852155' -InstallerType 'EXE' -InstallVerifyPath ('{0}\Microsoft VS Code Insiders\Code.exe' -f ($env:ProgramW6432)) -ArgumentList '/VERYSILENT /NORESTART /NOCLOSEAPPLICATIONS /NORESTARTAPPLICATIONS /MERGETASKS=!runcode'


    .EXAMPLE Microsoft Yammer (SYSTEM)
        & '.\Install-EXEorMSI.ps1' -ProductName 'Yammer' -Uri 'https://aka.ms/yammer_desktop_msi_x64' -InstallerType 'MSI' -InstallVerifyPath ('{0}\Yammer Installer\yammerdesktop.exe' -f (${env:ProgramFiles(x86)}))


    .EXAMPLE Microsoft Yammer (USER)
        & '.\Install-EXEorMSI.ps1' -ProductName 'Yammer' -Uri 'https://aka.ms/yammer_desktop_x64' -InstallerType 'EXE' -InstallVerifyPath ('{0}\yammerdesktop\Yammer.exe' -f ($env:LOCALAPPDATA)) -UserContext -ArgumentList '-s'
#>


# Input parameters
[CmdletBinding()]
[OutputType($null)]
Param(
    # Mandatory
    [Parameter(Mandatory = $true, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false)]
    [ValidateNotNullOrEmpty()]
    [string] $ProductName,

    [Parameter(Mandatory = $true, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false)]
    [ValidateNotNullOrEmpty()]
    [string] $Uri,

    [Parameter(Mandatory = $true, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false)]
    [ValidateSet('EXE','MSI')]
    [string] $InstallerType,

    [Parameter(Mandatory = $true, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false)]
    [ValidateNotNullOrEmpty()]
    [string] $InstallVerifyPath,    

    # Optional
    [Parameter(Mandatory = $false, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false)]
    [string] $ArgumentList,

    [Parameter(Mandatory = $false, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, HelpMessage = 'Whether to install to user context.')]
    [switch] $UserContext
)


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
$WhatIfPreference       = $false


# Script variables
$ScriptWorkingDirectory      = [string]$(if([string]::IsNullOrEmpty($PSScriptRoot)){[System.IO.Directory]::GetParent($($MyInvocation.'MyCommand'.'Path',$psISE.'CurrentFile'.'FullPath').Where{-not[string]::IsNullOrEmpty($_)}[0]).'FullName'}else{$PSScriptRoot})
$ScriptName                  = [string]($([string[]]($psISE.'CurrentFile'.'DisplayName',$MyInvocation.'MyCommand'.'Name')).Where{-not[string]::IsNullOrEmpty($_)}[0].Replace('.ps1',''))
$ScriptIsRunningAsAdmin      = [bool](([System.Security.Principal.WindowsPrincipal]$([System.Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator))
$ScriptIsRunningOn64Bit      = [bool]([System.Environment]::Is64BitOperatingSystem)
$ScriptIsRunningAs64Bit      = [bool]([System.Environment]::Is64BitProcess)
$ScriptRunningAsArchitecture = [string]$(if([System.Environment]::Is64BitProcess){'64'}else{'86'})
$ScriptRunningAsUserSID      = [string]([System.Security.Principal.WindowsIdentity]::GetCurrent().'User'.'Value')
$ScriptRunningAsUserName     = [string]([System.Security.Principal.WindowsIdentity]::GetCurrent().'Name')


# Product specific variables
$UriExpectedMinimumSize = [uint32](300KB)
$InstallDirPath         = [string]([System.IO.Directory]::GetParent($InstallVerifyPath))
$Destination            = [string]('{0}\Temp\{1}Setup.{2}' -f ($env:SystemRoot,$ProductName.Replace(' ',''),$InstallerType))
$ArgumentList           = [string]$(if($InstallerType -eq 'EXE'){$ArgumentList}else{('/i "{0}" /qn /norestart {1}' -f ($Destination,$ArgumentList))})


# Logging
## Attributes
$ExitCode    = [byte]$(0)
$PathDirLog  = [string]$('{0}\IronstoneIT\Intune\ClientApps' -f ($env:ProgramData))
$PathFileLog = [string]$(
    '{0}\{1}-{2}-Install-{3}-x{4}-{5}Context.txt' -f (
        $PathDirLog,
        $ScriptName,
        $ProductName.Replace(' ','_'),
        [datetime]::Now.ToString('yyyyMMdd-HHmmssffff'),
        $ScriptRunningAsArchitecture,
        [string]$(if($UserContext){'User'}else{'System'})
    )
)
## Create log path if not exist
if (-not(Test-Path -Path $PathDirLog -ErrorAction 'Stop')) {$null = New-Item -Path $PathDirLog -ItemType 'Directory' -ErrorAction 'Stop'}
## Start Transcript (Logging)
Start-Transcript -Path $PathFileLog -Force -ErrorAction 'Stop'


# Failproof - Make sure
## We're running
### Current context
if ($UserContext) {
    if ($ScriptRunningAsUserSID -eq 'S-1-5-18') {
        Write-Error -Message '$UserContext specified, and script is running as NT AUTHORITY\SYSTEM.'
    }
}
else {
    if (-not $ScriptIsRunningAsAdmin) {
        Write-Error -Message '$UserContext is not specified, and script is not running as administrator.'
    }
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
    if (Test-Path -Path $InstallVerifyPath) {
        $ExitCode = 10
        Throw ('ERROR - Already installed.')        
    }


    # Remove installer if it exist
    if ([bool]$(-not([string]::IsNullOrEmpty($Destination))) -and [bool]$(Test-Path -Path $Destination)) {
        Write-Output -InputObject ('# Removing existing installer "{0}".' -f ($Destination))
        $null = Remove-Item -Path $Destination -Force -ErrorAction 'SilentlyContinue'
        if (-not$?) {
            $ExitCode = 11
            Throw ('ERROR - Did not manage to delete "{0}" before downlowding installer.' -f ($Destination))
        }
    }


    # Download - Use System.Net.WebClient
    Write-Output -InputObject ('# Downloading "{0}" ({1}).' -f ($ProductName,$Uri))
    $SuccessDownload = [bool]$(Try{[System.Net.WebClient]::new().DownloadFile($Uri,$Destination);$?}Catch{$false})
    if ((-not$?) -or (-not($SuccessDownload)) -or (-not(Test-Path -Path $Destination)) -or [bool]$([uint32]$(Get-Item -Path $Destination | Select-Object -ExpandProperty 'Length') -lt $UriExpectedMinimumSize)) {
        $ExitCode = 12
        Throw ('ERROR - Failed to download installer from "{0}".' -f ($Uri))
    }
    else {
        Write-Output -InputObject 'Success'
    }


    # Install    
    if ($InstallerType -eq 'EXE') {
        Write-Output -InputObject ('# Installing "{0}"{1}Installer path: "{2}"{1}Argument list:  "{3}".' -f ($ProductName,"`r`n## ",$Destination,$ArgumentList))
        $InstallProcess = Start-Process -FilePath $Destination -ArgumentList $ArgumentList -WindowStyle 'Hidden' -Verb 'RunAs' -Wait -ErrorAction 'SilentlyContinue'
    }
    else {
        $PathMsiExec = [string]('{0}\msiexec.exe' -f ([System.Environment]::GetFolderPath('System')))
        Write-Output -InputObject ('# Installing "{0}"{1}Installer path: "{2}"{1}Argument list:  "{3}".' -f ($ProductName,"`r`n## ",$PathMsiExec,$ArgumentList))
        $InstallProcess = Start-Process -FilePath ('{0}\msiexec.exe' -f ([System.Environment]::GetFolderPath('System'))) -ArgumentList $ArgumentList -WindowStyle 'Hidden' -Verb 'RunAs' -Wait -ErrorAction 'SilentlyContinue'
    }
        

    # Check install success
    if ($? -and [bool]$(Test-Path -Path $InstallVerifyPath)) {
        Write-Output -InputObject 'Success.'
    }
    else {
        $ExitCode = 13
        Throw ('ERROR - Installer failed: Could not verify that install path exist ("{0}").' -f ($InstallVerifyPath))
    }
}
Catch {
    # Make sure $ExitCode has a non-success value
    if ($ExitCode -eq 0){$ExitCode = 1}
    # Construct error message
    ## Generic content
    $ErrorMessage = [string]$('{0}Finished with errors:' -f ("`r`n"))    
    $ErrorMessage += [string]$('{0}# Script exit code (defined in script):{0}{1}' -f ("`r`n",$ExitCode.ToString()))
    ## Last exit code
    if (-not[string]::IsNullOrEmpty($LASTEXITCODE)) {
        $ErrorMessage += ('{0}# Last exit code ($LASTEXITCODE):{0}{1}' -f ("`r`n",$LASTEXITCODE))
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
            $ExitCode = 14
        }
    }
    
    # Stop Transcript (Logging)
    Stop-Transcript        
}
#endregion Main


# Exit script with exit code
exit $ExitCode
