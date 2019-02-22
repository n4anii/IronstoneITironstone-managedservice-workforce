#Requires -RunAsAdministrator

<#

.DESCRIPTION
    PROBLEM
        Over de siste månedene har flere brukere oppdaget at Windows av ukjent grunn skrur ned level på recording devices til ca 30%. 
        Følgen av dette blir at selv om man skur opp microphone level på max i Skype, er ikke dette nok til at andre møtedeltakere hører godt i andre enden. 
        Finnes det noen mulighet til å pushe et recording level på 100% via policies e.l?

    ULTIMAT GOAL
        * Disables "Allow applications to take exclusive control of this device" for recording device(s)
            * Win+S -> "Sound" -> Recording -> <Microphone_In_Use> -> Advanced -> [ ] Allow applications to take exclusive control of this device.
        * Sets default volume to 100% for recording devices

    RESEARCH
        Windows 10 built in settings
            App volume and device preferences
                * Win+S -> "Sound Mixer Options"
                * Right click sound icon in system tray -> Sound Settings -> Other Sound Options -> App volume and device preferences

            Volume Mixer
                * Win+S -> "Adjust System Volume"
                * Right click sound icon in system tray -> Volume Mixer

        NirSoft "nircmd"
            http://www.nirsoft.net/utils/nircmd.html
            * Set System Volume                     	             nircmd.exe setsysvolume 0-65535
            * Change System Volume                                   nircmd.exe setsysvolume +/- 0-65535
            * Mute System Volume                                     nircmd.exe mutesysvolume 1
            * Unmute System Volume                                   nircmd.exe mutesysvolume 0
            * Switch between mute                                    nircmd.exe mutesysvolume 2
            * Create desktop shortcut for sysvolume mute toggle      nircmd.exe cmdshortcut "~$folder.desktop$" "Switch Volume" mutesysvolume 2

        AudioDeviceCmdlets
            * PowerShellGallery                                      https://www.powershellgallery.com/packages/AudioDeviceCmdlets
            * GitHub                                                 https://github.com/frgnca/AudioDeviceCmdlets
            * Install module                                         Install-Module -Name 'AudioDeviceCmdlets' -Scope 'AllUsers' -Force
            * Unblock-File                                           Get-ChildItem ('{0}\WindowsPowerShell\Modules\AudioDeviceCmdlets\' -f ($env:ProgramFiles)) -File -Recurse | Select-Object -ExpandProperty FullName | ForEach-Object {Unblock-File -Path $_}
            * Import-Module                                          Import-Module -Name 'AudioDeviceCmdlets'
            * Import-Module Manuelt                                  Get-ChildItem ('{0}\WindowsPowerShell\Modules\AudioDeviceCmdlets\' -f ($env:ProgramFiles)) -File -Recurse | Select-Object -ExpandProperty FullName | ForEach-Object {Import-Module -Name $_ -Verbose}





.RESOURCES

#>


#region    Device Management
    # Get all PnpDevices in Class=Media
    Get-PnpDevice | Where-Object {$_.Class -eq 'Media'} | Sort-Object -Property FriendlyName | Format-Table -AutoSize

    # Get actual devices
    $AllDevices = Get-PnpDevice | Where-Object {
        $_.Class -eq 'Media' -and $_.FriendlyName -notlike 'Microsoft Streaming*' -and $_.FriendlyName -notlike 'Microsoft Trusted*' -and $_.FriendlyName -notlike '*Display Audio'
    } | Sort-Object -Property FriendlyName

    # View all
    $AllDevices | Format-Table -AutoSize

    # View one
    $AllDevices[0] | Select-Object -ExpandProperty CimInstanceProperties 
#endregion Device Management



#region    AudioDeviceCmdlets
    # Import Module Manually
    Get-ChildItem ('{0}\WindowsPowerShell\Modules\AudioDeviceCmdlets\' -f ($env:ProgramFiles)) -File -Recurse | Select-Object -ExpandProperty FullName | ForEach-Object {Import-Module -Name $_ -Verbose}

    # Get Recording Devices
    $RecordingDevices = @(Get-AudioDevice -List | Where-Object {$_.Type -eq 'Recording'})

    # Set Default Recording Device
    Set-AudioDevice $RecordingDevices[0].ID

    # Set Volume for Default Recording Device
    Set-AudioDevice -RecordingVolume 60

    # RecordingDeviceLooper
    #    Get Default Recording Device (To reset to this afterwards)
    #    Loop every Recording Device
    #    Set each recording volume to 100% by first setting device as default, then set volume
    #    Restore default recording device afterwards
    Get-ChildItem ('{0}\WindowsPowerShell\Modules\AudioDeviceCmdlets\' -f ($env:ProgramFiles)) -File -Recurse | Select-Object -ExpandProperty FullName | ForEach-Object {Import-Module -Name $_}
    [string]   $RecordingDeviceDefault = Get-AudioDevice -Recording | Select-Object -ExpandProperty ID
    [string[]] $RecordingDeviceAll     = @($RecordingDevices = @(Get-AudioDevice -List | Where-Object {$_.Type -eq 'Recording'}) | Select-Object -ExpandProperty ID)
    foreach ($Device in $RecordingDeviceAll) {
        $null = Set-AudioDevice $Device
        $null = Set-AudioDevice -RecordingVolume 100
    }
    $null = Set-AudioDevice $RecordingDeviceDefault

#endregion AudioDeviceCmdlets


#region    Registry


    # Paths
    [string] $PathDirRecordingDevices = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Capture\'
    [string] $PathDirRenderDevices    = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render\'

    # States
    [string] $DeviceState_Connected_Enabled         = '1'
    [string] $DeviceState_Connected_Enabled_Default = '4'
    [string] $DeviceState_Connected_Disabled        = '268435457'
    [string] $DeviceState_Disconnected              = '536870916'

    # Default / Not default
    [string] $Level_DefaultDevice                   = 5
    [string] $Name_Value_DefaultDevice              = 'Level:1'
    [string] $Name_Value_DefaultComDevice           = 'Level:2'

    # Device Names
    [string] $NameInternalMic = '{06b1f67f-61e5-43a0-8d7d-57013ef08510}'
    [string] $NameJabra370    = '{a858d673-3799-4ee2-801e-3859a04d764a}'

    # Get Audio Recording Devices
    Get-ChildItem -Path $PathDirRecordingDevices | Format-Table -AutoSize


    # Get ChildItemName and Property
    Get-ChildItem -Path $PathDirRecordingDevices | Select-Object -Property PSChildName,Property | Format-Table -AutoSize
    Get-ChildItem -Path $PathDirRecordingDevices | Where-Object {$_.PSChildName -like $NameInternalMic} | Format-Table -AutoSize
    Get-ChildItem -Path $PathDirRecordingDevices | Where-Object {$_.PSChildName -like $NameInternalMic -or $_.PSChildName -like $NameJabra370} | Format-Table -AutoSize



    # Get recording devices that aren't disabled or disconnected
    [string[]] $RecordingDevicesActive   = @()
    [string[]] $RecordingDevicesInactive = @()

    Get-ChildItem -Path $PathDirRecordingDevices | ForEach-Object {
        [string] $DeviceState = Get-ItemProperty -Path ('{0}\{1}' -f ($PathDirRecordingDevices,$_.PSChildName)) -Name 'DeviceState' | Select-Object -ExpandProperty 'DeviceState'
        Write-Verbose -Message ('{0} - DeviceState: {1}' -f ($_.PSChildName,$DeviceState))
    
        # Disconnected or Disabled devices
        if (@('268435457','536870916').Contains($DeviceState)) {
            $RecordingDevicesInactive += @($_.PSChildName)        
        }
    
        # Other devices
        else {
            $RecordingDevicesActive   += @($_.PSChildName)
        }
    }
#endregion Registry
