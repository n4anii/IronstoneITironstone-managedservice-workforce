# Check if any Intune user accounts has been created on the device
$UserAccountIsCreated  = [bool]$([byte]$([array]$(Get-ChildItem -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' -Depth 0 | Select-Object -ExpandProperty 'Name' | Where-Object -FilterScript {$_ -like '*\S-1-12-*'}).'Count') -gt 0)

# Check if the "LayoutModification.xml" file exist
$StartMenuLayoutExists = [bool]$([uint32]$(Get-Item -Path ('{0}\Users\Default\AppData\Local\Microsoft\Windows\Shell\LayoutModification.xml' -f ($env:SystemDrive)) -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'Length') -eq [uint32]$(1361))

# Return Success
if ($UserAccountIsCreated -and $StartMenuLayoutExists) {
    Write-Output -InputObject 'Success.'
    Exit 0
}
elseif ($UserAccountIsCreated -and -not $StartMenuLayoutExists) {
    Write-Output -InputObject 'Too late.'
    Exit 0
}
else {
    Exit 1
}