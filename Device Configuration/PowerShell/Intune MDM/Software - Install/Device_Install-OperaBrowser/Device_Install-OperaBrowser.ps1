#Requires -Version 5.1 -RunAsAdministrator
<#
    .NAME
        Device_Install-OperaBrowser.ps1


    .SYNAPSIS
        Installs latest Opera Browser.


    .NOTES
        Author:   Olav Rønnestad Birkeland
        Version:  1.0.0.0
        Modified: 191009
        Created:  191009

        Run from Intune
            Install - x64
                "%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy "Bypass" -NoLogo -NonInteractive -NoProfile -WindowStyle "Hidden" -Command "& '.\Device_Install-OperaBrowser.ps1' -Architecture 'x64'; exit $LASTEXITCODE"
            Install - x86
                "%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy "Bypass" -NoLogo -NonInteractive -NoProfile -WindowStyle "Hidden" -Command "& '.\Device_Install-OperaBrowser.ps1' -Architecture 'x86'; exit $LASTEXITCODE"
            Uninstall - x64
                "%ProgramW6432%\Opera\Launcher.exe" /uninstall /silent
            Uninstall - x86
                "%ProgramFiles(x86)%\Opera\Launcher.exe" /uninstall /silent

        Exit codes
            0  = Success.
            1  = Error - Failed, unknown reason.
            10 = Failproof - Can't install x64 Mozilla Firefox on x86 OS.
            11 = Failproof - Already installed, same architecture.
            12 = Failproof - Already installed, other architecture.
            13 = Failproof - Already installed, non-default location. Install path is mentioned in error message.
            14 = Error - Failed to remove existing installer before downloading new.
            15 = Error - Failed to fetch available versions.
            16 = Error - Failed to download installer.
            16 = Error - Installer failed.
            17 = Error - Failed to remove installer after script is done.
#>


[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true)]
    [ValidateSet(IgnoreCase = $false,'x86','x64')]
    [string] $Architecture
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

