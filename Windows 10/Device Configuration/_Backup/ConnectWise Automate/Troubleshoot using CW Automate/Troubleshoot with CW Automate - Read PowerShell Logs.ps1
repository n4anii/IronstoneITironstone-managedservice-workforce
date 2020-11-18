#region    Device Context / Program Files
    # List all logs by date
    ~(Get-ChildItem -Path ('{0}\IronstoneIT\Intune\DeviceConfiguration' -f ($env:ProgramW6432)) -File | Sort-Object -Property LastWriteTime)

    # Device_RecordingDeviceVolumeMax
    ~(Get-Content -Path (Get-ChildItem -Path ('{0}\IronstoneIT\Intune\DeviceConfiguration' -f ($env:ProgramW6432)) -File | Where-Object {$_.Name -like ('Device_Install-RecordingDeviceVolumeMax-64bit*')} | Sort-Object -Property LastWriteTime | Select-Object -Last 1 -ExpandProperty 'FullName') -Raw)

    # Device_Configure-OneDriveForBusiness
    ~(Get-Content -Path (Get-ChildItem -Path ('{0}\IronstoneIT\Intune\DeviceConfiguration' -f ($env:ProgramW6432)) -File | Where-Object {$_.Name -like ('Device_Configure-OneDriveForBusiness-64bit*')} | Sort-Object -Property LastWriteTime | Select-Object -Last 1 -ExpandProperty 'FullName') -Raw)

    # Set-CountryTime&Settings
    ~(Get-Content -Path (Get-ChildItem -Path ('{0}\IronstoneIT\Intune\DeviceConfiguration' -f ($env:ProgramW6432)) -File | Where-Object {$_.Name -like ('Device_Set-CountryTime&Settings-64bit*')} | Sort-Object -Property LastWriteTime | Select-Object -Last 1 -ExpandProperty 'FullName') -Raw)
#endregion Device Context / Program Files



#region    User Context / AppData    
    # List all User logs by date
    ~(Get-ChildItem -Path ('{0}\Users\{1}\AppData\Roaming\IronstoneIT\Intune\DeviceConfiguration' -f ($env:SystemDrive,@(Get-Process -Name 'explorer' -IncludeUserName)[0].UserName.Split('\')[-1])) -File | Sort-Object LastWriteTime)

    # User_Add-IETrustedSites_Microsoft
    ~(Get-Content -Path (Get-ChildItem -Path ('{0}\Users\{1}\AppData\Roaming\IronstoneIT\Intune\DeviceConfiguration' -f ($env:SystemDrive,@(Get-Process -Name 'explorer' -IncludeUserName)[0].UserName.Split('\')[-1])) -File | Where-Object {$_.Name -like ('User_Add-IETrustedSites_Microsoft-64bit*')} | Sort-Object -Property LastWriteTime | Select-Object -Last 1 -ExpandProperty 'FullName') -Raw)

    # Get UPN from registry AzureAD Joined Devices
    ~((Get-ItemProperty -Path ('Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo\{0}' -f ((Get-ChildItem -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo\').Name.Split('\')[-1])) -Name 'UserEmail' | Select-Object -ExpandProperty 'UserEmail'))

    # Get UPN from registry AzureAD Joined Devices
    ~(Get-ItemProperty -Path ('Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo\{0}' -f ((Get-ChildItem -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo\' -ErrorAction 'SilentlyContinue' | Select-Object -First 1 -ExpandProperty Name).Split('\')[-1])) -Name 'UserEmail' -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'UserEmail')
#endregion User Context / AppData



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



#region    Default Applications
    # Windows 10 Defaults - View list
    Dism.exe /Online /Get-DefaultAppAssociations
    
    # Export current list as SYSTEM user
    ~(Start-Process -NoNewWindow -FilePath ('{0}\Dism.exe' -f ([System.Environment]::SystemDirectory)) -ArgumentList ('/online /Export-DefaultAppAssociations:"{0}"' -f (('{0}\Temp\DefaultApps.txt' -f ($env:windir)))))

    # Get default app for ".pdf"   (HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.pdf\UserChoice)
    ~(Get-ItemProperty -Path ('Registry::HKEY_USERS\{0}\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.pdf\UserChoice' -f ([System.Security.Principal.NTAccount]::new(@(Get-Process -Name 'explorer' -IncludeUserName)[0].UserName).Translate([System.Security.Principal.SecurityIdentifier]).Value)) -Name 'ProgId' | Select-Object -ExpandProperty 'ProgId')

    # Get default app for "mailto" (HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\mailto\UserChoice)
    ~(Get-ItemProperty -Path ('Registry::HKEY_USERS\{0}\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\mailto\UserChoice' -f ([System.Security.Principal.NTAccount]::new(@(Get-Process -Name 'explorer' -IncludeUserName)[0].UserName).Translate([System.Security.Principal.SecurityIdentifier]).Value)) -Name 'ProgId' | Select-Object -ExpandProperty 'ProgId')

    # Look at the exported list
    ~(Get-Content -Path ('{0}\Temp\DefaultApps.txt' -f ($env:windir)))

    # Re-register all apps
    ~(Get-AppxPackage -User @(Get-Process -Name 'explorer' -IncludeUserName)[0].UserName | ForEach-Object {Add-AppxPackage -DisableDevelopmentmode -Register ('{0}\Appxmanifest.xml' -f ($_.InstallLocation))})
#endregion Default Applications



#region    Run a full fledged PowerShell Script as Base64
    '"%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy Bypass -NoLogo -NonInteractive -NoProfile -WindowStyle Hidden -EncodedCommand "base64string"'
#endregion Run a full fledged PowerShell Script as Base64