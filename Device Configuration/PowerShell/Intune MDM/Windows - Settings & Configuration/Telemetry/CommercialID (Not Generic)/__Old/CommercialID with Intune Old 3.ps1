<#
    .SYNOPSIS
    Checks and adds (if wrong or missing) CommercialID.

    .DESCRIPTION
    Checks and adds (if wrong or missing) CommercialID.
    Telemetry level is set by Intune => Device Configuration => Device Restrictions policy

    .USAGE
    - Get Telemetry CommercialID from OMS Workspace 
        - OMS -> Settings -> Connected Sources -> Windows Telemetry -> Commercial ID Key
            - Or 'Upgrade readiness' solution -> Settings
        - Set variable $Value to the value from OMS
    - Set telemetry level (0 = Off, 1 = Security, 2 = enchanced, 3 = Full) 

    Sources:
    - https://stackoverflow.com/questions/5648931/test-if-registry-value-exists
    - https://stackoverflow.com/questions/29804234/run-registry-file-remotely-with-powershell
    - https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/out-file?view=powershell-5.1
    - https://docs.microsoft.com/en-us/intune/intune-management-extension
    
#>


#region Variables
# Settings
[bool] $DebugWinTemp = $true
[bool] $DebugConsole = $false
[bool] $ReadOnly = $false
If ($DebugWinTemp) {[String] $Global:DebugStr=[String]::Empty}

# Script specific variables
[String] $WhatToConfig = 'Telemetry CommercialID'
[String] $ValuePath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection\'
[String] $CommercialID = ''                    # CommercialID, from OMS. EX: '0214110f-01c5-431f-899b-8bb6e6ed65e9'
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


    #region Write-RegistryValueString
    Function Write-RegistryValueString {
        Param(
            [Parameter(Mandatory=$true, Position=0)]
            [String] $Dir,

            [Parameter(Mandatory=$true, Position=0)]
            [String] $Key,

            [Parameter(Mandatory=$true, Position=0)]
            [String] $Val
        )
        Write-DebugIfOn -In ('Dir: ' + $Dir + ' | Key: ' + $Key + ' | Val: ' + $Val)
        # Check if path exists, create if doesn't
        Check-RegistryDir $Dir
        # Continue only if Dir exists
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
    #region Write-RegistryValueString
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
# String CommercialID
Write-DebugIfOn -In ("`r`n" + '### ' + $WhatToConfig)
Write-RegistryValueString -Dir $ValuePath -Key 'CommercialID' -Val $CommercialID
#endregion Main



#region Debug
If ($DebugWinTemp) {
    If ([String]::IsNullOrEmpty($Script:DebugStr)) {
        $Script:DebugStr = 'Everything failed'
    }

    ### Write Output
    # Get variables
    $Local:DirLog = ('{0}\Program Files\IronstoneIT\Intune\DeviceConfiguration\' -f ($env:SystemDrive))
    $Local:NameScriptFile = $Script:WhatToConfig
    $Local:CurTime = Get-Date -Uformat '%y%m%d%H%M%S'
    
    # Create log file name
    $Local:DebugFileName = ('{0} {1}.txt' -f ($Local:NameScriptFile,$Local:CurTime))

    # Check if log destination exists, or else: Create it
    If (-not(Test-Path -Path $DirLog)) {
        $null = New-Item -Path $DirLog -Force -ItemType Directory
    }
    $Script:DebugStr | Out-File -FilePath ($Local:DirLog + $Local:DebugFileName) -Encoding 'utf8'
}
#endregion Debug