<#PSScriptInfo 
.VERSION 1.7
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
- Backup other encrypted, fixed drives
    - Don't force encryption on those, only backup if they exist
- Webhook, email or similar for notifying admins about X failed runs  
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
### Variables
    [String] $Script:NameScript         = 'IronTrigger'
    [String] $Script:ScheduledTaskName = $Script:NameScript.Clone()
    [String] $Script:DirInstall        = ('{0}\Program Files\IronstoneIT\{1}\' -f ($env:SystemDrive,$Script:NameScript))
    [String] $Script:DirLog            = ('{0}\Program Files\IronstoneIT\Intune\DeviceConfiguration\' -f ($env:SystemDrive))
    [String] $Script:FileLog           = ('{0}IronTrigger - EnableBitLocker.log' -f ($Script:DirLog))
    [String] $Script:FileStats         = ('{0}stats.txt' -f ($Script:DirInstall))
# Help Variables (DON'T CHANGE)
    [String] $Script:ComputerName      = $env:COMPUTERNAME
    [bool]   $Script:BoolDidAnythingChangeThisRuntime = $false
    [String[]] $Script:BitLockerVolumeEncryptionStatuses = @('FullyDecrypted','EncryptionInProgress','FullyEncrypted')
#endregion Settings and Variables



#region Functions
    #region Logging and Output
        #region LogWrite
        Function LogWrite {
            Param ([string]$LogString)
            [string] $a = Get-Date
            [string] $LogString = $a, $LogString
            Add-content -Path $Script:FileLog -Value $LogString
            Write-Host $LogString
        }
        #endregion LogWrite

        #region LogErrors
        Function LogErrors {
            LogWrite ('Caught an exception:')
            LogWrite ('Exception Type: ' + $($_.Exception.GetType().FullName))
            LogWrite ('Exception Message: ' + $($_.Exception.Message))
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
            If ($PreviousOnly) {
                LogWrite ('Runs: {0} | Has IronTrigger had a successfull run already? {1}' -f ($Script:CountRuns,$Script:IsFinished1stTime))
            }
            
            # OS Drive
            LogWrite ('OS drive ({0}) | Encrypted: {1} | Recovery Passwords present: {2} | Backup to OneDrive: {3} | Backup to AzureAD: {4}' -f ($OSDrive,$Script:IsEncrypted,$Script:IsProtectionPassw,$Script:IsBackupOD,$Script:IsBackupAAD))
            If (-not($PreviousOnly)) {
                Logwrite ('OS drive ({0}) | VolumeStatus: {1} | ProtectionStatus: {2}' -f ($OSDrive,$Script:VolumeEncStatus,$Script:VolumeProtectionStatus))            
                If ($Script:VolumeHasTPMandPW) {
                    LogWrite ('OS drive ({0}) | Presence of BitLocker KeyProtector | TPM: {1} | RecoveryPassword: {2}' -f ($OSDrive,$Script:VolumeHasTPMandPW[0],$Script:VolumeHasTPMandPW[1]))
                    If ($Script:VolumeEncStatus[1]) {
                        LogWrite ('OS drive ({0}) | {1}' -f ($OSDrive,(Write-RecoveryPassword)))
                    }
                }
            
                # Other fixed drives with a drive letter
                <# #TODO
                If ($Script:OtherEncryptedDrives) {
                    $Script:OtherEncryptedDrives | ForEach-Object {
                        If (-not([string]::IsNullOrEmpty($Script:OtherEncryptedDrives[0]))) {
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
            [byte] $Local:C = $(If($Script:CountRecoveryPasswords){$Script:CountRecoveryPasswords}Else{0})
            Return ([string] ('{0} Recovery Password(s) present.{1}' -f ($Local:C,($(If($Local:C -ge 1){'{0}{1}' -f ("`r`n",(Get-StringRecoveryPasswords))})))))
        }
        #endregion Write-RecoveryPassword


        #region Get-StringRecoveryPasswords
        # Returns a string containing the recovery passwords from $Script:ArrayRecoveryPasswords. Usefull for printing/ logging/ backup
        Function Get-StringRecoveryPasswords {
            Param(
                [Parameter(Mandatory=$false)]
                [string] $DriveLetter = $OSDrive
            )
            
            # Create variable names
            [string] $Local:ArrName = 'ArrayRecoveryPasswords'
            If ($DriveLetter.Substring(0,1) -ne $env:SystemDrive.Substring(0,1)) {
                $Local:ArrName = ('{0}{1}' -f ($DriveLetter.Substring(0,1),$Local:ArrName))
            }


            # Get Array, loop it. Ideally only one pw, but loop just to be safe.
            [uint16] $Local:TempCounter = 0
            [String] $Local:OutStr = [String]::Empty
            (Get-Variable -Name $Local:ArrName -Scope 'Script').Value | ForEach-Object {
                $Local:OutStr += ('{0} | KeyProtectorId "{1}" | RecoveryPassword "{2}"' -f (($Local:TempCounter += 1),$_.KeyProtectorId,$_.RecoveryPassword))
                If ($Local:TempCounter -lt ((Get-Variable -Name $Local:ArrName -Scope 'Script').Value).Count) {$Local:OutStr += "`r`n"}
            }

            # Return the string
            Return $Local:OutStr
        }
        #endregion Get-StringRecoveryPasswords
    #endregion Logging and Output



    #region Return Values (Used by other Functions)
        #region Get-BitLockerKeyProtectorTypes
        # Returns a bool array, where the first represents status of TPM presence, and the second for Protection Password
        Function Get-BoolDriveHasBitLockerTPMandPW {
            Param(
                [Parameter(Mandatory=$false)]
                [string] $DriveLetter = $OSDrive
            )
            $Local:BitLockerStatus = Get-BitLockerVolume -MountPoint $DriveLetter
            [uint16] $Local:CountRecPass = 0
            [uint16] $Local:CountTPM = 0
            $Local:BitLockerStatus.KeyProtector | ForEach-Object {
                If ($_.KeyProtectorType -eq 'RecoveryPassword') {$Local:CountRecPass += 1}
                ElseIf ($_.KeyProtectorType -eq 'TPM') {$Local:CountTPM += 1}
            }
            return ([bool] ($Local:CountTPM -ge 1),[bool] ($Local:CountRecPass -ge 1))
        }
        #endregionGet-BitLockerKeyProtectorTypes


        #region Get-ArrayRecoveryPasswords
        # Returns a ArrayList with existing ProtectionPasswords
        Function Get-ArrayRecoveryPasswords {
            Param(
                [Parameter(Mandatory=$true)]
                [Microsoft.BitLocker.Structures.BitLockerVolume] $BitLockerVolume
            )
            
            # Get BitLocker ProtectionPasswords
            $Local:KeyProtectorStatus = ($BitLockerVolume | Select-Object -Property KeyProtector).KeyProtector
            $Local:ArrayRecoveryPasswords = New-Object Microsoft.BitLocker.Structures.BitLockerVolumeKeyProtector[] ($Local:KeyProtectorStatus.Count - 1)

            $Local:IndexCount = [byte]::MinValue
            $Local:KeyProtectorStatus | ForEach-Object {
                If ($_.KeyProtectorType -eq 'RecoveryPassword') {
                    $null = $Local:ArrayRecoveryPasswords[$Local:IndexCount++] = $_
                }
            }
                       
            return ($Local:ArrayRecoveryPasswords)
        }
        #endregion Get-ArrayRecoveryPasswords


        #region Get-VolumeUniqueID
        Function Get-VolumeUniqueID {
            param(
                [Parameter(Mandatory=$true)]
                [string] $DriveLetter
            )
            $Local:ADriveLetter = $DriveLetter.Substring(0,1)
            $Local:VolumeID = (Get-Volume -DriveLetter $ADriveLetter | Select *).UniqueID.Split('{')[-1]
            $Local:VolumeID = $Local:VolumeID.SubString(0,($Local:VolumeID.Length - 2))

            return $Local:VolumeID
        }
        #endregion Get-VolumeUniqueID


        #region Check-IfBitLockerPWHasChanged
        Function Check-IfBitLockerPWHasChanged{
            param(
                [Parameter(Mandatory=$false)]
                [string] $DriveLetter = $OSDrive
            )
            [bool] $Local:HasChanged = $false


            # Name Variables
            [string] $Local:NameArray = 'ArrayRecoveryPasswords'
            [string] $Local:NameFile  = ('{0}.txt' -f ($VolumeUniqueID))
            [string] $Local:VolumeID = $Script:VolumeUniqueID
            If ($DriveLetter.Substring(0,1) -ne $env:SystemDrive.Substring(0,1)) {
                $Local:NameArray = '{0}{1}' - ($Local:VolumeLetter,$Local:NameArray)
                $Local:VolumeID = Get-VolumeUniqueID -DriveLetter $DriveLetter
            }
           

            # Get Variables
            [string] $Local:PathDir = ('{0}{1}' -f ($Script:DirInstall,'BackupKeys\'))
            [string] $Local:PathFile = ('{0}{1}' -f ($Local:PathDir,$Local:NameFile))
            [string] $Local:NowKeyProtectorID = ((Get-Variable -Name $Local:NameArray -Scope 'Script').Value).KeyProtectorID
            [string] $Local:NowRecoveryPassword = ((Get-Variable -Name $Local:NameArray -Scope 'Script').Value).RecoveryPassword


            # Get stats
            If (-not (Test-Path -Path $Local:PathFile)) {
                If (-not(Test-Path -Path $Local:PathDir -ErrorAction SilentlyContinue)) {
                    $null = New-Item -Path $Local:PathDir -ItemType Directory -Force
                }
            }
            Else {
                [string[]] $Local:InputString = (Get-Content -Path $Local:PathFile).Split([Environment]::NewLine)
                If ($? -and $Local:InputString.Length -ge 7) {
                    [string] $Local:PrevKeyProtectorID = $Local:InputString[5].Trim()
                    [string] $Local:PrevRecoveryPassword = $Local:InputString[7].Trim()
                }
                Else {$Local:HasChanged = $true}
            }


            # Check if changed
            If ($Local:PrevKeyProtectorID) {
                If ($Local:PrevKeyProtectorID -ne $Local:NowKeyProtectorID) {$Local:HasChanged = $true}
                If ($Local:PrevRecoveryPassword -ne $Local:NowRecoveryPassword) {$Local:HasChanged = $true}
            }


            # Write new values if changed or does not exist
            If ($Local:HasChanged -or (-not (Test-Path -Path $Local:PathFile))) {
                $Local:OutStr = [string]::Empty
                $Local:OutStr += 'Drive/Volume Letter (Not Unique identifier):{0}' -f "`r`n"
                $Local:OutStr += '{0}{1}' -f $DriveLetter,"`r`n"
                $Local:OutStr += 'Volume UniqueID (Name of this file):{0}' -f "`r`n"
                $Local:OutStr += '{0}{1}' -f $Local:VolumeID,"`r`n"
                $Local:OutStr += 'KeyProtectorID:{0}' -f "`r`n"
                $Local:OutStr += '{0}{1}' -f $Local:NowKeyProtectorID,"`r`n"
                $Local:OutStr += 'Recovery Password:{0}' -f "`r`n"
                $Local:OutStr += '{0}{1}' -f $Local:NowRecoveryPassword,"`r`n"
                Out-File -FilePath $Local:PathFile -Encoding utf8 -Force -InputObject ($Local:OutStr)
            }



            # Return status
            return $Local:HasChanged      
        }
        #endregion Check-IfBitLockerPWHasChanged
    #endregion Return Values (Used by other Functions)



    #region Set Script Wide Variables
        #region Get-BitLockerStatus
        # Fills two strings with current Volume Encryption Status, and Volume Protection Status. 
        # Also makes a bool array with true false for | 1: TPM present | 2: Recovery Password Present
        Function Get-BitLockerStatus {
            Param(
                [Parameter(Mandatory=$false)]
                [string] $DriveLetter = $OSDrive
            )

            # Help variables
            $Local:StrName = [string]::Empty
            If ($DriveLetter -ne $env:SystemDrive) {
                $Local:StrName = $DriveLetter.Substring(0,1)
            }
            $Local:AddLetterToName = [string]::IsNullOrEmpty($Local:StrName)

            # Get BitLocker Status for Volume
            [Microsoft.BitLocker.Structures.BitLockerVolume] $Local:BitLockerVolumeStatus = Get-BitLockerVolume -MountPoint $DriveLetter
            New-Variable -Name ($(If(-not($Local:AddLetterToName)){$Local:StrName}) + 'BitLockerVolumeStatus') -Scope 'Script' -Force `
                         -Value ([string]($Local:BitLockerVolumeStatus.VolumeStatus))           
            
            # Volume Encryption Status: FullyDecrypted | EncryptionInProgress | FullyEncrypted
            New-Variable -Name ($(If(-not($Local:AddLetterToName)){$Local:StrName}) + 'VolumeEncStatus') -Scope 'Script' -Force `
                         -Value ([string] ($Local:BitLockerVolumeStatus | Select-Object -Property VolumeStatus).VolumeStatus)
            
            # Volume Protection Status: ON if Encryption Percentage = 100%
            New-Variable -Name ($(If(-not($Local:AddLetterToName)){$Local:StrName}) + 'VolumeProtectionStatus') -Scope 'Script' -Force `
                         -Value ([string] ($Local:BitLockerVolumeStatus | Select-Object -Property ProtectionStatus).ProtectionStatus)
            
            
            
            <#  
                    Volume can be 'Fully Decrypted', but still have a TPM present. 
                    This is usually the case right after encryption has started. 
            #>


            # If there is a KeyProtector for given volume, get the rest of the variables
            If ($Local:BitLockerVolumeStatus.KeyProtector.Count -gt 0) {
                # [0} = Volume has TPM?   [1] = Volume has Recovery Password?
                New-Variable -Name ($(If(-not($Local:AddLetterToName)){$Local:StrName}) + 'VolumeHasTPMandPW') -Scope 'Script' -Force `
                             -Value ([bool[]](Get-BoolDriveHasBitLockerTPMandPW -DriveLetter $DriveLetter))          
                
                # Encryption Percentage: How long has the encryption process come
                New-Variable -Name ($(If(-not($Local:AddLetterToName)){$Local:StrName}) + 'VolumeEncryptionPercentage') -Scope 'Script' -Force `
                             -Value ($Local:BitLockerVolumeStatus.EncryptionPercentage.ToString())                
                                             
                
                # If Drive has TPM and PW
                If ((Get-Variable -Name ($(If(-not([string]::IsNullOrEmpty($Local:StrName))){$Local:StrName}) + 'VolumeHasTPMandPW') -Scope 'Script').Value[1]) {
                    # Name the variables
                    $Local:NameArrayRecoveryPasswords = ($(If(-not([string]::IsNullOrEmpty($Local:StrName))){$Local:StrName}) + 'ArrayRecoveryPasswords')
                    $Local:NameCountRecoveryPasswords = ($(If(-not([string]::IsNullOrEmpty($Local:StrName))){$Local:StrName}) + 'CountRecoveryPasswords')

                    # Get Array with protection passwords
                    New-Variable -Name $Local:NameArrayRecoveryPasswords -Scope 'Script' -Force `
                                 -Value (Get-ArrayRecoveryPasswords -BitLockerVolume $Local:BitLockerVolumeStatus)

                    # Count ArrayRecoveryPasswords
                    New-Variable -Name $Local:NameCountRecoveryPasswords -Scope 'Script' -Force `
                                 -Value ((Get-Variable -Name $Local:NameArrayRecoveryPasswords).Value).Length

                    # Get Volume Unique ID (to check if protection password has changed)
                    New-Variable -Name ($(If(-not([string]::IsNullOrEmpty($Local:StrName))){$Local:StrName}) + 'VolumeUniqueID') -Scope 'Script' -Force `
                                 -Value ((Get-VolumeUniqueID -DriveLetter $Local:DriveLetter))
                }
            }
        }
        #endregion Get-BitLockerStatus
    #endregion Set Script Wide Variables



    #region Registry Functions
        #region Create-EnvVariables
        # Create-EnvVariables: Creates variables used by the troubleshooter at the bottom, when failed runs reaches a given number.  
        Function Create-EnvVariables {
            #### Global Variables
            ## Tenant
            [String] $Local:ID = (Get-ChildItem Cert:\LocalMachine\My\ | Where-Object { $_.Issuer -match 'CN=MS-Organization-Access' }).Subject.Replace('CN=','')
            [String] $Script:NameTenant = (Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo\$($Local:ID)).UserEmail.Split('@')[1]
            [String] $Script:NameTenantShort = $Global:NameTenant.Split('.')[0]
            ## Hardware and Windows info
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
        #endregion Create-EnvVariables


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
    #endregion Registry Functions



    #region    Edit-ScheduledTask
    function Edit-ScheduledTask {
        Param(
            [Parameter(Mandatory=$false)]
            [string] $TaskName = $Script:ScheduledTaskName
        )

        $Task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

        if ($Task) {
            if ($Script:BoolRemoveScheduledTaskAfterFirstSuccess) {
                $null = Unregister-ScheduledTask -TaskName $Task -Confirm:$false -ErrorAction SilentlyContinue
                LogWrite ('Removing the Scheduled task "{0}". Success? {1}' -f ($Task.TaskName,$?))
            }
            else {
                [string] $Local:NewSchedTime = '12:00'                       
                $null = Set-ScheduledTask -TaskName $Script:ScheduledTaskName -Trigger (New-ScheduledTaskTrigger -At $Local:NewSchedTime -Daily) -ErrorAction SilentlyContinue
                LogWrite ('Editing Scheduled task "{0}" to start daily at {1}. Success? {2}' -f ($Script:ScheduledTaskName,$Local:NewSchedTime,$?))
            }
        }
        else {
            LogWrite ('Found no Scheduled Task with name "{0}"' -f ($TaskName))
        }
    }
    #endregion Edit-ScheduledTask


    #region Prompt-Reboot
    Function Prompt-Reboot {
        [uint16] $Local:TimeToRebootInMinutes = 60 
        [string] $Local:StrShortMessage = ('Windows will restart in {0} minutes to finish device configuration. Save your work!' -f ($Local:TimeToRebootInMinutes))
        $null = cmd.exe /c ('shutdown /r /t {0} /c "{1}"' -f ($Local:TimeToRebootInMinutes*60),$Local:StrShortMessage) 2>&1
        If (-not($?)) {
            $null = cmd.exe /c ('shutdown /a') 2>&1
            $null = cmd.exe /c ('shutdown /r /t {0} /c "{1}"' -f ($Local:TimeToRebootInMinutes*60),$Local:StrShortMessage) 2>&1
        }

        <# FOR FUTURE ENHANCEMENTS
        [String] $Local:StrMessage = 'Your computer are awaiting a restart:'
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
    If (-not (Test-Path -Path $Script:FileStats)) {
        [uint16] $Script:CountRuns = 0
        [bool] $Script:IsFinished1stTime = [bool] $Script:IsEncrypted = [bool] $Script:IsProtectionPassw = [bool] $Script:IsBackupOD = [bool] $Script:IsBackupAAD = $false
        $Script:OSDriveKeyID = $Script:OSDriveProtectionPassword = [string]::Empty
        LogWrite ('# First run!')
    }
    Else {
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
    # OS Drive
    Get-BitLockerStatus
    If ($Script:VolumeHasTPMandPW) {
        If ($Script:VolumeHasTPMandPW[0]) {
            $Script:IsEncrypted = ($Script:BitLockerVolumeStatus -eq $Script:BitLockerVolumeEncryptionStatuses[2])
        }
        If ($Script:VolumeHasTPMandPW[1]) {
            $Script:IsProtectionPassw = ($Script:CountRecoveryPasswords -eq 1)
        }                   
    }
    Else {
        $Script:IsEncrypted = $Script:IsProtectionPassw = $false
    }


    # Other Fixed Drives
    #TODO
    <#
    [String[]] $Script:FixedVolumesLetters = @((Get-Volume | `
        Where-Object {$_.DriveType -eq 'Fixed' -and (-not([string]::IsNullOrEmpty($_.DriveLetter)))} | `
        Where-Object {$_.DriveLetter -ne $OSDrive.Replace(':','')}).DriveLetter)
    
    $Script:FixedVolumesLetters | ForEach-Object {
        If (-not([string]::IsNullOrEmpty($_))) {
            Get-BitlockerStatus -DriveLetter $_
            If ((Get-Variable -Name ('{0}CountProtectionKeys' -f $_) -Scope 'Script').Length -gt 0) {
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
If ($Script:IsEncrypted) {
    LogWrite ('OS Drive is already fully encrypted.')
}
Else {
    [bool] $Script:BoolDidAnythingChangeThisRuntime = $true
    
    # If 'FullyEncrypted', and TPM present
    # Means that OS Drive is successfully encrypted with BitLocker
    If (($Script:VolumeEncStatus -eq $Script:BitLockerVolumeEncryptionStatuses[2]) -and $Script:VolumeHasTPMandPW[0]) {
        LogWrite ('OS Drive is fully encrypted!')
        $Script:IsEncrypted = $true
    }
    

    # If 'EncryptionInProgress' and TPM present
    # Means computer has restarted after BitLocker encryption was enabled. Waiting for the volume to get encrypted
    ElseIf ($Script:VolumeEncStatus -eq $Script:BitLockerVolumeEncryptionStatuses[1] -and $Script:VolumeHasTPMandPW[0]) {
        LogWrite ('OS Drive encryption is in progress:')
        LogWrite ('Restart have taken place, and encryption has started.')
        LogWrite ('OS Drive Encryption Percentage: {0}%.' -f ($Script:VolumeEncryptionPercentage))
        LogWrite ('Can continue to check if Recovery Password is present, and backup it.')
    }


    # If 'FullyDrectypted'     
    ElseIf ($VolumeEncStatus -eq $Script:BitLockerVolumeEncryptionStatuses[0]) {
        
        # If 'FullyDrectypted' but there exists a TPM
        # Means that encryption has started, but computer is awaiting restart
        If ($Script:VolumeHasTPMandPW -and $Script:VolumeHasTPMandPW[0]) {
            LogWrite ('OS Drive Encryption has started, but computer has not been restarted yet.')
            LogWrite ('OS Drive Encryption Percentage: {0}%.' -f ($Script:VolumeEncryptionPercentage))
            LogWrite ('Can continue to check if Recovery Password is present, and backup it.')
        }
        
        Else {
            LogWrite ('OS Drive is not encrypted.')
            LogWrite ('Attempting to Enable BitLocker on OS drive ({0})' -f ($OSDrive))
            try {
                # Enable BitLocker using TPM
                $null = Enable-BitLocker -MountPoint $OSDrive -TpmProtector -UsedSpaceOnly -ErrorAction Continue
                If ($?) {
                    LogWrite ('Successfully enabled bitlocker.')                   
                }
                Else {
                    LogWrite ('Failed Enabling Bitlocker TpmProtector, it`s probably already enabled')
                }
            } 
            catch {
                LogErrors
                Enable-BitLocker -MountPoint $OSDrive -TpmProtector -ErrorAction SilentlyContinue
                LogWrite ('Will attempt to Enable BitLocker anyway and then continue. Success? {0}' -f ($?))
            }
            Finally {
                LogWrite ('Did we actually enable BitLocker?')
                Get-BitLockerStatus
                If ($Script:VolumeHasTPMandPW -and $Script:VolumeHasTPMandPW[0]) {
                    LogWrite ('TPM present for OS Drive? {0}' -f ($Script:VolumeHasTPMandPW[0]))
                    LogWrite ('Prompting reboot.')
                    Prompt-Reboot
                }
                Else {
                    LogWrite ('ERROR, not encrypted. TPM not present for OS Drive')
                }
            }
        }
    }
    # If scenario fits none of the cases above..
    Else {
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
If ($Script:IsEncrypted -or ($Script:VolumeHasTPMandPW -and $Script:VolumeHasTPMandPW[0])) {
    
    
    # If we're done with recovery password(s) already
    If ($Script:IsProtectionPassw -and ($Script:CountRecoveryPasswords -eq 1)) {
        LogWrite 'Recovery Password for OS Drive is already present'
    }
    

    # If we're not done with recovery password(s)
    Else {        
        [bool] $Script:BoolDidAnythingChangeThisRuntime = $true
        [bool] $Local:Success = $false
        
        
        # If there exists BitLocker Encryption Recovery Password       
        If ($Script:VolumeHasTPMandPW[1]) {
            

            # If theres is _a_ ProtectionPassword, we're done
            If ($Script:CountRecoveryPasswords -eq 1) {
                LogWrite 'Only a password present'
                $Script:IsProtectionPassw = $true
                $Local:Success = $true
            }


            # If there is multiple RecoveryPasswords, we need to remove all but one
            ElseIf ($Script:CountRecoveryPasswords -gt 1) {
                LogWrite 'Multiple passwords present'
                Write-RecoveryPassword
                LogWrite ('Will remove all but the first one')
                $Script:ArrayRecoveryPasswords | ForEach-Object { 
                    If ($_.KeyProtectorId -ne $Script:ArrayRecoveryPasswords[0].KeyProtectorId) {
                        $null = Remove-BitLockerKeyProtector -MountPoint $OSDrive -KeyProtectorId $_.KeyProtectorID
                        If ($?) {
                            LogWrite ('Successfully removed | KeyProtectorId "{0}" | RecoveryPassword "{1}"' -f ($_.KeyProtectorId,$_.RecoveryPassword))
                        }
                    }
                    Else {
                        LogWrite ('Successfully skipped the first key. | KeyProtectorId "{0}" | RecoveryPassword "{1}"' -f ($_.KeyProtectorId,$_.RecoveryPassword))
                    }
                }
               
                Get-BitLockerStatus
                If ($Script:VolumeHasTPMandPW -and $Script:VolumeHasTPMandPW[1] -and ($Script:CountRecoveryPasswords -eq 1)) {
                    $Local:Success = $true
                }              
            }


            # This should not be possible
            Else {
                LogWrite 'ERROR: RecoveryPassword present, but count < 1'
            }
        }

        
        #region Add Protection Password If None Present
        Else {
            LogWrite ('No BitLocker Recovery Passwords found for OS Drive {0}, creating one.' -f $OSDrive)
            try {
                $null = Add-BitLockerKeyProtector -MountPoint $OSDrive -RecoveryPasswordProtector -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
                If ($?) {
                    $Local:Success = $true
                }
                Else {
                    $null = Enable-BitLocker -MountPoint $OSDrive -RecoveryPasswordProtector -ErrorAction Stop
                    If ($?) {
                        $Local:Success = $true
                    }
                } 
            } 
            catch {
                LogErrors
                $null = Add-BitLockerKeyProtector -MountPoint $OSDrive -RecoveryPasswordProtector -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
                If ($LastExitCode -eq 0) {
                    $Local:Success = $true
                }
                Else {
                    $null = Enable-BitLocker -MountPoint $OSDrive -RecoveryPasswordProtector -ErrorAction SilentlyContinue
                    If ($?) {
                        $Local:Success = $true
                    }
                }
            }
            Finally {
                LogWrite ('Tried to add BitLocker RecoveryPasswordProtector. Success? {0}.' -f ($Local:Success))
                        
            }
        }
        #endregion Add Protection Password If None Present

        

        # Count and list existing RecoveryPassword, only write success if theres one        
        If ($Local:Success) {
            LogWrite 'Checking if there is only one Protection Password.'
            Get-BitLockerStatus
            $Local:BoolTemp = $(If($Script:VolumeHasTPMandPW){($Script:VolumeHasTPMandPW[1])}Else{$false})
            LogWrite ('Protection Password Present? {0}' -f ($Local:BoolTemp))
                    
            If($Local:BoolTemp) {                                   
                If ($Script:CountRecoveryPasswords -eq 1) {             
                    LogWrite ('SUCCESS, keys left: 1.')
                    $Script:IsProtectionPassw = $true
                }               
                Else {
                    LogWrite 'FAIL, keys left: {0}.' -f ($Script:CountRecoveryPasswords)
                    $Script:IsProtectionPassw = $false
                }  
            }
            Else {
                LogWrite ('FAIL, no Protection Password found')
            }                    
        }                    
        Else {
            LogWrite ('Something failed')
        }                    
    }
    #endregion If theres 0 or multiple ProtectionsPassword(s) 
}


# Not encrypted = No making of RecoveryPassword
Else {
    LogWrite ('OS Drive is "FullyDecrypted" and there exists no "TPM".')
    LogWrite ('BitLocker RecoveryPassword can not be added at this time.')
    LogWrite ('Recovery Password present? {0}' -f ($(If($Script:VolumeHasTPMandPW){$Script:VolumeHasTPMandPW[0]}Else{$false})))
    $Script:IsProtectionPassw = $false
}

# Write recovery password(s) if anything changed this runtime
If ($Script:BoolDidAnythingChangeThisRuntime -and $Script:VolumeHasTPMandPW[1]) {
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
If ($Script:IsFinished1stTime) {
    LogWrite ('Will check if anything has changed.')

    If (Check-IfBitLockerPWHasChanged) {
        LogWrite 'Something has changed, BitLocker Recovery Protection Password is not the same as the one backed up.'
        $Script:IsBackupAAD = $Script:IsBackupOD = $false
        $Script:BoolDidAnythingChangeThisRuntime = $true
    }
    Else {
        LogWrite 'Nothing has changed, BitLocker Recovery Protection Password is the same as the one previously backed up.'
    }
}

# If $IsBackupAAD -and $IsBackupOD
If ($Script:IsBackupAAD -and $Script:IsBackupOD) {
    LogWrite ('OS Drive is already backed up.')
}


# If no backups
Else {
    # If ProtectionPassword(s) exist
    If ($Script:IsProtectionPassw) {
            
        LogWrite ('OS Drive is encrypted, and there are {0} ProtectionPassword(s) present.' -f ($Script:ArrayRecoveryPasswords.Length))
        LogWrite ('Continuing with backup.')

    
        ##############################
        # OneDrive for Business backup
        ##############################
        #region Backup OneDrive for Business
    
        LogWrite ('# Backup to OneDrive')
        If ($Script:IsBackupOD) {
            LogWrite ('Already done')
        }
        Else {
            $Script:BoolDidAnythingChangeThisRuntime = $true
        
            try {
                #Writing Value to OneDrive first 
                $regValues = Get-ChildItem 'HKCU:\SOFTWARE\Microsoft\OneDrive\Accounts\'
                ForEach ($regValue in $regValues) {
                    [String] $Local:OD4BAccType = [String[]] ((($regValue | Select-Object Name).Name).Split('{\}')[-1])
                    If ($Local:OD4BAccType -like 'Business*') {
                        LogWrite ('Found a OneDrive for Business account')
                        $Local:Key = $regValue.name.Replace('HKEY_CURRENT_USER', 'HKCU:')              
                        [String] $Local:OD4BPath = (Get-ItemProperty -Path $Local:Key -Name 'UserFolder').UserFolder
                                
                        If ((-not($Local:OD4BPath -like ($OSDrive + '\Users\*\OneDrive -*'))) -and (Test-Path $Local:OD4BPath)) {
                            LogWrite ('Failed to build OneDrive path: "{0}", or it does not exist.' -f $Local:Path)
                            $Script:IsBackupOD = $false
                            #[String] $Local:Path = ($env:SystemDrive + $env:HOMEPATH + 'OneDrive - ' + '\BitLocker Recovery\' + $env:COMPUTERNAME + '\' )
                        } 
                        Else {                                      
                            If (-not($Script:ComputerProductName)) {
                                Create-EnvVariables
                            }
                            
                            # Runtime variables
                            [bool] $Local:BoolFolderExists = $false
                            

                            # Creating paths
                            [String] $Local:OD4BBackupPath = ($Local:OD4BPath + '\BitLocker Recovery\{0} ({1} {2})\' -f ($Script:ComputerName,$Script:ComputerManufacturer,$Script:ComputerProductName))
                            LogWrite ('OneDrive for Business path: {0}' -f ($Local:OD4BPath))
                            LogWrite ('Backup Path for Bitlocker Recovery Key(s): {0}' -f ($Local:OD4BBackupPath)) 
                            

                            #Testing if Recovery folder exists if not create one
                            LogWrite ('Testing if backup folder exists, create it if not.')
                            if (Test-Path -Path $Local:OD4BBackupPath -ErrorAction SilentlyContinue) {
                                $Local:BoolFolderExists = $true
                            }
                            else {
                                LogWrite 'Creating OneDrive for Business folder for backup.'
                                $null = New-Item -ItemType Directory -Force -Path $Local:OD4BBackupPath
                                $Local:BoolFolderExists = Test-Path -Path $Local:OD4BBackupPath
                                LogWrite ('{0}' -f $(If($Local:BoolFolderExists){'Success.'}Else{'Failed.'}))
                            }                        
                            

                            # If backup folder exists
                            If (-not($Local:BoolFolderExists)) {
                                LogWrite 'Failed to check or create folder.'
                            }
                            Else {
                                # Create string for BitLockerRecoveryPassword.txt
                                $Local:StrRecPass = [String]::Empty
                                $Local:StrRecPass += ('BitLocker RecoveryPassword for OS Drive ({0}){1}' -f ($env:SystemDrive,"`r`n"))
                                $Local:StrRecPass += Get-StringRecoveryPasswords
                                $Local:StrRecPass += "`r`n`r`n"
                                $Local:StrRecPass += 'BitLocker Drive Encryption recovery key{0}' -f "`r`n"
                                $Local:StrRecPass += 'To verify that this is the correct recovery key, compare the start of the following{0}' -f "`r`n"
                                $Local:StrRecPass += 'identifier with the identifier value displayed on your PC.'
                                $Local:StrRecPass += "`r`n`r`n"
                                $Local:StrRecPass += ('Identifier: {0}' -f ($Script:ArrayRecoveryPasswords[0].KeyProtectorId))
                                $Local:StrRecPass += "`r`n`r`n"
                                $Local:StrRecPass += 'If the above identifier matches the one displayed by your PC,{0}' -f "`r`n"
                                $Local:StrRecPass += 'then use the following key to  unlock your drive:'
                                $Local:StrRecPass += "`r`n`r`n"
                                $Local:StrRecPass += ('Recovery Key: {0}' -f ($Script:ArrayRecoveryPasswords[0].RecoveryPassword))
                                $Local:StrRecPass += "`r`n`r`n"
                                $Local:StrRecPass += 'If the above identifier doesn`t match the one displayed by your PC,{0}' -f "`r`n"
                                $Local:StrRecPass += 'then this isn`t the right key to unlock your drive.{0}' -f "`r`n"
                                $Local:StrRecPass += 'Try another recovery key, or refer to{0}' -f "`r`n" 
                                $Local:StrRecPass += 'https://go.microsoft.com/fwlink/?LinkID=260589 for additional assistance.'

                                # Out-File the string
                                LogWrite 'Creating backup in OneDrive for Business.'
                                [String] $Local:CurDate = (Get-Date -Uformat '%y%m%d%H%M%S')
                                [String] $Local:OD4BBackupFilePath = ($Local:OD4BBackupPath + 'BitlockerRecoveryPassword {0}.txt' -f ($Local:CurDate))
                                Out-File -FilePath $Local:OD4BBackupFilePath -Encoding utf8 -Force -InputObject ($Local:StrRecPass)
                                If (Test-Path -Path $Local:OD4BBackupFilePath) {
                                    $Script:IsBackupOD = $true
                                }
                            }


                            # OneDrive for Business Backup Success?
                            LogWrite ('Success? {0}' -f ($Script:IsBackupOD))
                        }
                    }
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
        #endregion Backup OneDrive for Business
    


        #################
        # Azure AD Backup
        #################
        #region Backup Azure AAD

        LogWrite ('# Backup to Azure AD')
        If ($Script:IsBackupAAD) {
            LogWrite ('Already done')
        }
        
        Else {
            $Script:BoolDidAnythingChangeThisRuntime = $true
                   
            #Check if we can use BackupToAAD-BitLockerKeyProtector commandlet
            try {
                LogWrite 'Check if we can use BackupToAAD-BitLockerKeyProtector commandlet...'
                $cmdName = 'BackupToAAD-BitLockerKeyProtector'
                if (Get-Command $cmdName -ErrorAction SilentlyContinue) {
                    #BackupToAAD-BitLockerKeyProtector commandlet exists
                    LogWrite ('{0} commandlet exists!' -f $cmdName) 
                    $null = BackupToAAD-BitLockerKeyProtector -MountPoint $OSDrive -KeyProtectorId $Script:ArrayRecoveryPasswords[0].KeyProtectorId -ErrorAction SilentlyContinue
                    If ($?) {
                        $Script:IsBackupAAD = $true
                    }
                    Else {
                        $Local:BLV = Get-BitLockerVolume -MountPoint $OSDrive
                        $null = BackupToAAD-BitLockerKeyProtector -MountPoint $OSDrive -KeyProtectorId $Local:BLV.KeyProtector[0].KeyProtectorId -ErrorAction Stop
                        If ($?) {
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
                        If ($?) {
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
            Finally {
                LogWrite ('Did backup to Azure AD Succeed? {0}' -f ($Script:IsBackupAAD))
            }
        }
        #endregion Backup Azure AAD
        
        
        # If no backup and no Recovery Passwords present
        
    }
    Else {
        LogWrite 'OS Drive is not encryptet, there are no Recovery Passwords, and there are no backups.'
    }
}
#endregion Backup
#endregion Main



####################
######  G U I ######
####################
#region GUI
If ($Script:IsEncrypted -and $Script:IsProtectionPassw -and $GUI) {
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
If ($Script:IsFinished1stTime) {
    LogWrite 'Finished first time = True | Just checked weather BitLocker Recovery Password had changed.'
}

Else {
    If ($Script:IsEncrypted -and $Script:IsProtectionPassw -and $Script:IsBackupAAD -and $Script:IsBackupOD) {
        Get-BitLockerStatus
        If (($Script:VolumeEncStatus -eq $Script:BitLockerVolumeEncryptionStatuses[2]) -and ($Script:CountRecoveryPasswords -eq 1)) {
        
            # First successfull run
            $Script:IsFinished1stTime = $true 
            
            # ScheduledTask
            Edit-ScheduledTask -TaskName $Script:ScheduledTaskName

            # Files
            #region Remove files
            If ($Script:BoolRemoveFilesAfterSuccess -and $Script:IsFinished1stTime) {               
                $null = Start-Job -ArgumentList $Script:FileLog -ScriptBlock {
                    Param([string] $FileLog)
        
                    Function LogWrite {
                        Param ([string]$LogString)
                        [string] $a = Get-Date
                        [string] $LogString = $a, $LogString
                        Add-content -Path $FileLog -Value $LogString
                    }
                    [String] $Local:RemDirPath = (${env:ProgramFiles(x86)} + '\BitLockerTrigger\')
                   
                    Start-Sleep -Seconds 5
                    LogWrite ('Started the job to remove "{0}"' -f ($Local:RemDirPath))
                    If (Test-Path $Local:RemDirPath) {
                        Remove-Item -Path $Local:RemDirPath -Recurse -Force
                        LogWrite ('Removing the folder (recurse, force). Success? {0}' -f ($?))
                    }
                    Else {
                        LogWrite ('Folder does not exist')
                    }            
                }                
            }
            #endregion Remove Files
        }    
    }
    Else {
        LogWrite 'There are still things to do. Trying again later.'
    }
}
#endregion End Results



####################
#### S T A T S #####
####################
LogWrite ('### STATS')
$Script:CountRuns += 1

If (-not($Script:BoolRemoveFilesAfterSuccess)) {
    If (-not(Test-Path $Script:DirInstall)) {
        $null = New-Item -Path $Script:DirInstall -ItemType Directory -Force
    }
    
    [String] $OutString = (($Script:CountRuns).ToString() + "`r`n")                   # 0
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

If ($Script:BoolDidAnythingChangeThisRuntime) {
    Write-Stats 
}



### Give up after X runs and IsFinished1stTime -eq $false
If ($Script:CountRuns -eq 30 -and (-not($Script:IsFinished1stTime))) {
    LogWrite ('Should have been done by now.')
    Edit-ScheduledTask -TaskName $Script:ScheduledTaskName

    If ($false) {
        ### Gathering info for the email
        If (-not($Script:WindowsVersion)) {
            Create-EnvVariables
        }
        ### Building email string
        [String] $Local:StrSubject = ('BitLockerTrigger failed {0} times for tenant "{1}", device: "{2}"' -f ($CountRuns.ToString(),$Local:NameTenant,$Local:NameComputer))
        [String] $Local:StrEmail = [String]::Empty
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
        [String] $Local:StrToEmailAddress = 'Olav R. Birkeland <olavb@ironstoeit.com>;'
        #$StrEmailAddress += 'Ironstone Servicedesk <servicedeks@ironstoneit.com>'
        [String] $Local:StrFromEmailAddress = ('BitLockerTriggerFail@{0}' -f ($Script:NameTenant))
        #Send-MailMessage -To $Local:StrToEmailAddress -SmtpServer  -From $Local:StrFromEmailAddress -Subject $Local:StrSubject -Body $Local:StrEmail
        #>
    }
}





####################
####  D O N E  #####
####################
LogWrite ('All done, exiting script...')
#endregion Main