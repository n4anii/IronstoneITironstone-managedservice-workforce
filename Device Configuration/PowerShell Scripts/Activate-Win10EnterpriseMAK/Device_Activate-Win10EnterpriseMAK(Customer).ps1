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



#region    ONLY EDIT THESE VARIABLES
[string] $Customer  = ''              # Name of customer, like 'IronstoneIT'
[string] $EntMAKKey = ''              # 25 Characters, like 'xXxXx-XxXxX-xXxXx-XxXxX-xXxXx'
#endregion ONLY EDIT THESE VARIABLES



#region Variables
# Settings
[bool] $Script:DebugLogFile = $true
[bool] $Script:DebugConsole = $false
[bool] $Script:ReadOnly     = $false
[bool] $Script:DeviceScope  = $true
If ($Script:DebugLogFile) {$Script:DebugStr=[string]::Empty}

# Script Specific Variables
[string] $WhatToConfig = ('Device_Activate-Windows10EnterpriseMAK({0})' -f ($Customer))
[string] $EntKMSClientSetupKey = ('NPPR9-FWDCX-D2C8J-H872K-2YT43')
[string] $PartialEntClientSetupKey = $EntKMSClientSetupKey.Substring(0,5)
#endregion Variables



#region Functions
    #region Write-DebugIfOn
    Function Write-DebugIfOn {
        param(
            [Parameter(Mandatory=$true, Position=0)]
            [String] $In
        )
        If ($Script:DebugConsole) {
            Write-Output -InputObject $In
        }
        If ($Script:DebugLogFile) {
            $Script:DebugStr += ($In + "`r`n")
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


    #region Query-Registry
    Function Query-Registry {
        Param ([Parameter(Mandatory=$true)] [String] $Dir)
        $Local:Out = [String]::Empty
        [String] $Local:Key = $Dir.Split('{\}')[-1]
        [String] $Local:Dir = $Dir.Replace($Local:Key,'')
        
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
        [String] $Script:ComputerManufacturer = Query-Registry -Dir 'HKLM:\HARDWARE\DESCRIPTION\System\BIOS\SystemManufacturer'
        If (-not([String]::IsNullOrEmpty($Script:ComputerManufacturer))) {
            [String] $Script:ComputerFamily = Query-Registry -Dir 'HKLM:\HARDWARE\DESCRIPTION\System\BIOS\SystemFamily'
            [String] $Script:ComputerProductName = Query-Registry -Dir 'HKLM:\HARDWARE\DESCRIPTION\System\BIOS\SystemProductName'
            [String] $Script:WindowsEdition = Query-Registry -Dir 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProductName'
            [String] $Script:WindowsVersion = Query-Registry -Dir 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ReleaseId'
            [String] $Script:WindowsVersion += (' ({0})' -f (Query-Registry -Dir 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\CurrentBuild'))
        } 
        Else {
            $Local:EnvInfo = Get-WmiObject -Class Win32_ComputerSystem | Select-Object -Property Manufacturer,Model,SystemFamily        
            [String] $Script:ComputerManufacturer = $Local:EnvInfo.Manufacturer
            [String] $Script:ComputerFamily = $Local:EnvInfo.SystemFamily
            [String] $Script:ComputerProductName = $Local:EnvInfo.Model
            $Local:OSInfo = Get-WmiObject -Class win32_operatingsystem | Select-Object -Property Caption,Version
            [String] $Script:WindowsEdition = $Local:OSInfo.Caption
            [String] $Script:WindowsVersion = $Local:OSInfo.Version
        }
    }
    #endregion Get-MachineInfo
#endregion Functions



#region Initialize
Get-MachineInfo
If ($Script:DebugLogFile -or $Script:DebugConsole) {
    Write-DebugIfOn -In '### Environment Info'
    Write-DebugIfOn -In ('Script settings: DebugConsole = "{0}", DebugWinTemp = "{1}", ReadOnly = "{2}"' -f ($Script:DebugConsole,$Script:DebugLogFile,$Script:ReadOnly))
    Write-DebugIfOn -In ('Machine info: Name = "{0}", Manufacturer = "{1}", Family = "{2}", Model = "{3}"' -f ($Script:ComputerName,$Script:ComputerManufacturer,$Script:ComputerFamily,$Script:ComputerProductName))
    Write-DebugIfOn -In ('Windows info: Edition = "{0}", Version = "{1}"' -f ($Script:WindowsEdition,$Script:WindowsVersion))
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
If ($Script:DebugLogFile) {
    If ([String]::IsNullOrEmpty($Script:DebugStr)) {
        $Script:DebugStr = 'Everything failed'
    }

    ### Write Output
    # Get variables
    If ($Script:DeviceScope) {
         $Local:DirLog = ('{0}\Program Files\IronstoneIT\Intune\DeviceConfiguration\' -f ($env:SystemDrive))
    }
    Else {
        $Local:DirLog = ('{0}\IronstoneIT\Intune\DeviceConfiguration\' -f ($env:APPDATA))
    }     
    $Local:NameScriptFile = $Script:WhatToConfig
    $Local:CurTime = Get-Date -Uformat '%y%m%d%H%M%S'
    

    # Create log file name
    $Local:DebugFileName = ('{0}_{1}.txt' -f ($Local:NameScriptFile,$Local:CurTime))
    

    # Check if log destination exists, or else: Create it
    If (-not(Test-Path -Path $DirLog)) {
        $null = New-Item -Path $DirLog -Force -ItemType Directory
    }
    
    
    # Out-File the Log
    $Script:DebugStr | Out-File -FilePath ($Local:DirLog + $Local:DebugFileName) -Encoding 'utf8'
}
#endregion Debug