#region    Computer Name - Registry
    # Edit this
    'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName\ComputerName'
    Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName' -Name 'ComputerName' | Select-Object -ExpandProperty 'ComputerName'


    # Don't edit this - Will be updated after reboot
    'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName\ComputerName'
    Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName' -Name 'ComputerName' | Select-Object -ExpandProperty 'ComputerName'
#endregion Computer Name - Registry





#region    Computer Name - WMI
    # Get
    Get-WmiObject -Class 'Win32_ComputerSystem' | Select-Object -ExpandProperty 'Name'

    # Set
    (Get-WmiObject -Class 'Win32_ComputerSystem').Rename('DESKTOP-H094RM2')

    # Set - Measure Success
    $RenameSuccess = [bool]$(if([byte]$((Get-WmiObject -Class 'Win32_ComputerSystem').Rename('DESKTOP-H094RM2') | Select-Object -ExpandProperty 'ReturnValue') -eq 0){$true}else{$false})
#endregion Computer Name - WMI





#region    Computer Serial - WMI
    # Get
    Get-WmiObject -Class 'Win32_ComputerSystemProduct' | Select-Object -ExpandProperty 'IdentifyingNumber'

    # Get - Automate
    ~Get-WmiObject -Class 'Win32_ComputerSystemProduct' | Select-Object -ExpandProperty 'IdentifyingNumber'
#endregion Computer Serial - WMI