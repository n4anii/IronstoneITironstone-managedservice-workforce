#region    Device Context / Program Files
    # List all logs by date - $env:ProgramW6432
    Get-ChildItem -Path ('{0}\IronstoneIT\Intune\DeviceConfiguration' -f ($env:ProgramW6432)) -File | Sort-Object -Property 'LastWriteTime'

    # List all logs by date - $env:ProgramData
    ## ProgramData
    ### All
    Get-ChildItem -Path ('{0}\IronstoneIT\Intune\ClientApps\Install' -f ($env:ProgramData)) -File -ErrorAction 'SilentlyContinue' | Sort-Object -Property 'LastWriteTime'
    Get-ChildItem -Path ('{0}\IronstoneIT\Intune\DeviceConfiguration' -f ($env:ProgramData)) -File | Sort-Object -Property 'LastWriteTime'
    

    # Read log content - Dynamically fetch the newest log
    ## ProgramData
    ### Device_
    Get-Content -Raw -Path ($([array](Get-ChildItem -Path ('{0}\IronstoneIT\Logs\DeviceConfiguration' -f ($env:ProgramData)) -File | Where-Object -Property 'Name' -like '*Device_*' | Sort-Object -Property 'LastWriteTime'))[0].'FullName')
    ### User_
    Get-Content -Raw -Path ($([array](Get-ChildItem -Path ('{0}\IronstoneIT\Logs\DeviceConfiguration' -f ($env:ProgramData)) -File | Where-Object -Property 'Name' -like '*User_*' | Sort-Object -Property 'LastWriteTime'))[0].'FullName')

    # Specific log
    ~(Get-Content -Path (Get-ChildItem -Path ('{0}\IronstoneIT\Intune\DeviceConfiguration\{1}' -f ($env:ProgramW6432,'Device_Add-IETrustedSites_Microsoft-64bit-181216-1012368379.txt'))))

    # Device_Install-RecordingDeviceVolumeMax
    ~(Get-Content -Path (Get-ChildItem -Path ('{0}\IronstoneIT\Intune\DeviceConfiguration' -f ($env:ProgramW6432)) -File | Where-Object {$_.Name -like ('Device_Install-RecordingDeviceVolumeMax-64bit*')} | Sort-Object -Property 'LastWriteTime' | Select-Object -Last 1 -ExpandProperty 'FullName') -Raw)

    # Device_Install-IronSync
    ~(Get-Content -Path (Get-ChildItem -Path ('{0}\IronstoneIT\Intune\DeviceConfiguration' -f ($env:ProgramW6432)) -File | Where-Object {$_.Name -like ('Device_Install-IronSync*-64bit*')} | Sort-Object -Property 'LastWriteTime' | Select-Object -Last 1 -ExpandProperty 'FullName') -Raw)

    # Device_Install-IronTrigger
    ~(Get-Content -Path (Get-ChildItem -Path ('{0}\IronstoneIT\Intune\DeviceConfiguration' -f ($env:ProgramW6432)) -File | Where-Object {$_.Name -like ('Device_Install-IronTrigger*-64bit*')} | Sort-Object -Property 'LastWriteTime' | Select-Object -Last 1 -ExpandProperty 'FullName') -Raw)
    
    # Enable-BitLocker.log
    ~(Get-Content -Path ('{0}\IronstoneIT\Intune\DeviceConfiguration\IronTrigger - EnableBitLocker.log' -f ($env:ProgramW6432)) -Raw)

    # Device_Configure-OneDriveForBusiness
    ~(Get-Content -Path (Get-ChildItem -Path ('{0}\IronstoneIT\Intune\DeviceConfiguration' -f ($env:ProgramW6432)) -File | Where-Object {$_.Name -like ('Device_Configure-OneDriveForBusiness-64bit*')} | Sort-Object -Property 'LastWriteTime' | Select-Object -Last 1 -ExpandProperty 'FullName') -Raw)

    # Device_Device_Add-IETrustedSites*
    ~(Get-Content -Path (Get-ChildItem -Path ('{0}\IronstoneIT\Intune\DeviceConfiguration' -f ($env:ProgramW6432)) -File | Where-Object {$_.Name -like ('Device_Add-IETrustedSites*-64bit*')} | Sort-Object -Property 'LastWriteTime' | Select-Object -Last 1 -ExpandProperty 'FullName') -Raw)

    # Set-CountryTime&Settings
    ~(Get-Content -Path (Get-ChildItem -Path ('{0}\IronstoneIT\Intune\DeviceConfiguration' -f ($env:ProgramW6432)) -File | Where-Object {$_.Name -like ('Device_Set-CountryTime&Settings-64bit*')} | Sort-Object -Property 'LastWriteTime' | Select-Object -Last 1 -ExpandProperty 'FullName') -Raw)

    # Device_Set-GoogleChromeEnterpriseStartupUrls(Customer)
    ~(Get-Content -Path (Get-ChildItem -Path ('{0}\IronstoneIT\Intune\DeviceConfiguration' -f ($env:ProgramW6432)) -File | Where-Object {$_.Name -like ('Device_Set-GoogleChromeEnterpriseStartupUrls*-64bit*')} | Sort-Object -Property 'LastWriteTime' | Select-Object -Last 1 -ExpandProperty 'FullName') -Raw)

    # Mozilla_Firefox_x64-Install*.txt
    Get-Content -Path (Get-ChildItem -Path ('{0}\IronstoneIT\Intune\ClientApps\Install' -f ($env:ProgramData)) -File | Where-Object -FilterScript {$_.'Name' -like 'Mozilla_Firefox_x64-Install*.txt'}  | Sort-Object -Property 'LastWriteTime' | Select-Object -Last 1 -ExpandProperty 'FullName') -Raw
