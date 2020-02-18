# OS Disk total size
## Get Disk
[uint16]$([uint64]$([uint64]$(Try{$SizeRaw=[uint64]$(Get-Disk | Where-Object -Property 'IsSystem' | Select-Object -ExpandProperty 'Size');if($? -and $SizeRaw -gt 0){$SizeRaw}else{0}}Catch{0})) / 1GB)
## WMI
[uint16]$([uint64]$(Try{$SizeRaw=[uint64]$($(Get-WmiObject -Class 'Win32_logicaldisk' -Filter ('DeviceID = "{0}"' -f ($env:SystemDrive)) -ErrorAction 'SilentlyContinue').GetRelated('Win32_DiskPartition').GetRelated('Win32_DiskDrive') | Select-Object -ExpandProperty 'Size');if($? -and $SizeRaw -gt 0){$SizeRaw}else{0}}Catch{0}) / 1GB)
## Both
[uint16]$($Size=[uint16]$([uint64]$(Try{$SizeRaw=[uint64]$($(Get-WmiObject -Class 'Win32_logicaldisk' -Filter ('DeviceID = "{0}"' -f ($env:SystemDrive)) -ErrorAction 'SilentlyContinue').GetRelated('Win32_DiskPartition').GetRelated('Win32_DiskDrive') | Select-Object -ExpandProperty 'Size');if($? -and $SizeRaw -gt 0){$SizeRaw}else{0}}Catch{0}) / 1GB);if($? -and $Size -gt 0){$Size}else{[uint16]$([uint64]$([uint64]$(Try{$SizeRaw=[uint64]$(Get-Disk | Where-Object -Property 'IsSystem' | Select-Object -ExpandProperty 'Size');if($? -and $SizeRaw -gt 0){$SizeRaw}else{0}}Catch{0})) / 1GB)})


# OS Partition size
[uint64]$(Get-WmiObject -Class 'Win32_logicaldisk' -Filter ('DeviceID = "{0}"' -f ($env:SystemDrive)) | Select-Object -ExpandProperty 'Size') / 1GB


$Disk = Get-WmiObject -Class 'Win32_logicaldisk' -Filter ('DeviceID = "{0}"' -f ($env:SystemDrive))
$Disk.GetRelated()
$(Get-WmiObject -Class 'Win32_logicaldisk' -Filter ('DeviceID = "{0}"' -f ($env:SystemDrive))).GetRelated('Win32_DiskPartition').GetRelated('Win32_DiskDrive') | Select-Object -ExpandProperty 'Size'