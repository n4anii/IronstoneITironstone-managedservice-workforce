# Ironstone logfolder in %appdata% for Currently Logged In User
('{0}\Users\{1}\AppData\Roaming\IronstoneIT\Intune\DeviceConfiguration' -f ($env:SystemDrive,((Get-Process -Name 'explorer' -IncludeUserName).UserName.Split('\')[-1])))



# Add Shortcut
~Get-Content -Path (Get-ChildItem -Path ('{0}\IronstoneIT\Intune\DeviceConfiguration' -f ($env:APPDATA)) | Where-Object {$_.Name -like ('User_Add-ShortcutFromDesktop*64bit*')} | Sort-Object -Property 'LastWriteTime' | Select-Object -Last 1 -ExpandProperty 'FullName') -Raw


# Remove Shortcut
~Get-Content -Path (Get-ChildItem -Path ('{0}\IronstoneIT\Intune\DeviceConfiguration' -f ($env:APPDATA)) | Where-Object {$_.Name -like ('User_Remove-ShortcutFromDesktop*64bit*')} | Sort-Object -Property 'LastWriteTime' | Select-Object -Last 1 -ExpandProperty 'FullName') -Raw


# Remove Shortcut from "NT Authority\System"
~Get-Content -Path (Get-ChildItem -Path ('{0}\Users\{1}\AppData\Roaming\IronstoneIT\Intune\DeviceConfiguration' -f ($env:SystemDrive,((Get-Process -Name 'explorer' -IncludeUserName).UserName.Split('\')[-1]))) | Where-Object {$_.Name -like ('User_Remove-ShortcutFromDesktop*64bit*')} | Sort-Object -Property 'LastWriteTime' | Select-Object -Last 1 -ExpandProperty 'FullName') -Raw
