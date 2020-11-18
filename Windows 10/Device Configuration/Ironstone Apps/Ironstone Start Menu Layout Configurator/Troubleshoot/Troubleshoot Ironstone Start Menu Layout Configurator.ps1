# Get all files
Get-ChildItem -Path ('{0}\Users\Default\AppData\Local\Microsoft\Windows\Shell' -f ($env:SystemDrive)) -Depth 0 -Force

# Get content of "DefaultLayouts.xml"
Get-Content -Path ('{0}\Users\Default\AppData\Local\Microsoft\Windows\Shell\DefaultLayouts.xml' -f ($env:SystemDrive)) -Raw

# Get content of "LayoutModification.xml"
Get-Content -Path ('{0}\Users\Default\AppData\Local\Microsoft\Windows\Shell\LayoutModification.xml' -f ($env:SystemDrive)) -Raw

# Get all file properties of "LayoutModification.xml"
Get-Item -Path ('{0}\Users\Default\AppData\Local\Microsoft\Windows\Shell\LayoutModification.xml' -f ($env:SystemDrive)) | Select-Object -Property '*'

# Get file size of "LayoutModification.xml"
Get-Item -Path ('{0}\Users\Default\AppData\Local\Microsoft\Windows\Shell\LayoutModification.xml' -f ($env:SystemDrive)) | Select-Object -ExpandProperty 'Length'

# Check if file size of "LayoutModification.xml" matches Ironstone version
[bool]$([uint32]$(Get-Item -Path ('{0}\Users\Default\AppData\Local\Microsoft\Windows\Shell\LayoutModification.xml' -f ($env:SystemDrive)) -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'Length') -eq [uint32]$(1361))