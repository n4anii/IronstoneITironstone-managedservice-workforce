Get-WmiObject -Class 'Lenovo_BiosSetting' -Namespace 'root\wmi'



# Get Current Lenovo BIOS Settings - Output
Get-WmiObject -class 'Lenovo_BiosSetting' -namespace 'root\wmi' | ForEach-Object {
    if (-not([string]::IsNullOrEmpty($_.'CurrentSetting'))) {
        $_.'CurrentSetting'.Replace(',',' = ')
    }
} | Sort-Object



# Get Current Lenovo BIOS Settings - PowerShellObject Array
$LenovoBIOSSettingsCurrent = [PSCustomObject[]]$(
    $TempStringArrayAll = [string[]]$(
        Get-WmiObject -class 'Lenovo_BiosSetting' -namespace 'root\wmi' | ForEach-Object {
            if (-not([string]::IsNullOrEmpty($_.'CurrentSetting'))) {
                $_.'CurrentSetting'
            }
        } | Sort-Object
    )
    $TempStringArrayAll | ForEach-Object {
        $TempStringArrayCurrent = [string[]]$($_.Split(',').Trim())
        [PSCustomObject]@{'Setting'=$TempStringArrayCurrent[0];'Value'=$TempStringArrayCurrent[1]}
    }
)



# Get Current Lenovo BIOS Settings - Hashtable
$LenovoBIOSSettingsCurrentHashtable = [hashtable]@{}
$TempStringArrayAll = [string[]]$(
    Get-WmiObject -class 'Lenovo_BiosSetting' -namespace 'root\wmi' | ForEach-Object {
        if (-not([string]::IsNullOrEmpty($_.'CurrentSetting'))) {
            $_.'CurrentSetting'
        }
    } | Sort-Object
)
foreach ($String in $TempStringArrayAll) {
    $TempStringArrayCurrent = [string[]]$($String.Split(',').Trim())
    $LenovoBIOSSettingsCurrentHashtable.Add($TempStringArrayCurrent[0],$TempStringArrayCurrent[1])
}





# Change a setting
(Get-WmiObject -Class 'Lenovo_SetBiosSetting' -Namespace 'root\wmi' -ErrorAction 'Stop').SetBiosSetting('WakeOnLAN,Disable')
(Get-WmiObject -Class 'Lenovo_SaveBiosSettings' -Namespace 'root\wmi' -ErrorAction 'Stop').SaveBiosSettings()
    