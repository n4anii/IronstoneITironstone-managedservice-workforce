# Architecture
$OSArchitecture  = [string]$(if([System.Environment]::Is64BitOperatingSystem){'64'}else{'32'})
$CPUArchitecture = [string]$(if([string]$(Get-WmiObject -Class 'Win32_Processor' | Select-Object -ExpandProperty 'Architecture') -eq 9){'64'}else{'32'})


# Size of OS Drive
## Easy way
$SizeOSPhysicalDiskInGbInt = [string]$([uint64]$([uint64]$([array]$(Get-Disk).Where{$_.'IsSystem'}.'Size')) / 1GB).ToSTring('0')

## Hard way
$OSPartitionPhysicalDiskObjectId = [string]$([string]$([string]$(Get-Volume -DriveLetter $env:SystemDrive -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'ObjectId') -split '"{' | Select-Object -Last 1) -split '}' | Select-Object -First 1)
$OSPhysicalDisk = Get-PhysicalDisk | Where-Object -FilterScript {$_.'BusType' -notlike '*virtual*' -and [string]$($_.'ObjectId' -split '"{')[-1].Split('}')[0] -eq $OSPartitionPhysicalDiskObjectId}
$SizeOSPhysicalDiskInGbInt = [string]$([uint64]$($OSPhysicalDisk | Select-Object -ExpandProperty 'Size') / 1GB).ToString('0')

# Windows Edition
## Dedicated Cmdlet (requires admin)
$WindowsEdition = [string]$(Get-WindowsEdition -Online | Select-Object -ExpandProperty 'Edition')
## Registry
$WindowsEdition = [string]$(Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'CompositionEditionID' | Select-Object -ExpandProperty 'CompositionEditionID')

## Output
### String array
[string]$([string[]]$($OSArchitecture,$CPUArchitecture,$SizeOSPhysicalDiskInGbInt,$WindowsEdition) -join ';')
### Hashtable to JSON
[string]$(ConvertTo-Json -InputObject ([hashtable]@{'OSArchitecture'=$OSArchitecture;'CPUArchitecture'=$CPUArchitecture;'SizeOSPhysicalDiskInGbInt'=$SizeOSPhysicalDiskInGbInt;'WindowsEdition'=$WindowsEdition}) -Depth 1 -Compress)
### AIO
[string]$(ConvertTo-Json -Depth 1 -Compress -InputObject ([hashtable]@{
    'CPUArchitecture' = [string]$(if([string]$(Get-WmiObject -Class 'Win32_Processor' | Select-Object -ExpandProperty 'Architecture') -eq 9){'64'}else{'32'})
    'OSArchitecture'  = [string]$(if([System.Environment]::Is64BitOperatingSystem){'64'}else{'32'})
    'OSDiskTotalSize' = [string]$([uint64]$([uint64]$(Try{$SizeRaw = [uint64]$(Get-Disk | Where-Object -Property 'IsSystem' | Select-Object -ExpandProperty 'Size');if($?){$SizeRaw}else{0}}Catch{0})) / 1GB).ToSTring('0')
    'WindowsEdition'  = [string]$(Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'CompositionEditionID' | Select-Object -ExpandProperty 'CompositionEditionID')    
}))