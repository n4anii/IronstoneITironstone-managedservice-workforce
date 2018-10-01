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
# Settings
[bool] $GUI = $false
[bool] $Script:BoolRemoveFilesAfterSuccess = $false
# Variables
[String] $Local:Name = 'IronTrigger'
[String] $Script:ScheduledTaskName = $Local:Name.Clone()
[String] $Script:ComputerName = $env:COMPUTERNAME
[String] $Script:BitLockerTriggerPath = ('{0}\{1}\' -f (${env:ProgramFiles(x86)},$Local:Name))
[String] $Script:FileLog = ('C:\Windows\Temp\{0}.log' -f ($Local:Name))
[String] $Script:FileStats = ($Script:BitLockerTriggerPath + 'stats.txt')
[String[]] $Script:BitLockerEncryptionStatuses = @('FullyDecrypted','EncryptionInProgress','FullyEncrypted')
#endregion Settings and Variables



#region Functions
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


    #region Write-Stats:
    # Write-Stats: Outputs current status of various booleans and other measurements
    Function Write-Stats {
        [bool[]] $Local:KeyProtectorTypes = Get-BitLockerKeyProtectorTypes    
        LogWrite ('Runs: {0} | Encrypted: {1} | Recovery Passwords present: {2} | Backup to OneDrive: {3} | Backup to AzureAD: {4}' -f ($Script:CountRuns,$Script:IsEncrypted,$Script:IsProtectionPassw,$Script:IsBackupOD,$Script:IsBackupAAD))
        LogWrite ('BitLocker KeyProtector Types present? | TPM: {0} | RecoveryPassword: {1}' -f ($Local:KeyProtectorTypes[0],$Local:KeyProtectorTypes[1]))
    }
    #endregion Write-Stats:


    #region Write-RecoveryPassword
    # Write-RecoveryPassword
    Function Write-RecoveryPassword {
        Get-RecoveryPasswords
        LogWrite ('Theres one Recovery Password present:')
        LogWrite (Get-RecoveryPasswordsString)
    }
    #endregion Write-RecoveryPassword


    #region Get-BitLockerStatus
    # Get-BitLockerStatus: Fills two strings (scope:script) with current Volume Encryption Status, and Volume Protection Status.
    Function Get-BitLockerStatus {
        [Microsoft.BitLocker.Structures.BitLockerVolume] $Local:BitLockerStatus = Get-BitLockerVolume -MountPoint $OSDrive
        [String] $Script:VolumeEncStatus = (($Local:BitLockerStatus | Select-Object -Property VolumeStatus).VolumeStatus).ToString()
        [String] $Script:VolumeProtectionStatus = (($Local:BitLockerStatus | Select-Object -Property ProtectionStatus).ProtectionStatus).ToString()
    }
    #endregion Get-BitLockerStatus


    #region Get-BitLockerKeyProtectorTypes
    # Get-BitLockerKeyProtectorTypes: Returns a bool array, where the first represents status of TPM presence, and the second for Protection Password
    Function Get-BitLockerKeyProtectorTypes {
        [Microsoft.BitLocker.Structures.BitLockerVolume] $Local:BitLockerStatus = Get-BitLockerVolume -MountPoint $OSDrive
        [uint16] $Local:CountRecPass = 0
        [uint16] $Local:CountTPM = 0
        $Local:BitLockerStatus.KeyProtector | ForEach-Object {
            If ($_.KeyProtectorType -eq 'RecoveryPassword') {$Local:CountRecPass += 1}
            ElseIf ($_.KeyProtectorType -eq 'TPM') {$Local:CountTPM += 1}
        }
        return ([bool] ($Local:CountTPM -ge 1),[bool] ($Local:CountRecPass -ge 1))
    }
    #endregionGet-BitLockerKeyProtectorTypes


    #region Get-RecoveryPasswords
    # Get-RecoveryPasswords: Fills a arraylist with existing ProtectionPasswords, scope:script
    Function Get-RecoveryPasswords {
        # Get Existing BitLocker ProtectionPasswords
        $Local:BitLockStatus = Get-BitLockerVolume -MountPoint $OSDrive
        $Local:KeyProtectorStatus = ($Local:BitLockStatus | Select-Object -Property KeyProtector).KeyProtector
        [System.Collections.ArrayList] $Script:ArrayProtectionPasswords = [System.Collections.ArrayList]::new()
        [uint16] $Script:CountProtectionKeys = 0

        $Local:KeyProtectorStatus | ForEach-Object {
            If ($_.KeyProtectorType -eq 'RecoveryPassword') {
                $Script:CountProtectionKeys += 1
                $null = $Script:ArrayProtectionPasswords.Add([PSCustomObject]@{KeyProtectorId = [String]$_.KeyProtectorId; RecoveryPassword = [String]$_.RecoveryPassword})
            }
        }
    }
    #endregion Get-RecoveryPasswords


    #region Get-RecoveryPasswordsString
    # Get-RecoveryPasswordsString: Returns a string containing the recovery passwords from $Script:ArrayProtectionPasswords. Usefull for printing/ logging/ backup
    Function Get-RecoveryPasswordsString {
        [uint16] $Local:TempCounter = 0
        [String] $Local:OutStr = [String]::Empty
        $Script:ArrayProtectionPasswords | ForEach-Object {
            $Local:OutStr += ('{0} | KeyProtectorId "{1}" | RecoveryPassword "{2}"' -f (($Local:TempCounter += 1),$_.KeyProtectorId,$_.RecoveryPassword))
        }
        Return $Local:OutStr
    }
    #endregion Get-RecoveryPasswordsString


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
#endregion Functions



#region Start
#### Start
##  Fetching previous run results
LogWrite ('Starting Trigger BitLocker script.')
If (-not (Test-Path -Path $Script:FileStats)) {
    [uint16] $Script:CountRuns = 0
    [bool] $Script:IsEncrypted = [bool] $Script:IsProtectionPassw = [bool] $Script:IsBackupOD = [bool] $Script:IsBackupAAD = $false
    LogWrite ('First run')
}
Else {
    [String[]] $InputString = (Get-Content -Path $Script:FileStats).Split([Environment]::NewLine)
    [uint16] $Script:CountRuns = [uint16] $InputString[0]
    [bool] $Script:IsEncrypted = [uint16] $InputString[1]
    [bool] $Script:IsProtectionPassw = [uint16] $InputString[2]
    [bool] $Script:IsBackupOD = [uint16] $InputString[3]
    [bool] $Script:IsBackupAAD = [uint16] $InputString[4]
    Write-Stats
}
#endregion Start



####################
#### ENCRYPTION ####
####################
LogWrite ('### BitLocker Encryption')
If ($Script:IsEncrypted) {
    LogWrite ('OS Drive is already encrypted.')
}
Else {
    # Get encryption status
    Get-BitLockerStatus
    LogWrite ('# Encryption')
    Logwrite ('Status of OS drive ({0}) | VolumeStatus: {1} | ProtectionStatus: {2}' -f ($OSDrive,$Script:VolumeEncStatus,$Script:VolumeProtectionStatus))

    # If 'FullyEncrypted'
    If ($Script:VolumeEncStatus -eq $Script:BitLockerEncryptionStatuses[2]) {
        LogWrite ('OS Drive is already encrypted.')
        $Script:IsEncrypted = $true
    }

    # If 'EncryptionInProgress'
    ElseIf ($Script:VolumeEncStatus -eq $Script:BitLockerEncryptionStatuses[1]) {
        LogWrite ('OS Drive encryption is in progress.')
        LogWrite ('Can continue to check if TPM is present, and add & backup Protection Password')
    }

    # If there exists a TPM, don't Enable-Bitlocker again
    ElseIf ((Get-BitLockerKeyProtectorTypes)[0]) {
        LogWrite ('OS Drive encryption has started, but it is not fully encrypted yet')
        LogWrite ('Awaiting restart')
        $Script:IsEncrypted = $false
    }

    # If there does not exist a TPM, and status = "FullyDecrypted": Enable-BitLocker     
    ElseIf ($VolumeEncStatus -eq $Script:BitLockerEncryptionStatuses[0]) {
        LogWrite ('OS Drive is not encrypted.')
        LogWrite ('Attempting to Enable BitLocker on OS drive ({0})' -f ($OSDrive))
        try {
            # Enable BitLocker using TPM
            $null = Enable-BitLocker -MountPoint $OSDrive -TpmProtector -UsedSpaceOnly -ErrorAction Continue
            If ($?) {
                LogWrite ('Success Enabling BitLocker? {0}' -f ($?))
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
    }

    # If scenario fits none of the cases above..
    Else {
        LogWrite ('Neither "{0}", "{1}" or "{2}", probably awaiting restart' -f ($Script:BitLockerEncryptionStatuses[0],$Script:BitLockerEncryptionStatuses[1],$Script:BitLockerEncryptionStatuses[2]))
    }
}


# Add BitLocker Recovery Password if none are present
LogWrite ('# RecoveryPassword')
If ($Script:IsEncrypted -or ($Script:VolumeEncStatus -eq $Script:BitLockerEncryptionStatuses[1])) {
    If (-not($Script:IsProtectionPassw)) {
        Get-RecoveryPasswords

        # If theres already a ProtectionPassword, we're done
        If ($Script:CountProtectionKeys -eq 1) {
            Write-RecoveryPassword
            $Script:IsProtectionPassw = $true
        }

        # If theres 0 or multiple ProtectionsPassword(s)
        Else {
            [bool] $Local:Success = $false

            # If there's no ProtectionPassword, we need to make one
            If ($Script:CountProtectionKeys -eq 0) {
                LogWrite ('No RecoveryPasswords found for OS Drive {0}, creating new one.' -f $OSDrive)
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
                    If ($?) {
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

        
            # If there's multiple existing ProtectionPasswords, delete all but one
            Else {
                LogWrite ('There are {0} Recovery Passwords present:' -f ($Script:CountProtectionKeys))
                [uint16] $Local:IntTempCounter = 0
                $Script:ArrayProtectionPasswords | ForEach-Object { LogWrite ('{0} | KeyProtectorId "{1}" | RecoveryPassword "{2}": ' -f (($Local:IntTempCounter += 1),$_.KeyProtectorId,$_.RecoveryPassword)) }
                LogWrite ('Will remove all but the first one')
                $Script:ArrayProtectionPasswords | ForEach-Object { 
                    If ($_.KeyProtectorId -ne $Script:ArrayProtectionPasswords[0].KeyProtectorId) {
                        $null = Remove-BitLockerKeyProtector -MountPoint $OSDrive -KeyProtectorId $_.KeyProtectorID
                        If ($?) {
                            LogWrite ('Successfully removed | KeyProtectorId "{0}" | RecoveryPassword "{1}"' -f ($_.KeyProtectorId,$_.RecoveryPassword))
                            $Script:CountProtectionKeys -= 1
                        }
                    }
                    Else {
                        LogWrite ('Successfully skipped the first key. | KeyProtectorId "{0}" | RecoveryPassword "{1}"' -f ($_.KeyProtectorId,$_.RecoveryPassword))
                    }
                }
                If ($Script:CountProtectionKeys -eq 1) {
                    $Local:Success = $true
                }              
            }

            # Count and list existing RecoveryPassword, only write success if theres one        
            If ($Local:Success) {
                LogWrite 'Checking if there is only one Protection Password.'
                Get-RecoveryPasswords
                
                If ($Script:CountProtectionKeys -eq 0) {
                    LogWrite ('FAIL, no Protection Password found')
                }               
                Else {
                    If ($Script:CountProtectionKeys -eq 1) {
                        LogWrite ('SUCCESS, keys left: 1.')
                        $Script:IsProtectionPassw = $true
                    }               
                    Else {
                        LogWrite 'FAIL, keys left: {0}.' -f ($Script:ArrayProtectionPasswords.Count)
                        $Script:IsProtectionPassw = $false
                    }
                    LogWrite ('Status: {0} key(s) present:' -f ($Global:CountProtectionKeys))
                    LogWrite ('KeyProtectorId "{0}" | RecoveryPassword "{1}".' -f ($Script:ArrayProtectionPasswords[0].KeyProtectorId,$Script:ArrayProtectionPasswords[0].RecoveryPassword))
                }                    
            }
            Else {
                LogWrite ('Something failed')
            }                    
        }
    
    }
    Else {
        Write-RecoveryPassword
    }
}
# Not encrypted = No making of RecoveryPassword
Else {
    LogWrite ('OS Drive is neither "FullyEncrypted" or "EncryptionInProgress": BitLocker RecoveryPassword can not be added.')
    LogWrite ('Recovery Password present? {0}' -f ((Get-BitLockerKeyProtectorTypes)[1]))
    $Script:IsProtectionPassw = $false
}



####################
###### BACKUP ######
####################
# Backup BitLocker Key to OneDrive and AzureAD
LogWrite ('### Backup Protection Password')
# Check whather OSDrive is encrypted and if Protection Password(s) exist
If (($Script:IsEncrypted -or ($Script:VolumeEncStatus -eq $Script:BitLockerEncryptionStatuses[1])) -and $Script:IsProtectionPassw) {
    LogWrite ('OS Drive is encrypted, and there are {0} ProtectionPassword(s) present.' -f ($Script:CountProtectionKeys))
    LogWrite ('Continuing with backup.')

    If ((-not($IsProtectionPassw)) -or (-not($IsBackupAAD))) {        
        If (-not ($Script:ArrayProtectionPasswords)) {
            Get-RecoveryPasswords
        }
    }

    ##############################
    # OneDrive for Business backup
    ##############################
    LogWrite ('# Backup to OneDrive')
    If ($Script:IsBackupOD) {
        LogWrite ('Already done')
    }
    Else {
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
                        [String] $Local:OD4BBackupPath = ($Local:OD4BPath + '\BitLocker Recovery\{0} ({1} {2})\' -f ($Script:ComputerName,$Script:ComputerManufacturer,$Script:ComputerProductName))
                        LogWrite ('OneDrive for Business path: {0}' -f ($Local:OD4BPath))
                        LogWrite ('Restore password path: {0}' -f ($Local:OD4BBackupPath)) 
                        #Testing if Recovery folder exists if not create one
                        LogWrite ('Testing if backup folder exists, create it if not.')
                        if (!(Test-Path $Local:OD4BBackupPath)) {
                            $null = New-Item -ItemType Directory -Force -Path $Local:OD4BBackupPath
                            If ($?) {
                                LogWrite 'Success creating OneDrive for Business folder for backup'
                            }
                        }
                        LogWrite ('Does backup folder exist? {0}' -f (Test-Path -Path $Local:OD4BBackupPath))                        
                        
                        # Create string for BitLockerRecoveryPassword.txt
                        $Local:StrRecPass = [String]::Empty
                        $Local:StrRecPass += ('BitLocker RecoveryPassword for OS Drive ({0}){1}' -f ($env:SystemDrive,"`r`n"))
                        $Local:StrRecPass += Get-RecoveryPasswordsString
                        $Local:StrRecPass += "`r`n`r`n"
                        $Local:StrRecPass += 'BitLocker Drive Encryption recovery key{0}' -f "`r`n"
                        $Local:StrRecPass += 'To verify that this is the correct recovery key, compare the start of the following{0}' -f "`r`n"
                        $Local:StrRecPass += 'identifier with the identifier value displayed on your PC.'
                        $Local:StrRecPass += "`r`n`r`n"
                        $Local:StrRecPass += ('Identifier: {0}' -f ($Script:ArrayProtectionPasswords[0].KeyProtectorId))
                        $Local:StrRecPass += "`r`n`r`n"
                        $Local:StrRecPass += 'If the above identifier matches the one displayed by your PC,{0}' -f "`r`n"
                        $Local:StrRecPass += 'then use the following key to  unlock your drive:'
                        $Local:StrRecPass += "`r`n`r`n"
                        $Local:StrRecPass += ('Recovery Key: {0}' -f ($Script:ArrayProtectionPasswords[0].RecoveryPassword))
                        $Local:StrRecPass += "`r`n`r`n"
                        $Local:StrRecPass += 'If the above identifier doesn`t match the one displayed by your PC,{0}' -f "`r`n"
                        $Local:StrRecPass += 'then this isn`t the right key to unlock your drive.{0}' -f "`r`n"
                        $Local:StrRecPass += 'Try another recovery key, or refer to{0}' -f "`r`n" 
                        $Local:StrRecPass += 'https://go.microsoft.com/fwlink/?LinkID=260589 for additional assistance.'

                        # Out-File the string
                        [String] $Local:CurDate = (Get-Date -Uformat '%y%m%d%H%M%S')
                        [String] $Local:OD4BBackupFilePath = ($Local:OD4BBackupPath + 'BitlockerRecoveryPassword {0}.txt' -f ($Local:CurDate))
                        Out-File -FilePath $Local:OD4BBackupFilePath -Encoding utf8 -Force -InputObject ($Local:StrRecPass)
                        If ($?) {
                            $Script:IsBackupOD = $true
                        }
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
    
    #################
    # Azure AD Backup
    #################
    LogWrite ('# Backup to Azure AD')
    If ($Script:IsBackupAAD) {
        LogWrite ('Already done')
    }
    Else {           
        #Check if we can use BackupToAAD-BitLockerKeyProtector commandlet
        try {
            LogWrite 'Check if we can use BackupToAAD-BitLockerKeyProtector commandlet...'
            $cmdName = 'BackupToAAD-BitLockerKeyProtector'
            if (Get-Command $cmdName -ErrorAction SilentlyContinue) {
                #BackupToAAD-BitLockerKeyProtector commandlet exists
                LogWrite ('{0} commandlet exists!' -f $cmdName) 
                $null = BackupToAAD-BitLockerKeyProtector -MountPoint $OSDrive -KeyProtectorId $Script:ArrayProtectionPasswords[0].KeyProtectorId -ErrorAction SilentlyContinue
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
                (Get-BitLockerVolume -MountPoint $OSDrive).KeyProtector|? {$_.KeyProtectorType -eq 'RecoveryPassword'}| % {
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

} 
else {
    LogWrite ('Drive is not encrypted and/or no Protection Password(s) present.')
    LogWrite ('Will skip backup, for now.')
}


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
#### S T A T S #####
####################
LogWrite ('### STATS')
$Script:CountRuns += 1

If (-not($Script:BoolRemoveFilesAfterSuccess)) {
    If (-not(Test-Path $Script:BitLockerTriggerPath)) {
        $null = New-Item -Path $Script:BitLockerTriggerPath -ItemType Directory -Force
    }
    
    [String] $OutString = (($Script:CountRuns).ToString() + "`r`n")
    $OutString += (([uint16] $Script:IsEncrypted).ToString() + "`r`n")
    $OutString += (([uint16] $Script:IsProtectionPassw).ToString() + "`r`n")
    $OutString += (([uint16] $Script:IsBackupOD).ToString() + "`r`n")
    $OutString += (([uint16] $Script:IsBackupAAD).ToString() + "`r`n")
    Out-File -FilePath $Script:FileStats -Encoding utf8 -Force -InputObject ($OutString)
}
LogWrite ('Runs so far: {0}' -f ($Script:CountRuns))

If ($Script:CountRuns -eq 30) {
    LogWrite ('Should have been done by now. Sending a support request to your helpdesk')
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



####################
#### END RESULT ####
####################
LogWrite ('### End results')
Write-Stats
# Cleaning up if success
If ($Script:IsEncrypted -and $Script:IsProtectionPassw -and $Script:IsBackupAAD -and $Script:IsBackupOD) {
    Get-BitLockerStatus
    Get-RecoveryPasswords
    If (($Script:VolumeEncStatus -eq 'FullyEncrypted') -and ($Script:ArrayProtectionPasswords.Count -ge 1)) {
        LogWrite 'Removing the Scheduled task and files.'
        
        # Scheduled Task
        $Local:ScheduledTasks = Get-ScheduledTask | Where-Object {$_.TaskName -like $Script:ScheduledTaskName -or $_.TaskName -like '*Trigger'}
        If ($Local:ScheduledTasks.length -gt 0) {
            $Local:Tasks | ForEach-Object {             
                $null = Unregister-ScheduledTask -TaskName $_.TaskName -Confirm:$false -ErrorAction SilentlyContinue
                LogWrite ('Removing the Scheduled task "{0}". Success? {1}' -f ($_.TaskName,$?))
            }
        }
        Else {
            If (Get-ScheduledTask -TaskName $Script:ScheduledTaskName -ErrorAction SilentlyContinue) {            
                $null = Unregister-ScheduledTask -TaskName $Script:ScheduledTaskName -Confirm:$false -ErrorAction SilentlyContinue
                LogWrite ('Removing the Scheduled task "{0}". Success? {1}' -f ($Script:ScheduledTaskName,$?))
            }
            Else {
                LogWrite ('Scheduled task "{0}" does not exist.' -f ($Script:ScheduledTaskName))
            }
        }

        # Files
        If (-not($Script:BoolRemoveFilesAfterSuccess)) {
            [String] $Local:LogDestPath = ($Script:BitLockerTriggerPath + 'TriggerBitLocker.log')
            Copy-Item -Path $Script:FileLog -Destination $Local:LogDestPath -Force
        }
        Else {
            $null = Start-Job -ArgumentList $Script:FileLog -ScriptBlock {
                Param(
                    [string] $FileLog
                )
        
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
    }    
}
Else {
    LogWrite 'There are still things to do. Trying again in 15 minutes.'
}



####################
####  D O N E  #####
####################
LogWrite ('All done, exiting script...')