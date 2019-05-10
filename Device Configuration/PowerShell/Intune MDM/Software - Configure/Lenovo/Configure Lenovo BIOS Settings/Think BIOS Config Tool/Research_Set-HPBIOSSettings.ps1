#Requires -Version 5.1 -RunAsAdministrator
<#

    .NOTES
        Resources
            * List and change BIOS settings with PowerShell
            http://www.systanddeploy.com/2019/03/list-and-change-bios-settings-with.html
#>


# Show Current BIOS Settings
Get-WmiObject -ComputerName $env:COMPUTERNAME -Class 'HP_BIOSSetting' -Namespace 'root\hp\instrumentedBIOS' -ErrorAction 'Stop' | `    
    Where-Object {-not([string]::IsNullOrEmpty($_.'Name'.Trim()))} | Sort-Object -Property 'Name' | `
    Format-Table -AutoSize -Property 'Name','IsReadOnly','CurrentValue'


# Store current BIOS Settings - PSCustomObject Array
$HPBIOSSettings = [PSCustomObject[]]$(Get-WmiObject -ComputerName $env:COMPUTERNAME -Class 'HP_BIOSSetting' -Namespace 'root\hp\instrumentedBIOS' -ErrorAction 'Stop' | `    
    Where-Object {-not([string]::IsNullOrEmpty($_.'Name'.Trim()))} | Select-Object -Property 'Name','IsReadOnly','Value' | `
    Sort-Object -Property 'Name')
$HPBIOSSettings | Foreach-Object -Process {$_.'PSObject'.'Properties' | Where-Object -Property 'TypeNameOfValue' -EQ 'System.String' | ForEach-Object -Process {$_.'Value' = $_.'Value'.Trim()}}

$HPBIOSSettings | Where-Object -Property 'Name' -EQ 'SecureBoot'



# Possible Values
$SettingsCurrent = Get-WmiObject -ComputerName $env:COMPUTERNAME -Class 'hp_biossetting' -Namespace 'root\hp\instrumentedbios'
$SettingNames    = [string[]]$('Fast Boot','SecureBoot','TPM Device')
foreach ($SettingName in $SettingNames) {
    Write-Output -InputObject ('"{0}" possible settings:' -f ($SettingName))
    $SettingsCurrent | Where-Object -Property 'Name' -EQ $SettingName | Select-Object -ExpandProperty 'PossibleValues' | ForEach-Object -Process {('{0}{1}' -f ("`t",$_))}
}




# Set a setting
    # Assets
    $HPBIOSSettingsWanted = [PSCustomObject[]]$(
        [PSCustomObject]@{'Name'='Fast Boot'; 'Value'='Enable'}
        [PSCustomObject]@{'Name'='SecureBoot';'Value'='Enable'},
        [PSCustomObject]@{'Name'='TPM Device';'Value'='Available'}
        # [PSCustomObject]@{'Name'='';'Value'=''}
    )

    # Get neccessary object 
    $SetBIOSSetting = Get-WmiObject -ComputerName $env:COMPUTERNAME -Class 'HP_BIOSSettingInterface' -Namespace 'root\hp\instrumentedbios'
    $IsPasswordSet  = [bool]$(Get-WmiObject -ComputerName $env:COMPUTERNAME -Class 'HP_BIOSPassword' -Namespace 'root\HP\InstrumentedBIOS' -Filter "Name = 'Setup Password'" | Select-Object -ExpandProperty 'IsSet')

    # Set wanted HP BIOS settings
    foreach ($Setting in $HPBIOSSettingsWanted) {
        $SetBIOSSettingReturnCode = [uint16]$($SetBiosSetting.SetBIOSSetting($Setting.'Name',$Setting.'Value','') | Select-Object -ExpandProperty 'Return')
        Switch ($SetBIOSSettingReturnCode) {
            0 {Write-Output -InputObject 'Success! Code: 0'}
            1 {Write-Warning -Message ('Failed: Property "{0}" not supported. Return code: {1}' -f ($Setting.'Name',$SetBIOSSettingReturnCode))}
            2 {Write-Warning -Message ('Failed: Unspecified Error. Return code: {0}' -f ($SetBIOSSettingReturnCode))}
            3 {Write-Warning -Message ('Failed: Timeout. Return code: {0}' -f ($SetBIOSSettingReturnCode))}
            4 {Write-Warning -Message ('Failed: Return code: {0}' -f ($SetBIOSSettingReturnCode))}
            5 {Write-Warning -Message ('Failed: Valid Property "{0}", invalid value "{1}". Return code: {2}' -f ($Setting.'Name',$Setting.'Value',$SetBIOSSettingReturnCode))}
            6 {Write-Warning -Message ('Failed: Access Denied. Return code: {0}' -f ($SetBIOSSettingReturnCode))}
            10 {Write-Warning -Message ('Failed: Invalid password. Return code: {0}' -f ($SetBIOSSettingReturnCode))}
            default {Write-Warning -Message ('Failed: Unknown error. Return code: {0}' -f ($SetBIOSSettingReturnCode))}
        }
    }