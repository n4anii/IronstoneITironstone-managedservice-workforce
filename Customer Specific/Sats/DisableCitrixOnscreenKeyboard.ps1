#Disable on screen keyboard in Citrix

if ((Test-Path -LiteralPath "HKLM:\SOFTWARE\Wow6432Node\Citrix\ICA Client\Engine\Configuration\Advanced\Modules\MobileReceiver") -ne $true) { 
    New-Item "HKLM:\SOFTWARE\Wow6432Node\Citrix\ICA Client\Engine\Configuration\Advanced\Modules\MobileReceiver" -force -ea SilentlyContinue 
}
New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Wow6432Node\Citrix\ICA Client\Engine\Configuration\Advanced\Modules\MobileReceiver' -Name 'DisableKeyboardPopup' -Value '1' -PropertyType DWord -Force -ea SilentlyContinue
New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Wow6432Node\Citrix\ICA Client\Engine\Configuration\Advanced\Modules\MobileReceiver' -Name 'AlwaysKeyboardPopup' -Value '0' -PropertyType DWord -Force -ea SilentlyContinue