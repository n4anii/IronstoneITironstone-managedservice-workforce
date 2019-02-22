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

#region Variables
# Settings
[bool] $DebugWinTemp = $true
[bool] $DebugConsole = $false
[bool] $ReadOnly = $false
If ($DebugWinTemp) {[String] $Global:DebugStr=[String]::Empty}

# Script specific variables
[String] $WhatToConfig = 'Windows Enterprise Activation'
[String] $EntKMSClientSetupKey = 'NPPR9-FWDCX-D2C8J-H872K-2YT43'
[String] $PartialEntClientSetupKey = $EntKMSClientSetupKey.Substring(0,5)
[String] $EntMAKKey = 'D2DB6-7NFB3-GV9K7-Y9BBD-M7V2F'
#endregion Variables



#region Functions
    #region Write-DebugIfOn
    Function Write-DebugIfOn {
        param(
            [Parameter(Mandatory=$true, Position=0)]
            [String] $In
        )
        If ($DebugConsole) {
            Write-Output -InputObject $In
        }
        If ($DebugWinTemp) {
            $Global:DebugStr += ($In + "`r`n")
        }
    }
    #endregion Write-DebugIfOn
    
    
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
        } catch {
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
        [String] $CompName = $env:COMPUTERNAME
        
        $ActivationService = Get-WmiObject -Query 'select * from SoftwareLicensingService' -ComputerName $CompName
        $null = $ActivationService.InstallProductKey($Key)
        $null = Start-Job -ScriptBlock {$ActivationService.RefreshLicenseStatus()} | Wait-Job
        $Job = Invoke-Command -ComputerName $CompName -ScriptBlock {$ActivationService.RefreshLicenseStatus()} -AsJob
        $ActStatus = Get-ActivationStatus -HostName $CompName
        If ($ActStatus.Status -like 'Licensed') {
            Write-DebugIfOn -In  ('      Success, Windows is activated!')
        }
        Else {
            Write-DebugIfOn -In  ('      Fail, Windows is not activated!')
        }
    }
    #endregion Activate-WinWithKey
#endregion Functions



#region Initialize
If ($DebugWinTemp -or $DebugConsole) {
    [String] $ComputerName = $env:COMPUTERNAME
    [String] $WindowsEdition = (Get-WmiObject -Class win32_operatingsystem).Caption
    [String] $WindowsVersion = (Get-WmiObject -Class win32_operatingsystem).Version
    Write-DebugIfOn -In '### Environment Info'
    Write-DebugIfOn -In ('Script settings: DebugConsole = ' + $DebugConsole + ' | DebugWinTemp = ' + $DebugWinTemp + ' ' + ' | ReadOnly = ' + $ReadOnly)
    Write-DebugIfOn -In ('Host runs: ' + $WindowsEdition + ' v' + $WindowsVersion)
}
#endregion Initialize



#region Main    
    Write-DebugIfOn -In ("`r`n" + '### ' + $WhatToConfig)

    # Get activation status
    $ActStatus = Get-ActivationStatus -HostName $env:COMPUTERNAME
    If ($ActStatus.Status -like 'Licensed') {
        Write-DebugIfOn -In ('  Activation Status: Licensed')
    } Else {
        Write-DebugIfOn -In ('  Activation Status: Not licensed.')
        If ($WindowsEdition -Like '*enterprise*') {
            If (!($ReadOnly)) {
                Write-DebugIfOn -In  ('    ReadOnly is off, trying to activate.')
                Activate-WinWithKey -Key $EntMAKKey
            }
            Else {
                Write-DebugIfOn -In ('    ReadOnly is on, will not attempt to activate')
            }
        }
        Else {
            Write-DebugIfOn -In  ("`n`n" + '    Process stopped: This will only work for Enterprise Edition')
        }
    }
#endregion Main




#region Debug
If ($DebugWinTemp) {
    If ([String]::IsNullOrEmpty($DebugStr)) {
        $DebugStr = 'Everything failed'
    }

    # Write Output
    $DebugPath = 'C:\Windows\Temp\'
    $CurDate = Get-Date -Uformat '%y%m%d'
    $CurTime = Get-Date -Format 'HHmmss'
    $DebugFileName = ('Debug Powershell ' + $WhatToConfig + ' ' + $CurDate + $CurTime + '.txt')

    $DebugStr | Out-File -FilePath ($DebugPath + $DebugFileName) -Encoding 'utf8'
    If (!($?)) {
        $DebugStr | Out-File -FilePath ($env:TEMP + '\' + $DebugFileName) -Encoding 'utf8'
    }
}
#endregion Debug