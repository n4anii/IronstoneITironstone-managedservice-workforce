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
#region Variables
# Settings
[bool] $Script:DebugLogFile = $true
[bool] $Script:DebugConsole = $false
[bool] $Script:ReadOnly = $false
If ($Script:DebugLogFile) {$Script:DebugStr=[string]::Empty}

# Script specific variables
[bool] $Script:DeviceScope = $true
[string] $Script:WhatToConfig = 'Device_Add-Registry-OneDrive-EnableSilentAutoConfig'
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


    #region Check-RegistryDir
    Function Check-RegistryDir {
        Param(
            [Parameter(Mandatory=$true, Position=0)]
            [String] $Dir
        )
        If (!(Test-Path $Dir)) {
                Write-DebugIfOn -In '   Reg dir does not exist, trying to create.'
                If(!($ReadOnly)) {
                    $null = New-Item -ItemType Directory -Force -Path $Dir 2>&1
                    If (!($?)) {
                        Write-DebugIfOn -In '      ERROR: Dir could not be created'
                    }
                    Else {
                        Write-DebugIfOn -In '      SUCCESS: Dir was created'
                    }
                }
                Else {Write-DebugIfOn -In '      ReadOnly mode'}
            } 
        Else {
            Write-DebugIfOn -In '   Reg dir does already exist.'
        } 
    }
    #endregion Check-RegistryDir


    #region Write-RegistryValueDword
    Function Write-RegistryValueDword {
        Param(
            [Parameter(Mandatory=$true, Position=0)]
            [String] $Dir,

            [Parameter(Mandatory=$true, Position=0)]
            [String] $Key,

            [Parameter(Mandatory=$true, Position=0)]
            [Int] $Val
        )
        Write-DebugIfOn -In ('Dir: ' + $Dir + ' | Key: ' + $Key + ' | Val: ' + $Val)
        # Check if path exists, create if doesn't
        Check-RegistryDir $Dir
        # Continue only if Dir exists or gets created successfully
        If (Test-Path $Dir) {
            # Check if key exists
            $Exists = Get-ItemProperty -Path ('{0}' -f $Dir) -Name ('{0}' -f $Key) -ErrorAction SilentlyContinue
            # If key does not exist
            If (!($Exists)) {
                Write-DebugIfOn -In '   Key does not exist. Creating key and setting value'
                If (!($ReadOnly)) {
                    $null = Set-ItemProperty -Path $Dir -Name $Key -Value $Val 2>&1                       
                }
            }
            # If key does exist   
            Else {
                # Don't write new value if new key is the same
                If ($Exists.$Key -eq $Val) {
                    Write-DebugIfOn -In '   Key does exist, and value is the same as the new one'
                }
                # Write new key if key is not the same
                Else {
                    Write-DebugIfOn -In '   Key does exist, but is not equal to the new one. Trying to change it'
                    If (!($ReadOnly)) {
                        $null = Set-ItemProperty -Path $Dir -Name $Key -Value $Val 2>&1                 
                    }
                }
            }       
            # Final check
            If ($ReadOnly) {
                Write-DebugIfOn -In '      ReadOnly mode, succeeded in checking reg value'
                }
                Else {
                $Exists = Get-ItemProperty -Path ('{0}' -f $Dir) -Name ('{0}' -f $Key) -ErrorAction SilentlyContinue
                If ($Exists) {
                    If ($Exists.$Key -eq $Val) {
                    Write-DebugIfOn -In '      SUCCESS: Key is correct'}
                    Else {Write-DebugIfOn -In '      ERROR: Key does exist | Val was not set'}
                }
                Else {Write-DebugIfOn -In '      ERROR: Key does not Exist | Val was not set'}
            }
        }
    }
    #endregion Write-RegistryValueDword


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
    #region Set SilentAccountConfig
    Write-DebugIfOn -In ("`r`n" + '### ' + $Script:WhatToConfig)
    [string] $Local:Dir = 'HKLM:\Software\Policies\Microsoft\OneDrive'
    [string] $Local:Key = 'SilentAccountConfig'
    [byte]   $Local:Val = 1
    Write-RegistryValueDword -Dir $Local:Dir -Key $Local:Key -Val $Local:Val
    #endregion Set SilentAccountConfig
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