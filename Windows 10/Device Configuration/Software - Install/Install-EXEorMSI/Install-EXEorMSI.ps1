#Requires -Version 5.1
<#
    .NAME
        Install-EXEorMIS.ps1


    .SYNAPSIS
        Installs a EXE or MSI from provided URL in system context by default, user context by input parameter switch.


    .NOTES
        Author:   Olav Rønnestad Birkeland
        Version:  1.0.2.1        
        Modified: 200812
        Created:  200423
        
        Exit codes
            0  = Success.
            1  = Error - Failed, unknown reason.
            10 = Failproof - Running in wrong context (user vs system).
            11 = Failproof - Running as x86 process on x64 OS.
            12 = Failproof - Working directory dynamically fetched does not exist.
            13 = Failproof - Already installed.
            20 = Error - Failed to remove existing installer before downloading new.
            21 = Error - Failed to download installer.            
            22 = Error - Installer failed.
            23 = Error - Installer succeeded, but $InstallVerifyPath does not exist.
            24 = Error - Failed to remove installer after script is done.  
#>



# Input parameters
[CmdletBinding()]
[OutputType($null)]
Param(
    # Mandatory
    [Parameter(Mandatory = $true, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, HelpMessage = 'Name of the product to install, used for logging.')]
    [ValidateNotNullOrEmpty()]
    [string] $ProductName,

    [Parameter(Mandatory = $true, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, HelpMessage = 'URL to the installer.')]
    [ValidateNotNullOrEmpty()]
    [string] $Uri,

    [Parameter(Mandatory = $true, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, HelpMessage = 'MSI or EXE installer.')]
    [ValidateSet('EXE','MSI')]
    [string] $InstallerType,
    
    # Optional    
    [Parameter(Mandatory = $false, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, HelpMessage = 'Install arguments. For MSI, "/i" and "/qn" is already specified in script.')]
    [string] $ArgumentList,

    [Parameter(Mandatory = $false, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, HelpMessage = 'Whether to install to user context.')]
    [switch] $UserContext,

    [Parameter(Mandatory = $false, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, HelpMessage = 'Path to verify that install was successfull.')]
    [string] $InstallVerifyPath
)



# Settings - PowerShell
## Output Preferences
$DebugPreference        = 'SilentlyContinue'
$VerbosePreference      = $(if(-not$([bool]$($PSCmdlet.'MyInvocation'.'BoundParameters'['Verbose'].'IsPresent'))){'SilentlyContinue'})
$WarningPreference      = 'Continue'
## Interaction
$ConfirmPreference      = 'None'
$InformationPreference  = 'SilentlyContinue'
$ProgressPreference     = 'SilentlyContinue'
## Behaviour
$ErrorActionPreference  = 'Stop'
$WhatIfPreference       = $false



# If OS is 64 bit and PowerShell got launched as x86, relaunch as x64
if ([System.Environment]::Is64BitOperatingSystem -and -not [System.Environment]::Is64BitProcess) {
    Write-Output -InputObject (' * Will restart this PowerShell session as x64.')
    if (-not([string]::IsNullOrEmpty($MyInvocation.'Line'))) {
        & ('{0}\sysnative\WindowsPowerShell\v1.0\powershell.exe' -f ($env:windir)) -NonInteractive -NoProfile $MyInvocation.'Line'
    }
    else {
        & ('{0}\sysnative\WindowsPowerShell\v1.0\powershell.exe' -f ($env:windir)) -NonInteractive -NoProfile -File ('{0}' -f ($MyInvocation.'InvocationName')) $args
    }
    exit $LASTEXITCODE
}



