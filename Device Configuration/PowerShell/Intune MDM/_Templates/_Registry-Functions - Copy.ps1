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
[bool] $DebugWinTemp = $false
[bool] $DebugConsole = $true
[bool] $ReadOnly = $true
If ($DebugWinTemp) {[String] $Global:DebugStr=[String]::Empty}

# Script specific variables
[String] $WhatToConfig = 'Registry functions'
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


    #region Test if admin
    Function Test-IsAdmin {
        ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    }
    #region Test if admin


    #region Check-RegistryDir
    Function Check-RegistryDir {
        Param(
            [Parameter(Mandatory=$true, Position=0)]
            [String] $Dir
        )
        If (!(Test-Path $Dir)) {
                Write-DebugIfOn -In '   Reg dir does not exist, trying to create'
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
            Write-DebugIfOn -In '   Reg dir does already exist'
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


    #region Write-RegistryValueBinary
    Function Write-RegistryValueBinary {
        Param(
            [Parameter(Mandatory=$true, Position=0)]
            [String] $Dir,

            [Parameter(Mandatory=$true, Position=0)]
            [String] $Key,

            [Parameter(Mandatory=$true, Position=0)]
            [String] $Val
        )
        [String] $Local:ValOutput = [String]::Empty
        If ($Val.Length -ge 15) {
            $Local:ValOutput = ($Val.Substring(0,15) + '...')
        }
        Else {
            $Local:ValOutput = $Val
        }

        $Local:ValBin = $Val.Split(',') | ForEach-Object { "0x$_"}

        Write-DebugIfOn -In ('Dir: ' + $Dir + ' | Key: ' + $Key + ' | Val: ' + $ValOutput)
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
                    $null = New-ItemProperty -Path $Dir -Name $Key -Value ([byte[]]$Local:ValBin) -PropertyType Binary 2>&1                       
                }
            }
            # If key does exist   
            Else {
                # Don't write new value if new key is the same
                [uint16] $Local:ExistingVal = $Exists.$Key[0]
                [uint16] $Local:CheckAgainst = [uint16]$ValBin[0]

                If ($Local:ExistingVal -eq $Local:CheckAgainst) {
                    Write-DebugIfOn -In '   Key does exist, and value is the same as the new one'
                }
                # Write new key if key is not the same
                Else {
                    Write-DebugIfOn -In ('   Key does exist, but is not equal to the new one. ({0} != {1}). Trying to change it' -f ($Local:ExistingVal,$Local:CheckAgainst))
                    If (!($ReadOnly)) {
                        $null = New-ItemProperty -Path $Dir -Name $Key -Value ([byte[]]$Local:ValBin) -PropertyType Binary 2>&1                 
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
                    [uint16] $Local:ExistingVal = $Exists.$Key[0]
                    [uint16] $Local:CheckAgainst = [uint16]$ValBin[0]
                    If ($Local:ExistingVal -eq $Local:CheckAgainst) {
                        Write-DebugIfOn -In '      SUCCESS: Key is correct'}
                    Else {
                        Write-DebugIfOn -In '      ERROR: Key does exist | Val was not set'
                    }
                }
                Else {
                    Write-DebugIfOn -In '      ERROR: Key does not Exist | Val was not set'
                }
            }
        }
    }
    #endregion Write-RegistryValueBinary


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


    #region Test-RegistryKey
    Function Test-RegistryKey {
      Param(
            [Parameter(Mandatory=$true, Position=0)]
            [String] $Dir,

            [Parameter(Mandatory=$true, Position=0)]
            [String] $Key,

            [Parameter(Mandatory=$true, Position=0)]
            [Int] $Val
        )
  
      $Exists = Get-ItemProperty -Path ('{0}' -f $Dir) -Name ('{0}' -f $Key) -ErrorAction SilentlyContinue
      If (($Exists -ne $null) -and ($Exists.Length -ne 0)) {
        If ($Exists.$Key -like $Val) {
            Write-DebugIfOn -In ($WhatToConfig + ' present in registry: ' + $ValueName + ' exists, and is equal to new value.' + "`r`n" + '(' + $Exists.$ValueName + ' == ' + $Value + ')' + "`r`n")
            Return $true        
        }
        Else { 
            Write-DebugIfOn -In ($WhatToConfig + ' present in registry: ' + $ValueName + ' exists, but is not equal to new value.' + "`r`n" + '(' + $Exists.$Valuename + ' != ' + $Value + ')' + "`r`n")
            Return $false
        }
      }
      Else {
        Write-DebugIfOn -In ($WhatToConfig + ' not present in registry.' + "`r`n")
        Return $false
      }
    }
    #endregion Test-RegistryKey


    #region Test-RegistryString
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
        If (($Exists -ne $null) -and ($Exists.Length -ne 0)) {
            If ($Exists.$Key -like $Val) {
                $OutputStr = ($WhatToConfig + ' present in registry: ' + $ValueName + ' exists, and is equal to new value.' + "`r`n" + '(' + $Exists.$ValueName + ' == ' + $Value + ')' + "`r`n")       
                $IsThere = $true
            }
            Else { 
                $OutputStr = ($WhatToConfig + ' present in registry: ' + $ValueName + ' exists, but is not equal to new value.' + "`r`n" + '(' + $Exists.$Valuename + ' != ' + $Value + ')' + "`r`n")
            }
        }
        Else {
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
        If (Test-Path -Path $Dir) {
            $CurrentValue = (Get-ItemProperty -Path $Dir -Name $Key).$Key
            If ($CurrentValue -eq $ValueToCompare) {
                Return $true
            }
        }
        Return $false
    }
    #endregion Test-RegistryValue


    #region Delete-RegDirRecursive
    Function Delete-RegDirRecursive {
        Param(
            [Parameter(Mandatory=$true)]
            [String] $Dir
        )
        Write-DebugIfOn -In ('Remove-RegDirRecursive | Dir: ' + $Dir)
        
        If (Test-Path $Dir) {
            # If dir exists, remove it
            Write-DebugIfOn -In ('   Dir does exists, trying to remove')
            Remove-Item -Recurse -Force $Dir
            Write-DebugIfOn -In ('      Removed successfully? ' + $?)
            Write-DebugIfOn -In ('         Dir Actually gone? {0}' -f (-not (Test-Path $Dir)))
        }
        Else {
        # Else, do nothing
            Write-DebugIfOn -In ('   Dir does not exists')
        }
    }
    #endregion Delete-RegDirRecursive


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
            [String] $Script:ComputerModel = $Local:EnvInfo.Model
            $Local:OSInfo = Get-WmiObject -Class win32_operatingsystem | Select-Object -Property Caption,Version
            [String] $Script:WindowsEdition = $Local:OSInfo.Caption
            [String] $Script:WindowsVersion = $Local:OSInfo.Version
        }
    }
    #endregion Get-MachineInfo


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
#endregion Functions



