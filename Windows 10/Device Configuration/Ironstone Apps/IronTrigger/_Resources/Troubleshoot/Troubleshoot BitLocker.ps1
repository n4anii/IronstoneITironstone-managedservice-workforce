Get-BitLockerVolume -MountPoint $env:SystemDrive | Select-Object -Property *

# Get all RecoveryPasswords os OS Volume
Get-BitLockerVolume -MountPoint $env:SystemDrive | Select-Object -ExpandProperty KeyProtector | Where-Object {$_.KeyProtectorType -eq 'RecoveryPassword'}
Remove-BitLockerKeyProtector -MountPoint $env:SystemDrive -KeyProtectorId '{71D8EF83-BE49-4DAF-B019-94E6E94DB796}'

# Disable BitLocker on OS Drive
Disable-BitLocker -MountPoint $env:SystemDrive

# Enable BitLocker on OS Drive
Enable-BitLocker -MountPoint $env:SystemDrive -TpmProtector
Add-BitLockerKeyProtector -MountPoint $env:SystemDrive -RecoveryPasswordProtector



# Fixed Drive
Get-BitLockerVolume -MountPoint D | Select-Object -Property *


Add-BitLockerKeyProtector -MountPoint D -RecoveryPasswordProtector
Enable-BitLockerAutoUnlock -MountPoint D
Enable-BitLocker -MountPoint $MountPoint -RecoveryPassword ($BitLockerVolume | Select-Object -ExpandProperty KeyProtector | Where-Object {$_.KeyProtectorType -eq 'RecoveryPassword'} | Select-Object -First 1 -ExpandProperty RecoveryPassword)

Enable-BitLocker -MountPoint D -RecoveryPasswordProtector
if (($RecoveryPasswords = @(Get-BitLockerVolume -MountPoint D | Select-Object -ExpandProperty KeyProtector | Where-Object {$_.KeyProtectorType -eq 'RecoveryPassword'})).Count -eq 2) {
    Remove-BitLockerKeyProtector -MountPoint D -KeyProtectorId $RecoveryPasswords[-1].KeyProtectorId
}
