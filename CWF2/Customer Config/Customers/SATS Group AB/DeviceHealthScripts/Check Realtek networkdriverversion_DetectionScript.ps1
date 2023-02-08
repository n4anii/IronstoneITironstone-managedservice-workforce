$driver = Get-WmiObject Win32_PnPSignedDriver| Select-Object devicename, driverversion | Where-Object {$_.devicename -like "*realtek usb gbe family*"}

if($driver.driverversion -eq "10.54.20.608"){
    Write-Output -InputObject ("Correct driver {0} installed" -f ($driver.driverversion))
    Exit 0
}
else {
    Write-Output -InputObject ("Wrong driver {0} installed" -f ($driver.driverversion))
    Exit 1
}