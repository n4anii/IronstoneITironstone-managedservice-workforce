# Get current license info
cscript 'C:\Windows\System32\slmgr.vbs' '/dli'

# Display detailed license information
cscript 'C:\Windows\System32\slmgr.vbs' '/dlv'

# Get license key from UEFI / BIOS. OEM key programmed into the hardware
Get-WmiObject -Query 'Select * from SoftwareLicensingService' | Select-Object -Property 'OA3xOriginalProductKey','OA3xOriginalProductKeyDescription' | Format-List

# Insert Windows 10 KMS Client Setup Key
cscript 'C:\Windows\System32\slmgr.vbs' '/ipk' '<key>'

# Activate key against Microsoft servers
cscript 'C:\Windows\System32\slmgr.vbs' '/ato'

# Uninstall Product Key
cscript 'C:\Windows\System32\slmgr.vbs' '/upk'

# Remove Product Key from Registry
cscript 'C:\Windows\System32\slmgr.vbs' '/cpky'

# Version number
$(Get-WmiObject -Query 'Select * from SoftwareLicensingService' -ComputerName $env:COMPUTERNAME).'Version'
