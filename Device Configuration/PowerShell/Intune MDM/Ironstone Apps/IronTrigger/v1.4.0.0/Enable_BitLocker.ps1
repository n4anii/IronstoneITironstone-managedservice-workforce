<#
PSScriptInfo 
.VERSION 1.4.0.0
.GUID f5187e3f-ed0a-4ce1-b438-d8f421619ca3 
.ORIGINAL AUTHOR Jan Van Meirvenne 
.MODIFIED BY Olav R. Birkeland, Sooraj Rajagopalan, Paul Huijbregts, Pieter Wigleven & Niall Brady (windows-noob.com 2017/8/17)
.COPYRIGHT 
.TAGS Azure Intune BitLocker  
.LICENSEURI  
.PROJECTURI  
.ICONURI  
.EXTERNALMODULEDEPENDENCIES  
.REQUIREDSCRIPTS  
.EXTERNALSCRIPTDEPENDENCIES  
.RELEASENOTES
.TODO 
#>

<# 
 
.DESCRIPTION 
 Check whether BitLocker is Enabled, if not Enable BitLocker on AAD Joined devices and store recovery info in AAD 
 Added logging
#> 

[cmdletbinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string] $OSDrive = $env:SystemDrive
)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12



#region Settings and Variables
### Settings
    # If on, will prompt user to reboot with Windows Forms GUI.
    [bool] $GUI = $false
    # If on, will remove all files after first success.
    [bool] $Script:BoolRemoveFilesAfterSuccess = $false
    # If off, will change scheduled task to run once a day at 12:00 after first successfull run, or after 30 failed runs
    # If on, will delete scheduled task after first successfull run and after 30 failed runs
    [bool] $Script:BoolRemoveScheduledTaskAfterFirstSuccess = $false
### Variables - Help
    [string] $Script:OSDriveLetter     = $OSDrive.Trim(':').ToUpper()
