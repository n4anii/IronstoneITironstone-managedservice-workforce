$disc = Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object DeviceID -EQ "C:"

$freespace = ($disc.FreeSpace / $disc.Size)

if($freespace -le 0.1){
    Write-Output -InputObject "Discspace below threshold, remediate problem"
    Exit 1
}
else{
    Write-Output -InputObject "Discspace ok"
    Exit 0
}