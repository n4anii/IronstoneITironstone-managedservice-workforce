# IronMaintainer

## Description
IronMaintainer will make sure users devices is up to date (Windows Update) and synced with Ironstone MDM Solution (Intune MDM).
The script runs once a day, and checks for two things

X will represent days in following descriptions. Default will be 7, but will be a parameter.

### 1 Pending reboots due to Windows Updates. 
* If theres Windows Updates available that requires reboot
* AND If last reboot is greater than X days:
* Nag the user to reboot.

### 2 - Last sync to Intune
* If last sync to Intune is greater than X days, force a sync silently.