$disc = Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object DeviceID -EQ "C:"

$freespace = 1 - ($disc.FreeSpace / $disc.Size)

if($freespace -le 0.60){
    Exit 0
}
else{
    Exit 1
}