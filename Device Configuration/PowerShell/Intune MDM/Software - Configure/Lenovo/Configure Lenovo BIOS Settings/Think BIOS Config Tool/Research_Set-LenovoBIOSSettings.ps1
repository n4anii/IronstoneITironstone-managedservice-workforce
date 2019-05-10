#Requires -RunAsAdministrator


# Only continue if this computer is manufactured by Lenovo
$Manufacturer = [string]$(Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\HARDWARE\DESCRIPTION\System\BIOS' -Name 'SystemManufacturer' | Select-Object -ExpandProperty 'SystemManufacturer')
if ($Manufacturer -ne 'Lenovo') {
    Throw ('ERROR: This will only work on Lenovo, while this is manufactured by "{0}".' -f ($Manufacturer))
    Exit 1
}


# Assets - Help Variables
$WriteChanges    = [bool]$($false)
$AnythingChanged = [bool]$($false)
    

# Assets - Wanted Settings
$LenovoBIOSSettings = [string[]]$(
    'AdaptiveThermalManagementAC,MaximizePerformance',
    'AdaptiveThermalManagementBattery,Balanced',
    'BIOSUpdateByEndUsers,Enable',
    'BluetoothAccess,Enable',
    'BootMode,Quick',
    'CPUPowerManagement,Automatic',
    'DataExecutionPrevention,Enable',
    'EthernetLANAccess,Enable',
    'EthernetLANOptionROM,Enable',
    'FingerprintPasswordAuthentication,Enable',
    'FingerprintPredesktopAuthentication,Enable',
    'FingerprintReaderAccess,Enable',
    'FingerprintReaderPriority,External',
    'FingerprintSecurityMode,Normal',
    'IntegratedCameraAccess,Enable',
    'PhysicalPresenceForTpmClear,Enable',
    'SecureBoot,Enable',
    'SecureRollBackPrevention,Enable',
    'SecurityChip,Enable',
    'ThunderboltAccess,Enable',
    'ThunderboltSecurityLevel,UserAuthorization',
    'USBBIOSSupport,Enable',
    'USBPortAccess,Enable',
    'WakeOnLAN,Disable',
    'WakeOnLANDock,Disable',
    'WiGig,Enable',
    'WiGigWake,Disable'
)



# Get Current Lenovo BIOS Settings - Hashtable
$LenovoBIOSSettingsCurrentHashtable = [hashtable]@{}
$TempStringArrayAll = [string[]]$(
    Get-WmiObject -Class 'Lenovo_BiosSetting' -Namespace 'root\wmi' | ForEach-Object {
        if (-not([string]::IsNullOrEmpty($_.'CurrentSetting'))) {
            $_.'CurrentSetting'
        }
    } | Sort-Object
)
foreach ($String in $TempStringArrayAll) {
    $TempStringArrayCurrent = [string[]]$($String.Split(',').Trim())
    $LenovoBIOSSettingsCurrentHashtable.Add($TempStringArrayCurrent[0],$TempStringArrayCurrent[1])
}



# Get the Lenovo BIOS Settings WMI Object
$LenovoSetBIOSSettingsWMIObject = Get-WmiObject -Class 'Lenovo_SetBiosSetting' -Namespace 'root\wmi' -ErrorAction 'Stop'



# Set all settings in $LenovoBIOSSettings using Lenovo BIOS Settings WMI Object
:ForEachSetting foreach ($Setting in $LenovoBIOSSettings) {
    Write-Output -InputObject $Setting
    $SettingName  = [string]$($Setting.Split(',')[0])
    $SettingValue = [string]$($Setting.Split(',')[-1])

    # Only proceed if setting name exists in BIOS on this machine
    if ([byte]$([PSCustomObject[]]$($LenovoBIOSSettingsCurrentHashtable.GetEnumerator() | Where-Object -Property 'Name' -eq $SettingName).'Count') -ne 1) {
        Write-Output -InputObject ('{0}Setting is not available in BIOS on this device. Skipping.' -f ("`t"))
        Continue ForEachSetting
    }
    else {  
        # Only proceed if the new value is not equal to the existing one
        if ([string]$($SettingValue) -eq [string]$($LenovoBIOSSettingsCurrentHashtable.$SettingName)) {
            Write-Output -InputObject ('{0}Setting is already correct.' -f ("`t"))
            Continue ForEachSetting
        }
        else {
            # Only proceed if $WriteChanges is set to $true
            if ($WriteChanges) {
                $SetSetting = $LenovoSetBIOSSettingsWMIObject.SetBiosSetting($Setting)
                if ((-not($?)) -or $SetSetting.'return' -ne 'Success') {
                    Write-Error -Message ('ERROR: Failed to set Lenovo BIOS Setting "{0}".' -f ($Setting)) -ErrorAction 'Stop'
                    Break ForEachSetting
                }
                $AnythingChanged = $true
                Write-Output -InputObject ('{0}Setting changed.' -f ("`t"))
            }
            else {
                Write-Output -InputObject ('{0}$WriteChanges is $false, not writing changes.' -f ("`t"))
            }
        }
    }
}



# Save changed settings
if ($AnythingChanged) {
    Write-Output -InputObject ('BIOS settings changed, saving changes.')
    if ($WriteChanges) {
        $SaveSettings = (Get-WmiObject -Class 'Lenovo_SaveBiosSettings' -Namespace 'root\wmi' -ErrorAction 'Stop').SaveBiosSettings()
        if ((-not($?)) -or $SaveSettings.'return' -ne 'Success') {
            Write-Error -Message ('ERROR: Failed to save Lenovo BIOS Settings.')
        }
    }
    else {
        Write-Output -InputObject ('{0}$WriteChanges is $false, not writing changes.' -f ("`t"))
    }
}
else {
    Write-Output -InputObject ('No BIOS settings changed, no need to save anything.')
}