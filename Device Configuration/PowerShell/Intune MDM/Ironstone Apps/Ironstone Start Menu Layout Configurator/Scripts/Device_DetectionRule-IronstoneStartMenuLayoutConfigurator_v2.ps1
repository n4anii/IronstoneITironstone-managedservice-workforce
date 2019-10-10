# Check if the "LayoutModification.xml" file exist
$StartMenuLayoutExists = [bool]$([uint32]$(Get-Item -Path ('{0}\Users\Default\AppData\Local\Microsoft\Windows\Shell\LayoutModification.xml' -f ($env:SystemDrive)) -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'Length') -eq [uint32]$(1361))

# Return Success
if ($StartMenuLayoutExists) {
    Write-Output -InputObject 'Success.'
    Exit 0
}
else {
    Exit 1
}