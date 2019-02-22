#Requires -RunAsAdministrator
[string]$($BLV = Get-BitLockerVolume -MountPoint $env:SystemDrive -ErrorAction 'SilentlyContinue';if((-not($?)) -or [string]::IsNullOrEmpty($BLV.ProtectionStatus)){'Error'}elseif($BLV.VolumeStatus -ne 'FullyEncrypted'){'FullyDecrypted'}elseif($BLV.VolumeStatus -eq 'FullyEncrypted' -and (-not([string]::IsNullOrEmpty($BLV.EncryptionMethod)))){$BLV.EncryptionMethod}else{'Error'})

[string]$($BLV = Get-BitLockerVolume -MountPoint $env:SystemDrive -ErrorAction 'SilentlyContinue';$BLV.VolumeStatus)




<#
    Searches
        Computer.IS.IsServer                                                      = $false
        Computer.IS.Type                                                          = Windows
        Computer.Network.Domain                                                   = WORKGROUP
        Computer.Extra Data Field.Ironstone.BitLockerEncryptionMethodSystemVolume = ''
#>

# Software Encryption          ExtraDataField | BitLockerEncryptionMethodSystemVolume Software Encrypted (-contains "Xtr")
$EncryptionMethod -contains 'Xts'

# Error                        ExtraDataField | BitLockerEncryptionMethodSystemVolume Error (-eq "Error")
$EncryptionMethod -eq 'Error'

# Not run yet                  ExtraDataField | BitLockerEncryptionMethodSystemVolume Empty (-eq '')
$EncryptionMethod -like ''

# Not Encrypted                ExtraDataField | BitLockerEncryptionMethodSystemVolume Decrypted (-eq "FullyDecrypted")
$EncryptionMethod -eq 'Not Encrypted'

# Hardware encryption          ExtraDataField | BitLockerEncryptionMethodSystemVolume Hardware Encryption (none of the others)
$EncryptionMethod -notlike 'Xts' -and $EncryptionMethod -ne 'Error' -and $EncryptionMethod -eq 'Not Encrypted' -and (-not([string]::IsNullOrEmpty($EncryptionMethod)))

# Not BitLocker Compliant      ExtraDataField | BitLockerEncryptionMethodSystemVolume BitLocker not Compliant (-ne '' -and -notcontains 'Xts')
$EncryptionMethod -notcontains 'Xts' -and $EncryptionMethod -ne ''




<# 
    Groups
#>
