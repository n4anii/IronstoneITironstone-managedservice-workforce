<#
    Error Codes
        600 = Paths to directories can't be found
        601 = Paths to programs can't be found
        602 = Installed version is not equal or newer to required version
        603 = Required services are not running
        604 = Required processes are not running
        605 = Firewall block traffic on one of the required ports outbound

    Run From Intune Win32
        "%windir%\sysnative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy Bypass -NoLogo -NonInteractive -NoProfile -WindowStyle Hidden -File ".\Install.ps1"
#>



# Settings
$DebugPreference       = 'Continue'
$VerbosePreference     = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'
$InformationPreference = 'SilentlyContinue'
$ProgressPreference    = 'SilentlyContinue'



# Install MSI
if (-not(Test-Path -Path ('{0}\LTSvc\databases' -f ($env:windir)))) {
    $PathMsiExec        = [string]$('{0}\System32\msiexec.exe' -f ($env:windir))
    $PathDirInvocation  = [string]$([string]$($MyInvocation.'InvocationName').Replace(('\{0}' -f ($MyInvocation.'MyCommand')),''))
    $PathAgentInstaller = [string]$('{0}\Agent_Install.MSI' -f ($PathDirInvocation))
    $PathLogFile        = [string]$('{0}\IronstoneIT\Intune\ClientApps\ConnectWise Automate Agent Install\InstallLog_{1}.txt' -f ($env:ProgramW6432,[datetime]::Now.ToString('yyyyMMdd-hhmmssffff')))
    Start-Process -FilePath $PathMsiExec -ArgumentList ('/package "{0}" /qn /norestart /l*v "{1}"' -f ($PathAgentInstaller,$PathLogFile)) -Wait
}



# Paths to directories
foreach ($Path in [string[]]$(('{0}\LTSvc' -f ($env:windir)),('{0}\ScreenConnect Client (*)' -f (${env:ProgramFiles(x86)})))) {
    if ([bool]$([string[]]$(Get-Item -Path $Path -ErrorAction 'SilentlyContinue' -Debug:$false | Select-Object -ExpandProperty 'Name' -ErrorAction 'SilentlyContinue').'Count' -le 0)) {
        Write-Debug -Verbose ('Could not find path "{0}".' -f ($Path))
        exit 600        
    }
}



# Paths to programs
$PathFileScreenConnectClientService = [string]$(Get-Item -Path ('{0}\ScreenConnect Client (*)' -f (${env:ProgramFiles(x86)})) | Select-Object -ExpandProperty 'FullName')
foreach ($Path in [string[]]$(('{0}\LTSvc\LTSVC.exe' -f ($env:windir)),('{0}\ScreenConnect.ClientService.exe' -f ($PathFileScreenConnectClientService)))) {
    if ([bool]$([string[]]$(Get-Item -Path $Path -ErrorAction 'SilentlyContinue' -Debug:$false | Select-Object -ExpandProperty 'Name' -ErrorAction 'SilentlyContinue').'Count' -le 0)) {
        Write-Debug -Verbose ('Could not find path "{0}".' -f ($Path))
        exit 601        
    }
}



# Version - Automate
$VersionRequired = [System.Version]$('190.78.7003.30430')
if ([System.Version]$($VersionRequired) -gt [System.Version]$(Get-ItemProperty -Path ('{0}\LTSvc\LTSVC.exe' -f ($env:windir)) | Select-Object -ExpandProperty 'VersionInfo' | Select-Object -ExpandProperty 'FileVersion')) {
    Write-Debug -Verbose ('Version is not equal or newer to the required version "{0}".' -f ($VersionRequired.ToString()))
    exit 602    
}



# Services
foreach ($ServiceName in [string[]]$('LTService','LTSvcMon','ScreenConnect Client (*)')) {
    if (-not([bool]$([string]$(Get-Service -Name $ServiceName -ErrorAction 'SilentlyContinue' -Debug:$false | Select-Object -ExpandProperty 'Status' -ErrorAction 'SilentlyContinue') -eq [string]$('Running')))) {
        Write-Debug -Verbose ('Service "{0}" is not running.' -f ($ServiceName))
        exit 603        
    }
}



# Processes
foreach ($ProcessName in [string[]]$('LTSVC','LTTray','ScreenConnect.ClientService','ScreenConnect.WindowsClient')) {
    if (-not([bool]$(Get-Process -Name $ProcessName -ErrorAction 'SilentlyContinue' -Debug:$false | Select-Object -ExpandProperty 'Responding'))) {
        Write-Debug -Verbose ('Process "{0}" is not running.' -f ($ProcessName))
        exit 604        
    }
}



# Test Open Ports Outbound
foreach ($Port in [uint16[]]$(70,80,8040,8041)) {
    if (-not([bool]$(Test-NetConnection -Computername 'ironstoneit.hostedrmm.com' -Port $Port -ErrorAction 'SilentlyContinue' -Debug:$false | Select-Object -ExpandProperty 'TcpTestSucceeded' -ErrorAction 'SilentlyContinue'))) {
        Write-Debug -Message ('Can`t connect to "ironstoneit.hostedrmm.com" on port "{0}".' -f ($Port.ToString()))
        exit 605
    }
}