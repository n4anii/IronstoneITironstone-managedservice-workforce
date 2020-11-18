#Requires -RunAsAdministrator
<# 
    .SYNOPSIS
        Enables BitLocker and backups Recovery Password to both Azure AD and OneDrive for Business.

    .DESCRIPTION 
        Enables BitLocker and backups Recovery Password to both Azure AD and OneDrive for Business.
            * Designed for Intune MDM managed, Azure AD joined devices.
            * Continously monitors BitLocker status.
                * Will re-enable if BitLocker gets disabled.
                * Will backup new Recovery Passwords if not already backed up.
#>


# Input parameters
[OutputType($null)]
[CmdletBinding()]
param()


# Import BitLocker module - Requirement
if ([byte]$(Get-Module -Name 'BitLocker' -ErrorAction 'SilentlyContinue' | Measure-Object | Select-Object -ExpandProperty 'Count') -le 0) {
    $null = Import-Module -Name 'BitLocker' -DisableNameChecking -ErrorAction 'Stop'
}


# Make sure all network traffic generacted in this script uses TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12


#region Settings and Variables
    # Settings   
    ## Remove files after success
    ### If on, will remove all files after first success.
    $null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'BoolRemoveFilesAfterSuccess' -Value ([bool]$false)
    
    ## Remove scehduled task after success
    ### If false, will change scheduled task to run once a day at 12:00 after first successfull run, or after 30 failed runs
    ### If true, will delete scheduled task after first successfull run and after 30 failed runs
    $null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'BoolRemoveScheduledTaskAfterFirstSuccess' -Value ([bool]$false)
    
    ## Backup to OneDrive
    ### If true will backup to OneDrive for Business, will not count as successful run before this step has completed successfully
    ### If false will skup backup to OneDrive for Business
    $null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'BoolBackupToOneDriveForBusiness' -Value ([bool]$true)
    
    ## Skip hardware test if newly enrolled
    ### If true, will skip hardware test when enabling BitLocker on newly enrolled Intune device.
    ### If false, will not.
    $null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'BoolSkipHardwareTestOnNewlyEnrolledDevice' -Value ([bool]$true)


    # Variables
    ## Script
    $null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'NameScript' -Value $([string]$('IronTrigger'))
    $null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'ScheduledTaskName' -Value $([string]$($Script:NameScript.Clone()))
    $null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'DirInstall' -Value $([string]$('{0}\Program Files\IronstoneIT\{1}\' -f ($env:SystemDrive,$Script:NameScript)))
    $null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'DirLog' -Value $([string]$('{0}\Program Files\IronstoneIT\Intune\DeviceConfiguration\' -f ($env:SystemDrive)))
    $null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'FileLog' -Value $([string]$('{0}IronTrigger - EnableBitLocker.log' -f ($Script:DirLog)))
    $null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'FileStats' -Value $([string]$('{0}stats.txt' -f ($Script:DirInstall)))
    
    ## Help
    ### Static / ReadOnly
    $null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'OSDriveLetter' -Value $([string]$($env:SystemDrive.Trim(':').ToUpper()))
    $null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'ComputerName' -Value $([string]$([string[]]$([string]($env:COMPUTERNAME).Trim(),[string]([System.Environment]::MachineName).Trim() -ne [string]::Empty)[0]))
    $null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'BitLockerVolumeEncryptionStatuses' -Value $([string[]]$('FullyDecrypted','EncryptionInProgress','FullyEncrypted'))
    ### Dynamic
    $Script:BoolDidAnythingChangeThisRuntime = [bool]$($false)    
#endregion Settings and Variables



#region Functions
    #region Logging and Output
        #region LogWrite
        Function LogWrite {
            Param (
                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [string] $LogString
            )

            # Create variables
            $DateTime  = [string]$([System.DateTime]::Now.ToString('yyMMdd HH:mm:ss:ff'))
            $LogString = [string]$('{0} {1}' -f ($DateTime,$LogString))
            
            # Add content to log file
            Add-content -Path $Script:FileLog -Value $LogString -Encoding 'utf8'
            
            # Output content to console
            Write-Output -InputObject $LogString
        }
        #endregion LogWrite

        #region LogErrors
        Function LogErrors {
            LogWrite ('Caught an exception:')
            LogWrite ('Exception Type:    {0}' -f ($_.'Exception'.GetType().'FullName'))
            LogWrite ('Exception Message: {0}' -f ($_.'Exception'.'Message'))
        }
        #endregion LogErrors


        #region Write-Stats
        # Write-Stats: Outputs current status of various booleans and other measurements
        Function Write-Stats {    
            Param(
                [parameter(Mandatory=$false)]
                [bool] $PreviousOnly = $false
            )
            # General
            if ($PreviousOnly) {
                LogWrite ('Runs: {0} | Has IronTrigger had a successfull run already? {1}' -f ($Script:CountRuns,$Script:IsFinished1stTime))
            }
            
            # OS Drive
            LogWrite ('OS drive ({0}) | Encrypted: {1} | Recovery Passwords present: {2} | Backup to OneDrive: {3} | Backup to AzureAD: {4}' -f ($OSDriveLetter,$Script:IsEncrypted,$Script:IsProtectionPassw,$Script:IsBackupOD,$Script:IsBackupAAD))
            if (-not($PreviousOnly)) {
                Logwrite ('OS drive ({0}) | VolumeStatus: {1} | ProtectionStatus: {2}' -f ($OSDriveLetter,$Script:VolumeEncryptionStatus,$Script:VolumeProtectionStatus))            
                if ($Script:VolumeHasTPMandPW) {
                    LogWrite ('OS drive ({0}) | Presence of BitLocker KeyProtector | TPM: {1} | RecoveryPassword: {2}' -f ($OSDriveLetter,$Script:VolumeHasTPMandPW[0],$Script:VolumeHasTPMandPW[1]))
                    if ($Script:VolumeEncryptionStatus[1]) {
                        LogWrite ('OS drive ({0}) | {1}' -f ($OSDriveLetter,(Write-RecoveryPassword)))
                    }
                }
            
                # Other fixed drives with a drive letter
                <# #TODO
                if ($Script:OtherEncryptedDrives) {
                    $Script:OtherEncryptedDrives | ForEach-Object {
                        if (-not([string]::IsNullOrEmpty($Script:OtherEncryptedDrives[0]))) {
                            [string] $Local:DriveVolumeStatus = (Get-Variable -Name ('Volume{0}EncStatus' -f $_) -Scope 'Script').Value
                            [string] $Local:DriveProtectionStatus = (Get-Variable -Name ('Volume{0}ProtectionStatus' -f $_) -Scope 'Script').Value
                            Logwrite ('Status drive "{0}" | VolumeStatus: {1} | ProtectionStatus: {2}' -f ($_,$Local:DriveVolumeStatus,$Local:DriveProtectionStatus))
                            [bool[]] $Local:KeyProtectorTypes = Get-BitLockerKeyProtectorTypes -DriveLetter $_
                            LogWrite ('BitLocker KeyProtector Types present for drive "{0}"? | TPM: {1} | RecoveryPassword: {2}' -f ($_,$Local:KeyProtectorTypes[0],$Local:KeyProtectorTypes[1]))
                        }
                    }
                }#>
            }
        }
        #endregion Write-Stats


        #region Write-RecoveryPassword
        # Write-RecoveryPassword
        Function Write-RecoveryPassword {
            $Local:C = [byte]$(if($Script:CountRecoveryPasswords){$Script:CountRecoveryPasswords}else{0})
            Return ([string]$('{0} Recovery Password(s) present.{1}' -f ($Local:C,($(if($Local:C -ge 1){'{0}{1}' -f ("`r`n",(Get-StringRecoveryPasswords))})))))
        }
        #endregion Write-RecoveryPassword


        #region Get-StringRecoveryPasswords
        # Returns a string containing the recovery passwords from $Script:ArrayRecoveryPasswords. Usefull for printing/ logging/ backup
        Function Get-StringRecoveryPasswords {
            Param(
                [Parameter(Mandatory=$false)]
                [ValidateNotNullOrEmpty()]
                [string] $DriveLetter = $OSDriveLetter
            )

            # Validate Input
            $Local:CurrentVolumeLetter = [string]$($DriveLetter.Trim(':').ToUpper())
            if ($Local:CurrentVolumeLetter.'Length' -gt 1) {
                Throw 'ERROR: Drive letter cannot be more than one letter'
            }


            # Create variable names
            $Local:ArrayName     = [string]$('{0}ArrayRecoveryPasswords' -f ($Local:CurrentVolumeLetter))


            # Get Array, loop it. Ideally only one pw, but loop just to be safe.
            $Local:TempCounter = [uint16]$(0)
            $Local:OutStr = [string]::Empty
            (Get-Variable -Name $Local:ArrayName -Scope 'Script' -ValueOnly) | ForEach-Object {
                $Local:OutStr += ('{0} | KeyProtectorId "{1}" | RecoveryPassword "{2}"' -f (($Local:TempCounter += 1),$_.KeyProtectorId,$_.RecoveryPassword))
                if ($Local:TempCounter -lt ((Get-Variable -Name $Local:ArrayName -Scope 'Script').Value).Count) {$Local:OutStr += "`r`n"}
            }


            # Return the string
            Return $Local:OutStr
        }
        #endregion Get-StringRecoveryPasswords
    #endregion Logging and Output



    #region Return Values (Used by other Functions)
        #region    Get-BitLockerKeyProtectorTypes
        Function Get-BoolDriveHasBitLockerTPMandPW {
            <#
                Returns a bool array, where the first represents status of TPM presence, and the second for Protection Password
            #>
            Param(
                [Parameter(Mandatory=$false)]
                [ValidateNotNullOrEmpty()]
                [string] $DriveLetter = $OSDriveLetter
            )
            
            # Validate Input
            $Local:CurrentVolumeLetter = [string]$($DriveLetter.Trim(':').ToUpper())
            if ($Local:CurrentVolumeLetter.'Length' -gt 1) {
                Throw 'ERROR: Drive letter cannot be more than one letter'
            }
            
            # Get BitLocker Volume
            $Local:BitLockerStatus = Get-BitLockerVolume -MountPoint $Local:CurrentVolumeLetter
            
            # Create object containing number of RecoveryPasswords (Index = 0) and TPM (Index = 1)
            $Local:CountRecPass = [uint16]$(0)
            $Local:CountTPM = [uint16]$(0)
            $Local:BitLockerStatus.'KeyProtector' | ForEach-Object {
                if ($_.'KeyProtectorType' -eq 'RecoveryPassword') {$Local:CountRecPass += 1}
                elseif ($_.'KeyProtectorType' -eq 'TPM') {$Local:CountTPM += 1}
            }
            
            # Return the object
            return ([bool]$($Local:CountTPM -ge 1),[bool]$($Local:CountRecPass -ge 1))
        }
        #endregion Get-BitLockerKeyProtectorTypes


        #region    Get-ArrayRecoveryPasswords
        # Returns a ArrayList with existing ProtectionPasswords
        Function Get-ArrayRecoveryPasswords {
            Param(
                [Parameter(Mandatory=$true)]
                [Microsoft.BitLocker.Structures.BitLockerVolume] $BitLockerVolume
            )
            
            # Get BitLocker ProtectionPasswords
            $Local:KeyProtectorStatus     = $BitLockerVolume | Select-Object -ExpandProperty 'KeyProtector'
            $Local:ArrayRecoveryPasswords = [Microsoft.BitLocker.Structures.BitLockerVolumeKeyProtector[]]$()

            $Local:KeyProtectorStatus | ForEach-Object -Process {
                if ($_.'KeyProtectorType' -eq 'RecoveryPassword') {
                    $Local:ArrayRecoveryPasswords += [Microsoft.BitLocker.Structures.BitLockerVolumeKeyProtector[]]$($_)
                }
            }
            
            # Return the object           
            return $Local:ArrayRecoveryPasswords
        }
        #endregion Get-ArrayRecoveryPasswords


        #region    Get-VolumeUniqueID
        Function Get-VolumeUniqueID {
            param(
                [Parameter(Mandatory=$true)]
                [ValidateNotNullOrEmpty()]
                [string] $DriveLetter
            )
            
            # Validate Input
            $Local:CurrentVolumeLetter = [string]$($DriveLetter.Trim(':').ToUpper())
            if ($Local:CurrentVolumeLetter.'Length' -gt 1) {
                Throw 'ERROR: Drive letter cannot be more than one letter'
            }

            # Get Unique Volume
            return [string]$(Get-Volume -DriveLetter $Local:CurrentVolumeLetter | Select-Object -ExpandProperty 'UniqueId').Split('{')[-1].Trim('}\')
        }
        #endregion Get-VolumeUniqueID


        #region    Refresh-BitLockerVariablesForCurrentVolume
        Function Refresh-BitLockerVariablesForCurrentVolume {
            param(
                [Parameter(Mandatory=$true)]
                [ValidateNotNullOrEmpty()]
                [string] $DriveLetter
            )
            
            # Validate Input
            $Local:CurrentVolumeLetter = [string]$($DriveLetter.Trim(':').ToUpper())
            if ($Local:CurrentVolumeLetter.Length -gt 1) {
                Throw 'ERROR: Drive letter cannot be more than one letter'
            }


            # Variables thats always present
            $Script:VolumeEncryptionStatus     = [string]$(Get-Variable -Name ('{0}VolumeEncryptionStatus' -f ($Local:CurrentVolumeLetter)) -Scope 'Script' -ValueOnly -ErrorAction 'Stop')
            $Script:VolumeProtectionStatus     = [string]$(Get-Variable -Name ('{0}VolumeProtectionStatus' -f ($Local:CurrentVolumeLetter)) -Scope 'Script' -ValueOnly -ErrorAction 'Stop')
            
            # Variables thats present only if theres at least one KeyProtector for current volume
            $Script:VolumeHasTPMandPW          = [bool[]]$(Get-Variable -Name ('{0}VolumeHasTPMandPW' -f ($Local:CurrentVolumeLetter)) -Scope 'Script' -ValueOnly -ErrorAction 'SilentlyContinue')
            $Script:VolumeEncryptionPercentage = [string]$(Get-Variable -Name ('{0}VolumeEncryptionPercentage' -f ($Local:CurrentVolumeLetter)) -Scope 'Script' -ValueOnly -ErrorAction 'SilentlyContinue')
            
            # Variables thats present only if current volume is protected with minimum a TPM and a Recovery Password
            $Script:ArrayRecoveryPasswords     = Get-Variable -Name ('{0}ArrayRecoveryPasswords' -f ($Local:CurrentVolumeLetter)) -Scope 'Script' -ValueOnly -ErrorAction 'SilentlyContinue'
            $Script:CountRecoveryPasswords     = [byte]$(Get-Variable -Name ('{0}CountRecoveryPasswords' -f ($Local:CurrentVolumeLetter)) -Scope 'Script' -ValueOnly -ErrorAction 'SilentlyContinue')
        }
        #endregion Refresh-BitLockerVariablesForCurrentVolume


        #region    Check-IfBitLockerPWHasChanged
        Function Check-IfBitLockerPWHasChanged {
            param(
                [Parameter(Mandatory=$false)]
                [ValidateNotNullOrEmpty()]
                [string] $DriveLetter = $OSDriveLetter
            )
            
            # Help Variables
            $Local:HasChanged = [bool]$($false)
            $Local:CurrentVolumeLetter = [string]$($DriveLetter.Trim(':').ToUpper())
            if ($Local:CurrentVolumeLetter.'Length' -gt 1) {
                Throw 'ERROR: Drive letter cannot be more than one letter'
            }

            # Name Variables
            $Local:NameArray = [string]$('{0}ArrayRecoveryPasswords' -f ($Local:CurrentVolumeLetter))
            $Local:VolumeUniqueID = [string]$(Get-VolumeUniqueID -DriveLetter $Local:CurrentVolumeLetter)
            $Local:NameFile = [string]$('{0}.txt' -f ($VolumeUniqueID))
           
            # Get Variables
            $Local:PathDir = [string]$('{0}{1}' -f ($Script:DirInstall,'BackupKeys\'))
            $Local:PathFile = [string]$('{0}{1}' -f ($Local:PathDir,$Local:NameFile))
            $Local:NowKeyProtectorID = [string]$(((Get-Variable -Name $Local:NameArray -Scope 'Script').'Value').'KeyProtectorID')
            $Local:NowRecoveryPassword = [string]$(((Get-Variable -Name $Local:NameArray -Scope 'Script').'Value').'RecoveryPassword')


            # Get stats
            if (-not (Test-Path -Path $Local:PathFile)) {
                $Local:HasChanged = $true
                if (-not(Test-Path -Path $Local:PathDir -ErrorAction 'SilentlyContinue')) {
                    $null = New-Item -Path $Local:PathDir -ItemType 'Directory' -Force
                }
            }
            else {
                $Local:InputString = [string[]]$((Get-Content -Path $Local:PathFile).Split([Environment]::NewLine))
                if ($? -and $Local:InputString.'Length' -ge 7) {
                    $Local:PrevKeyProtectorID = [string]$($Local:InputString[5].Trim())
                    $Local:PrevRecoveryPassword = [string]$($Local:InputString[7].Trim())
                }
                else {$Local:HasChanged = $true}
            }


            # Check if changed
            if ($Local:PrevKeyProtectorID) {
                if ($Local:PrevKeyProtectorID -ne $Local:NowKeyProtectorID) {$Local:HasChanged = $true}
                if ($Local:PrevRecoveryPassword -ne $Local:NowRecoveryPassword) {$Local:HasChanged = $true}
            }


            # Write new values if changed or does not exist
            if ($Local:HasChanged -or (-not (Test-Path -Path $Local:PathFile))) {
                $Local:OutStr = [string]::Empty
                $Local:OutStr += 'Drive/Volume Letter (Not Unique identifier):{0}' -f "`r`n"
                $Local:OutStr += '{0}{1}' -f $CurrentVolumeLetter,"`r`n"
                $Local:OutStr += 'Volume UniqueID (Name of this file):{0}' -f "`r`n"
                $Local:OutStr += '{0}{1}' -f $Local:VolumeUniqueID,"`r`n"
                $Local:OutStr += 'KeyProtectorID:{0}' -f "`r`n"
                $Local:OutStr += '{0}{1}' -f $Local:NowKeyProtectorID,"`r`n"
                $Local:OutStr += 'Recovery Password:{0}' -f "`r`n"
                $Local:OutStr += '{0}{1}' -f $Local:NowRecoveryPassword,"`r`n"
                $null = Out-File -FilePath $Local:PathFile -Encoding 'utf8' -Force -InputObject ($Local:OutStr)
            }



            # Return status
            return $Local:HasChanged
        }
        #endregion Check-IfBitLockerPWHasChanged
    #endregion Return Values (Used by other Functions)



    #region Set Script Wide Variables
        #region Get-BitLockerStatus
        Function Get-BitLockerStatus {
            <#
                * Fills two strings with current Volume Encryption Status, and Volume Protection Status. 
                * Also makes a bool array with true false for | 1: TPM present | 2: Recovery Password Present
            #>
            Param(
                [Parameter(Mandatory=$false)]
                [ValidateNotNullOrEmpty()]
                [string] $DriveLetter = $OSDriveLetter
            )

            # Help variable
            $Local:CurrentVolumeLetter = [string]$($DriveLetter.Trim(':').ToUpper())
            if ($Local:CurrentVolumeLetter.'Length' -ne 1) {
                Throw 'ERROR: Drive letter cannot be more or less than one letter!'
            }

            # Get BitLocker Status for Volume
            $Local:BitLockerVolumeStatus = [Microsoft.BitLocker.Structures.BitLockerVolume]$(Get-BitLockerVolume -MountPoint $Local:CurrentVolumeLetter)
                  
            # BitLocker Volume Encryption Status: FullyDecrypted | EncryptionInProgress | FullyEncrypted
            New-Variable -Name ('{0}VolumeEncryptionStatus' -f ($Local:CurrentVolumeLetter)) -Scope 'Script' -Force `
                         -Value ([string]$($Local:BitLockerVolumeStatus | Select-Object -ExpandProperty 'VolumeStatus'))
            
            # BitLocker Volume Protection Status: ON if Encryption Percentage = 100%
            New-Variable -Name ('{0}VolumeProtectionStatus' -f ($Local:CurrentVolumeLetter)) -Scope 'Script' -Force `
                         -Value ([string]$($Local:BitLockerVolumeStatus | Select-Object -ExpandProperty 'ProtectionStatus'))
            
            
            
            <#  
                    Volume can be 'Fully Decrypted', but still have a TPM present. 
                    This is usually the case right after encryption has started. 
            #>


            # If there is a KeyProtector for given volume, get the rest of the variables
            if ($Local:BitLockerVolumeStatus.'KeyProtector'.'Count' -gt 0) {
                # [0} = Volume has TPM?   [1] = Volume has Recovery Password?
                New-Variable -Name ('{0}VolumeHasTPMandPW' -f ($Local:CurrentVolumeLetter)) -Scope 'Script' -Force `
                             -Value ([bool[]]$(Get-BoolDriveHasBitLockerTPMandPW -DriveLetter $CurrentVolumeLetter))          
                
                # Encryption Percentage: How long has the encryption process come
                New-Variable -Name ('{0}VolumeEncryptionPercentage' -f ($Local:CurrentVolumeLetter)) -Scope 'Script' -Force `
                             -Value ([string]$($Local:BitLockerVolumeStatus | Select-Object -ExpandProperty 'EncryptionPercentage').ToString())                
                                             
                
                # If Drive has TPM and PW
                if ((Get-Variable -Name ('{0}VolumeHasTPMandPW' -f ($Local:CurrentVolumeLetter)) -Scope 'Script').Value[1]) {
                    # Name the variables
                    $Local:NameArrayRecoveryPasswords = [string]$('{0}ArrayRecoveryPasswords' -f ($Local:CurrentVolumeLetter))
                    $Local:NameCountRecoveryPasswords = [string]$('{0}CountRecoveryPasswords' -f ($Local:CurrentVolumeLetter))

                    # Get Array with protection passwords
                    New-Variable -Name $Local:NameArrayRecoveryPasswords -Scope 'Script' -Force `
                                 -Value (Get-ArrayRecoveryPasswords -BitLockerVolume $Local:BitLockerVolumeStatus)

                    # Count ArrayRecoveryPasswords
                    New-Variable -Name $Local:NameCountRecoveryPasswords -Scope 'Script' -Force `
                                 -Value ([byte]$((Get-Variable -Name $Local:NameArrayRecoveryPasswords).'Value').'Length')

                    # Get Volume Unique ID (to check if protection password has changed)
                    New-Variable -Name ('{0}VolumeUniqueID' -f ($Local:NameVolume)) -Scope 'Script' -Force `
                                 -Value ((Get-VolumeUniqueID -DriveLetter $Local:CurrentVolumeLetter))
                }
            }
        }
        #endregion Get-BitLockerStatus
    #endregion Set Script Wide Variables



    #region Registry Functions
        #region Create-EnvVariables
        # Create-EnvVariables: Creates variables used by the troubleshooter at the bottom, when failed runs reaches a given number.  
        Function Create-EnvVariables {
            #### Script Wide Variables
            ## Tenant
            $Local:PathDirRegTenantJoinInfoBase = [string]$('Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo')
            $Local:PathDirRegTenantJoinInfoFull = [string]$('{0}\{1}' -f ($Local:PathDirRegTenantJoinInfoBase,
                (Get-ChildItem -Path $Local:PathDirRegTenantJoinInfoBase | Select-Object -ExpandProperty 'Name').Split('\')[-1]
            ))
            $Script:NameTenant = [string]$(Get-ItemProperty -Path $Local:PathDirRegTenantJoinInfoFull).'UserEmail'.Split('@')[1]
            $Script:NameTenantShort = [string]$($Script:NameTenant.Split('.')[0])
            
            ## Hardware and Windows info
            $Script:ComputerManufacturer = [string]$(Query-Registry -Dir 'Registry::HKEY_LOCAL_MACHINE\HARDWARE\DESCRIPTION\System\BIOS\SystemManufacturer')
            if (-not([string]::IsNullOrEmpty($Script:ComputerManufacturer))) {
                $Script:ComputerFamily = [string]$(Query-Registry -Dir 'Registry::HKEY_LOCAL_MACHINE\HARDWARE\DESCRIPTION\System\BIOS\SystemFamily')
                $Script:ComputerProductName = [string]$(Query-Registry -Dir 'Registry::HKEY_LOCAL_MACHINE\HARDWARE\DESCRIPTION\System\BIOS\SystemProductName')
                $Script:WindowsEdition = [string]$(Query-Registry -Dir 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProductName')
                $Script:WindowsVersion = [string]$(Query-Registry -Dir 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ReleaseId')
                $Script:WindowsVersion += [string]$(' ({0})' -f (Query-Registry -Dir 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\CurrentBuild'))
            } 
            else {
                $Local:EnvInfo = Get-WmiObject -Class 'Win32_ComputerSystem' | Select-Object -Property 'Manufacturer','Model','SystemFamily'
                $Script:ComputerManufacturer = [string]$($Local:EnvInfo.'Manufacturer')
                $Script:ComputerFamily = [string]$($Local:EnvInfo.'SystemFamily')
                $Script:ComputerProductName = [string]$($Local:EnvInfo.'Model')
                $Local:OSInfo = Get-WmiObject -Class 'Win32_operatingsystem' | Select-Object -Property 'Caption','Version'
                $Script:WindowsEdition = [string]$($Local:OSInfo.'Caption')
                $Script:WindowsVersion = [string]$($Local:OSInfo.'Version')
            }
        }
        #endregion Create-EnvVariables


        #region    Query-Registry
        Function Query-Registry {
            Param ([Parameter(Mandatory=$true)] [string] $Dir)
            $Local:Out = [string]::Empty
            $Local:Key = [string]$($Dir.Split('{\}')[-1])
            $Local:Dir = [string]$($Dir.Replace($Local:Key,''))
        
            $Local:Exists = Get-ItemProperty -Path ('{0}' -f $Dir) -Name ('{0}' -f $Local:Key) -ErrorAction 'SilentlyContinue'
            if ($Exists) {
                $Local:Out = $Local:Exists.$Local:Key
            }
            return $Local:Out
        }
        #endregion Query-Registry
    #endregion Registry Functions



    #region    Edit-ScheduledTask
    function Edit-ScheduledTask {
        Param(
            [Parameter(Mandatory=$false)]
            [string] $TaskName = $Script:ScheduledTaskName
        )

        $Task = Get-ScheduledTask -TaskName $TaskName -ErrorAction 'SilentlyContinue'

        if ($Task) {
            if ($Script:BoolRemoveScheduledTaskAfterFirstSuccess) {
                $null = Unregister-ScheduledTask -TaskName $Task -Confirm:$false -ErrorAction 'SilentlyContinue'
                LogWrite ('Removing the Scheduled task "{0}". Success? {1}' -f ($Task.'TaskName',$?.ToString()))
            }
            else {
                $Local:NewSchedTime = [datetime]$([datetime]::Today.AddHours(12))
                $null = Set-ScheduledTask -TaskName $Script:ScheduledTaskName -Trigger (New-ScheduledTaskTrigger -Daily -At $Local:NewSchedTime) -ErrorAction 'SilentlyContinue'
                LogWrite ('Editing Scheduled task "{0}" to start daily at {1}. Success? {2}.' -f ($Script:ScheduledTaskName,$Local:NewSchedTime.'Hour'.ToString(),$?.ToString()))
            }
        }
        else {
            LogWrite ('Found no Scheduled Task with name "{0}".' -f ($TaskName))
        }
    }
    #endregion Edit-ScheduledTask


    #region    Prompt-Reboot
    Function Prompt-Reboot {
        $Local:TimeToRebootInMinutes = [uint16]$(60)
        $Local:StrShortMessage = [string]$('Windows will restart in {0} minutes to finish device configuration. Save your work!' -f ($Local:TimeToRebootInMinutes))
        $null = cmd.exe /c ('shutdown /r /t {0} /c "{1}"' -f ($Local:TimeToRebootInMinutes*60),$Local:StrShortMessage) 2>&1
        if (-not($?)) {
            $null = cmd.exe /c ('shutdown /a') 2>&1
            $null = cmd.exe /c ('shutdown /r /t {0} /c "{1}"' -f ($Local:TimeToRebootInMinutes*60),$Local:StrShortMessage) 2>&1
        }

        <# FOR FUTURE ENHANCEMENTS
        [string] $Local:StrMessage = 'Your computer are awaiting a restart:'
        $Local:StrMessage += '{0} Your organization requires your hard' -f "`r`n"
        $Local:StrMessage += '{0} drive to be encypted. In order to' -f "`r`n"
        $Local:StrMessage += '{0} finish this process, you need to' -f "`r`n"
        $Local:StrMessage += '{0} restart your computer. You can' -f "`r`n"
        $Local:StrMessage += '{0} either do it manually, or it will' -f "`r`n"
        $Local:StrMessage += '{0} automatically happen in' -f "`r`n"
        $Local:StrMessage += '{0} {1} minutes.' -f "`r`n",$Local:TimeToRebootInMinutes
        $Local:StrMessage += '{0}{0} SAVE YOUR WORK!' -f "`r`n"
        #>
    }
    #endregion Prompt-Reboot    
#endregion Functions



#region Initialize
    LogWrite ('###################################################')
    LogWrite ('Starting Trigger BitLocker script.')
    LogWrite ('###################################################')
    LogWrite ('### Get stats.')
    ############################
    ## Fetch prev run results ##
    ############################    
    if (-not(Test-Path -Path $Script:FileStats)) {
        $Script:CountRuns = [uint16]$(0)
        $Script:IsFinished1stTime = $Script:IsEncrypted = $Script:IsProtectionPassw = $Script:IsBackupOD = $Script:IsBackupAAD = [bool]$($false)
        $Script:OSDriveKeyID = $Script:OSDriveProtectionPassword = [string]::Empty
        LogWrite ('# First run!')
    }
    else {
        $InputString = [string[]]$(Get-Content -Path $Script:FileStats).Split([Environment]::NewLine)
        $Script:CountRuns = [uint16]$($InputString[0])
        $Script:IsFinished1stTime = [uint16]$($InputString[1])
        $Script:IsEncrypted = [uint16]$($InputString[2])
        $Script:IsProtectionPassw = [uint16]$($InputString[3])
        $Script:IsBackupOD = [uint16]$($InputString[4])
        $Script:IsBackupAAD = [uint16]$($InputString[5])
        $Script:OSDriveKeyID = [string]$($InputString[6])
        $Script:OSDriveProtectionPassword = [string]$($InputString[7])
        LogWrite ('# Previous run results:')
        Write-Stats -PreviousOnly $true
    }
    

    ############################
    #### Get current status ####
    ############################  
    LogWrite ('# Current status:')
        
    # Get Current Status for OS Drive
    Get-BitLockerStatus -DriveLetter $Script:OSDriveLetter
    Refresh-BitLockerVariablesForCurrentVolume -DriveLetter $Script:OSDriveLetter
    

    if ($Script:VolumeHasTPMandPW) {
        if ($Script:VolumeHasTPMandPW[0]) {
            $Script:IsEncrypted = [bool]$($Script:VolumeEncryptionStatus -eq $Script:BitLockerVolumeEncryptionStatuses[2])
        }
        if ($Script:VolumeHasTPMandPW[1]) {
            $Script:IsProtectionPassw = [bool]$($Script:CountRecoveryPasswords -eq 1)
        }                   
    }
    else {
        $Script:IsEncrypted = $Script:IsProtectionPassw = [bool]$($false)
    }


    # Other Fixed Drives
    #TODO
    <#
    [String[]] $Script:FixedVolumesLetters = @((Get-Volume | `
        Where-Object {$_.DriveType -eq 'Fixed' -and (-not([string]::IsNullOrEmpty($_.DriveLetter)))} | `
        Where-Object {$_.DriveLetter -ne $OSDriveLetter.Replace(':','')}).DriveLetter)
    
    $Script:FixedVolumesLetters | ForEach-Object {
        if (-not([string]::IsNullOrEmpty($_))) {
            Get-BitlockerStatus -DriveLetter $_
            if ((Get-Variable -Name ('{0}CountProtectionKeys' -f $_) -Scope 'Script').Length -gt 0) {
                [string[]] $Script:OtherEncryptedDrives += @($_)
            }
        }     
    }#>

    Write-Stats
#endregion Initialize
    


#region Main
#region Encryption
##############################
#### BitLocker Encryption ####
##############################
LogWrite ('### BitLocker Encryption')



#####################################
# BitLocker Encryption of OS Drive  #
#####################################
#region BitLocker Encryption of OS Drive

LogWrite ('# BitLocker Encryption of OS Drive')
if ($Script:IsEncrypted) {
    LogWrite ('OS Drive is already fully encrypted.')
}
else {
    $Script:BoolDidAnythingChangeThisRuntime = [bool]$($true)
    
    # If 'FullyEncrypted', and TPM present
    ## Means that OS Drive is successfully encrypted with BitLocker
    if (($Script:VolumeEncryptionStatus -eq $Script:BitLockerVolumeEncryptionStatuses[2]) -and $Script:VolumeHasTPMandPW[0]) {
        LogWrite ('OS Drive is fully encrypted!')
        $Script:IsEncrypted = $true
    }
    

    # If 'EncryptionInProgress' and TPM present
    ## Means computer has restarted after BitLocker encryption was enabled. Waiting for the volume to get encrypted
    elseif ($Script:VolumeEncryptionStatus -eq $Script:BitLockerVolumeEncryptionStatuses[1] -and $Script:VolumeHasTPMandPW[0]) {
        LogWrite ('OS Drive encryption is in progress:')
        LogWrite ('Restart have taken place, and encryption has started.')
        LogWrite ('OS Drive Encryption Percentage: {0}%.' -f ($Script:VolumeEncryptionPercentage))
        LogWrite ('Can continue to check if Recovery Password is present, and backup it.')
    }


    # If 'FullyDrectypted'     
    elseif ($Script:VolumeEncryptionStatus -eq $Script:BitLockerVolumeEncryptionStatuses[0]) {        
        # If 'FullyDrectypted' but there exists a TPM
        ## Means that encryption has started, but computer is awaiting restart
        if ($Script:VolumeHasTPMandPW -and $Script:VolumeHasTPMandPW[0]) {
            LogWrite ('OS Drive Encryption has started, but computer has not been restarted yet.')
            LogWrite ('OS Drive Encryption Percentage: {0}%.' -f ($Script:VolumeEncryptionPercentage))
            LogWrite ('Can continue to check if Recovery Password is present, and backup it.')
        }
        
        # Else
        ## Means BitLocker should be enabled
        else {
            LogWrite ('OS Drive is not encrypted.')
            LogWrite ('Attempting to Enable BitLocker on OS drive ({0})' -f ($OSDrive))
            
            # Set $SkipHardwareTest
            $SkipHardwareTest = [bool]$(
                if ($Script:BoolSkipHardwareTestOnNewlyEnrolledDevice) {
                    # Set to true if it's less than one day since enrollment.
                    $Path = ('{0}\Microsoft Intune Management Extension' -f (${env:ProgramFiles(x86)}))
                    [bool]$(
                        [datetime]$(
                            if ([bool]$(Test-Path -Path $Path -ErrorAction 'SilentlyContinue')) {
                                Try{
                                    $Date = [datetime]$(Get-Item -Path $Path -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'CreationTimeUtc')
                                    if ($Date -ne [datetime]::MinValue) {
                                        $Date
                                    }
                                    else{
                                        [datetime]::UtcNow
                                    }
                                }
                                Catch{
                                    [datetime]::UtcNow
                                }
                            }
                            else {
                                [datetime]::UtcNow
                            }
                        ) -gt [datetime]::UtcNow.AddDays(-1)
                    )
                }
                else {
                    $false
                }
            )
            
            # Try to enable BitLocker
            try {
                # Enable BitLocker using TPM
                $null = Enable-BitLocker -MountPoint $OSDriveLetter -TpmProtector -UsedSpaceOnly:$false -HardwareEncryption:$false -SkipHardwareTest:$SkipHardwareTest -ErrorAction 'Continue'
                if ($?) {
                    LogWrite ('Successfully enabled bitlocker.')                   
                }
                else {
                    LogWrite ('Failed Enabling Bitlocker TpmProtector, it`s probably already enabled')
                }
            } 
            catch {
                LogErrors
                Enable-BitLocker -MountPoint $OSDriveLetter -TpmProtector -UsedSpaceOnly:$false -HardwareEncryption:$false -SkipHardwareTest:$SkipHardwareTest -ErrorAction 'SilentlyContinue'
                LogWrite ('Will attempt to Enable BitLocker anyway and then continue. Success? {0}' -f ($?))
            }
            finally {
                LogWrite ('Did we actually enable BitLocker?')
                
                # Refresh Variables
                Get-BitLockerStatus -DriveLetter $OSDriveLetter
                Refresh-BitLockerVariablesForCurrentVolume -DriveLetter $OSDriveLetter

                # Check result
                if ($Script:VolumeHasTPMandPW -and $Script:VolumeHasTPMandPW[0]) {
                    LogWrite ('TPM present for OS Drive? {0}' -f ($Script:VolumeHasTPMandPW[0]))
                    
                    # Prompt reboot if not $SkipHardwareTest
                    if ($SkipHardwareTest) {
                        LogWrite ('Not prompting for reboot - $SkipHardwareTest is $true.')
                    }
                    else {
                        LogWrite ('Prompting reboot - $SkipHardwareTest is $false.')
                        Prompt-Reboot
                    }
                }
                else {
                    LogWrite ('ERROR, not encrypted. TPM not present for OS Drive')
                }
            }
        }
    }
    # If scenario fits none of the cases above..
    else {
        LogWrite ('Neither "{0}", "{1}" or "{2}".' -f ($Script:BitLockerVolumeEncryptionStatuses[0],$Script:BitLockerVolumeEncryptionStatuses[1],$Script:BitLockerVolumeEncryptionStatuses[2]))
    }
}
#endregion BitLocker Encryption of OS Drive



#####################################
# Protection Password for OS Drive  #
#####################################
#region Protection Password for OS Drive

LogWrite ('# BitLocker Protection Password for OS Drive')
# If 'FullyEncrypted', or TMP is present
if ($Script:IsEncrypted -or ($Script:VolumeHasTPMandPW -and $Script:VolumeHasTPMandPW[0])) {
    
    
    # If we're done with recovery password(s) already
    if ($Script:IsProtectionPassw -and ($Script:CountRecoveryPasswords -eq 1)) {
        LogWrite 'Recovery Password for OS Drive is already present'
    }
    

    # If we're not done with recovery password(s)
    else {        
        $Script:BoolDidAnythingChangeThisRuntime = [bool]$($true)
        $Local:Success = [bool]$($false)
        
        
        # If there exists BitLocker Encryption Recovery Password       
        if ($Script:VolumeHasTPMandPW[1]) {
            

            # If theres is _a_ ProtectionPassword, we're done
            if ($Script:CountRecoveryPasswords -eq 1) {
                LogWrite 'Only a password present'
                $Script:IsProtectionPassw = $true
                $Local:Success = $true
            }


            # If there is multiple RecoveryPasswords, we need to remove all but one
            elseif ($Script:CountRecoveryPasswords -gt 1) {
                LogWrite 'Multiple passwords present'
                Write-RecoveryPassword
                LogWrite ('Will remove all but the first one')
                $Script:ArrayRecoveryPasswords | ForEach-Object { 
                    if ($_.'KeyProtectorId' -ne $Script:ArrayRecoveryPasswords[0].'KeyProtectorId') {
                        $null = Remove-BitLockerKeyProtector -MountPoint $OSDriveLetter -KeyProtectorId $_.'KeyProtectorId'
                        if ($?) {
                            LogWrite ('Successfully removed | KeyProtectorId "{0}" | RecoveryPassword "{1}"' -f ($_.'KeyProtectorId',$_.'RecoveryPassword'))
                        }
                    }
                    else {
                        LogWrite ('Successfully skipped the first key. | KeyProtectorId "{0}" | RecoveryPassword "{1}"' -f ($_.'KeyProtectorId',$_.'RecoveryPassword'))
                    }
                }
               
                Get-BitLockerStatus
                if ($Script:VolumeHasTPMandPW -and $Script:VolumeHasTPMandPW[1] -and ($Script:CountRecoveryPasswords -eq 1)) {
                    $Local:Success = $true
                }              
            }


            # This should not be possible
            else {
                LogWrite 'ERROR: RecoveryPassword present, but count < 1'
            }
        }

        
        #region Add Protection Password If None Present
        else {
            LogWrite ('No BitLocker Recovery Passwords found for OS Drive {0}, creating one.' -f ($OSDriveLetter))
            try {
                $null = Add-BitLockerKeyProtector -MountPoint $OSDriveLetter -RecoveryPasswordProtector -ErrorAction 'SilentlyContinue' -WarningAction 'SilentlyContinue'
                if ($?) {
                    $Local:Success = $true
                }
                else {
                    $null = Enable-BitLocker -MountPoint $OSDriveLetter -RecoveryPasswordProtector -UsedSpaceOnly:$false -HardwareEncryption:$false -SkipHardwareTest:$false -ErrorAction 'Stop'
                    if ($?) {
                        $Local:Success = $true
                    }
                } 
            } 
            catch {
                LogErrors
                $null = Add-BitLockerKeyProtector -MountPoint $OSDriveLetter -RecoveryPasswordProtector -ErrorAction 'SilentlyContinue' -WarningAction 'SilentlyContinue'
                if ($LastExitCode -eq 0) {
                    $Local:Success = $true
                }
                else {
                    $null = Enable-BitLocker -MountPoint $OSDriveLetter -RecoveryPasswordProtector -UsedSpaceOnly:$false -HardwareEncryption:$false -SkipHardwareTest:$false -ErrorAction 'SilentlyContinue'
                    if ($?) {
                        $Local:Success = $true
                    }
                }
            }
            finally {
                LogWrite ('Tried to add BitLocker RecoveryPasswordProtector. Success? {0}.' -f ($Local:Success))
                        
            }
        }
        #endregion Add Protection Password If None Present

        

        # Count and list existing RecoveryPassword, only write success if theres one        
        if ($Local:Success) {
            LogWrite 'Checking if there is only one Protection Password.'
            
            # Refresh Variables for current volume
            Get-BitLockerStatus -DriveLetter $OSDriveLetter
            Refresh-BitLockerVariablesForCurrentVolume -DriveLetter $OSDriveLetter

            # Check results
            $Local:BoolTemp = [bool]$(if($Script:VolumeHasTPMandPW){($Script:VolumeHasTPMandPW[1])}else{$false})
            LogWrite ('Protection Password Present? {0}' -f ($Local:BoolTemp))
                    
            if ($Local:BoolTemp) {                                   
                if ($Script:CountRecoveryPasswords -eq 1) {             
                    LogWrite ('SUCCESS, keys left: 1.')
                    $Script:IsProtectionPassw = $true
                }               
                else {
                    LogWrite 'FAIL, keys left: {0}.' -f ($Script:CountRecoveryPasswords)
                    $Script:IsProtectionPassw = $false
                }  
            }
            else {
                LogWrite ('FAIL, no Protection Password found')
            }                    
        }                    
        else {
            LogWrite ('Something failed')
        }                    
    }
    #endregion If theres 0 or multiple ProtectionsPassword(s) 
}


# Not encrypted = No making of RecoveryPassword
else {
    LogWrite ('OS Drive is "FullyDecrypted" and there exists no "TPM".')
    LogWrite ('BitLocker RecoveryPassword can not be added at this time.')
    LogWrite ('Recovery Password present? {0}' -f ([string]$(if($Script:VolumeHasTPMandPW){$Script:VolumeHasTPMandPW[0]}else{$false})))
    $Script:IsProtectionPassw = $false
}

# Write recovery password(s) if anything changed this runtime
if ($Script:BoolDidAnythingChangeThisRuntime -and $Script:VolumeHasTPMandPW[1]) {
    Write-RecoveryPassword
}
#endregion Protection Password for OS Drive
#endregion Encryption



####################
###### BACKUP ######
####################
#region Backup


LogWrite ('### Backup Protection Password to AzureAAD and OneDrive4B')

# Check for changes if Finished1stTime
if ($Script:IsFinished1stTime -or $Script:IsBackupAAD -and [bool]$([bool]$($Script:BoolBackupToOneDriveForBusiness -and $Script:IsBackupOD) -or [bool]$(-not($Script:BoolBackupToOneDriveForBusiness)))) {
    LogWrite ('Drive is already backed up.')
    LogWrite ('Will check if anything has changed.')

    if (Check-IfBitLockerPWHasChanged) {
        LogWrite 'Something has changed, BitLocker Recovery Protection Password is not the same as the one backed up.'
        $Script:IsBackupAAD = $Script:IsBackupOD = $false
        $Script:BoolDidAnythingChangeThisRuntime = $true
    }
    else {
        LogWrite 'Nothing has changed, BitLocker Recovery Protection Password is the same as the one previously backed up.'
    }
}


# If no backups
if (-not($Script:IsBackupAAD -and [bool]$([bool]$($Script:BoolBackupToOneDriveForBusiness -and $Script:IsBackupOD) -or [bool]$(-not($Script:BoolBackupToOneDriveForBusiness))))) {
    # If ProtectionPassword(s) exist
    if ($Script:IsProtectionPassw) {
            
        LogWrite ('OS Drive is encrypted, and there are {0} ProtectionPassword(s) present.' -f ($Script:ArrayRecoveryPasswords.'Count'))
        LogWrite ('Writing existing RecoveryPassword for current drive, for future reference...')
        $null = Check-IfBitLockerPWHasChanged
        
        LogWrite ('Continuing with backup.')

    
        ##############################
        # OneDrive for Business backup
        ##############################
        #region Backup OneDrive for Business
    
        LogWrite ('# Backup to OneDrive')
        if (-not$Script:BoolBackupToOneDriveForBusiness) {
            LogWrite ('Disabled in script settings.')
        }
        else {
            LogWrite ('Enabled in script settings.')
            if ($Script:IsBackupOD) {
                LogWrite ('Already done')
            }                
            else {
                $Script:BoolDidAnythingChangeThisRuntime = $true
            
                Try {
                    # Get Current User as SecurityIdentifier
                    if (-not($Script:PathDirRootCU)){
                        $Script:PathDirRootCU = [string]$('Registry::HKEY_USERS\{0}\' -f ([System.Security.Principal.NTAccount]::new((Get-Process -Name 'explorer' -IncludeUserName | Select-Object -ExpandProperty 'UserName' -First 1)).Translate([System.Security.Principal.SecurityIdentifier]).'Value'))
                        if((-not($?)) -or [string]::IsNullOrEmpty($PathDirRootCU)){Break}
                    }
                
                
                    # Get OneDrive for Business path from registry                 
                    $RegValues = [array]$(Get-ChildItem -Path ('{0}\SOFTWARE\Microsoft\OneDrive\Accounts\' -f ($PathDirRootCU)) | Where-Object -Property 'Name' -like '*\Business*')
                    
                    # Exit Try/Catch if no accounts where found
                    if ($RegValues.'Count' -le 0) {                        
                        $Script:IsBackupOD = $false
                        Throw ('Failed to find OneDrive for Business accounts.')
                    }

                    # For each found OneDrive for Business account
                    foreach ($RegValue in $RegValues) {                        
                        $Local:PathDirOD4B = [string]$(Get-ItemProperty -Path $RegValue.'Name'.Replace('HKEY_USERS\','Registry::HKEY_USERS\') -Name 'UserFolder').'UserFolder'
                        
                        # Exit Try/Catch if failed to build path for OneDrive for Business folder     
                        if ($Local:PathDirOD4B -notlike ('{0}\Users\*\OneDrive -*' -f ($OSDrive)) -and (-not[bool]$(Test-Path -Path $Local:PathDirOD4B))) {                            
                            $Script:IsBackupOD = $false
                            Throw ('Failed to build OneDrive path ("{0}"), or it does not exist.' -f ($Local:Path))
                        }
                        
                                                          
                        # Create script variables if they do not exist already
                        if (-not($Script:ComputerProductName)) {
                            Create-EnvVariables
                        }
                            
                        # Runtime variable
                        $Local:BoolFolderExists = [bool]$($false)
                            

                        # Creating paths
                        $Local:PathDirOD4BBackupParent = [string]$('{0}\BitLocker Recovery\' -f ($Local:PathDirOD4B))
                        $Local:PathDirOD4BBackup = [string]$('{0}{1} ({2} {3})\' -f ($Local:PathDirOD4BBackupParent,$Script:ComputerName,$Script:ComputerManufacturer,$Script:ComputerProductName))
                        LogWrite ('OneDrive for Business Path: {0}' -f ($Local:PathDirOD4B))
                        LogWrite ('Backup Path Parent:         {0}' -f ($Local:PathDirOD4BBackupParent))
                        LogWrite ('Backup Path for Bitlocker Recovery Key(s): {0}' -f ($Local:PathDirOD4BBackup)) 
                            

                        #Testing if Recovery folder exists if not create one
                        LogWrite ('Testing if backup folder exists, create it if not.')
                        if (Test-Path -Path $Local:PathDirOD4BBackup -ErrorAction 'SilentlyContinue') {
                            $Local:BoolFolderExists = $true
                        }
                        else {
                            LogWrite 'Creating OneDrive for Business folder for backup.'
                            $null = New-Item -Path $Local:PathDirOD4BBackup -ItemType 'Directory' -Force 
                            $Local:BoolFolderExists = Test-Path -Path $Local:PathDirOD4BBackup
                            LogWrite ('{0}' -f $(if($Local:BoolFolderExists){'Success.'}else{'Failed.'}))
                        }                        
                            

                        # Exit Try/Catch of failed to create OneDrive for Business Backup if it didn't exist
                        if (-not($Local:BoolFolderExists)) {
                            $Script:IsBackupOD = $false
                            Throw 'Failed to check or create folder.'
                        }
                        
                        # Make sure 'BitLocker Recovery' folder is hidden
                        LogWrite ('Making sure "{0}" is hidden.' -f ($Local:PathDirOD4BBackupParent))
                        if ((Get-Item -Path $Local:PathDirOD4BBackupParent -Force).Attributes -notlike '*hidden*') {
                            (Get-Item -Path $Local:PathDirOD4BBackupParent -Force).Attributes = (Get-Item -Path $Local:PathDirOD4BBackupParent -Force).Attributes -bor 'Hidden'
                            LogWrite ('Successfully hidden? {0}.' -f ($?))
                        }
                        else {
                            LogWrite ('Already hidden.')
                        }
                                

                        # Get ArrayRecoveryPasswords for current volume
                        $Local:CurrentVolumeArrayRecoveryPasswords = Get-Variable -Name ('{0}ArrayRecoveryPasswords' -f ($OSDriveLetter)) -Scope 'Script' -ValueOnly -ErrorAction 'Stop'

             
                        # Create string for BitLockerRecoveryPassword.txt
                        $Local:StrRecPass = [string]::Empty
                        $Local:StrRecPass += ('BitLocker RecoveryPassword for OS Drive ({0}){1}' -f ($env:SystemDrive,"`r`n"))
                        $Local:StrRecPass += Get-StringRecoveryPasswords
                        $Local:StrRecPass += "`r`n`r`n"
                        $Local:StrRecPass += 'BitLocker Drive Encryption recovery key{0}' -f "`r`n"
                        $Local:StrRecPass += 'To verify that this is the correct recovery key, compare the start of the following{0}' -f "`r`n"
                        $Local:StrRecPass += 'identifier with the identifier value displayed on your PC.'
                        $Local:StrRecPass += "`r`n`r`n"
                        $Local:StrRecPass += ('Identifier: {0}' -f ($Local:CurrentVolumeArrayRecoveryPasswords[0].KeyProtectorId))
                        $Local:StrRecPass += "`r`n`r`n"
                        $Local:StrRecPass += 'If the above identifier matches the one displayed by your PC,{0}' -f "`r`n"
                        $Local:StrRecPass += 'then use the following key to  unlock your drive:'
                        $Local:StrRecPass += "`r`n`r`n"
                        $Local:StrRecPass += ('Recovery Key: {0}' -f ($Local:CurrentVolumeArrayRecoveryPasswords[0].RecoveryPassword))
                        $Local:StrRecPass += "`r`n`r`n"
                        $Local:StrRecPass += 'If the above identifier doesn`t match the one displayed by your PC,{0}' -f "`r`n"
                        $Local:StrRecPass += 'then this isn`t the right key to unlock your drive.{0}' -f "`r`n"
                        $Local:StrRecPass += 'Try another recovery key, or refer to{0}' -f "`r`n" 
                        $Local:StrRecPass += 'https://go.microsoft.com/fwlink/?LinkID=260589 for additional assistance.'


                        # Out-File the string
                        LogWrite 'Creating backup in OneDrive for Business.'
                        $Local:OD4BBackupFilePath = [string]$('{0}BitlockerRecoveryPassword-{1}.txt' -f ($Local:PathDirOD4BBackup,(Get-Date -Format 'yyMMddhhmmss')))
                        Out-File -FilePath $Local:OD4BBackupFilePath -Encoding 'utf8' -Force -InputObject ($Local:StrRecPass)
                        if (Test-Path -Path $Local:OD4BBackupFilePath) {
                            $Script:IsBackupOD = $true
                        }                        


                        # OneDrive for Business Backup Success?
                        LogWrite ('Success? {0}' -f ($Script:IsBackupOD))
                    }                    
                }
                Catch {
                    LogWrite ('Error while backup to OneDrive, make sure that you are AAD joined and are running the cmdlet as an admin.')
                    LogWrite ('Error message:' + "`r`n" + ($_))
                }
                Finally {
                    LogWrite ('Did backup to OneDrive succeed? {0}' -f ($Script:IsBackupOD))
                }
            }
        }
        #endregion Backup OneDrive for Business
    


        #################
        # Azure AD Backup
        #################
        #region Backup Azure AAD

        LogWrite ('# Backup to Azure AD')
        if ($Script:IsBackupAAD) {
            LogWrite ('Already done')
        }
        
        else {
            $Script:BoolDidAnythingChangeThisRuntime = $true
                   
            
            Try {
                # Get ArrayRecoveryPasswords for current volume
                $Local:CurrentVolumeArrayRecoveryPasswords = Get-Variable -Name ('{0}ArrayRecoveryPasswords' -f ($OSDriveLetter)) -Scope 'Script' -ValueOnly -ErrorAction 'Stop'
                
                # Check if we can use BackupToAAD-BitLockerKeyProtector commandlet                
                LogWrite 'Checking if we can use "BackupToAAD-BitLockerKeyProtector" commandlet.'

                if (Get-Command -Name 'BackupToAAD-BitLockerKeyProtector' -ErrorAction 'SilentlyContinue') {                    
                    LogWrite ('Commandlet exists!' -f ($Local:CmdName)) 
                    $null = BackupToAAD-BitLockerKeyProtector -MountPoint $OSDriveLetter -KeyProtectorId $Local:CurrentVolumeArrayRecoveryPasswords[0].'KeyProtectorId' -ErrorAction 'SilentlyContinue'
                    if ($?) {
                        $Script:IsBackupAAD = $true
                    }
                    else {
                        $null = BackupToAAD-BitLockerKeyProtector -MountPoint $OSDriveLetter -KeyProtectorId $Local:CurrentVolumeArrayRecoveryPasswords[0].KeyProtectorId -ErrorAction 'Stop'
                        if ($?) {
                            $Script:IsBackupAAD = $true
                        }
                    }
                    LogWrite ('Success? {0}' -f ($Script:IsBackupAAD))
                } 
                else { 
                    # BackupToAAD-BitLockerKeyProtector commandlet not available, using other mechanism 
                    LogWrite 'BackupToAAD-BitLockerKeyProtector commandlet not available, using other mechanism.' 
                    # Get the AAD Machine Certificate
                    $Certificate           = ($([array]$(Get-ChildItem -Path 'Certificate::LocalMachine\My')).Where{$_.'Issuer' -match 'CN=MS-Organization-Access'})
                    $CertificateThumbprint = [string]$($Certificate | Select-Object -ExpandProperty 'Thumbprint')
                    $CertificateSubject    = [string]$([string]$($Certificate | Select-Object -ExpandProperty 'Subject').Replace('CN=',''))
                    
                    # Get tenant domain name from registry
                    $TenantDomain = [string]$([string]$(Get-ItemProperty -Path ('Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo\{0}' -f ($CertificateThumbprint)) -Name 'UserEmail' | Select-Object -ExpandProperty 'UserEmail').Split('@')[-1])
                    
                    # Make sure we have valid values
                    foreach ($Variable in [array]$($CertificateThumbprint,$CertificateSubject,$TenantDomain)) {
                        if ([string]::IsNullOrEmpty($Variable)) {
                            Throw 'Failed to backup to AAD using alternative method involving Invoke-WebRequest.'
                        }
                    }

                    # Log
                    LogWrite $TenantDomain
                    # Generate the body to send to AAD containing the recovery information
                    # Get the BitLocker key information from WMI
                    [array]$(Get-BitLockerVolume -MountPoint $OSDriveLetter | Select-Object -ExpandProperty 'KeyProtector').Where{$_.'KeyProtectorType' -eq 'RecoveryPassword'}.ForEach{
                        $Key = $_
                        LogWrite ("kid : $($Key.'KeyProtectorId') key: $($Key.'RecoveryPassword')")
                        $Body = [string]$("{""key"":""$($Key.'RecoveryPassword')"",""kid"":""$($Key.'KeyProtectorId'.Replace('{','').Replace('}',''))"",""vol"":""OSV""}")
                    
                        # Create the URL to post the data to based on the tenant and device information
                        $Uri = [string]$('https://enterpriseregistration.windows.net/manage/{0}/device/{1}?api-version=1.0' -f ($TenantDomain,$CertificateSubject))
                        LogWrite "Creating url...$Uri"
                    
                        # Post the data to the URL and sign it with the AAD Machine Certificate
                        $Request = Invoke-WebRequest -Uri $Uri -Body $Body -UseBasicParsing -Method 'Post' -UseDefaultCredentials -Certificate $Certificate
                        LogWrite $Request.'RawContent'
                        if ($?) {
                            $Script:IsBackupAAD = $true
                        }    
                        LogWrite ('Post the data to the URL and sign it with the AAD Machine Certificate. Success? {0}' -f ($Script:IsBackupAAD))
                    }
                } 
            }
            Catch {
                LogWrite ('Error while backup to Azure AD, make sure that you are AAD joined and are running the cmdlet as an admin.')
                LogWrite ('Error message:' + "`r`n" + ($_))
                $IsBackupAAD = $false
            }
            Finally {
                LogWrite ('Did backup to Azure AD Succeed? {0}' -f ($Script:IsBackupAAD))
            }
        }
        #endregion Backup Azure AAD
        
        
        # If no backup and no Recovery Passwords present
        
    }
    else {
        LogWrite 'OS Drive is not encrypted, there are no Recovery Passwords, and there are no backups.'
    }
}
#endregion Backup
#endregion Main




####################
#### END RESULTS ###
####################
#region End Results 
LogWrite ('### End results')
# Cleaning up if success
if ($Script:IsFinished1stTime) {
    LogWrite 'Finished first time = True | Just checked weather BitLocker Recovery Password had changed.'
}

else {
    if ($Script:IsEncrypted -and $Script:IsProtectionPassw -and $Script:IsBackupAAD -and
        ([bool]$($Script:BoolBackupToOneDriveForBusiness -and $Script:IsBackupOD) -or [bool]$(-not($Script:BoolBackupToOneDriveForBusiness)))
    ) {
        $BLV = Get-BitLockerVolume -MountPoint $env:SystemDrive
        if (($BLV.'VolumeStatus' -eq $Script:BitLockerVolumeEncryptionStatuses[2]) -and (@($BLV.'KeyProtector' | Where-Object -Property 'KeyProtectorType' -eq 'RecoveryPassword').'Count' -eq 1)) {
        
            # First successfull run
            $Script:IsFinished1stTime = $true
            
            # ScheduledTask
            Edit-ScheduledTask -TaskName $Script:ScheduledTaskName

            # Files
            #region Remove files
            if ($Script:BoolRemoveFilesAfterSuccess -and $Script:IsFinished1stTime) {               
                $null = Start-Job -ArgumentList $Script:FileLog -ScriptBlock {
                    Param([string] $FileLog)
        
                    Function LogWrite {
                        Param ([string]$LogString)
                        $a = [string]$(Get-Date)
                        $LogString = [string]$($a, $LogString)
                        Add-content -Path $FileLog -Value $LogString
                    }
                    $Local:RemDirPath = [string]$(${env:ProgramFiles(x86)} + '\BitLockerTrigger\')
                   
                    Start-Sleep -Seconds 5
                    LogWrite ('Started the job to remove "{0}"' -f ($Local:RemDirPath))
                    if (Test-Path $Local:RemDirPath) {
                        Remove-Item -Path $Local:RemDirPath -Recurse -Force
                        LogWrite ('Removing the folder (recurse, force). Success? {0}' -f ($?))
                    }
                    else {
                        LogWrite ('Folder does not exist')
                    }            
                }                
            }
            #endregion Remove Files
        }    
    }
    else {
        LogWrite 'There are still things to do. Trying again later.'
    }
}
#endregion End Results



####################
#### S T A T S #####
####################
LogWrite ('### STATS')
$Script:CountRuns += 1

if (-not($Script:BoolRemoveFilesAfterSuccess)) {
    if (-not(Test-Path $Script:DirInstall)) {
        $null = New-Item -Path $Script:DirInstall -ItemType 'Directory' -Force
    }
    
    # Fetch OS drive encryption key and password
    $Script:OSDriveKeyID = [string]$($Script:CArrayRecoveryPasswords | Select-Object -First 1 -ExpandProperty 'KeyProtectorId')
    $Script:OSDriveProtectionPassword = [string]$($Script:CArrayRecoveryPasswords | Select-Object -First 1 -ExpandProperty 'RecoveryPassword')

    # Create output string
    $OutString = [string]$(($Script:CountRuns).ToString() + "`r`n")            # 0   Line 1
    $OutString += (([byte] $Script:IsFinished1stTime).ToString() + "`r`n")     # 1   Line 2
    $OutString += (([byte] $Script:IsEncrypted).ToString() + "`r`n")           # 2   Line 3
    $OutString += (([byte] $Script:IsProtectionPassw).ToString() + "`r`n")     # 3   Line 4
    $OutString += (([byte] $Script:IsBackupOD).ToString() + "`r`n")            # 4   Line 5
    $OutString += (([byte] $Script:IsBackupAAD).ToString() + "`r`n")           # 5   Line 6
    $OutString += (([string] $Script:OSDriveKeyID) + "`r`n")                   # 6   Line 7
    $OutString += (([string] $Script:OSDriveProtectionPassword))               # 7   Line 8
   
    # Output the stats file
    $null = Out-File -FilePath $Script:FileStats -Encoding 'utf8' -Force -InputObject ($OutString)
}
LogWrite ('Runs so far: {0}' -f ($Script:CountRuns))

if ($Script:BoolDidAnythingChangeThisRuntime) {
    Write-Stats 
}



### Give up after X runs and IsFinished1stTime -eq $false
if ($Script:CountRuns -eq 30 -and (-not($Script:IsFinished1stTime))) {
    LogWrite ('Should have been done by now.')
    Edit-ScheduledTask -TaskName $Script:ScheduledTaskName    
}




####################
####  D O N E  #####
####################
LogWrite ('All done, exiting script...')
#endregion Main
