<#

    View Keyboard Switching Hotkeys
    Settings -> Time & Language -> Advanced keyboard settings -> Language bar options -> Text Services and Input Languages -> Advanced Key Settings

    .RESOURCE
        Turn off ALL Win+X Shortcuts
        https://www.howtogeek.com/282080/how-to-disable-the-built-in-windows-key-shortcuts/
            HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer
            NoWinKeys
            0 (DWord)

            HKCU:\Control Panel\Input Method\Hot Keys

#>

# Disables Layout and Language Hotkeys (ctrl+shift etc).       WILL NOT DISABLE WIN+SPACE
[PSCustomObject[]] $Keys = @(
    [PSCustomObject]@{Name=[string]'Hotkey';         Val=[string]'3';Type=[string]'String'},
    [PSCustomObject]@{Name=[string]'Language Hotkey';Val=[string]'3';Type=[string]'String'},
    [PSCustomObject]@{Name=[string]'Layout Hotkey';  Val=[string]'3';Type=[string]'String'}
)

foreach ($Key in $Keys) {
    $null = Set-ItemProperty -Path 'HKCU:\Keyboard Layout\Toggle' -Name $Key.Name -Value $Key.Val -Type $Key.Type -Force
    Write-Output -InputObject ('Success setting {0}? {1}.' -f ($Key.Name,$?))
}