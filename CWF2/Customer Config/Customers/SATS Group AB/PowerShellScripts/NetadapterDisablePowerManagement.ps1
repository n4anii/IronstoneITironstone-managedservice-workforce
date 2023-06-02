<# 
This script disables the "Allow the computer to turn off this device to save power" on the ethernet on a Kiosk
The reason is that we suspect a temporarily drop of ethernetconnection is interfering with exerp updates
 #>


$adapter = Get-NetAdapter -Name "Ethernet" | Get-NetAdapterPowerManagement
$adapter.AllowComputerToTurnOffDevice = 'Disabled'
$adapter | Set-NetAdapterPowerManagement