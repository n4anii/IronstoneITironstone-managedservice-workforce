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
    - ValueKind: https://msdn.microsoft.com/en-us/library/microsoft.win32.registryvaluekind.aspx

#>



#region Settings and Variables
# Settings - PowerShell
$VerbosePreference     = 'Continue'
$WarningPreference     = 'Continue'
$ErrorActionPreference = 'Continue'
# Settings - Script
[bool] $Script:WriteChanges   = $true
# Variables
[String] $NameScript = 'Registry functions'
#endregion Settings and Variables



#region    Functions   
    #region    Get-UserIsAdmin
    Function Get-UserIsAdmin {
        ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    }
    #endregion Get-UserIsAdmin


    #region    Set-RegistryDir
    Function Set-RegistryDir {
        Param(
            [Parameter(Mandatory=$true, Position=0)]
            [string] $Dir
        )
        if (-not(Test-Path -Path $Dir)) {
                Write-Verbose -Message '   Reg dir does not exist, trying to create'
                if ($WriteChanges) {
                    $null = New-Item -ItemType Directory -Force -Path $Dir 2>&1
                    if ($? -and (Test-Path -Path $Dir)) {Write-Verbose -Message '      SUCCESS: Dir was created'}
                    else {Write-Verbose -Message '      ERROR: Dir could not be created'}
                }
                else {Write-Verbose -Message '      ReadOnly mode'}
            } 
        else {Write-Verbose -Message '   Reg dir does already exist'} 
    }
    #endregion Set-RegistryDir


    #region    Set-RegistryValue
    Function Set-RegistryValue {
        Param(
            [Parameter(Mandatory=$true)]
            [string] $Dir, 
            
            [Parameter(Mandatory=$true)]
            [string] $Key,
            
            [Parameter(Mandatory=$true)]
            [ValidateSet('REG_BINARY','REG_DWORD','REG_QWORD','REG_SZ','REG_MULTI_SZ','REG_EXPAND_SZ')]
            [string] $ValType,
            
            [Parameter(Mandatory=$true)]
            $Val
        )
        Write-Verbose -Message ('Dir: {0} | Key: {1} | Val: {2} | ValType = {3}' -f ($Dir,$Key,$Val,$ValType))
        
        # Validate input
        if ($ValType -eq 'REG_DWORD') {
            [string] $Local:Type = 'DWord'
            $Val = [int32] $Val
            if (-not($?)) {
                Write-Verbose -Message 'Error, could not convert value to int32.'
                return $false
            }       
        }
        elseif ($ValType -eq 'REG_SZ') {
            [string] $Local:Type = 'String'
            $Val = [string] $Val
            if (-not($?)) {
                Write-Verbose -Message 'Error, could not convert value to string.'
                return $false
            }
        }
        else {
            Write-Verbose -Message 'Function is only capable of REG_DWORD and REG_STRING for now.'
            return $false
        }
        
        
        # Check if path exists, create if doesn't
        Set-RegistryDir $Dir
        # Continue only if Dir exists or gets created successfully
        if (Test-Path -Path $Dir) {
            [bool] $Local:WriteNewValue = $true
            
            # Check if key exists
            $Exists = Get-ItemProperty -Path ('{0}' -f $Dir) -Name ('{0}' -f $Key) -ErrorAction SilentlyContinue
            # If key does not exist
            if (-not($Exists)) {
                Write-Verbose -Message '   Key does not exist. Creating key and setting value'
            }
            # If key does exist   
            else {
                # Don't write new value if new key is the same
                if ($Exists.$Key -eq $Val) {
                    Write-Verbose -Message '   Key does exist, and value is the same as the new one'
                    $Local:WriteNewValue = $false
                }
                # Write new key if key is not the same
                else {
                    Write-Verbose -Message '   Key does exist, but is not equal to the new one. Trying to change it'
                }
            }
            
            # Write new value if $WriteNewValue and $WriteChanges
            if ($Local:WriteNewValue -and $WriteChanges) {
                $null = Set-ItemProperty -Path $Dir -Name $Key -Value $Val -Type $Local:Type 2>&1                       
            }


            # Final check
            if (-not($WriteChanges)) {
                Write-Verbose -Message '      ReadOnly mode, succeeded in checking reg value'
            }
            else {
                $Exists = Get-ItemProperty -Path ('{0}' -f $Dir) -Name ('{0}' -f $Key) -ErrorAction SilentlyContinue
                if ($Exists) {
                    if ($Exists.$Key -eq $Val) {
                    Write-Verbose -Message '      SUCCESS: Key is correct'}
                    else {Write-Verbose -Message '      ERROR: Key does exist | Val was not set'}
                }
                else {Write-Verbose -Message '      ERROR: Key does not Exist | Val was not set'}
            }
        }
    }
    #endregion Set-RegistryValue


    #region    Write-RegistryValueDword
    Function Write-RegistryValueDword {
        Param(
            [Parameter(Mandatory=$true)]
            [string] $Dir, [string] $Key, [uint16] $Val
        )
        Write-Verbose -Message ('Dir: ' + $Dir + ' | Key: ' + $Key + ' | Val: ' + $Val)
        # Check if path exists, create if doesn't
        Set-RegistryDir $Dir
        # Continue only if Dir exists or gets created successfully
        if (Test-Path -Path $Dir) {
            [bool] $Local:WriteNewValue = $true
            
            # Check if key exists
            $Exists = Get-ItemProperty -Path ('{0}' -f $Dir) -Name ('{0}' -f $Key) -ErrorAction SilentlyContinue
            # If key does not exist
            if (-not($Exists)) {
                Write-Verbose -Message '   Key does not exist. Creating key and setting value'
            }
            # If key does exist   
            else {
                # Don't write new value if new key is the same
                if ($Exists.$Key -eq $Val) {
                    Write-Verbose -Message '   Key does exist, and value is the same as the new one'
                    $Local:WriteNewValue = $false
                }
                # Write new key if key is not the same
                else {
                    Write-Verbose -Message '   Key does exist, but is not equal to the new one. Trying to change it'
                }
            }
            
            # Write new value if $WriteNewValue and $WriteChanges
            if ($Local:WriteNewValue -and $WriteChanges) {
                $null = Set-ItemProperty -Path $Dir -Name $Key -Value $Val 2>&1                       
            }


            # Final check
            if (-not($WriteChanges)) {
                Write-Verbose -Message '      ReadOnly mode, succeeded in checking reg value'
            }
            else {
                $Exists = Get-ItemProperty -Path ('{0}' -f $Dir) -Name ('{0}' -f $Key) -ErrorAction SilentlyContinue
                if ($Exists) {
                    if ($Exists.$Key -eq $Val) {
                    Write-Verbose -Message '      SUCCESS: Key is correct'}
                    else {Write-Verbose -Message '      ERROR: Key does exist | Val was not set'}
                }
                else {Write-Verbose -Message '      ERROR: Key does not Exist | Val was not set'}
            }
        }
    }
    #endregion Write-RegistryValueDword


    #region    Write-RegistryValueBinary
    Function Write-RegistryValueBinary {
        Param(
            [Parameter(Mandatory=$true)]
            [string] $Dir, [string] $Key, [string] $Val
        )
        [String] $Local:ValOutput = [String]::Empty
        if ($Val.Length -ge 15) {
            $Local:ValOutput = ($Val.Substring(0,15) + '...')
        }
        else {
            $Local:ValOutput = $Val
        }

        $Local:ValBin = $Val.Split(',') | ForEach-Object { "0x$_"}

        Write-Verbose -Message ('Dir: ' + $Dir + ' | Key: ' + $Key + ' | Val: ' + $ValOutput)
        # Check if path exists, create if doesn't
        Set-RegistryDir $Dir
        # Continue only if Dir exists or gets created successfully
        if (Test-Path -Path $Dir) {
            # Check if key exists
            $Exists = Get-ItemProperty -Path ('{0}' -f $Dir) -Name ('{0}' -f $Key) -ErrorAction SilentlyContinue
            # If key does not exist
            if (-not($Exists)) {
                Write-Verbose -Message '   Key does not exist. Creating key and setting value'
                if ($WriteChanges) {
                    $null = New-ItemProperty -Path $Dir -Name $Key -Value ([byte[]]$Local:ValBin) -PropertyType Binary 2>&1                       
                }
            }
            # If key does exist   
            else {
                # Don't write new value if new key is the same
                [uint16] $Local:ExistingVal = $Exists.$Key[0]
                [uint16] $Local:CheckAgainst = [uint16]$ValBin[0]

                if ($Local:ExistingVal -eq $Local:CheckAgainst) {
                    Write-Verbose -Message '   Key does exist, and value is the same as the new one'
                }
                # Write new key if key is not the same
                else {
                    Write-Verbose -Message ('   Key does exist, but is not equal to the new one. ({0} != {1}). Trying to change it' -f ($Local:ExistingVal,$Local:CheckAgainst))
                    if ($WriteChanges) {
                        $null = New-ItemProperty -Path $Dir -Name $Key -Value ([byte[]]$Local:ValBin) -PropertyType Binary 2>&1                 
                    }
                }
            }       
            # Final check
            if (-not($WriteChanges)) {
                Write-Verbose -Message '      ReadOnly mode, succeeded in checking reg value'
            }
            else {
                $Exists = Get-ItemProperty -Path ('{0}' -f $Dir) -Name ('{0}' -f $Key) -ErrorAction SilentlyContinue
                if ($Exists) {
                    [uint16] $Local:ExistingVal = $Exists.$Key[0]
                    [uint16] $Local:CheckAgainst = [uint16]$ValBin[0]
                    if ($Local:ExistingVal -eq $Local:CheckAgainst) {
                        Write-Verbose -Message '      SUCCESS: Key is correct'}
                    else {
                        Write-Verbose -Message '      ERROR: Key does exist | Val was not set'
                    }
                }
                else {
                    Write-Verbose -Message '      ERROR: Key does not Exist | Val was not set'
                }
            }
        }
    }
    #endregion Write-RegistryValueBinary


    #region    Write-RegistryValueString
    Function Write-RegistryValueString {
        Param(
            [Parameter(Mandatory=$true)]
            [string] $Dir, [string] $Key, [string] $Val
        )
        Write-Verbose -Message ('Dir: ' + $Dir + ' | Key: ' + $Key + ' | Val: ' + $Val)
        # Check if path exists, create if doesn't
        Set-RegistryDir $Dir
        # Continue only if Dir exists
        if (Test-Path -Path $Dir) {
            # Check if key exists
            $Exists = Get-ItemProperty -Path ('{0}' -f $Dir) -Name ('{0}' -f $Key) -ErrorAction SilentlyContinue
            # If key does not exist
            if (-not($Exists)) {
                Write-Verbose -Message '   Key does not exist. Creating key and setting value'
                if ($WriteChanges) {
                    $null = Set-ItemProperty -Path $Dir -Name $Key -Value $Val 2>&1                       
                }
            }
            # If key does exist   
            else {
                # Don't write new value if new key is the same
                if ($Exists.$Key -eq $Val) {
                    Write-Verbose -Message '   Key does exist, and value is the same as the new one'
                }
                # Write new key if key is not the same
                else {
                    Write-Verbose -Message '   Key does exist, but is not equal to the new one. Trying to change it'
                    if ($WriteChanges) {
                        $null = Set-ItemProperty -Path $Dir -Name $Key -Value $Val 2>&1                 
                    }
                }
            }       
            # Final check
            if (-not($WriteChanges)) {
                Write-Verbose -Message '      ReadOnly mode, succeeded in checking reg value'
            }
            else {
                $Exists = Get-ItemProperty -Path ('{0}' -f $Dir) -Name ('{0}' -f $Key) -ErrorAction SilentlyContinue
                if ($Exists) {
                    if ($Exists.$Key -eq $Val) {
                    Write-Verbose -Message '      SUCCESS: Key is correct'}
                    else {Write-Verbose -Message '      ERROR: Key does exist | Val was not set'}
                }
                else {Write-Verbose -Message '      ERROR: Key does not Exist | Val was not set'}
            }
        }
    }
    #region Write-RegistryValueString


    #region    Test-RegistryKey
    Function Test-RegistryKey {
        Param(
            [Parameter(Mandatory=$true)]
            [string] $Dir, [string] $Key, [string] $Val
        )
  
        $Exists = Get-ItemProperty -Path ('{0}' -f $Dir) -Name ('{0}' -f $Key) -ErrorAction SilentlyContinue
        if (($Exists -ne $null) -and ($Exists.Length -ne 0)) {
            if ($Exists.$Key -like $Val) {
                Write-Verbose -Message ($WhatToConfig + ' present in registry: ' + $ValueName + ' exists, and is equal to new value.' + "`r`n" + '(' + $Exists.$ValueName + ' == ' + $Value + ')')
                Return $true        
            }
            else { 
                Write-Verbose -Message ($WhatToConfig + ' present in registry: ' + $ValueName + ' exists, but is not equal to new value.' + "`r`n" + '(' + $Exists.$Valuename + ' != ' + $Value + ')')
                Return $false
            }
        }
        else {
            Write-Verbose -Message ($WhatToConfig + ' not present in registry.')
            Return $false
        }
    }
    #endregion Test-RegistryKey


    #region    Test-RegistryString
    Function Test-RegistryString {
        Param(
            [Parameter(Mandatory=$true, Position=0)]
            [String] $Dir,

            [Parameter(Mandatory=$true, Position=0)]
            [String] $Key,

            [Parameter(Mandatory=$true, Position=0)]
            [String] $Val
        )
        
        [bool] $IsThere = $false
        [String] $OutputStr = [String]::Empty

        $Exists = Get-ItemProperty -Path ('{0}' -f $Dir) -Name ('{0}' -f $Key) -ErrorAction SilentlyContinue
        if (($Exists -ne $null) -and ($Exists.Length -ne 0)) {
            if ($Exists.$Key -like $Val) {
                $OutputStr = ($WhatToConfig + ' present in registry: ' + $ValueName + ' exists, and is equal to new value.' + "`r`n" + '(' + $Exists.$ValueName + ' == ' + $Value + ')')       
                $IsThere = $true
            }
            else { 
                $OutputStr = ($WhatToConfig + ' present in registry: ' + $ValueName + ' exists, but is not equal to new value.' + "`r`n" + '(' + $Exists.$Valuename + ' != ' + $Value + ')')
            }
        }
        else {
            $OutputStr = ($WhatToConfig + ' not present in registry.')
        }

        Return @($IsThere,$OutputStr)
    }
    #endregion Test-RegistryString


    #region    Test-RegistryValue
    function Test-RegistryValue {
        <#
        .SYNAPSIS
        Returns true if value exists and is equal to the ValueToCompare.
        Else, returns false
        .EXAMPLE
        Test-RegistryValue -PathToCheck 'HKCU:\Environment\TEMP' -ValueToCompare ('{0}\AppData\Local\Temp' -f ($env:USERPROFILE))
        .PARAMETER PathToCheck
        The full registry path to check
        .PARAMETER ValueToCompare
        The value to compare against
        #>
        param(
            [Parameter(Mandatory=$true)]
            [string] $PathToCheck, 
        
            [Parameter(Mandatory=$true)]
            $ValueToCompare
        )
        $Key   = $PathToCheck.Split('\')[-1]
        $Dir   = $PathToCheck.Replace('\{0}' -f $Key,'\')
        if (Test-Path -Path $Dir) {
            $CurrentValue = (Get-ItemProperty -Path $Dir -Name $Key).$Key
            if ($CurrentValue -eq $ValueToCompare) {
                Return $true
            }
        }
        Return $false
    }
    #endregion Test-RegistryValue


    #region    Delete-RegDirRecursive
    Function Delete-RegDirRecursive {
        Param(
            [Parameter(Mandatory=$true)]
            [String] $Dir
        )
        Write-Verbose -Message ('Remove-RegDirRecursive | Dir: ' + $Dir)
        
        if (Test-Path -Path $Dir) {
            # If dir exists, remove it
            Write-Verbose -Message ('   Dir does exists, trying to remove')
            Remove-Item -Recurse -Force $Dir
            Write-Verbose -Message ('      Removed successfully? ' + $?)
            Write-Verbose -Message ('         Dir Actually gone? {0}' -f (-not (Test-Path -Path $Dir)))
        }
        else {
            # Else, do nothing
            Write-Verbose -Message ('   Dir does not exists')
        }
    }
    #endregion Delete-RegDirRecursive


    #region    Query-Registry
    Function Query-Registry {
        Param ([Parameter(Mandatory=$true)] [String] $Dir)
        $Local:Out = [String]::Empty
        [string] $Local:Key = $Dir.Split('{\}')[-1]
        [string] $Local:Dir = $Dir.Replace($Local:Key,'')
        
        $Local:Exists = Get-ItemProperty -Path ('{0}' -f $Dir) -Name ('{0}' -f $Local:Key) -ErrorAction SilentlyContinue
        if ($Exists) {
            $Local:Out = $Local:Exists.$Local:Key
        }
        return $Local:Out
    }
    #endregion Query-Registry


    #region    Get-MachineInfo
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



#region Initialize
    Get-MachineInfo
    Write-Output -InputObject '### Environment Info'
    Write-Output -InputObject ('Settings - PowerShell: VerbosePreference = "{0}", WarningPreference = "{1}", ErrorActionPreference = "{2}"' -f ($VerbosePreference,$WarningPreference,$ErrorActionPreference))
    Write-Output -InputObject ('Settings - Script:     WriteChanges = "{0}"' -f ($Script:WriteChanges))
    Write-Output -InputObject ('Machine info: Name = "{0}", Manufacturer = "{1}", Family = "{2}", Model = "{3}"' -f ($Script:ComputerName,$Script:ComputerManufacturer,$Script:ComputerFamily,$Script:ComputerProductName))
    Write-Output -InputObject ('Windows info: Edition = "{0}", Version = "{1}"' -f ($Script:WindowsEdition,$Script:WindowsVersion))
#endregion Initialize



#region Main
    Write-Output -InputObject ("`r`n" + '### ' + $NameScript)
    #region Test if admin
        [bool] $Script:IsAdmin = Get-UserIsAdmin
        if (-not($Script:IsAdmin)) {
            Write-Output -InputObject ("`r`n" + '### RUN AS ADMIN!')
            Write-Output -InputObject 'This script must be run as admin!'
            Write-Output -InputObject '  Can only view reg values without admin privileges'
            Write-Output -InputObject '  ReadOnly will now be True' 
            $ReadOnly = $true
        }
    #endregion Test if admin
    
    #region Example single dir, key, value
    Write-Output -InputObject ("`r`n" + '### Example single dir, key, value')
    [string] $RegPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Cloud Content'
    [string] $RegName = 'DisableWindowsConsumerFeatures'
    [byte]   $RegValue = 1
    Write-RegistryValueDword -Dir $RegPath -Key $RegName -Val $RegValue
    #endregion Example single dir, key, value
    
    #region Create new dir
    Write-Output -InputObject ("`r`n" + '### Example create single dir, key, value')
    [string] $RegPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Cloud Content\Bwekfust'
    [string] $RegName = 'TestValue'
    [byte]   $RegValue = 1
    Write-RegistryValueDword -Dir $RegPath -Key $RegName -Val $RegValue
    #endregion Create new dir

    #region Example single dir, multiple values
    Write-Output -InputObject ("`r`n" + '### Example single dir, multiple values')
    [string]   $RegPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
    $RegValues = @(
        [PSCustomObject]@{Key = [string]'FeatureManagementEnabled';     Val = [byte]0}
        [PSCustomObject]@{Key = [string]'OemPreInstalledAppsEnabled';   Val = [byte]0}
        [PSCustomObject]@{Key = [string]'PreInstalledAppsEnabled';      Val = [byte]0}
        [PSCustomObject]@{Key = [string]'SilentInstalledAppsEnabled';   Val = [byte]0}
        [PSCustomObject]@{Key = [string]'SoftLandingEnabled';           Val = [byte]0}
        [PSCustomObject]@{Key = [string]'SystemPaneSuggestionsEnabled'; Val = [byte]0}
    )
    Foreach ($x in $RegValues) {
        Write-RegistryValueDword -Dir $RegPath -Key $x.Key -Val $x.Val
    }
    #endregion Example single dir, multiple values
#endregion Main