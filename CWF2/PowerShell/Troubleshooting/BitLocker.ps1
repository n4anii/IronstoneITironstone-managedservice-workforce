#region    BitLocker Troubleshooting
    # Get Architecture
    ~(Write-Output -InputObject ('OS Architecture 64bit? {0} | CPU Architecture: {1}' -f ([System.Environment]::Is64BitOperatingSystem,$env:PROCESSOR_ARCHITECTURE)))
    
    # Get BIOS Version
    ~(Get-ItemProperty -Path 'HKLM:\HARDWARE\DESCRIPTION\System\BIOS' -Name 'BIOSVersion' | Select-Object -ExpandProperty 'BIOSVersion')

    # Check if SecureBoot is enabled
    ~(Confirm-SecureBootUEFI)

    # Get TPM
    ~(Get-Tpm)

    # Check if encrypted
    ~(Get-BitLockerVolume -MountPoint $env:SystemDrive | Select-Object -Property *)
    ~(Get-BitLockerVolume -MountPoint $env:SystemDrive | Select-Object -ExpandProperty VolumeStatus)
    ~(Get-BitLockerVolume -MountPoint $env:SystemDrive | Select-Object -ExpandProperty EncryptionPercentage)
    ~(Get-BitLockerVolume -MountPoint $env:SystemDrive | Select-Object -ExpandProperty KeyProtector | Select-Object -ExpandProperty KeyProtectorType)

    # Get current RecoveryPassword
    ~(Get-BitLockerVolume -MountPoint $env:SystemDrive | Select-Object -ExpandProperty KeyProtector | Where-Object -Property 'KeyProtectorType' -EQ 'RecoveryPassword' | Select-Object -ExpandProperty 'RecoveryPassword')
    
    # Add new RecoveryPassword
    $Object = Add-BitLockerKeyProtector -MountPoint $env:SystemDrive -RecoveryPasswordProtector -WarningAction 'SilentlyContinue'

    # Start Encryption
        # OS DRIVE
        ~(Enable-BitLocker -MountPoint $env:SystemDrive -RecoveryPasswordProtector -TpmProtector -Confirm:$false)
        # RecoveryPasswordProtector   YES   If TPM fails, or we need to take the storage out of the computer, we need a recovery key. This will get backed up to OneDrive for Business.
        # TpmProtector                YES   If not, user must type in a pin or password before even booting Windows.
        # SkipHardwareTest            NO    We don't know how bad this might turn out to be, if a PC that would not succeed hardware test where to get encrypted anyway.
        # UsedSpaceOnly               NO    Quick format of a drive will leave data, it's just not "available" / "viewable" to the user. Therefor we want to encrypt the whole volume!
    
    # Get log from Install-IronTrigger      (C:\Program Files\IronstoneIT\Intune\DeviceConfiguration\Device_Install-IronTrigger-64bit-*.txt)
    ~(Get-Content -Path (Get-ChildItem -Path ('{0}\IronstoneIT\Intune\DeviceConfiguration' -f ($env:ProgramW6432)) | Where-Object {$_.Name -like ('Device_Install-IronTrigger-64bit*')} | Sort-Object -Property LastWriteTime | Select-Object -Last 1 -ExpandProperty 'FullName') -Raw)

    # Get EnableBitLocker log               (C:\Program Files\IronstoneIT\Intune\DeviceConfiguration\IronTrigger - EnableBitLocker.log)
    ~(Get-Content -Path (Get-ChildItem -Path ('{0}\IronstoneIT\Intune\DeviceConfiguration' -f ($env:ProgramW6432)) | Where-Object {$_.Name -like ('IronTrigger - EnableBitLocker.log')} | Sort-Object -Property LastWriteTime | Select-Object -Last 1 -ExpandProperty 'FullName') -Raw)
#endregion BitLockerTroubleshooting