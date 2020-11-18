#Requires -Version 5.1 -RunAsAdministrator

<#
.DESCRIPTION
    This script will make sure all fixed drives are encrypted, protected by TPM and RecoveryPassword, and that RecoveryPassword is backed up to OneDrive for Business.
    It's designed to work in conjunction with existing features in Microsoft Intune MDM: The actual progress of encryption is not possible with Intune Policies yet. 
    Additional functionality is backing up the RecoveryPassword to OneDrive for Business.

    Script recepy
        1. Continue only if TPM is present
        2. Surpress Toast Notification from BitLocker
        3. Add / make sure RecoveryPassword is present for each volume, BEFORE encryption / Enable-BitLocker
        4. If 3., Enable-BitLocker
        5. If 4., and volume != Os Drive, Enable-BitLockerAutoUnlock

    This script handles
        * Surpress everything GUI related to BitLocker, to avoid exposure of these highly technical decisions to the end user
        * Encryption of all fixed NTFS volumes
        * KeyProtors for all BitLocker enabled volumes
        * BitLocker AutoUnlock for all BitLocker enabled volumes EXCEPT the SystemDrive ($env:SystemDrive)
        * Backup of BitLocker RecoveryPassword for BitLocker enabled volumes

    Intune handles these tasks (Make sure to configure these before deploying this script):
        * Backup RecoveryPassword to Azure AD    (Azure RM Portal -> Intune MDM -> Device Configuration -> Profiles -> Endpoint Protection -> Windows Encryption
        * Set default EncryptionMethod by Policy (Azure RM Portal -> Intune MDM -> Device Configuration -> Profiles -> Endpoint Protection -> Windows Encryption
        * Require BitLocker Encryption
        * Automatic encryption during AADJ       (Azure RM Portal -> Intune MDM -> Device Configuration -> Profiles -> Device Restrictions -> Passwords)
        * Disable BitLockerProtectors other than TPM and RecoveryPassword
        * Hide notification regardig 3rd party encryption tools
        

.RESOURCES
    Add-BitLockerKeyProtector       https://docs.microsoft.com/en-us/powershell/module/bitlocker/add-bitlockerkeyprotector
    Get-BitLockerVolume             https://docs.microsoft.com/en-us/powershell/module/bitlocker/get-bitlockervolume
    Enable-BitLockerVolume          https://docs.microsoft.com/en-us/powershell/module/bitlocker/enable-bitlocker
    Enable-BitLockerVolumeUnlock    https://docs.microsoft.com/en-us/powershell/module/bitlocker/enable-bitlockerautounlock
#>


#region    Settings & Variables
    # Settings
    $VerbosePreference = 'SilentlyContinue'
    # Variables - SystemDrive
    [string] $DriveLetterSystemDrive = [string]$(if(-not([string]::IsNullOrEmpty($env:SystemDrive))){$env:SystemDrive.Remove(1,1)}else{[System.Environment]::SystemDirectory.Split(':')[0]}).ToUpper()
    # Variables - EncryptionMethod
    [string] $PathDirReg        = 'HKLM:\SOFTWARE\Policies\Microsoft\FVE'                                                    # Registry path where policies regarding BitLocker Encryption Methods reside                                                                                    
    [PSCustomObject[]] $EncryptionMethods = @(
        [PSCustomObject]@{RegValue=[byte]3;StringValue=[string]'Aes128'},
        [PSCustomObject]@{RegValue=[byte]4;StringValue=[string]'Aes256'},
        [PSCustomObject]@{RegValue=[byte]6;StringValue=[string]'XtsAes128'},                                                 # <-- Default from Windows 10 1511 and newer, will be default in this script
        [PSCustomObject]@{RegValue=[byte]7;StringValue=[string]'XtsAes256'}
    )
    [string[]] $NamesReg        = [string[]]@('EncryptionMethodWithXtsOs','EncryptionMethodWithXtsFdv','EncryptionMethodWithXtsRdv')   # 1st Value = OS Drive, 2nd Value = Other Fixed Drives, 3rd Value = Removable Drives
#endregion Settings & Variables



#region    Initialization
    # Only continue if TPM is present
    $TpmState = Get-TPM -Verbose:$false
    if (($TpmState).TpmPresent) {Write-Output -InputObject ('TPM Present, will continue.')}
    else {Throw 'No TPM present, cannot continue'}


    # Check if secureBoot is enabled, for the records.
    Write-Output -InputObject ('SecureBoot enabled? {0}.' -f (([bool] $SecureBootEnabled = Confirm-SecureBootUEFI -Verbose:$false).ToString()))


    # Get All Fixed Volumes
    [string[]] $VolumesToEncrypt = [string[]]@(Get-Volume -Verbose:$false | Where-Object {$_.DriveLetter -and $_.DriveType -eq 'Fixed' -and [bool]([string](@('NTFS','ReFS'))).Contains($_.FileSystem)
    } | Select-Object -ExpandProperty 'DriveLetter' -Unique | ForEach-Object {([string]($_)).ToUpper()})
#endregion Initialization



#region    Surpress Toast Notifications from BitLocker
    # Get Current User as SecurityIdentifier
    if (-not($Script:PathDirRootCU)){
        [string] $Script:PathDirRootCU = ('HKU:\{0}\' -f ([System.Security.Principal.NTAccount]::new(@(Get-Process -Name 'explorer' -IncludeUserName)[0].UserName).Translate([System.Security.Principal.SecurityIdentifier]).Value))
        if((-not($?)) -or [string]::IsNullOrEmpty($Script:PathDirRootCU)){Break}
    }
    # Add HKU:\ as PSDrive if not already
    if ((Get-PSDrive -Name 'HKU' -ErrorAction SilentlyContinue) -eq $null) {$null = New-PSDrive -PSProvider Registry -Name 'HKU' -Root 'HKEY_USERS' -Verbose:$false}

    # Set REG value
    [string] $RegDir = ('{0}\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.BitLockerPolicyRefresh' -f ($PathDirRootCU))
    if (-not(Test-Path -Path $RegDir)) {$null = New-Item -Path $RegDir -ItemType 'Directory' -Force -Verbose:$false}
    $null = Set-ItemProperty -Path $RegDir -Name 'Enabled' -Value 0 -Type 'DWord' -Force -Verbose:$false
#endregion Surpress Toast Notifications from BitLocker



#region    Encryption
    if ([System.Version]$PSVersionTable.BuildVersion -gt [System.Version]'10.0.17134.0') {
        Write-Output -InputObject ('Will not configure BitLocker on 1803 or newer.')
    }

    else {  
        # Loop all of them
        :MainLoop foreach ($MountPoint in $VolumesToEncrypt) {
            # Output which drive we're currently at
            Write-Output -InputObject ('## Mount Point: {0}' -f ($MountPoint))
    


            # Get Info
            $BitLockerVolume = Get-BitLockerVolume -MountPoint $MountPoint -Verbose:$false
        
        
              
            #region    Add-BitLockerKeyProtector -RecoveryPasswordProtector (If A: BitLockerStatus is If no RecoveryPassword is found)
                Write-Output -InputObject ('# Add-BitLockerKeyProtector -RecoveryPasswordProtector')
        
                # Get current status
                $RecoveryPasswords = @($BitLockerVolume | Select-Object -ExpandProperty KeyProtector | Where-Object {$_.KeyProtectorType -eq 'RecoveryPassword'})
            

                if ($RecoveryPasswords.Count -ne 1) {                
                    # Enable RecoveryPasswordProtector if none is found
                    if ($RecoveryPasswords.Count -eq 0) {
                        $null = Add-BitLockerKeyProtector -MountPoint $MountPoint -RecoveryPasswordProtector -Confirm:$false -Verbose:$false -WarningAction SilentlyContinue
                    } 

                    # If more than one RecoveryPassword, remove everyone but one
                    elseif ($RecoveryPasswords.Count -gt 1) {
                        Write-Output -InputObject ('Found more than one RecoveryPassword. Will Remove everyone but one.')
                        foreach ($RecoveryPassword in $RecoveryPasswords) {
                            if ($RecoveryPassword -ne $RecoveryPasswords[0]) {
                                $null = Remove-BitLockerKeyProtector -MountPoint $MountPoint -KeyProtectorId $RecoveryPasswords.KeyProtectorId -Confirm:$false -Verbose:$false
                            }
                        }

                    }

                    # Refresh Variables
                    $null = Start-Sleep -Seconds 1
                    $BitLockerVolume = Get-BitLockerVolume -MountPoint $MountPoint -Verbose:$false
                    $RecoveryPasswords = @($BitLockerVolume | Select-Object -ExpandProperty KeyProtector | Where-Object {$_.KeyProtectorType -eq 'RecoveryPassword'})
                }

                # Write Out Status
                Write-Output -InputObject ('Status: {0}' -f ($(
                    if     ($RecoveryPasswords.Count -eq 0) {'Fail, no RecoveryPassword found.'}
                    elseif ($RecoveryPasswords.Count -eq 1) {'All good, 1 RecoveryPassword found.'}
                    elseif ($RecoveryPasswords.Count -ge 2) {'Fail, more than one RecoveryPassword found.'}
                    else   {'Unknown error.'}
                )))

                # Don't continue if 0 or multiple RecoveryPasswords Present
                    if ($RecoveryPasswords.Count -ne 1){Continue}
            #endregion Add-BitLockerKeyProtector -RecoveryPasswordProtector (If no RecoveryPassword is found)   



            #region    Enable-BitLockerAutoUnlock (If A: Not SystemDrive B: One RecoveryPassword Available C: Not already enabled)
                Write-Output -InputObject ('# Enable-BitLockerAutoUnlock')
                if ([string]$MountPoint -eq [string]$DriveLetterSystemDrive) {
                    Write-Output -InputObject ('Will not enable for OS Drive.')
                }
                else {
                    # OS Drive must have ProtectionStatus = On before AutoUnlock can be enabled for other fixed drives
                    if ([string](Get-BitLockerVolume -MountPoint $DriveLetterSystemDrive | Select-Object -ExpandProperty ProtectionStatus) -ne 'On') {
                        Write-Output -InputObject ('Cannot enable AutoUnlock and therefore not BitLocker before OS Drive is fully protected.')
                    }
                    elseif (($RecoveryPasswords.Count -eq 1) -and ($BitLockerVolume.AutoUnlockEnabled -ne $true)) {
                        Write-Output -InputObject ('Enable-BitLockerAutoUnlock')
                        Enable-BitLockerAutoUnlock -MountPoint $MountPoint -Confirm:$false -Verbose:$false
                        $BitLockerVolume = Get-BitLockerVolume -MountPoint $MountPoint
                    }

                    # Write Out Status
                    Write-Output -InputObject $(
                        if   ($BitLockerVolume.AutoUnlockEnabled -eq $true) {'All good, AutoUnlock is enabled.'}
                        else {'Failed, did not manage to enable AutoUnlock.'}
                    )

                    # Continue if this was not a OS Drive, and AutoUnlock is not enabled
                    if ($MountPoint -ne $DriveLetterSystemDrive -and $BitLockerVolume.AutoUnlockEnabled -ne $true){Continue MainLoop}
                }
            #endregion Enable-BitLockerAutoUnlock (If A: Not SystemDrive B: One RecoveryPassword Available C: Not already enabled)


    
            #region    Enable-BitLocker (If not enabled)
                Write-Output -InputObject ('# Enable-BitLocker')
        
                # Encrypt if not encrypted
                [string] $VolumeStatus = $BitLockerVolume | Select-Object -ExpandProperty VolumeStatus
                if ($VolumeStatus -eq 'FullyEncrypted') {
                    Write-Output -InputObject ('BitLocker is already enabled, and fully encrypted. EncryptionMethod: {0}.' -f ($BitLockerVolume.EncryptionMethod))
                }
                elseif ($VolumeStatus -eq 'EncryptionInProgress') {
                    Write-Output -InputObject ('BitLocker is already enabled, but drive is not done being encrypted. EncryptionPercentage: {0}. EncryptionMethod: {1}.' -f (
                        ($BitLockerVolume | Select-Object -ExpandProperty EncryptionPercentage),$BitLockerVolume.EncryptionMethod))
                }
                else {
                    Write-Output -InputObject ('BitLocker is not enabled yet. Enabling.')  
            
                    # Only continue if 1 RecoveryPassword is found for current Volume / MountPoint
                    if (@($BitLockerVolume | Select-Object -ExpandProperty 'KeyProtector' | Where-Object {$_.KeyProtectorType -eq 'RecoveryPassword'}).Count -ne 1) {
                        Write-Output -InputObject ('Error, zero or multiple RecoveryPassword is available. Will not continue.')
                    }

                    else {
                        # Set encryption method if policy does not specify anything xts
                        [string] $NameReg = $(if($MountPoint -eq $env:SystemDrive){$NamesReg[0]}else{$NamesReg[1]})
                        [string] $EncryptionMethodRegistryValue = Get-ItemProperty -Path $PathDirReg -Name $NameReg -ErrorAction SilentlyContinue | Select-Object -ExpandProperty $NameReg
                        if ([string]::IsNullOrEmpty($EncryptionMethodRegistryValue) -or (-not([byte[]]@(6,7).Contains([byte] $EncryptionMethodRegistryValue)))) {
                            [string] $EncryptionMethodUse = ($EncryptionMethods | Where-Object {[byte]$_.RegValue -eq [byte]6}).StringValue
                        } else {[string] $EncryptionMethodUse = ($EncryptionMethods | Where-Object {[byte]$_.RegValue -eq [byte]$EncryptionMethodRegistryValue}).StringValue}
            
                        # Enable BitLocker
                        if ($MountPoint -eq $DriveLetterSystemDrive -and @($BitLockerVolume | Select-Object -ExpandProperty 'KeyProtector' | Where-Object {$_.KeyProtectorType -eq 'TPM'}).Count -eq 0) {
                            $null = Enable-BitLocker -MountPoint $MountPoint -EncryptionMethod $EncryptionMethodUse -TpmProtector -Confirm:$false -Verbose:$false -WarningAction SilentlyContinue
                        } 
                        else {
                            if ($MountPoint -ne $DriveLetterSystemDrive -and $BitLockerVolume.AutoUnlockEnabled -ne $true) {
                                Write-Output -InputObject ('Will not enable BitLocker on this drive when AutoUnlock is false.')
                            }
                            else {
                                $null = Enable-BitLocker -MountPoint $MountPoint -EncryptionMethod $EncryptionMethodUse -RecoveryPasswordProtector -RecoveryPassword `
                                    ($BitLockerVolume | Select-Object -ExpandProperty KeyProtector | Where-Object {$_.KeyProtectorType -eq 'RecoveryPassword'} | Select-Object -First 1 -ExpandProperty RecoveryPassword).Replace('-','') `
                                    -Confirm:$false -Verbose:$false -WarningAction SilentlyContinue
                            }
                        }
                        $BitLockerVolume = Get-BitLockerVolume -MountPoint $MountPoint -Verbose:$false
                    }
                }
        
                # Write Out Status
                Write-Output -InputObject ('Status: {0}' -f ($(
                    if     ($BitLockerVolume.VolumeStatus -eq 'FullyDecrypted')       {'Fail, neither enabled or encrypted.'}
                    elseif ($BitLockerVolume.VolumeStatus -eq 'DecryptionInProgress') {'Fail, actually decyptiong this volume.'}
                    elseif ($BitLockerVolume.VolumeStatus -eq 'EncryptionInProgress') {'Enabled, but not fully encrypted yet.'}
                    elseif ($BitLockerVolume.VolumeStatus -eq 'FullyEncrypted')       {'Enabled and fully encrypted.'}
                    else   {'Unknown VolumeStatus'}
                )))
            #endregion Enable-BitLocker (If not enabled)
          

            #region    Only Continue available TPM and RecoveryPassword count is 2
                #if (@($BitLockerVolume | Select-Object -ExpandProperty 'KeyProtector' | Where-Object {[string[]]@('RecoveryPassword','TPM').Contains($_.KeyProtectorType)}).Count -ne 2){Continue}      
            #endregion Only Continue available TPM and RecoveryPassword count is 2
        }
    }
#endregion Encryption



#region    Backup

#endregion Backup