<#
    .SYNOPSIS
    Checks and adds (if wrong or missing) CommercialID, and Telemetry level.

    .DESCRIPTION
    Checks and adds (if wrong or missing) CommercialID, and Telemetry level.

    .USAGE
    - Get Telemetry CommercialID from OMS Workspace 
        - OMS -> Settings -> Connected Sources -> Windows Telemetry -> Commercial ID Key
        - Set variable $Value to the value from OMS
    - Set telemetry level (2 = enchanced) 

    Sources:
    - https://stackoverflow.com/questions/5648931/test-if-registry-value-exists
    - https://stackoverflow.com/questions/29804234/run-registry-file-remotely-with-powershell
    - https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/out-file?view=powershell-5.1
    - https://docs.microsoft.com/en-us/intune/intune-management-extension
    
#>


#region Variables
# Settings
[bool] $DebugIntune = $true
[bool] $DebugDevelopment = $false
[bool] $Readonly = $false
if ($DebugIntune) {[String] $global:DebugStr=''}

# Scenario specific information
[String] $WhatToConfig = 'Telemetry CommercialID'
[String] $ValuePath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection\'
[String] $ValueName = 'CommercialID'
[String] $Value = '0214110f-01c5-431f-899b-8bb6e6ed65e9'
[Int] $TelemetryLevel = 3
#endregion Variables



#region Functions
#region Write-Output
Function Out {
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [String] $In
    )
    If ($DebugDevelopment) {
        Write-Output -InputObject $In
    }
    If ($DebugIntune) {
        $Global:DebugStr += $In + "`r`n"
    }
}
#region Write-Output


#region Write registry dword
Function Write-RegistryValueDword {
    Param(
        [Parameter(Mandatory=$true, Position=0)]
        [String] $Dir,

        [Parameter(Mandatory=$true, Position=0)]
        [String] $Key,

        [Parameter(Mandatory=$true, Position=0)]
        [Int] $Val
    )
    # Check if directory exists
    Out ('Dir: ' + $Dir + ' | Key: ' + $Key + ' | Val: ' + $Val)
    If (!($Dir)) {
        Out '   Reg dir does not exist, trying to create..'
        force-mkdir $Dir
        If (!($?)) {
            Out '         ERROR: Dir could not be created'    
        }
        Out '         SUCCESS: Dir was created'
    } Else {
        Out '   Reg dir does already exist.'
    }

    # Check if key exists
    $Exists = Get-ItemProperty -Path ('{0}' -f $Dir) -Name ('{0}' -f $Key) -ErrorAction SilentlyContinue
    # If key does not exist
    If (!($Exists)) {
        Out '   Key does not exist. Creating key and setting value'
        If (!($ReadOnly)) {
            $null = Set-ItemProperty $Dir $Key $Val                       
        }
    }
    # If key does exist   
    Else {
        # Don't write new value if new key is the same
        If ($Exists.$Key -eq $Val) {
            Out '   Key does exist, and value is the same as the new one'
        }
        # Write new key if key is not the same
        Else {
            Out '   Key does exist, but is not equal to the new one. Trying to change it'
            If (!($ReadOnly)) {
                $null = Set-ItemProperty $Dir $Key $Val                
            }
        }
    }

    # Final check
    If ($ReadOnly) {
        Out '         ReadOnly mode, succeeded in checking reg value'
        }
        Else {
        $Exists = Get-ItemProperty -Path ('{0}' -f $Dir) -Name ('{0}' -f $Key) -ErrorAction SilentlyContinue
        If ($Exists) {
            If ($Exists.$Key -eq $Val) {
            Out '         SUCCESS: Key is correct'}
            Else {Out '         ERROR: Key does exist | Val was not set'}
        }
        Else {Out '         ERROR: Key does not Exist | Val was not set'}
    }
}
#endregion Write registry dword


#region Write registry string
Function Write-RegistryValueString {
    Param(
        [Parameter(Mandatory=$true, Position=0)]
        [String] $Dir,

        [Parameter(Mandatory=$true, Position=0)]
        [String] $Key,

        [Parameter(Mandatory=$true, Position=0)]
        [String] $Val
    )
    # Check if directory exists
    Out ('Dir: ' + $Dir + ' | Key: ' + $Key + ' | Val: ' + $Val)
    If (!($Dir)) {
        Out '   Reg dir does not exist, trying to create..'
        force-mkdir $Dir
        If (!($?)) {
            Out '         ERROR: Dir could not be created'    
        }
        Out '         SUCCESS: Dir was created'
    } Else {
        Out '   Reg dir does already exist.'
    }

    # Check if key exists
    $Exists = Get-ItemProperty -Path ('{0}' -f $Dir) -Name ('{0}' -f $Key) -ErrorAction SilentlyContinue
    # If key does not exist
    If (!($Exists)) {
        Out '   Key does not exist. Creating key and setting value'
        If (!($ReadOnly)) {
            $null = Set-ItemProperty $Dir $Key $Val                       
        }
    }
    # If key does exist   
    Else {
        # Don't write new value if new key is the same
        If ($Exists.$Key -eq $Val) {
            Out '   Key does exist, and value is the same as the new one'
        }
        # Write new key if key is not the same
        Else {
            Out '   Key does exist, but is not equal to the new one. Trying to change it'
            If (!($ReadOnly)) {
                $null = Set-ItemProperty $Dir $Key $Val                
            }
        }
    }

    # Final check
    If ($ReadOnly) {
        Out '         ReadOnly mode, succeeded in checking reg value'
        }
        Else {
        $Exists = Get-ItemProperty -Path ('{0}' -f $Dir) -Name ('{0}' -f $Key) -ErrorAction SilentlyContinue
        If ($Exists) {
            If ($Exists.$Key -eq $Val) {
            Out '         SUCCESS: Key is correct'}
            Else {Out '         ERROR: Key does exist | Val was not set'}
        }
        Else {Out '         ERROR: Key does not Exist | Val was not set'}
    }
}
#endregion Write registry string
#endregion Functions



#region Main
# String CommercialID
Write-RegistryValueString -Dir $ValuePath -Key $ValueName -Val $Value

# Dword Telemetry level
[String[]] $RegValues = 'AllowTelemetry','AllowTelemetry_PolicyManager'
Foreach ($x in $RegValues) {
    Write-RegistryValueDword -Dir $ValuePath -Key $x -Val $TelemetryLevel
}
#endregion Main



#region Debug
If ($DebugIntune) {
    If ([String]::IsNullOrEmpty($DebugStr)) {
        $DebugStr = 'Everything failed'
    }

    # Write Output
    $DebugPath = 'C:\Windows\Temp\'
    $DebugFileName = ('Debug Powershell ' + $WhatToConfig + '.txt')

    $DebugStr | Out-File -FilePath ($DebugPath + $DebugFileName) -Encoding 'utf8'
    If (!($?)) {
        $DebugStr | Out-File -FilePath ($env:TEMP + '\' + $DebugFileName) -Encoding 'utf8'
    }
}
#endregion Debug