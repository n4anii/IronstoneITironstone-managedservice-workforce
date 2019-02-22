# Step by Step
$PathDirLog = ('{0}\IronstoneIT\Intune\DeviceConfiguration' -f ($env:ProgramW6432))
$NameFileLogQuery = ('Device_Install-RecordingDeviceVolumeMax-64bit*')
$PathFileLog = Get-ChildItem -Path $PathDirLog | Where-Object {$_.Name -like $NameFileLogQuery} | Sort-Object -Property 'LastWriteTime' | Select-Object -First 1 -ExpandProperty 'FullName'
Get-Content -Path $PathFileLog -Raw #| Select-Object -Property *

# Oneliner
Get-Content -Path (Get-ChildItem -Path ('{0}\IronstoneIT\Intune\DeviceConfiguration' -f ($env:ProgramW6432)) | Where-Object {$_.Name -like ('Device_Install-RecordingDeviceVolumeMax-64bit*')} | Sort-Object -Property 'LastWriteTime' | Select-Object -Last 1 -ExpandProperty 'FullName') -Raw


~Get-Content -Path (Get-ChildItem -Path ('{0}\IronstoneIT\Intune\DeviceConfiguration' -f ($env:ProgramW6432)) | Where-Object {$_.Name -like ('Device_Install-RecordingDeviceVolumeMax-64bit*')} | Sort-Object -Property 'LastWriteTime' | Select-Object -Last 1 -ExpandProperty 'FullName') -Raw