#endregion Device Context / Program Files



#region    User Context / AppData    
    # List all User logs by date
    Get-ChildItem -Path ('{0}\Users\{1}\AppData\Roaming\IronstoneIT\Intune\DeviceConfiguration' -f ($env:SystemDrive,@(Get-Process -Name 'explorer' -IncludeUserName)[0].'UserName'.Split('\')[-1])) -File | Sort-Object 'LastWriteTime'

    # User_Add-IETrustedSites_Microsoft
    Get-Content -Path (Get-ChildItem -Path ('{0}\Users\{1}\AppData\Roaming\IronstoneIT\Intune\DeviceConfiguration' -f ($env:SystemDrive,@(Get-Process -Name 'explorer' -IncludeUserName)[0].'UserName'.Split('\')[-1])) -File | Where-Object -FilterScript {$_.'Name' -like ('User_Add-IETrustedSites_Microsoft-64bit*')} | Sort-Object -Property 'LastWriteTime' | Select-Object -Last 1 -ExpandProperty 'FullName') -Raw

    # User_Uninstall-Bloatware
    Get-Content -Path (Get-ChildItem -Path ('{0}\Users\{1}\AppData\Roaming\IronstoneIT\Intune\DeviceConfiguration' -f ($env:SystemDrive,@(Get-Process -Name 'explorer' -IncludeUserName)[0].'UserName'.Split('\')[-1])) -File | Where-Object -FilterScript {$_.'Name' -like ('User_Uninstall-Bloatware-64bit*')} | Sort-Object -Property 'LastWriteTime' | Select-Object -Last 1 -ExpandProperty 'FullName') -Raw

    # User_Add-ShortcutToDesktop&StartMenu_URL
    Get-Content -Path (Get-ChildItem -Path ('{0}\Users\{1}\AppData\Roaming\IronstoneIT\Intune\DeviceConfiguration' -f ($env:SystemDrive,@(Get-Process -Name 'explorer' -IncludeUserName)[0].'UserName'.Split('\')[-1])) -File | Where-Object -FilterScript {$_.'Name' -like ('User_Add-ShortcutToDesktop&StartMenu_URL*64bit*')} | Sort-Object -Property 'LastWriteTime' | Select-Object -Last 1 -ExpandProperty 'FullName') -Raw

    # User_*shortcut*64bit* newest
    Get-Content -Path (Get-ChildItem -Path ('{0}\Users\{1}\AppData\Roaming\IronstoneIT\Intune\DeviceConfiguration' -f ($env:SystemDrive,@(Get-Process -Name 'explorer' -IncludeUserName)[0].'UserName'.Split('\')[-1])) -File | Where-Object -FilterScript {$_.'Name' -like ('User_*Shortcut*64bit*')} | Sort-Object -Property 'LastWriteTime' | Select-Object -Last 1 -ExpandProperty 'FullName') -Raw

    # User_Disable-KeyboardLayoutSwitchShortcut
    Get-Content -Path (Get-ChildItem -Path ('{0}\Users\{1}\AppData\Roaming\IronstoneIT\Intune\DeviceConfiguration' -f ($env:SystemDrive,@(Get-Process -Name 'explorer' -IncludeUserName)[0].'UserName'.Split('\')[-1])) -File | Where-Object -FilterScript {$_.'Name' -like ('User_Disable-KeyboardLayoutSwitchShortcut-64bit*')} | Sort-Object -Property 'LastWriteTime' | Select-Object -Last 1 -ExpandProperty 'FullName') -Raw    
#endregion User Context / AppData