### Variables - Script
    [string] $Script:NameScript        = 'IronTrigger'
    [string] $Script:ScheduledTaskName = $Script:NameScript.Clone()
    [string] $Script:DirInstall        = ('{0}\Program Files\IronstoneIT\{1}\' -f ($env:SystemDrive,$Script:NameScript))
    [string] $Script:DirLog            = ('{0}\Program Files\IronstoneIT\Intune\DeviceConfiguration\' -f ($env:SystemDrive))
    [string] $Script:FileLog           = ('{0}IronTrigger - EnableBitLocker.log' -f ($Script:DirLog))
    [string] $Script:FileStats         = ('{0}stats.txt' -f ($Script:DirInstall))
# Help Variables (DON'T CHANGE)
    [string] $Script:ComputerName      = [string] $ComputerName = @([string]($env:COMPUTERNAME).Trim(),[string]([System.Environment]::MachineName).Trim() -ne [string]::Empty)[0]
    [bool]   $Script:BoolDidAnythingChangeThisRuntime = $false
    [String[]] $Script:BitLockerVolumeEncryptionStatuses = @('FullyDecrypted','EncryptionInProgress','FullyEncrypted')
#endregion Settings and Variables



#region Functions
    #region Logging and Output
        #region LogWrite
        Function LogWrite {
            Param (
                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [string]$LogString
            )

            # Create variables
            [string] $DateTime  = [System.DateTime]::Now.ToString('yyMMdd HH:mm:ss:ff')
            [string] $LogString = ('{0} {1}' -f ($DateTime,$LogString))
            
            # Add content to log file
            Add-content -Path $Script:FileLog -Value $LogString -Encoding 'utf8'
            
            # Output content to console
            Write-Output -InputObject $LogString
        }
        #endregion LogWrite

        #region LogErrors
        Function LogErrors {
            LogWrite ('Caught an exception:')
            LogWrite ('Exception Type:    {0}' -f ($_.Exception.GetType().FullName))
            LogWrite ('Exception Message: {0}' -f ($_.Exception.Message))
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
            LogWrite ('OS drive ({0}) | Encrypted: {1} | Recovery Passwords present: {2} | Backup to OneDrive: {3} | Backup to AzureAD: {4}' -f ($OSDrive,$Script:IsEncrypted,$Script:IsProtectionPassw,$Script:IsBackupOD,$Script:IsBackupAAD))
            if (-not($PreviousOnly)) {
                Logwrite ('OS drive ({0}) | VolumeStatus: {1} | ProtectionStatus: {2}' -f ($OSDrive,$Script:VolumeEncryptionStatus,$Script:VolumeProtectionStatus))            
                if ($Script:VolumeHasTPMandPW) {
                    LogWrite ('OS drive ({0}) | Presence of BitLocker KeyProtector | TPM: {1} | RecoveryPassword: {2}' -f ($OSDrive,$Script:VolumeHasTPMandPW[0],$Script:VolumeHasTPMandPW[1]))
                    if ($Script:VolumeEncryptionStatus[1]) {
                        LogWrite ('OS drive ({0}) | {1}' -f ($OSDrive,(Write-RecoveryPassword)))
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
            [byte] $Local:C = $(if($Script:CountRecoveryPasswords){$Script:CountRecoveryPasswords}else{0})
            Return ([string] ('{0} Recovery Password(s) present.{1}' -f ($Local:C,($(If($Local:C -ge 1){'{0}{1}' -f ("`r`n",(Get-StringRecoveryPasswords))})))))
        }
        #endregion Write-RecoveryPassword


        #region Get-StringRecoveryPasswords
        # Returns a string containing the recovery passwords from $Script:ArrayRecoveryPasswords. Usefull for printing/ logging/ backup
        Function Get-StringRecoveryPasswords {
            Param(
                [Parameter(Mandatory=$false)]
                [ValidateNotNullOrEmpty()]
                [string] $DriveLetter = $OSDrive
            )

            # Validate Input
            [string] $Local:CurrentVolumeLetter = $DriveLetter.Trim(':').ToUpper()
            if ($Local:CurrentVolumeLetter.Length -gt 1) {
                Throw 'ERROR: Drive letter cannot be more than one letter'
            }


            # Create variable names
            [string] $Local:ArrayName     = ('{0}ArrayRecoveryPasswords' -f ($Local:CurrentVolumeLetter))


            # Get Array, loop it. Ideally only one pw, but loop just to be safe.
            [uint16] $Local:TempCounter = 0
            [string] $Local:OutStr = [string]::Empty
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
                [string] $DriveLetter = $OSDrive
            )
            
            # Validate Input
            [string] $Local:CurrentVolumeLetter = $DriveLetter.Trim(':').ToUpper()
            if ($Local:CurrentVolumeLetter.Length -gt 1) {
                Throw 'ERROR: Drive letter cannot be more than one letter'
            }
            
            # Get BitLocker Volume
            $Local:BitLockerStatus = Get-BitLockerVolume -MountPoint $Local:CurrentVolumeLetter
            
            # Create object containing number of RecoveryPasswords (Index = 0) and TPM (Index = 1)
            [uint16] $Local:CountRecPass = 0
            [uint16] $Local:CountTPM = 0
            $Local:BitLockerStatus.KeyProtector | ForEach-Object {
                if ($_.KeyProtectorType -eq 'RecoveryPassword') {$Local:CountRecPass += 1}
                elseif ($_.KeyProtectorType -eq 'TPM') {$Local:CountTPM += 1}
            }
            
            # Return the object
            return ([bool] ($Local:CountTPM -ge 1),[bool] ($Local:CountRecPass -ge 1))
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
            $Local:KeyProtectorStatus     = $BitLockerVolume | Select-Object -ExpandProperty KeyProtector
            $Local:ArrayRecoveryPasswords = New-Object Microsoft.BitLocker.Structures.BitLockerVolumeKeyProtector[] ($Local:KeyProtectorStatus.Count - 1)

            $Local:IndexCount = [byte]::MinValue
            $Local:KeyProtectorStatus | ForEach-Object {
                if ($_.KeyProtectorType -eq 'RecoveryPassword') {
                    $null = $Local:ArrayRecoveryPasswords[$Local:IndexCount++] = $_
                }
            }
            
            # Return the object           
            return ($Local:ArrayRecoveryPasswords)
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
            [string] $Local:CurrentVolumeLetter = $DriveLetter.Trim(':').ToUpper()
            if ($Local:CurrentVolumeLetter.Length -gt 1) {
                Throw 'ERROR: Drive letter cannot be more than one letter'
            }

            # Get Unique Volume
            return [string]((Get-Volume -DriveLetter $Local:CurrentVolumeLetter | Select-Object -ExpandProperty 'UniqueId').Split('{')[-1].Trim('}\'))
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
            [string] $Local:CurrentVolumeLetter = $DriveLetter.Trim(':').ToUpper()
            if ($Local:CurrentVolumeLetter.Length -gt 1) {
                Throw 'ERROR: Drive letter cannot be more than one letter'
            }


            # Variables thats always present
            [string] $Script:VolumeEncryptionStatus     = Get-Variable -Name ('{0}VolumeEncryptionStatus' -f ($Local:CurrentVolumeLetter)) -Scope 'Script' -ValueOnly -ErrorAction 'Stop'
            [string] $Script:VolumeProtectionStatus     = Get-Variable -Name ('{0}VolumeProtectionStatus' -f ($Local:CurrentVolumeLetter)) -Scope 'Script' -ValueOnly -ErrorAction 'Stop'
            
            # Variables thats present only if theres at least one KeyProtector for current volume
            [bool[]] $Script:VolumeHasTPMandPW          = Get-Variable -Name ('{0}VolumeHasTPMandPW' -f ($Local:CurrentVolumeLetter)) -Scope 'Script' -ValueOnly -ErrorAction 'SilentlyContinue'
            [string] $Script:VolumeEncryptionPercentage = Get-Variable -Name ('{0}VolumeEncryptionPercentage' -f ($Local:CurrentVolumeLetter)) -Scope 'Script' -ValueOnly -ErrorAction 'SilentlyContinue'
            
            # Variables thats present only if current volume is protected with minimum a TPM and a Recovery Password
            $Script:ArrayRecoveryPasswords              = Get-Variable -Name ('{0}ArrayRecoveryPasswords' -f ($Local:CurrentVolumeLetter)) -Scope 'Script' -ValueOnly -ErrorAction 'SilentlyContinue'
            [byte] $Script:CountRecoveryPasswords       = Get-Variable -Name ('{0}CountRecoveryPasswords' -f ($Local:CurrentVolumeLetter)) -Scope 'Script' -ValueOnly -ErrorAction 'SilentlyContinue'
        }
        #endregion Refresh-BitLockerVariablesForCurrentVolume


        #region    Check-IfBitLockerPWHasChanged
        Function Check-IfBitLockerPWHasChanged {
            param(
                [Parameter(Mandatory=$false)]
                [ValidateNotNullOrEmpty()]
                [string] $DriveLetter = $OSDrive
            )
            
            # Help Variables
            [bool] $Local:HasChanged            = $false
            [string] $Local:CurrentVolumeLetter = $DriveLetter.Trim(':').ToUpper()
            if ($Local:CurrentVolumeLetter.Length -gt 1) {
                Throw 'ERROR: Drive letter cannot be more than one letter'
            }

            # Name Variables
            [string] $Local:NameArray      = ('{0}ArrayRecoveryPasswords' -f ($Local:CurrentVolumeLetter))
            [string] $Local:VolumeUniqueID = Get-VolumeUniqueID -DriveLetter $Local:CurrentVolumeLetter
            [string] $Local:NameFile       = ('{0}.txt' -f ($VolumeUniqueID))
           
            # Get Variables
            [string] $Local:PathDir  = ('{0}{1}' -f ($Script:DirInstall,'BackupKeys\'))
            [string] $Local:PathFile = ('{0}{1}' -f ($Local:PathDir,$Local:NameFile))
            [string] $Local:NowKeyProtectorID = ((Get-Variable -Name $Local:NameArray -Scope 'Script').Value).KeyProtectorID
            [string] $Local:NowRecoveryPassword = ((Get-Variable -Name $Local:NameArray -Scope 'Script').Value).RecoveryPassword


            # Get stats
            if (-not (Test-Path -Path $Local:PathFile)) {
                $Local:HasChanged = $true
                if (-not(Test-Path -Path $Local:PathDir -ErrorAction 'SilentlyContinue')) {
                    $null = New-Item -Path $Local:PathDir -ItemType Directory -Force
                }
            }
            else {
                [string[]] $Local:InputString = (Get-Content -Path $Local:PathFile).Split([Environment]::NewLine)
                if ($? -and $Local:InputString.Length -ge 7) {
                    [string] $Local:PrevKeyProtectorID = $Local:InputString[5].Trim()
                    [string] $Local:PrevRecoveryPassword = $Local:InputString[7].Trim()
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
                $null = Out-File -FilePath $Local:PathFile -Encoding utf8 -Force -InputObject ($Local:OutStr)
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
                [string] $DriveLetter = $OSDrive
            )

            # Help variable
            [string] $Local:CurrentVolumeLetter = $DriveLetter.Trim(':').ToUpper()
            if ($Local:CurrentVolumeLetter.Length -ne 1) {
                Throw 'ERROR: Drive letter cannot be more or less than one letter!'
            }

            # Get BitLocker Status for Volume
            [Microsoft.BitLocker.Structures.BitLockerVolume] $Local:BitLockerVolumeStatus = Get-BitLockerVolume -MountPoint $Local:CurrentVolumeLetter
                  
            # BitLocker Volume Encryption Status: FullyDecrypted | EncryptionInProgress | FullyEncrypted
            New-Variable -Name ('{0}VolumeEncryptionStatus' -f ($Local:CurrentVolumeLetter)) -Scope 'Script' -Force `
                         -Value ([string]($Local:BitLockerVolumeStatus | Select-Object -ExpandProperty 'VolumeStatus'))
            
            # BitLocker Volume Protection Status: ON if Encryption Percentage = 100%
            New-Variable -Name ('{0}VolumeProtectionStatus' -f ($Local:CurrentVolumeLetter)) -Scope 'Script' -Force `
                         -Value ([string]($Local:BitLockerVolumeStatus | Select-Object -ExpandProperty 'ProtectionStatus'))
            
            
            
            <#  
                    Volume can be 'Fully Decrypted', but still have a TPM present. 
                    This is usually the case right after encryption has started. 
            #>


            # If there is a KeyProtector for given volume, get the rest of the variables
            if ($Local:BitLockerVolumeStatus.KeyProtector.Count -gt 0) {
                # [0} = Volume has TPM?   [1] = Volume has Recovery Password?
                New-Variable -Name ('{0}VolumeHasTPMandPW' -f ($Local:CurrentVolumeLetter)) -Scope 'Script' -Force `
                             -Value ([bool[]](Get-BoolDriveHasBitLockerTPMandPW -DriveLetter $CurrentVolumeLetter))          
                
                # Encryption Percentage: How long has the encryption process come
                New-Variable -Name ('{0}VolumeEncryptionPercentage' -f ($Local:CurrentVolumeLetter)) -Scope 'Script' -Force `
                             -Value ([string]($Local:BitLockerVolumeStatus | Select-Object -ExpandProperty 'EncryptionPercentage').ToString())                
                                             
                
                # If Drive has TPM and PW
                if ((Get-Variable -Name ('{0}VolumeHasTPMandPW' -f ($Local:CurrentVolumeLetter)) -Scope 'Script').Value[1]) {
                    # Name the variables
                    [string] $Local:NameArrayRecoveryPasswords = ('{0}ArrayRecoveryPasswords' -f ($Local:CurrentVolumeLetter))
                    [string] $Local:NameCountRecoveryPasswords = ('{0}CountRecoveryPasswords' -f ($Local:CurrentVolumeLetter))

                    # Get Array with protection passwords
                    New-Variable -Name $Local:NameArrayRecoveryPasswords -Scope 'Script' -Force `
                                 -Value (Get-ArrayRecoveryPasswords -BitLockerVolume $Local:BitLockerVolumeStatus)

                    # Count ArrayRecoveryPasswords
                    New-Variable -Name $Local:NameCountRecoveryPasswords -Scope 'Script' -Force `
                                 -Value ([byte]((Get-Variable -Name $Local:NameArrayRecoveryPasswords).Value).Length)

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
            [string] $Local:PathDirRegTenantJoinInfoBase = 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo'
            [string] $Local:PathDirRegTenantJoinInfoFull = ('{0}\{1}' -f ($Local:PathDirRegTenantJoinInfoBase,
                (Get-ChildItem -Path $Local:PathDirRegTenantJoinInfoBase | Select-Object -ExpandProperty Name).Split('\')[-1]
            ))
            [string] $Script:NameTenant = (Get-ItemProperty -Path $Local:PathDirRegTenantJoinInfoFull).UserEmail.Split('@')[1]
            [string] $Script:NameTenantShort = $Script:NameTenant.Split('.')[0]
            
            ## Hardware and Windows info
            [string] $Script:ComputerManufacturer = Query-Registry -Dir 'HKLM:\HARDWARE\DESCRIPTION\System\BIOS\SystemManufacturer'
            if (-not([string]::IsNullOrEmpty($Script:ComputerManufacturer))) {
                [string] $Script:ComputerFamily = Query-Registry -Dir 'HKLM:\HARDWARE\DESCRIPTION\System\BIOS\SystemFamily'
                [string] $Script:ComputerProductName = Query-Registry -Dir 'HKLM:\HARDWARE\DESCRIPTION\System\BIOS\SystemProductName'
                [string] $Script:WindowsEdition = Query-Registry -Dir 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProductName'
                [string] $Script:WindowsVersion = Query-Registry -Dir 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ReleaseId'
                [string] $Script:WindowsVersion += (' ({0})' -f (Query-Registry -Dir 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\CurrentBuild'))
            } 
            else {
                $Local:EnvInfo = Get-WmiObject -Class 'Win32_ComputerSystem' | Select-Object -Property Manufacturer,Model,SystemFamily        
                [string] $Script:ComputerManufacturer = $Local:EnvInfo.Manufacturer
                [string] $Script:ComputerFamily = $Local:EnvInfo.SystemFamily
                [string] $Script:ComputerProductName = $Local:EnvInfo.Model
                $Local:OSInfo = Get-WmiObject -Class 'Win32_operatingsystem' | Select-Object -Property Caption,Version
                [string] $Script:WindowsEdition = $Local:OSInfo.Caption
                [string] $Script:WindowsVersion = $Local:OSInfo.Version
            }
        }
        #endregion Create-EnvVariables


        #region    Query-Registry
        Function Query-Registry {
            Param ([Parameter(Mandatory=$true)] [string] $Dir)
            $Local:Out = [string]::Empty
            [string] $Local:Key = $Dir.Split('{\}')[-1]
            [string] $Local:Dir = $Dir.Replace($Local:Key,'')
        
            $Local:Exists = Get-ItemProperty -Path ('{0}' -f $Dir) -Name ('{0}' -f $Local:Key) -ErrorAction SilentlyContinue
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
                LogWrite ('Removing the Scheduled task "{0}". Success? {1}' -f ($Task.TaskName,$?.ToString()))
            }
            else {
                [DateTime] $Local:NewSchedTime = [DateTime]::Today.AddHours(12)                      
                $null = Set-ScheduledTask -TaskName $Script:ScheduledTaskName -Trigger (New-ScheduledTaskTrigger -Daily -At $Local:NewSchedTime) -ErrorAction 'SilentlyContinue'
                LogWrite ('Editing Scheduled task "{0}" to start daily at {1}. Success? {2}.' -f ($Script:ScheduledTaskName,$Local:NewSchedTime.Hour.ToString(),$?.ToString()))
            }
        }
        else {
            LogWrite ('Found no Scheduled Task with name "{0}".' -f ($TaskName))
        }
    }
    #endregion Edit-ScheduledTask


    #region    Prompt-Reboot
    Function Prompt-Reboot {
        [uint16] $Local:TimeToRebootInMinutes = 60 
        [string] $Local:StrShortMessage = ('Windows will restart in {0} minutes to finish device configuration. Save your work!' -f ($Local:TimeToRebootInMinutes))
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
    if (-not (Test-Path -Path $Script:FileStats)) {
        [uint16] $Script:CountRuns = 0
        [bool] $Script:IsFinished1stTime = [bool] $Script:IsEncrypted = [bool] $Script:IsProtectionPassw = [bool] $Script:IsBackupOD = [bool] $Script:IsBackupAAD = $false
        $Script:OSDriveKeyID = $Script:OSDriveProtectionPassword = [string]::Empty
        LogWrite ('# First run!')
    }
    else {
        [String[]] $InputString = (Get-Content -Path $Script:FileStats).Split([Environment]::NewLine)
        [uint16] $Script:CountRuns = [uint16] $InputString[0]
        [bool] $Script:IsFinished1stTime = [uint16] $InputString[1]
        [bool] $Script:IsEncrypted = [uint16] $InputString[2]
        [bool] $Script:IsProtectionPassw = [uint16] $InputString[3]
        [bool] $Script:IsBackupOD = [uint16] $InputString[4]
        [bool] $Script:IsBackupAAD = [uint16] $InputString[5]
        [string] $Script:OSDriveKeyID = [string] $InputString[6]
        [string] $Script:OSDriveProtectionPassword = [string] $InputString[7]
        LogWrite ('# Previous run results:')
        Write-Stats -PreviousOnly $true
    }
    

    ############################
    #### Get current status ####
    ############################  
    LogWrite ('# Current status:')
    
    # Current Drive (OS Drive)
    $Local:CurrentVolumeLetter = $Script:OSDriveLetter
    
    # Get Current Status for OS Drive
    Get-BitLockerStatus -DriveLetter $Local:CurrentVolumeLetter
    Refresh-BitLockerVariablesForCurrentVolume -DriveLetter $Local:CurrentVolumeLetter
    

    if ($Script:VolumeHasTPMandPW) {
        if ($Script:VolumeHasTPMandPW[0]) {
            [bool] $Script:IsEncrypted = ($Script:VolumeEncryptionStatus -eq $Script:BitLockerVolumeEncryptionStatuses[2])
        }
        if ($Script:VolumeHasTPMandPW[1]) {
            [bool] $Script:IsProtectionPassw = ($Script:CountRecoveryPasswords -eq 1)
        }                   
    }
    else {
        [bool] $Script:IsEncrypted = [bool] $Script:IsProtectionPassw = $false
    }


    # Other Fixed Drives
    #TODO
    <#
    [String[]] $Script:FixedVolumesLetters = @((Get-Volume | `
        Where-Object {$_.DriveType -eq 'Fixed' -and (-not([string]::IsNullOrEmpty($_.DriveLetter)))} | `
        Where-Object {$_.DriveLetter -ne $OSDrive.Replace(':','')}).DriveLetter)
    
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
    [bool] $Script:BoolDidAnythingChangeThisRuntime = $true
    
    # If 'FullyEncrypted', and TPM present
    # Means that OS Drive is successfully encrypted with BitLocker
    if (($Script:VolumeEncryptionStatus -eq $Script:BitLockerVolumeEncryptionStatuses[2]) -and $Script:VolumeHasTPMandPW[0]) {
        LogWrite ('OS Drive is fully encrypted!')
        $Script:IsEncrypted = $true
    }
    

    # If 'EncryptionInProgress' and TPM present
    # Means computer has restarted after BitLocker encryption was enabled. Waiting for the volume to get encrypted
    elseif ($Script:VolumeEncryptionStatus -eq $Script:BitLockerVolumeEncryptionStatuses[1] -and $Script:VolumeHasTPMandPW[0]) {
        LogWrite ('OS Drive encryption is in progress:')
        LogWrite ('Restart have taken place, and encryption has started.')
        LogWrite ('OS Drive Encryption Percentage: {0}%.' -f ($Script:VolumeEncryptionPercentage))
        LogWrite ('Can continue to check if Recovery Password is present, and backup it.')
    }


    # If 'FullyDrectypted'     
    elseif ($Script:VolumeEncryptionStatus -eq $Script:BitLockerVolumeEncryptionStatuses[0]) {
        
        # If 'FullyDrectypted' but there exists a TPM
        # Means that encryption has started, but computer is awaiting restart
        if ($Script:VolumeHasTPMandPW -and $Script:VolumeHasTPMandPW[0]) {
            LogWrite ('OS Drive Encryption has started, but computer has not been restarted yet.')
            LogWrite ('OS Drive Encryption Percentage: {0}%.' -f ($Script:VolumeEncryptionPercentage))
            LogWrite ('Can continue to check if Recovery Password is present, and backup it.')
        }
        
        else {
            LogWrite ('OS Drive is not encrypted.')
            LogWrite ('Attempting to Enable BitLocker on OS drive ({0})' -f ($OSDrive))
            try {
                # Enable BitLocker using TPM
                $null = Enable-BitLocker -MountPoint $OSDrive -TpmProtector -UsedSpaceOnly -ErrorAction Continue
                if ($?) {
                    LogWrite ('Successfully enabled bitlocker.')                   
                }
                else {
                    LogWrite ('Failed Enabling Bitlocker TpmProtector, it`s probably already enabled')
                }
            } 
            catch {
                LogErrors
                Enable-BitLocker -MountPoint $OSDrive -TpmProtector -ErrorAction SilentlyContinue
                LogWrite ('Will attempt to Enable BitLocker anyway and then continue. Success? {0}' -f ($?))
            }
            finally {
                LogWrite ('Did we actually enable BitLocker?')
                
                # Refresh Variables
                Get-BitLockerStatus -DriveLetter $OSDrive
                Refresh-BitLockerVariablesForCurrentVolume -DriveLetter $OSDrive

                # Check result
                if ($Script:VolumeHasTPMandPW -and $Script:VolumeHasTPMandPW[0]) {
                    LogWrite ('TPM present for OS Drive? {0}' -f ($Script:VolumeHasTPMandPW[0]))
                    LogWrite ('Prompting reboot.')
                    Prompt-Reboot
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
        [bool] $Script:BoolDidAnythingChangeThisRuntime = $true
        [bool] $Local:Success = $false
        
        
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
                    if ($_.KeyProtectorId -ne $Script:ArrayRecoveryPasswords[0].KeyProtectorId) {
                        $null = Remove-BitLockerKeyProtector -MountPoint $OSDrive -KeyProtectorId $_.KeyProtectorID
                        if ($?) {
                            LogWrite ('Successfully removed | KeyProtectorId "{0}" | RecoveryPassword "{1}"' -f ($_.KeyProtectorId,$_.RecoveryPassword))
                        }
                    }
                    else {
                        LogWrite ('Successfully skipped the first key. | KeyProtectorId "{0}" | RecoveryPassword "{1}"' -f ($_.KeyProtectorId,$_.RecoveryPassword))
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
            LogWrite ('No BitLocker Recovery Passwords found for OS Drive {0}, creating one.' -f $OSDrive)
            try {
                $null = Add-BitLockerKeyProtector -MountPoint $OSDrive -RecoveryPasswordProtector -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
                if ($?) {
                    $Local:Success = $true
                }
                else {
                    $null = Enable-BitLocker -MountPoint $OSDrive -RecoveryPasswordProtector -ErrorAction Stop
                    if ($?) {
                        $Local:Success = $true
                    }
                } 
            } 
            catch {
                LogErrors
                $null = Add-BitLockerKeyProtector -MountPoint $OSDrive -RecoveryPasswordProtector -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
                if ($LastExitCode -eq 0) {
                    $Local:Success = $true
                }
                else {
                    $null = Enable-BitLocker -MountPoint $OSDrive -RecoveryPasswordProtector -ErrorAction SilentlyContinue
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
            Get-BitLockerStatus -DriveLetter $OSDrive
            Refresh-BitLockerVariablesForCurrentVolume -DriveLetter $OSDrive

            # Check results
            [bool] $Local:BoolTemp = $(if($Script:VolumeHasTPMandPW){($Script:VolumeHasTPMandPW[1])}else{$false})
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
    LogWrite ('Recovery Password present? {0}' -f ($(if($Script:VolumeHasTPMandPW){$Script:VolumeHasTPMandPW[0]}else{$false})))
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
if ($Script:IsFinished1stTime -or $Script:IsBackupAAD -and $Script:IsBackupOD) {
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
if (-not ($Script:IsBackupAAD -and $Script:IsBackupOD)) {
    # If ProtectionPassword(s) exist
    if ($Script:IsProtectionPassw) {
            
        LogWrite ('OS Drive is encrypted, and there are {0} ProtectionPassword(s) present.' -f ($Script:ArrayRecoveryPasswords.Count))
        LogWrite ('Writing existing RecoveryPassword for current drive, for future reference...')
        $null = Check-IfBitLockerPWHasChanged
        
        LogWrite ('Continuing with backup.')

    
        ##############################
        # OneDrive for Business backup
        ##############################
        #region Backup OneDrive for Business
    
        LogWrite ('# Backup to OneDrive')
        if ($Script:IsBackupOD) {
            LogWrite ('Already done')
        }
        else {
            $Script:BoolDidAnythingChangeThisRuntime = $true
            
            try {
                # Get Current User as SecurityIdentifier
                if (-not($Script:PathDirRootCU)){
                    [string] $Script:PathDirRootCU = ('HKU:\{0}\' -f ([System.Security.Principal.NTAccount]::new((Get-Process -Name 'explorer' -IncludeUserName | Select-Object -ExpandProperty UserName -First 1)).Translate([System.Security.Principal.SecurityIdentifier]).Value))
                    if((-not($?)) -or [string]::IsNullOrEmpty($PathDirRootCU)){Break}
                }
                
                # Add HKU:\ as PSDrive if not already
                if ((Get-PSDrive -Name 'HKU' -ErrorAction SilentlyContinue) -eq $null) {$null = New-PSDrive -PSProvider Registry -Name 'HKU' -Root 'HKEY_USERS'}
                
                # Get OneDrive for Business path from registry                 
                $RegValues = Get-ChildItem -Path ('{0}\SOFTWARE\Microsoft\OneDrive\Accounts\' -f ($PathDirRootCU))
                foreach ($RegValue in $RegValues) {
                    [string] $Local:OD4BAccType = ($RegValue | Select-Object -ExpandProperty 'Name').Split('{\}')[-1]
                    if ($Local:OD4BAccType -like 'Business*') {
                        LogWrite ('Found a OneDrive for Business account.')
                        [string] $Local:PathDirOD4B = (Get-ItemProperty -Path $RegValue.Name.Replace('HKEY_USERS\','HKU:\') -Name 'UserFolder').UserFolder
                                
                        if ($Local:PathDirOD4B -notlike ('{0}\Users\*\OneDrive -*' -f ($OSDrive)) -and (-not(Test-Path -Path $Local:PathDirOD4B))) {
                            LogWrite ('Failed to build OneDrive path: "{0}", or it does not exist.' -f ($Local:Path))
                            $Script:IsBackupOD = $false
                        } 
                        else {                                      
                            if (-not($Script:ComputerProductName)) {
                                Create-EnvVariables
                            }
                            
                            # Runtime variable
                            [bool] $Local:BoolFolderExists = $false
                            

                            # Creating paths
                            [string] $Local:PathDirOD4BBackupParent = ('{0}\BitLocker Recovery\' -f ($Local:PathDirOD4B))
                            [string] $Local:PathDirOD4BBackup = ('{0}{1} ({2} {3})\' -f ($Local:PathDirOD4BBackupParent,$Script:ComputerName,$Script:ComputerManufacturer,$Script:ComputerProductName))
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
                            

                            # Create OneDrive for Business Backup if the folder exists
                            if (-not($Local:BoolFolderExists)) {
                                LogWrite 'Failed to check or create folder.'
                            }
                            else {
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
                                [string] $Local:OD4BBackupFilePath = ('{0}BitlockerRecoveryPassword-{1}.txt' -f ($Local:PathDirOD4BBackup,(Get-Date -Format 'yyMMddhhmmss')))
                                Out-File -FilePath $Local:OD4BBackupFilePath -Encoding 'utf8' -Force -InputObject ($Local:StrRecPass)
                                if (Test-Path -Path $Local:OD4BBackupFilePath) {
                                    $Script:IsBackupOD = $true
                                }
                            }


                            # OneDrive for Business Backup Success?
                            LogWrite ('Success? {0}' -f ($Script:IsBackupOD))
                        }
                    }
                    else {
                        LogWrite ('Skipping personal OneDrive for Business folders.')
                    }
                }
            }
            catch {
                LogWrite ('Error while backup to OneDrive, make sure that you are AAD joined and are running the cmdlet as an admin.')
                LogWrite ('Error message:' + "`r`n" + ($_))
            }
            finally {
                LogWrite ('Did backup to OneDrive succeed? {0}' -f ($Script:IsBackupOD))
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
                   
            
            try {
                # Get ArrayRecoveryPasswords for current volume
                $Local:CurrentVolumeArrayRecoveryPasswords = Get-Variable -Name ('{0}ArrayRecoveryPasswords' -f ($OSDriveLetter)) -Scope 'Script' -ValueOnly -ErrorAction 'Stop'
                
                # Check if we can use BackupToAAD-BitLockerKeyProtector commandlet
                $Local:CmdName = 'BackupToAAD-BitLockerKeyProtector'
                LogWrite 'Checking if we can use BackupToAAD-BitLockerKeyProtector commandlet.'

                if (Get-Command $Local:CmdName -ErrorAction 'SilentlyContinue') {
                    #BackupToAAD-BitLockerKeyProtector commandlet exists
                    LogWrite ('{0} commandlet exists!' -f ($Local:CmdName)) 
                    $null = BackupToAAD-BitLockerKeyProtector -MountPoint $OSDrive -KeyProtectorId $Local:CurrentVolumeArrayRecoveryPasswords[0].KeyProtectorId -ErrorAction 'SilentlyContinue'
                    if ($?) {
                        $Script:IsBackupAAD = $true
                    }
                    else {
                        $null = BackupToAAD-BitLockerKeyProtector -MountPoint $OSDrive -KeyProtectorId $Local:CurrentVolumeArrayRecoveryPasswords[0].KeyProtectorId -ErrorAction 'Stop'
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
                    $cert = Get-ChildItem Cert:\LocalMachine\My\ | Where-Object { $_.Issuer -match 'CN=MS-Organization-Access' }

                    # Obtain the AAD Device ID from the certificate
                    $id = $cert.Subject.Replace('CN=','')

                    # Get the tenant name from the registry
                    $tenant = (Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo\$($id)).UserEmail.Split('@')[1]
                    LogWrite $tenant
                    # Generate the body to send to AAD containing the recovery information
                    # Get the BitLocker key information from WMI
                    (Get-BitLockerVolume -MountPoint $OSDrive).KeyProtector| Where-Object {$_.KeyProtectorType -eq 'RecoveryPassword'} | ForEach-Object {
                        $key = $_
                        write-verbose "kid : $($key.KeyProtectorId) key: $($key.RecoveryPassword)"
                        $body = "{""key"":""$($key.RecoveryPassword)"",""kid"":""$($key.KeyProtectorId.replace('{','').Replace('}',''))"",""vol"":""OSV""}"
                    
                        # Create the URL to post the data to based on the tenant and device information
                        $url = "https://enterpriseregistration.windows.net/manage/$tenant/device/$($id)?api-version=1.0"
                        Logstring "Creating url...$url"
                    
                        # Post the data to the URL and sign it with the AAD Machine Certificate
                        $req = Invoke-WebRequest -Uri $url -Body $body -UseBasicParsing -Method Post -UseDefaultCredentials -Certificate $cert
                        $req.RawContent
                        if ($?) {
                            $Script:IsBackupAAD = $true
                        }    
                        LogString ('Post the data to the URL and sign it with the AAD Machine Certificate. Success? {0}' -f ($Script:IsBackupAAD))
                    }
                } 
            }
            catch {
                LogWrite ('Error while backup to Azure AD, make sure that you are AAD joined and are running the cmdlet as an admin.')
                LogWrite ('Error message:' + "`r`n" + ($_))
                $IsBackupAAD = $false
            }
            finally {
                LogWrite ('Did backup to Azure AD Succeed? {0}' -f ($Script:IsBackupAAD))
            }
        }
        #endregion Backup Azure AAD
        
        
        # If no backup and no Recovery Passwords present
        
    }
    else {
        LogWrite 'OS Drive is not encryptet, there are no Recovery Passwords, and there are no backups.'
    }
}
#endregion Backup
#endregion Main



####################
######  G U I ######
####################
#region GUI
if ($Script:IsEncrypted -and $Script:IsProtectionPassw -and $GUI) {
    # Show reboot prompt to user
    LogWrite "Prompting user to Reboot computer."
           

    [void][System.Reflection.Assembly]::LoadWithPartialName( “System.Windows.Forms”)
    [void][System.Reflection.Assembly]::LoadWithPartialName( “Microsoft.VisualBasic”)

    $form = New-Object “System.Windows.Forms.Form”;
    $form.Width = 500;
    $form.Height = 150;
    $form.Text = "BitLocker requires a reboot !";
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen;

    $DropDownArray = @("4:Hours", "8:Hours", "12:Hours", "24:Hours")
    $DDL = New-Object System.Windows.Forms.ComboBox
    $DDL.Location = New-Object System.Drawing.Size(140, 10)
    $DDL.Size = New-Object System.Drawing.Size(130, 30)
    ForEach ($Item in $DropDownArray) {
        $DDL.Items.Add($Item) | Out-Null
    }
    $DDL.SelectedIndex = 0

    $button1 = New-Object “System.Windows.Forms.button”;
    $button1.Left = 40;
    $button1.Top = 85;
    $button1.Width = 100;
    $button1.Text = “Reboot Now”;
    $button1.Add_Click( {$global:xinput = "Reboot"; $Form.Close()})

    $button2 = New-Object “System.Windows.Forms.button”;
    $button2.Left = 170;
    $button2.Top = 85;
    $button2.Width = 100;
    $button2.Text = “Postpone”;
    $button2.Add_Click( {$global:xinput = "Postpone:" + $DDL.Text; $Form.Close()})

    $button3 = New-Object “System.Windows.Forms.button”;
    $button3.Left = 290;
    $button3.Top = 85;
    $button3.Width = 100;
    $button3.Text = “Cancel”;
    $button3.Add_Click( {$global:xinput = "Postpone24"; $Form.Close()})


    $form.KeyPreview = $True
    $form.Add_KeyDown( {if ($_.KeyCode -eq "Enter") 
        {$x = $textBox1.Text; $form.Close()}})
    $form.Add_KeyDown( {if ($_.KeyCode -eq "Escape") 
        {$form.Close()}})

    $eventHandler = [System.EventHandler] { 
        $button1.Click;
        $DropDownArray.Text;
        $form.Close(); };

    #$button.Add_Click($eventHandler) ;
    $form.Controls.Add($button1);
    $form.Controls.Add($button2);
    $form.Controls.Add($button3);
    $form.Controls.Add($DDL);
    $form.Controls.Add($textLabel1)
    $ret = $form.ShowDialog();

    if ($global:xinput -eq "Reboot") {shutdown -r -f /t 600}
    if ($global:xinput -like "Postpone:*:Hours") {
        $hval = (([int]$global:xinput.split(":")[1]) * 60 * 60)
        shutdown -r -f /t $hval
    }
    if ($global:xinput -eq "Postpone24") {shutdown -r -f /t 86400}
}
#endregion GUI



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
    if ($Script:IsEncrypted -and $Script:IsProtectionPassw -and $Script:IsBackupAAD -and $Script:IsBackupOD) {
        Get-BitLockerStatus
        if (($Script:VolumeEncStatus -eq $Script:BitLockerVolumeEncryptionStatuses[2]) -and ($Script:CountRecoveryPasswords -eq 1)) {
        
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
                        [string] $a = Get-Date
                        [string] $LogString = $a, $LogString
                        Add-content -Path $FileLog -Value $LogString
                    }
                    [string] $Local:RemDirPath = (${env:ProgramFiles(x86)} + '\BitLockerTrigger\')
                   
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
        $null = New-Item -Path $Script:DirInstall -ItemType Directory -Force
    }
    
    [string] $OutString = (($Script:CountRuns).ToString() + "`r`n")                   # 0
    $OutString += (([byte] $Script:IsFinished1stTime).ToString() + "`r`n")            # 1
    $OutString += (([byte] $Script:IsEncrypted).ToString() + "`r`n")                  # 2
    $OutString += (([byte] $Script:IsProtectionPassw).ToString() + "`r`n")            # 3
    $OutString += (([byte] $Script:IsBackupOD).ToString() + "`r`n")                   # 4
    $OutString += (([byte] $Script:IsBackupAAD).ToString() + "`r`n")                  # 5
    $OutString += (([string] $Script:OSDriveKeyID) + "`r`n")                          # 6
    $OutString += (([string] $Script:OSDriveProtectionPassword) + "`r`n")             # 7
   
    Out-File -FilePath $Script:FileStats -Encoding utf8 -Force -InputObject ($OutString)
}
LogWrite ('Runs so far: {0}' -f ($Script:CountRuns))

if ($Script:BoolDidAnythingChangeThisRuntime) {
    Write-Stats 
}



### Give up after X runs and IsFinished1stTime -eq $false
if ($Script:CountRuns -eq 30 -and (-not($Script:IsFinished1stTime))) {
    LogWrite ('Should have been done by now.')
    Edit-ScheduledTask -TaskName $Script:ScheduledTaskName

    if ($false) {
        ### Gathering info for the email
        if (-not($Script:WindowsVersion)) {
            Create-EnvVariables
        }
        ### Building email string
        [string] $Local:StrSubject = ('BitLockerTrigger failed {0} times for tenant "{1}", device: "{2}"' -f ($CountRuns.ToString(),$Local:NameTenant,$Local:NameComputer))
        [string] $Local:StrEmail = [string]::Empty
        $Local:StrEmail += ($Local:StrSubject)
        $Local:StrEmail += ("`r`n")
        $Local:StrEmail += ("`r`n" + '## Environment info')
        $Local:StrEmail += ("`r`n" + 'Device name: ' + $Script:ComputerName + ' | Manufacturer: ' + $Script:ComputerManufacturer + ' | Model: ' + $Script:ComputerProductName) 
        $Local:StrEmail += ("`r`n" + 'Windows Edition: ' + $Script:WindowsEdition + ' | Windows Version' + $Script:WindowsVersion)
        $Local:StrEmail += ("`r`n`r`n" + 'There have now been {0} runs, but BitLockerTrigger STILL fails.' -f ($Script:CountRuns))
        $Local:StrEmail += ("`r`n" + 'Success status | Encrypted : {0} | Protection Passwords present : {1} | Backup to AzureAD : {2} | Backup to OneDrive : {3}' -f ($Script:IsEncrypted,$Script:IsProtectionPassw,$Script:IsBackupAAD,$Script:IsBackupOD))
        LogWrite ($Local:StrEmail)
        <### Send email
        ## Mail address(es)
        [string] $Local:StrToEmailAddress = 'Olav R. Birkeland <olavb@ironstoeit.com>;'
        #$StrEmailAddress += 'Ironstone Servicedesk <servicedeks@ironstoneit.com>'
        [string] $Local:StrFromEmailAddress = ('BitLockerTriggerFail@{0}' -f ($Script:NameTenant))
        #Send-MailMessage -To $Local:StrToEmailAddress -SmtpServer  -From $Local:StrFromEmailAddress -Subject $Local:StrSubject -Body $Local:StrEmail
        #>
    }
}





####################
####  D O N E  #####
####################
LogWrite ('All done, exiting script...')
#endregion Main