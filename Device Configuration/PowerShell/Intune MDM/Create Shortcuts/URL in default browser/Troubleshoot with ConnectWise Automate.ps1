# Ironstone logfolder in %appdata% for Currently Logged In User
## Local (New)
('{0}\Users\{1}\AppData\Local\IronstoneIT\Intune\DeviceConfiguration' -f ($env:SystemDrive,(([array](Get-Process -Name 'explorer' -IncludeUserName))[0].'UserName'.Split('\')[-1])))
## Roaming (Old)
('{0}\Users\{1}\AppData\Roaming\IronstoneIT\Intune\DeviceConfiguration' -f ($env:SystemDrive,(([array](Get-Process -Name 'explorer' -IncludeUserName))[0].'UserName'.Split('\')[-1])))




# Logs
## Add Shortcut
### Running as user
Get-Content -Path (Get-ChildItem -Path ('{0}\IronstoneIT\Intune\DeviceConfiguration' -f ($env:LOCALAPPDATA)) | Where-Object -FilterScript {$_.'Name' -like ('User_Add-Shortcut*64bit*')} | Sort-Object -Property 'LastWriteTime' | Select-Object -Last 1 -ExpandProperty 'FullName') -Raw
### Running as SYSTEM
Get-Content -Path (Get-ChildItem -Path ('{0}\Users\{1}\AppData\Local\IronstoneIT\Intune\DeviceConfiguration' -f ($env:SystemDrive,(([array](Get-Process -Name 'explorer' -IncludeUserName))[0].'UserName'.Split('\')[-1]))) | Where-Object -FilterScript {$_.'Name' -like ('User_Add-Shortcut*64bit*')} | Sort-Object -Property 'LastWriteTime' | Select-Object -Last 1 -ExpandProperty 'FullName') -Raw

## Remove Shortcut
### Running as user
Get-Content -Path (Get-ChildItem -Path ('{0}\IronstoneIT\Intune\DeviceConfiguration' -f ($env:LOCALAPPDATA)) | Where-Object -FilterScript {$_.'Name' -like ('User_Remove-Shortcut*64bit*')} | Sort-Object -Property 'LastWriteTime' | Select-Object -Last 1 -ExpandProperty 'FullName') -Raw
### Running as system
Get-Content -Path (Get-ChildItem -Path ('{0}\Users\{1}\AppData\Local\IronstoneIT\Intune\DeviceConfiguration' -f ($env:SystemDrive,(([array](Get-Process -Name 'explorer' -IncludeUserName))[0].'UserName'.Split('\')[-1]))) | Where-Object -FilterScript {$_.'Name' -like ('User_Remove-Shortcut*64bit*')} | Sort-Object -Property 'LastWriteTime' | Select-Object -Last 1 -ExpandProperty 'FullName') -Raw



# Remove Shortcut
## from "NT Authority\System"
Get-Content -Path (Get-ChildItem -Path ('{0}\Users\{1}\AppData\Local\IronstoneIT\Intune\DeviceConfiguration' -f ($env:SystemDrive,((Get-Process -Name 'explorer' -IncludeUserName)[0].'UserName'.Split('\')[-1]))) | Where-Object -FilterScript {$_.'Name' -like ('User_Remove-ShortcutFromDesktop*64bit*')} | Sort-Object -Property 'LastWriteTime' | Select-Object -Last 1 -ExpandProperty 'FullName') -Raw
