$disk = Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object DeviceID -EQ "C:"

if($disk.FreeSpace -le 20000000000){
    Write-Output -InputObject "Discspace below threshold, remediate problem"
    Exit 1
}
else{
    Write-Output -InputObject "Discspace ok"
    Exit 0
}