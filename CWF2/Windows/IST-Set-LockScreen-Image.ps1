<#
THIS POWERSHELL SCRIPT SETS THE LOCKSCREEN IMAGE ON YOUR WINDOWS DEVICE.
Supported Windowsv. Windows 10 and 11
Author: Stefan Petrovic / Ironstone
---------------------------------------------------------------------------
HOW TO USE 
1. Use PowerShell App deployment tool kit to copy the image to C:\Windows\Logs\Software
call the png "lockscreen then run the scipt below:". Easy peasy.

2. INTUNE

* Use the Detection rule that is added in the same repo
* If u want to change the lock screen, replace the C:\Windows\Logs\Software\lockscreen.png with a new .PNG file


#>

#Set logging (Use if you dont use PSDAT)

# Start-Transcript -Path "C:\Windows\Logs\Software\lockscreen.log"

# Define the parent registry path 
$parentRegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP" 

# Define the name and value 
$keyName = "LockScreenImagePath" 
$imagePath = "C:\Windows\Logs\Software\lockscreen.png" 

# Create the registry key 
New-Item -Path $parentRegistryPath -Name $keyName -Force 

# Set the registry key value 
Set-ItemProperty -Path "$parentRegistryPath" -Name $keyName -Value $imagePath 

# Stop Transcript
# Stop-Transcript