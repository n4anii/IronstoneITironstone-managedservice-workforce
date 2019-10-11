#Requires -Version 5.1 -RunAsAdministrator
<#
    .NAME
        Device_Install-MozillaFirefox.ps1

    
    .SYNAPSIS
        Install latest Mozilla Firefox.


    .NOTES
        Author:   Olav Rønnestad Birkeland
        Version:  1.1.0.0
        Modified: 191008
        Created:  190709
        
        
        Run from Intune
            Install - x64 enUS                          
                "%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy "Bypass" -NoLogo -NonInteractive -NoProfile -WindowStyle "Hidden" -Command "& '.\Device_Install-MozillaFirefox.ps1' -Language 'en-US' -Architecture 'win64'; exit $LASTEXITCODE"
            Install - x64 enUS          
                "%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy "Bypass" -NoLogo -NonInteractive -NoProfile -WindowStyle "Hidden" -Command "& '.\Device_Install-MozillaFirefox.ps1' -Language 'nb-NO' -Architecture 'win64'; exit $LASTEXITCODE"
            Uninstall - x64
                "%ProgramW6432%\Mozilla Firefox\uninstall\helper.exe" -ms
            Uninstall - x86
                "%ProgramFiles(x86)%\Mozilla Firefox\uninstall\helper.exe" -ms
        
        Exit codes
            0  = Success.
            1  = Error - Failed, unknown reason.
            10 = Failproof - Can't install x64 Mozilla Firefox on x86 OS.
            11 = Failproof - Already installed, same architecture.
            12 = Failproof - Already installed, other architecture.
            13 = Failproof - Already installed, non-default location. Install path is mentioned in error message.
            14 = Error - Failed to remove existing installer before downloading new.
            15 = Error - Failed to download installer.
            16 = Error - Installer failed.
            17 = Error - Failed to remove installer after script is done.
        
        Get all available languages from Mozilla
            "'{0}'" -f ((Invoke-WebRequest -Uri 'https://download-installer.cdn.mozilla.net/pub/firefox/releases/69.0/win64/' | Select-Object -ExpandProperty 'Links' | Select-Object -ExpandProperty 'innerHTML' | `
                ForEach-Object -Process {$_.Replace('/','')} | Where-Object -FilterScript {$_ -notlike '*.*'} | Sort-Object) -join "','") | clip
#>


[CmdletBinding()]
Param (
    [Parameter(Mandatory = $true, Position = 0, HelpMessage = 'Language code matching what Mozilla uses. English (US) = "en-US". Case sensitive!')]
    [ValidateSet(IgnoreCase = $false,'ach','af','an','ar','ast','az','be','bg','bn','br','bs','ca','cak','cs','cy','da','de','dsb','el','en-CA','en-GB','en-US','eo','es-AR','es-CL','es-ES','es-MX','et','eu','fa','ff','fi','fr','fy-NL','ga-IE','gd','gl','gn','gu-IN','he','hi-IN','hr','hsb','hu','hy-AM','ia','id','is','it','ja','ka','kab','kk','km','kn','ko','lij','lt','lv','mk','mr','ms','my','nb-NO','ne-NP','nl','nn-NO','oc','pa-IN','pl','pt-BR','pt-PT','rm','ro','ru','si','sk','sl','son','sq','sr','sv-SE','ta','te','th','tr','uk','ur','uz','vi','xh','xpi','zh-CN','zh-TW')]    
    [string] $Language,

    [Parameter(Mandatory = $true, Position = 1, HelpMessage = 'Architecture code matching what Mozilla uses. x86 = "win", x64 = "win64". Case sensitive!')]
    [ValidateSet(IgnoreCase = $false,'win','win64')]
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
$ProductName            = [string]$('Mozilla Firefox {0}' -f ([string]$(if($Architecture -eq 'win'){'x86'}else{'x64'})))
$ProcessName            = [string]$('firefox.exe')
$Uri                    = [string]$('https://download.mozilla.org/?product=firefox-latest&os={0}&lang={1}' -f ($Architecture,$Language))
$UriExpectedMinimumSize = [uint32]$(40MB)
$Destination            = [string]$('{0}\Temp\FirefoxSetup.exe' -f ($env:SystemRoot))
$ArgumentList           = [string]$('-ms')
$InstallDirPath         = [string]$('{0}\Mozilla Firefox' -f ([string]$(if($Architecture -eq 'win'){${env:ProgramFiles(x86)}}else{$env:ProgramW6432})))
$InstallVerifyPath      = [string]$('{0}\{1}' -f ($InstallDirPath,$ProcessName))

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
    if ($Architecture -eq 'win64' -and -not [System.Environment]::Is64BitOperatingSystem) {
        $ExitCode = 10
        Throw ('ERROR - Cannot install "{0}" on a x86 OS.' -f ($ProductName))        
    }

    # Fail proofing - Already installed - Same Architecture
    if (Test-Path -Path $InstallVerifyPath) {
        $ExitCode = 11
        Throw ('ERROR - Already installed, same architecture as specified for this script, default install path.')        
    }

    # Fail proofing - Already installed - Different Architecture
    if ([bool]$(Test-Path -Path $InstallVerifyPath.Replace([string]$(if($Architecture -eq 'win'){${env:ProgramFiles(x86)}}else{$env:ProgramW6432}),[string]$(if($Architecture -eq 'win'){$env:ProgramW6432}else{${env:ProgramFiles(x86)}})))) {
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

    # Download - Use System.Net.WebClient
    Write-Output -InputObject ('# Downloading "{0}" ({1}).' -f ($ProductName,$Uri))
    $SuccessDownload = [bool]$(Try{[System.Net.WebClient]::new().DownloadFile($Uri,$Destination);$?}Catch{$false})
    if ((-not$?) -or (-not($SuccessDownload)) -or (-not(Test-Path -Path $Destination)) -or [bool]$([uint32]$(Get-Item -Path $Destination | Select-Object -ExpandProperty 'Length') -lt $UriExpectedMinimumSize)) {
        $ExitCode = 15
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
        $ExitCode = 16
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
            $ExitCode = 17
        }
    }
    
    # Stop Transcript (Logging)
    Stop-Transcript
    
    # Return Exit Code
    exit $ExitCode
}
#endregion Main