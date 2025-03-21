#IronTrigger

## Introduction
IronTrigger is a solutions for BitLocker encryption + recovery key backup for clients controlled through Intune MDM.

It consists of 4 components:
* A install script, PowerShell
* A scheduled script, PowerShell
* A scheduled task, XML
* A VBasic Script that runs the scheduled task with sufficient permissions

It makes backups of the BitLocker Recovery Key to:
* AzureAD (<UserName>\Devices\<Device>)
* OneDrive for Business
  
  
## Prerequisites
* Clients
  * AzureAD Joined and Azure Intune MDM controlled
  * Windows 10 1709 or newer
  * OneDrive for Business client (NOT the old Groove client)
  
  
## Components Explained
### 1 - Device_Install-IronTrigger.ps1
This script will install IronTrigger to the client, create a scheduled task to run the IronTrigger.ps1 through the IronTrigger.vbs file.
The other IronTrigger components (Enable_BitLocker.*) are embedded in this install script as BASE64 strings.

### 2 - Enable_BitLocker.ps1
Enable_BitLocker.ps1 is the script doing everything BitLocker related.

### 3 - Enable_BitLocker.vbs
Enable_BitLocker.vbs is a simple VBasic Script which ensures that IntronTrigger.ps1 runs with elevated privileges.
It takes two variables:
* The program running the 2nd parameter, PowerShell.exe for this case
* Input to the 1st parameter, IronTrigger.ps1 for this case

### 4 - Enable_BitLocker.xml
Enable_BitLocker.xml is the file holding all the details about the scheduled task which Device_Install-IronTrigger.ps1 creates.



## To Do
* Create Scheduled Task with PowerShell only
* Clean up PowerShell Output Streams
  * Currently using a custom function for that
* Use PowerShell built in functions for logging (Transcript)
  * Currently using a custom function for that


## Resources
### Microsoft Technet Blogs
* [How to enable Bitlocker and escrow the keys to Azure AD when using AutoPilot for standard users](https://blogs.technet.microsoft.com/showmewindows/2018/01/18/how-to-enable-bitlocker-and-escrow-the-keys-to-azure-ad-when-using-autopilot-for-standard-users/)
* [Hardware independent automatic Bitlocker encryption using AAD/MDM](https://blogs.technet.microsoft.com/home_is_where_i_lay_my_head/2017/06/07/hardware-independent-automatic-bitlocker-encryption-using-aadmdm/)
### Microsoft Workplace Blog
* [UPDATED BITLOCKER EXPERIENCE WITH WINDOWS 10 INSIDER AND INTUNE](https://www.vroege.biz/?p=3998)
### Others
* [Check device BitLocker Recovery Key (User)](https://account.activedirectory.windowsazure.com/n/#/devices)
* [Windows Noob Forum: Configuring BitLocker in Intune - Part 1. Automating Encryption](https://www.windows-noob.com/forums/topic/15514-configuring-bitlocker-in-intune-part-1-configuring-bitlocker/)
* [Windows Noob Forum: Configuring BitLocker in Intune - Part 2. Automating Encryption](https://www.windows-noob.com/forums/topic/15696-configuring-bitlocker-in-intune-part-2-automating-encryption/)
