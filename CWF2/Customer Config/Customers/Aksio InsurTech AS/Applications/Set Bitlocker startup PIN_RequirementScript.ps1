$bitlockerVolume = Get-BitLockerVolume -MountPoint "C:"
$statusBitlocker = $bitlockerVolume.ProtectionStatus
$VolumeStatus = $bitlockerVolume.VolumeStatus
if ($statusBitlocker -eq "On" -And $VolumeStatus -eq "FullyEncrypted"){
#Write-host “Bitlocker active and 100% encrypted”
Write-Output 1
Exit 0
}