# Script variables
$ScriptWorkingDirectory      = [string]$([string]$($MyInvocation.'MyCommand'.'Path').Replace(('\{0}' -f ($MyInvocation.'MyCommand'.'Name')),''))
$ScriptIsRunningAsAdmin      = [bool]$(([System.Security.Principal.WindowsPrincipal]$([System.Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator))
$ScriptIsRunningOn64Bit      = [bool]$([System.Environment]::Is64BitOperatingSystem)
$ScriptIsRunningAs64Bit      = [bool]$([System.Environment]::Is64BitProcess)
$ScriptRunningAsArchitecture = [string]$(if([System.Environment]::Is64BitProcess){'64'}else{'86'})
$ScriptRunningAsUserSID      = [string]$([System.Security.Principal.WindowsIdentity]::GetCurrent().'User'.'Value')
$ScriptRunningAsUserName     = [string]$([System.Security.Principal.WindowsIdentity]::GetCurrent().'Name')

# Product specific variables
$ProductName            = [string]$('Opera Browser {0}' -f ([string]$(if($Architecture -eq 'x86'){'x86'}else{'x64'})))
$ProcessName            = [string]$('opera.exe')
$Uri                    = [string]$('https://get.opera.com/ftp/pub/opera/desktop')
$UriExpectedMinimumSize = [uint32]$(40MB)
$Destination            = [string]$('{0}\Temp\OperaSetup.exe' -f ($env:SystemRoot))
$ArgumentList           = [string]$('/silent /norestart /allusers=1 /desktopshortcut=1 /launchbrowser=0 /pintotaskbar=0 /quicklaunchshortcut=0 /setdefaultbrowser=0 /startmenushortcut=1')
$InstallDirPath         = [string]$('{0}\Opera' -f ([string]$(if($Architecture -eq 'win'){${env:ProgramFiles(x86)}}else{$env:ProgramW6432})))
$InstallVerifyPath      = [string]$('{0}\launcher.exe' -f ($InstallDirPath))

# Logging
## Attributes
$ExitCode    = [byte]$(0)
$PathDirLog  = [string]$('{0}\IronstoneIT\Intune\ClientApps\Install' -f ($env:ProgramData))
$PathFileLog = [string]$('{0}\{1}-Install-{2}-x{3}.txt' -f ($PathDirLog,$ProductName.Replace(' ','_'),[datetime]::Now.ToString('yyyyMMdd-HHmmssffff'),$ScriptRunningAsArchitecture))
## Create log path if not exist
if (-not(Test-Path -Path $PathDirLog -ErrorAction 'Stop')) {$null = New-Item -Path $PathDirLog -ItemType 'Directory' -ErrorAction 'Stop'}
## Start Transcript (Logging)
Start-Transcript -Path $PathFileLog -Force -ErrorAction 'Stop'

# Make sure we're running
## As admin
if (-not $ScriptIsRunningAsAdmin) {Write-Error -Message 'Not running as administrator.'}
## As 64 bit
if (-not [bool]$($ScriptIsRunningOn64Bit -and $ScriptIsRunningAs64Bit)) {Write-Error -Message 'Not running as 64 bit process on a 64 bit operating system.'}

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

    # Fail proofing - Correct architecture
    if ($Architecture -eq 'x64' -and -not [System.Environment]::Is64BitOperatingSystem) {
        $ExitCode = 10
        Throw ('ERROR - Cannot install "{0}" on a x86 OS.' -f ($ProductName))
    }

    # Fail proofing - Already installed - Same Architecture
    if (Test-Path -Path $InstallVerifyPath) {
        $ExitCode = 11
        Throw ('ERROR - Already installed, same architecture as specified for this script, default install path.')
    }

    # Fail proofing - Already installed - Different Architecture
    if ([bool]$(Test-Path -Path $InstallVerifyPath.Replace([string]$(if($Architecture -eq 'x86'){${env:ProgramFiles(x86)}}else{$env:ProgramW6432}),[string]$(if($Architecture -eq 'x86'){$env:ProgramW6432}else{${env:ProgramFiles(x86)}})))) {
        $ExitCode = 12
        Throw ('ERROR - Already installed, different architecture than specified for this script, default install path')
    }

    # Fail proofing - Already installed - Unknown location
    if ([bool]$([array]$(Get-Process -Name $ProcessName.Split('.')[0] -ErrorAction 'SilentlyContinue').'Count' -ge 1)) {
        $ExitCode = 13
        Throw ('ERROR - Already installed, non-default location: "{0}".' -f ([string]$(Get-Process -Name $ProcessName.Split('.')[0] | Select-Object -First 1 -ExpandProperty 'Path')))
    }

    # Remove installer if it exist
    if ([bool]$(-not([string]::IsNullOrEmpty($Destination))) -and [bool]$(Test-Path -Path $Destination)) {
        Write-Output -InputObject ('# Removing existing installer "{0}".' -f ($Destination))
        $null = Remove-Item -Path $Destination -Force -ErrorAction 'SilentlyContinue'
        if (-not$?) {
            $ExitCode = 14
            Throw ('ERROR - Did not manage to delete "{0}" before downlowding installer.' -f ($Destination))
        }
    }

    # Download
    Write-Output -InputObject ('# Downloading "{0}".' -f ($ProductName,$Uri))
    ## Fetch available versions
    Write-Output -InputObject ('## Fetch available versions.')    
    $ContentString = [string]$(Try{$Temp=[string]$([System.Net.WebClient]::new().DownloadString($Uri));if($?){$Temp}else{''}}Catch{''})
    $Versions      = [System.Version[]]$($ContentString.Split([System.Environment]::NewLine).Foreach{$_.Replace(' ','')}.Where{-not[string]::IsNullOrEmpty($_)}.Foreach{$Line=$_.Split('/')[0].Split('"')[-1];if([bool]$(Try{$Line=[System.Version]$($Line);$?}Catch{$false})){$Line}} | Sort-Object -Descending)
    if ($Versions.'Count' -lt 10) {
        $Versions = [System.Version[]]$(
            Try{
                $Temp = [System.Version[]]$([System.Version[]]$(Invoke-WebRequest -Uri $Uri -ErrorAction 'SilentlyContinue' | `
                    Select-Object -ExpandProperty 'Links' | Select-Object -ExpandProperty 'innerHTML' | `
                    ForEach-Object -Process {$_.Replace('/','')} | Where-Object -FilterScript {$_ -notlike '*..*'}) | Sort-Object -Descending
                )
                if($?){$Temp}else{$null}
            }
            Catch{$null}
        )
    }
    if ($Versions.'Count' -lt 10) {
        $ExitCode = 15
        Throw ('ERROR - Failed to fetch available versions from "{0}".' -f ($Uri))
    }
    else {
        Write-Output -InputObject 'Success'
    }
    ## Download
    Write-Output -InputObject ('## Download')
    $UriArchitecture = [string]$(if($Architecture -eq 'x64'){'_x64'}else{''})
    $Index = [byte]$(0)
    do {
        # Remove file if already exist
        if(Test-Path -Path $Destination){$null=Remove-Item -Path $Destination -Force}
        # Create Uri
        $UriDownload = [string]$('{0}/{1}/win/Opera_{1}_Setup{2}.exe' -f ($Uri,$Versions[$Index].ToString(),$UriArchitecture))        
        # Try to download
        $SuccessDownload = [bool]$(Try{[System.Net.WebClient]::new().DownloadFile($UriDownload,$Destination);$?}Catch{$false})
        # If $SuccessDownload, make sure downloaded files is at least $UriExpectedMinimumSize.
        if ($SuccessDownload) {$SuccessDownload = [bool]$([uint32]$(Get-Item -Path $Destination | Select-Object -ExpandProperty 'Length') -gt $UriExpectedMinimumSize)}
        # If not $SuccessDownload, try again.
        if (-not$SuccessDownload){$Index++}    
    } while (-not$SuccessDownload -and $Index -lt 8)
    ## Check success
    if (-not$SuccessDownload) {
        $ExitCode = 16
        Throw ('ERROR - Failed to download installer from "{0}".' -f ($Uri))
    }
    else {
        Write-Output -InputObject 'Success'
    }

    # Install
    Write-Output -InputObject ('# Installing "{0}"{1}Installer path: "{2}"{1}Argument list:  "{3}".' -f ($ProductName,"`r`n## ",$Destination,$ArgumentList))
    $InstallProcess = Start-Process -FilePath $Destination -ArgumentList $ArgumentList -WindowStyle 'Hidden' -Verb 'RunAs' -Wait -ErrorAction 'SilentlyContinue'

    # Check install success
    if ($? -and [bool]$(Test-Path -Path $InstallVerifyPath)) {
        Write-Output -InputObject 'Success.'
    }
    else {
        $ExitCode = 17
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
    $ErrorMessage += [string]$('{0}# Exception:{0}{1}' -f ("`r`n",$_.'Exception'))
    ## Dynamically add info to the error message
    foreach ($ParentProperty in [string[]]$($_ | Get-Member -MemberType 'Property' | Select-Object -ExpandProperty 'Name')) {
        if ($_.$ParentProperty) {
            $ErrorMessage += ('{0}# {1}:' -f ("`r`n",$ParentProperty))
            foreach ($ChildProperty in [string[]]$($_.$ParentProperty | Get-Member -MemberType 'Property' | Select-Object -ExpandProperty 'Name')) {
                ### Build ErrorValue
                $ErrorValue = [string]::Empty
                if ($_.$ParentProperty.$ChildProperty -is [System.Collections.IDictionary]) {
                    foreach ($Name in [string[]]$($_.$ParentProperty.$ChildProperty.GetEnumerator().'Name')) {
                        $ErrorValue += ('{0} = {1}{2}' -f ($Name,[string]$($_.$ParentProperty.$ChildProperty.$Name),"`r`n"))
                    }
                }
                else {
                    $ErrorValue = [string]$($_.$ParentProperty.$ChildProperty)
                }
                if (-not[string]::IsNullOrEmpty($ErrorValue)) {
                    $ErrorMessage += ('{0}## {1}\{2}:{0}{3}' -f ("`r`n",$ParentProperty,$ChildProperty,$ErrorValue.Trim()))
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
            $ExitCode = 18
        }
    }
    
    # Stop Transcript (Logging)
    Stop-Transcript
    
    # Return Exit Code
    exit $ExitCode
}
#endregion Main