# Script variables
$ScriptWorkingDirectory      = [string]$(if([string]::IsNullOrEmpty($PSScriptRoot)){[System.IO.Directory]::GetParent($($MyInvocation.'MyCommand'.'Path',$psISE.'CurrentFile'.'FullPath').Where{-not[string]::IsNullOrEmpty($_)}[0]).'FullName'}else{$PSScriptRoot})
$ScriptName                  = [string]($([string[]]($psISE.'CurrentFile'.'DisplayName',$MyInvocation.'MyCommand'.'Name')).Where{-not[string]::IsNullOrEmpty($_)}[0].Replace('.ps1',''))
$ScriptIsRunningAsAdmin      = [bool](([System.Security.Principal.WindowsPrincipal]$([System.Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator))
$ScriptRunningAsArchitecture = [string]$(if([System.Environment]::Is64BitProcess){'64'}else{'86'})
$ScriptRunningAsUserSID      = [string]([System.Security.Principal.WindowsIdentity]::GetCurrent().'User'.'Value')
$ScriptRunningAsUserName     = [string]([System.Security.Principal.WindowsIdentity]::GetCurrent().'Name')



# Product specific variables
$UriExpectedMinimumSize = [uint32](300KB)
$InstallDirPath         = [string]$(if($InstallVerifyPath){[System.IO.Directory]::GetParent($InstallVerifyPath)}else{''})
$Destination            = [string]('{0}\Temp\{1}Setup.{2}' -f ($env:SystemRoot,$ProductName.Replace(' ',''),$InstallerType))
$ArgumentList           = [string]$(if($InstallerType -eq 'EXE'){$ArgumentList}else{('/i "{0}" /qn /norestart {1}' -f ($Destination,$ArgumentList))})



# Logging
## Attributes
$ExitCode    = [byte](0)
$PathFileLog = [string](
    '{0}\IronstoneIT\Logs\ClientApps\{1}-{2}-Install-{3}-x{4}-{5}Context.txt' -f (
        $env:ProgramData,      
        $ScriptName,
        $ProductName.Replace(' ','_'),
        [datetime]::Now.ToString('yyyyMMdd-HHmmssffff'),
        $ScriptRunningAsArchitecture,
        [string]$(if($UserContext){'User'}else{'System'})
    )
)
$PathDirLog = [string][System.IO.Directory]::GetParent($PathFileLog).'FullName'
## Create log path if not exist
if (-not [System.IO.Directory]::Exists($PathDirLog)) {
    $null = [System.IO.Directory]::CreateDirectory($PathDirLog)
}
## Start Transcript (Logging)
Start-Transcript -Path $PathFileLog -Force -ErrorAction 'Stop'



#region    Main
Try {
    # Troubleshooting info
    Write-Output -InputObject ('# Troubleshooting info')
    Write-Output -InputObject ('{0}Working directory:   "{1}"' -f ("`t",$ScriptWorkingDirectory))
    Write-Output -InputObject ('{0}Running as Username: "{1}"' -f ("`t",$ScriptRunningAsUserName))
    Write-Output -InputObject ('{0}Running as SID:      "{1}"' -f ("`t",$ScriptRunningAsUserSID))
    Write-Output -InputObject ('{0}Running as admin:    "{1}"' -f ("`t",$ScriptIsRunningAsAdmin.ToString()))
    Write-Output -InputObject ('{0}Is 64 bit OS?        "{1}"' -f ("`t",[System.Environment]::Is64BitOperatingSystem.ToString()))
    Write-Output -InputObject ('{0}Is 64 bit process?   "{1}"' -f ("`t",[System.Environment]::Is64BitProcess.ToString()))   


    # Fail proofing
    ## Correct context
    if ($UserContext) {
        if ($ScriptRunningAsUserSID -eq 'S-1-5-18') {
            $ExitCode = 10
            Throw '$UserContext specified, and script is running as NT AUTHORITY\SYSTEM.'
        }
    }
    else {
        if (-not $ScriptIsRunningAsAdmin) {
            $ExitCode = 10
            Throw '$UserContext is not specified, and script is not running as administrator.'
        }
    }
    ## 64 bit process on a 64 bit OS
    ### Make sure we're running as 64 bit now
    if ([System.Environment]::Is64BitOperatingSystem -and -not [System.Environment]::Is64BitProcess) {
        $ExitCode = 11
        Throw 'Not running as 64 bit process on a 64 bit operating system.'
    }
    ### $ScriptWorkingDirectory is real
    if ([string]::IsNullOrEmpty($ScriptWorkingDirectory) -or -not [bool]$(Test-Path -Path $ScriptWorkingDirectory -ErrorAction 'SilentlyContinue')) {
        $ExitCode = 12
        Write-Error -Message ('$ScriptWorkingDirectory is either empty or does not exist ("{0}").' -f ($ScriptWorkingDirectory))
    }
    ## Already installed
    if ($InstallVerifyPath -and (Test-Path -Path $InstallVerifyPath)) {
        $ExitCode = 13
        Throw ('ERROR - Already installed.')        
    }


    # Remove installer if it exist
    if ([bool]$(-not([string]::IsNullOrEmpty($Destination))) -and [bool]$(Test-Path -Path $Destination)) {
        Write-Output -InputObject ('# Removing existing installer "{0}".' -f ($Destination))
        $null = Remove-Item -Path $Destination -Force -ErrorAction 'SilentlyContinue'
        if (-not$?) {
            $ExitCode = 20
            Throw ('ERROR - Did not manage to delete "{0}" before downlowding installer.' -f ($Destination))
        }
    }


    # Download - Use System.Net.WebClient
    Write-Output -InputObject ('# Downloading "{0}" ({1}).' -f ($ProductName,$Uri))
    ## Try with .NET WebClient
    $SuccessDownload = [bool]$(Try{[System.Net.WebClient]::new().DownloadFile($Uri,$Destination);$?}Catch{$false})
    ## If fail, try with BITS
    if (-not $? -or -not $SuccessDownload) {
        if ([System.IO.File]::Exists($Destination)) {
            $null = [System.IO.File]::Delete($Destination)
        }
        $SuccessDownload = [bool]$(Try{$null = Start-BitsTransfer -Source $Uri -Destination $Destination;$?}Catch{$false})
    }
    ## If fail, exit script
    if ((-not $?) -or (-not $SuccessDownload) -or (-not(Test-Path -Path $Destination)) -or [bool]$([uint32]$(Get-Item -Path $Destination | Select-Object -ExpandProperty 'Length') -lt $UriExpectedMinimumSize)) {
        $ExitCode = 21
        Throw ('ERROR - Failed to download installer from "{0}".' -f ($Uri))
    }
    else {
        Write-Output -InputObject 'Success'
    }


    # Install    
    if ($InstallerType -eq 'EXE') {
        Write-Output -InputObject ('# Installing "{0}"{1}Installer path: "{2}"{1}Argument list:  "{3}".' -f ($ProductName,"`r`n## ",$Destination,$ArgumentList))
        $InstallProcess = if ([string]::IsNullOrEmpty($ArgumentList)) {
             Start-Process -FilePath $Destination -WindowStyle 'Hidden' -Verb 'RunAs' -Wait -ErrorAction 'SilentlyContinue'
        }
        else {
            Start-Process -FilePath $Destination -ArgumentList $ArgumentList -WindowStyle 'Hidden' -Verb 'RunAs' -Wait -ErrorAction 'SilentlyContinue'
        }
    }
    else {
        $PathMsiExec = [string]('{0}\msiexec.exe' -f ([System.Environment]::GetFolderPath('System')))
        Write-Output -InputObject ('# Installing "{0}"{1}Installer path: "{2}"{1}Argument list:  "{3}".' -f ($ProductName,"`r`n## ",$PathMsiExec,$ArgumentList))
        $InstallProcess = if ([string]::IsNullOrEmpty($ArgumentList)) {
            Start-Process -FilePath ('{0}\msiexec.exe' -f ([System.Environment]::GetFolderPath('System'))) -WindowStyle 'Hidden' -Verb 'RunAs' -Wait -ErrorAction 'SilentlyContinue'
        }
        else {        
            Start-Process -FilePath ('{0}\msiexec.exe' -f ([System.Environment]::GetFolderPath('System'))) -ArgumentList $ArgumentList -WindowStyle 'Hidden' -Verb 'RunAs' -Wait -ErrorAction 'SilentlyContinue'
        }
    }
       

    # Check install success
    if ($?) {
        if ($InstallVerifyPath) {
            if (Test-Path -Path $InstallVerifyPath) {
                Write-Output -InputObject 'Success.'
            }
            else {
                $ExitCode = 23
                Throw ('ERROR - Installer failed: Could not verify that install path exist ("{0}").' -f ($InstallVerifyPath))
            }
        }
        else {
            Write-Output -InputObject 'Success.'
        }
    }
    else {
        $ExitCode = 22
        Throw ('ERROR - Installer did not exit successfully.')
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
}
Finally {
    # Remove installer if it exist
    if ([bool]$(-not([string]::IsNullOrEmpty($Destination))) -and [bool]$(Test-Path -Path $Destination)) {
        Write-Output -InputObject ('# Removing existing installer "{0}".' -f ($Destination))
        $null = Remove-Item -Path $Destination -Force -ErrorAction 'SilentlyContinue'
        if (-not$?) {
            Write-Output -InputObject 'Failed'
            $ExitCode = 24
        }
    }
    
    # Stop Transcript (Logging)
    Stop-Transcript        
}
#endregion Main


# Exit script with exit code
exit $ExitCode
