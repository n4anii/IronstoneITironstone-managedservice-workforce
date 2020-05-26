# Todo - IronSync



## Information
Author: 	Olav Rønnestad Birkeland
Company: 	Ironstone IT



## Todo
### Both
#### Probably
##### More generic
* **[x]** Make it more generic, so that everything that's needed is 3-4 variables

##### AzCopy v10
* **[x]** Update to using AzCopy v10, which will also remove files if removed from Storage Account.
	* Requires writing an installer, v10 is just a zipped folder with exe files.
	* Requires rewriting installer to Win32.
		* Will make install more failproof with more logic to check success, reinstall if something gets removed etc.

##### Intune Win32 installer
* **[x]** Use Win32 package for install
	* Dependencies, requirements, detection rules etc.
	* More reliable, and can create dependency chain requiring AzCopy to be present before IronSync installs.

#### Maybe


### Install-IronSync(Customer_Application).ps1
#### Probably
##### Update config vs. clean install
* **[ ]** Switch for (1) Initial config vs (2) update existing config
	1. Delete all conflicting shit
		* If templates are in use, schedule script to run on next reboot
	2. Don't touch the templates folder, AzCopy will handle that

#### Maybe
##### NTFS Permissions
* **[ ]** NTFS Permissions ReadOnly for AzureAD\<users> on the IronSync download folder
	* For now it only uses directory labels for hiding the folder.