#region Initialize
If ($DebugWinTemp -or $DebugConsole) {
    Get-MachineInfo
    Write-DebugIfOn -In '### Environment Info'
    Write-DebugIfOn -In ('Script settings: DebugConsole = "{0}", DebugWinTemp = "{1}", ReadOnly = "{2}"' -f ($DebugConsole,$DebugWinTemp,$ReadOnly))
    Write-DebugIfOn -In ('Machine info: Name = "{0}", Manufacturer = "{1}", Family = "{2}", Model = "{3}"' -f ($Script:ComputerName,$Script:ComputerManufacturer,$Script:ComputerFamily,$Script:ComputerModel))
    Write-DebugIfOn -In ('Windows info: Edition = "{0}", Version = "{1}"' -f ($Script:WindowsEdition,$Script:WindowsVersion))
}
#endregion Initialize



#region Main
    Write-DebugIfOn -In ("`r`n" + '### ' + $WhatToConfig)
    #region Test if admin
        $IsAdmin = $false
        If (!(Test-IsAdmin)) {
            Write-DebugIfOn -In ("`r`n" + '### RUN AS ADMIN!')
            Write-DebugIfOn -In 'This script must be run as admin!'
            Write-DebugIfOn -In '  Can only view reg values without admin privileges'
            Write-DebugIfOn -In '  ReadOnly will now be True' 
            $ReadOnly = $true
        } Else {$IsAdmin = $true}
    #endregion Test if admin
    
    #region Example single dir, key, value
    Write-DebugIfOn -In ("`r`n" + '### Example single dir, key, value')
    [String] $RegPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Cloud Content'
    [String] $RegName = 'DisableWindowsConsumerFeatures'
    [Int]   $RegValue = 1
    Write-RegistryValueDword -Dir $RegPath -Key $RegName -Val $RegValue
    #endregion Example single dir, key, value
    
    #region Create new dir
    Write-DebugIfOn -In ("`r`n" + '### Example create single dir, key, value')
    [String] $RegPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Cloud Content\Bwekfust'
    [String] $RegName = 'TestValue'
    [Int]   $RegValue = 1
    Write-RegistryValueDword -Dir $RegPath -Key $RegName -Val $RegValue
    #endregion Create new dir

    #region Example single dir, multiple values
    Write-DebugIfOn -In ("`r`n" + '### Example single dir, multiple values')
    [String]   $RegPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
    $RegValues = @(
        [PSCustomObject]@{Key = [String]'FeatureManagementEnabled'; Val = [Int]0}
        [PSCustomObject]@{Key = [String]'OemPreInstalledAppsEnabled'; Val = [Int]0}
        [PSCustomObject]@{Key = [String]'PreInstalledAppsEnabled'; Val = [Int]0}
        [PSCustomObject]@{Key = [String]'SilentInstalledAppsEnabled'; Val = [Int]0}
        [PSCustomObject]@{Key = [String]'SoftLandingEnabled'; Val = [Int]0}
        [PSCustomObject]@{Key = [String]'SystemPaneSuggestionsEnabled'; Val = [Int]0}
    )
    Foreach ($x in $RegValues) {
        Write-RegistryValueDword -Dir $RegPath -Key $x.Key -Val $x.Val
    }
    #endregion Example single dir, multiple values
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