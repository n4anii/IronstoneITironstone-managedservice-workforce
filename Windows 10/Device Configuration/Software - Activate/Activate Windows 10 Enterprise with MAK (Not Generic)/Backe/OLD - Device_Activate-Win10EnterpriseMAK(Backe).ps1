<#
.SYNOPSIS
    <Short, what it does>


.DESCRIPTION
    <Long, what it does>


.OUTPUTS
    <What it outputs during runtime>


Usage:


Todo:


Resources:

#>


#Change the app name
$AppName   = 'Device_Activate-Win10EnterpriseMAK'
# Settings - Logging
$Timestamp = Get-Date -Format 'HHmmssffff'
$LogDirectory = ('{0}\Program Files\IronstoneIT\Intune\DeviceConfiguration' -f ($env:SystemDrive))
$Transcriptname = ('{2}\{0}_{1}.txt' -f ($AppName,$Timestamp,$LogDirectory))
# Settings - PowerShell
$ErrorActionPreference = 'Continue'
$VerbosePreference = 'Continue'
$WarningPreference = 'Continue'


if (-not(Test-Path -Path $LogDirectory)) {
    New-Item -ItemType Directory -Path $LogDirectory -ErrorAction Stop
}

Start-Transcript -Path $Transcriptname
#Wrap in a try/catch, so we can always end the transcript
Try {
    # Get the ID and security principal of the current user account
    $myWindowsID = [Security.Principal.WindowsIdentity]::GetCurrent()
    $myWindowsPrincipal = New-Object -TypeName System.Security.Principal.WindowsPrincipal -ArgumentList ($myWindowsID)
 
    # Get the security principal for the Administrator role
    $adminRole = [Security.Principal.WindowsBuiltInRole]::Administrator
 
    # Check to see if we are currently running "as Administrator"
    if (-not($myWindowsPrincipal.IsInRole($adminRole))) {
        # We are not running "as Administrator" - so relaunch as administrator
   
        # Create a new process object that starts PowerShell
        $newProcess = New-Object -TypeName System.Diagnostics.ProcessStartInfo -ArgumentList 'PowerShell'
   
        # Specify the current script path and name as a parameter
        $newProcess.Arguments = $myInvocation.MyCommand.Definition
   
        # Indicate that the process should be elevated
        $newProcess.Verb = 'runas'
   
        # Start the new process
        [Diagnostics.Process]::Start($newProcess)
   
        # Exit from the current, unelevated, process
        Write-Output -InputObject 'Restart in elevated'
        exit
   
    }

    #64-bit invocation
    if ($env:PROCESSOR_ARCHITEW6432 -eq 'AMD64') {
        write-Output -InputObject "Y'arg Matey, we're off to the 64-bit land....."
        if ($myInvocation.Line) {
            &"$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile $myInvocation.Line
        }
        else {
            &"$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile -file ('{0}' -f $myInvocation.InvocationName) $args
        }
        exit $lastexitcode
    }
 
 

    #region    Code Goes Here
    ##############################




#region    ONLY EDIT THESE VARIABLES
[string] $Customer  = 'Backe'
[string] $EntMAKKey = 'D2DB6-7NFB3-GV9K7-Y9BBD-M7V2F'
#endregion ONLY EDIT THESE VARIABLES



#region Variables
# Settings
[bool] $Script:ReadOnly     = $false


# Script Specific Variables
[string] $WhatToConfig = ('Device_Activate-Windows10EnterpriseMAK({0})' -f ($Customer))
[string] $EntKMSClientSetupKey = ('NPPR9-FWDCX-D2C8J-H872K-2YT43')
[string] $PartialEntClientSetupKey = $EntKMSClientSetupKey.Substring(0,5)
#endregion Variables



#region Functions     
    #region Get-ActivationStatus
    Function Get-ActivationStatus {
        param(
            [Parameter(Mandatory=$true, Position=0)]
            [String] $HostName
        )
        try {
            $wpa = Get-WmiObject -Class SoftwareLicensingProduct -ComputerName $HostName `
            -Filter "ApplicationID = '55c92734-d682-4d71-983e-d6ec3f16059f'" `
            -Property LicenseStatus -ErrorAction Stop
        } 
        catch {
            $status = New-Object -TypeName ComponentModel.Win32Exception -ArgumentList ($_.Exception.ErrorCode)
            $wpa = $null    
        }
        $out = New-Object -TypeName psobject -Property @{
            ComputerName = $HostName
            Status = [string]::Empty
        }
        If ($wpa) {
            :outer foreach($item in $wpa) {
                switch ($item.LicenseStatus) {
                    0 {$out.Status = 'Unlicensed'}
                    1 {$out.Status = 'Licensed'; break outer}
                    2 {$out.Status = 'Out-Of-Box Grace Period'; break outer}
                    3 {$out.Status = 'Out-Of-Tolerance Grace Period'; break outer}
                    4 {$out.Status = 'Non-Genuine Grace Period'; break outer}
                    5 {$out.Status = 'Notification'; break outer}
                    6 {$out.Status = 'Extended Grace'; break outer}
                    Default {$out.Status = 'Unknown value'}
                }
            }
        } 
        Else {$out.Status = $status.Message}
        $out
    }
    #endregion Get-ActivationStatus
    

    #region Activate-WinWithKey
    Function Activate-WinWithKey {
        param(
            [Parameter(Mandatory=$true, Position=0)]
            [String] $Key
        )
        [string] $CompName = $env:COMPUTERNAME
        
        $ActivationService = Get-WmiObject -Query 'select * from SoftwareLicensingService' -ComputerName $CompName
        $null = $ActivationService.InstallProductKey($Key)
        $null = Start-Job -ScriptBlock {$ActivationService.RefreshLicenseStatus()} | Wait-Job
        $Job = Invoke-Command -ComputerName $CompName -ScriptBlock {$ActivationService.RefreshLicenseStatus()} -AsJob
        $ActStatus = Get-ActivationStatus -HostName $CompName
        If ($ActStatus.Status -like 'Licensed') {
            Write-Verbose -Message  ('      Success, Windows is activated!')
        }
        Else {
            Write-Verbose -Message  ('      Fail, Windows is not activated!')
        }
    }
    #endregion Activate-WinWithKey


    #region Query-Registry
    Function Query-Registry {
        Param ([Parameter(Mandatory=$true)] [String] $Dir)
        $Local:Out = [String]::Empty
        [string] $Local:Key = $Dir.Split('{\}')[-1]
        [string] $Local:Dir = $Dir.Replace($Local:Key,'')
        
        $Local:Exists = Get-ItemProperty -Path ('{0}' -f $Dir) -Name ('{0}' -f $Local:Key) -ErrorAction SilentlyContinue
        If ($Exists) {
            $Local:Out = $Local:Exists.$Local:Key
        }
        return $Local:Out
    }
    #endregion Query-Registry


    #region Get-MachineInfo
    Function Get-MachineInfo {
        $Script:ComputerName = $env:COMPUTERNAME
        [string] $Script:ComputerManufacturer = Query-Registry -Dir 'HKLM:\HARDWARE\DESCRIPTION\System\BIOS\SystemManufacturer'
        If (-not([string]::IsNullOrEmpty($Script:ComputerManufacturer))) {
            [string] $Script:ComputerFamily = Query-Registry -Dir 'HKLM:\HARDWARE\DESCRIPTION\System\BIOS\SystemFamily'
            [string] $Script:ComputerProductName = Query-Registry -Dir 'HKLM:\HARDWARE\DESCRIPTION\System\BIOS\SystemProductName'
            [string] $Script:WindowsEdition = Query-Registry -Dir 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProductName'
            [string] $Script:WindowsVersion = Query-Registry -Dir 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ReleaseId'
            [string] $Script:WindowsVersion += (' ({0})' -f (Query-Registry -Dir 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\CurrentBuild'))
        } 
        Else {
            $Local:EnvInfo = Get-WmiObject -Class Win32_ComputerSystem | Select-Object -Property Manufacturer,Model,SystemFamily        
            [string] $Script:ComputerManufacturer = $Local:EnvInfo.Manufacturer
            [string] $Script:ComputerFamily = $Local:EnvInfo.SystemFamily
            [string] $Script:ComputerProductName = $Local:EnvInfo.Model
            $Local:OSInfo = Get-WmiObject -Class win32_operatingsystem | Select-Object -Property Caption,Version
            [string] $Script:WindowsEdition = $Local:OSInfo.Caption
            [string] $Script:WindowsVersion = $Local:OSInfo.Version
        }
    }
    #endregion Get-MachineInfo
#endregion Functions




#region Main    
    Write-Verbose -Message ("`r`n" + '### Device_Activate-Win10EnterpriseMAK({0})' -f ($Customer))
    Get-MachineInfo

    # Get activation status
    $ActStatus = Get-ActivationStatus -HostName $env:COMPUTERNAME
    If ($ActStatus.Status -like 'Licensed') {
        Write-Verbose -Message ('  Activation Status: Licensed')
    } 
    Else {
        Write-Verbose -Message ('  Activation Status: Not licensed.')
        If ($WindowsEdition -Like '*enterprise*') {
            If (-not($ReadOnly)) {
                Write-Verbose -Message  ('    ReadOnly is off, trying to activate.')
                Activate-WinWithKey -Key $EntMAKKey
            }
            Else {
                Write-Verbose -Message ('    ReadOnly is on, will not attempt to activate')
            }
        }
        Else {
            Write-Verbose -Message  ("`n`n" + '    Process stopped: This will only work for Enterprise Edition')
        }
    }
#endregion Main


    ##############################
    #endregion Code Goes Here
 
 
    
}
Catch {
    # Construct Message
    $ErrorMessage = ('Unable to {0}.' -f ($AppName))
    $ErrorMessage += " `n"
    $ErrorMessage += 'Exception: '
    $ErrorMessage += $_.Exception
    $ErrorMessage += " `n"
    $ErrorMessage += 'Activity: '
    $ErrorMessage += $_.CategoryInfo.Activity
    $ErrorMessage += " `n"
    $ErrorMessage += 'Error Category: '
    $ErrorMessage += $_.CategoryInfo.Category
    $ErrorMessage += " `n"
    $ErrorMessage += 'Error Reason: '
    $ErrorMessage += $_.CategoryInfo.Reason
    Write-Error -Message $ErrorMessage
}
Finally {
    Stop-Transcript
}