<#
.SYNOPSIS
Configures trusted sites for Windows / Internet Explorer

.DESCRIPTION


.AUTHOR
Olav R. Birkeland


.CHANGELOG
180119
- Initial Release


.RESOURCES

.TODO
- Add sites with PSCustomObject
    - Something like: [PSCustomObject]@{Dir = [string]'inter.net'; Key = [string]'https'; Val= [bool] 2}
        HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains\metiero365.sharepoint.com\www
#>



#region Variables
# Settings
[bool] $DebugWinTemp = $true
[bool] $DebugConsole = $false
[bool] $ReadOnly = $false
If ($DebugWinTemp) {[String] $Global:DebugStr=[String]::Empty}

# Script specific variables
[String] $WhatToConfig = 'Metier - IE Trusted Sites - Current User'
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
            $null = Remove-Item -Recurse -Force $Dir
            Write-DebugIfOn -In ('      Removed successfully? ' + $?)
            Write-DebugIfOn -In ('         Dir Actually gone? {0}' -f (-not (Test-Path $Dir)))
        }
        Else {
        # Else, do nothing
            Write-DebugIfOn -In ('   Dir does not exists')
        }
    }
    #endregion Delete-RegDirRecursive
#endregion Functions



#region Initialize
[String] $Script:CompName = $env:COMPUTERNAME
[System.Management.ManagementObject] $Script:WMIInfo = Get-WmiObject -Class win32_operatingsystem
[String] $Script:WindowsEdition = $Script:WMIInfo.Caption
[String] $Script:WindowsVersion = $Script:WMIInfo.Version
If ($DebugWinTemp -or $DebugConsole) {   
    Write-DebugIfOn -In '### Environment Info'
    Write-DebugIfOn -In ('Script settings: DebugConsole = ' + $DebugConsole + ' | DebugWinTemp = ' + $DebugWinTemp + ' ' + ' | ReadOnly = ' + $ReadOnly)
    Write-DebugIfOn -In ('Host (' + $Script:CompName + ') runs: ' + $Script:WindowsEdition + ' v' + $Script:WindowsVersion)
}
#endregion Initialize



#region Main
    Write-DebugIfOn -In ("`r`n" + '### ' + $WhatToConfig)


    # Add IE Trusted Domain 'https://metiero365.sharepoint.com'
    [String] $Dir1 = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains\metiero365.sharepoint.com\www'
    [String] $Key1 = 'https'
    [uint16] $Val1 = 2
    Write-RegistryValueDword -Dir $Dir1 -Key $Key1 -Val $Val1

    # EXAMPLE
    # Remove IE Trusted Domain 'prosjekthotell.com', Clean up from previous script
    #[String] $DirRem = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains\prosjekthotell.com'
    #Delete-RegDirRecursive -Dir $DirRem
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