# Changelog
## Contributors
### Original Author(s)
- Jan Van Meirvenne (Original Author)

### Add more logic and logging, still MSI
- Sooraj Rajagopalan
- Paul Huijbregts
- Pieter Wigleven
- Niall Brady 

### Minor rewrite and scheduled task edit
- Niklas Jern (XML edit)
- Sebastian Thörnblad (XML edit)

### Convert from MSI to PS1, and major rewrite including removal of XML and VBScript
- Olav Rønnestad Birkeland


## Todo and done
### Todo - Functionality we want to add
	Both
		- Use PowerShell Transcript for logging, remove custom functions
			- "-Append" for Enable-Bitlocker.ps1
	Install-IronTrigger.ps1
		- Don't use BASE64 for storing "Enable-BitLocker.ps1", it's not space efficient. Use either: 
			- [System.Management.Automation.ScriptBlock], $Obj.ToString() in Out-File
			- Deflate BASE64 instead of RAW BASE64, ~470% space savings.
		- Don't install if computer does not have TPM, throw error
	Enable-BitLocker.ps1
		- Don't try to enable BitLocker if setting TPM Owner fails
			- Find out how to check weather TPM has owner
			- Do not upload BitLocker Recovery Password if no TPM Owner
		- Simplify
		- Add more dynamic handling of multiple internal partitions
		- OneDrive for Business:
			- Better error-handling than just "Make sure you are AAD joined". For instance:
				- When AAD Joined, but OD4B not done configured
				- (?) Auto configure OD4B
		- Backup other encrypted, fixed drives
			- Don't force encryption on those, only backup if they exist
		- Webhook, email or similar for notifying admins about X failed runs
			- ConnectWise Automate Remote Agent: Create ticket?
		- Check if TPM ready, try to initialize it. If not ready, return error to admins.
			- Get-Tpm | Select-Object -ExpandProperty 'TpmReady'
			- Initialize-TPM -AllowClear -AllowPhysicalPresence

### Done - Functionality that has already been added
	Install-IronTrigger.ps1
		- Implement Ironstone Device_Verb-Noun template
		- Create Scheduled Task with pure powershell; no more XML or VBScript
	Enable-BitLocker.ps1
		- Make it work no matter logged in user authority, by
			- Run as "NT AUTHORITY\SYSTEM"
			- Get HKCU:\ from currently logged in user (OneDrive 4 Business location)


## CHANGELOG
### v1.5.0.0 - 2019.10.28
#### Both
#### Install-IronTrigger.ps1
##### Additions
##### Fixes
##### Improvements
* Latest and greatest Ironstone Intune MDM PowerShell Template
* Removed/ replaced function for extracting Base64 to file: It's only a one liner anyways
#### Enable-ItronTrigger.ps1
##### Additions
* Added boolean to control backup to OneDrive, Kiosk devices will not be user dependant and thus not necessarily have OneDrive.
##### Fixes
##### Improvements
* Speed and realiability improvements
* Some code cleanup
* Made script settings read only, to make sure they don't change by accident during script run.
		

### v1.4.2.0 - 2018.12.05
	Install-IronTrigger.ps1
		Feature
			* Block more Windows 10 Toast Notifications for BitLocker


### v1.4.1.0 - 2018.11.27
	Install-IronTrigger.ps1
		Feature
			- Updated Ironstone Intune PowerShell Template
			- Updated creation of scheduled task to Ironstone best practice
	Enable-BitLocker.ps1
		Feature
			* Will now disable hardware encryption when turning on bitlocker, with -HardwareEncryption:$false
			* Will not encrypt used space only, with -UsedSpaceOnly:$false
				* If a freshly installed OS over old OS with data, data skipped by -UsedSPaceOnly might be readable by Recuva or similar
		Bug
			* Editing scheduled task after finished 1st time was broken. Fixed it.


### v1.4.0.0 - 2018.10.12
	Install-IronTrigger.ps1
		Feature
			- Updated Ironstone Intune PowerShell Template
	Enable-BitLocker.ps1
		Feature
			- Prepared for more volumes in the feature, not OS drive/ volume only
		Bugs
			- Did not detect changes to recovery password, and therefore did not trigger backup to neither AAD or OneDrive for Business
			- Did not manage to backup to OneDrive for Business
			- Did not write recovery key to Install Dir for checking for changes between runs


### v1.3.2 - 2018.06.07
	Both
		Bugs
			* Fixed bug where getting username from explorer.exe could return multiple values, and fail.


### v1.3.1 - 2018.06.01
	Install-IronTrigger.ps1
		Feature
			- More control over the scheduled task
			- Finally running as 64 bit PowerShell on 64 bit systems
			- More fail proof logic when creating install path
				- Check if lack of, or to many "\"
				- Check if admin rights if writing to "Program Files"
		Bugs
			- Fixed bug in Ironstone Intune PowerShell Template where it wouldn't work if default Windows OS Language was not English
				- Example: "[System.Security.Principal.WindowsIdentity]::GetCurrent().Name" says "NT-MYNDIGHET" on nb-NO, but "NT-AUTHORTITY" on en-US
			- Fixed double \ in install path


### v1.3.0 - 2018.05.28
	Both
		- Now running as "NT Authority\System", which means it will work regardless if current user has admin rights
	Enable-BitLocker.ps1
		- Now using HKU:\ instead of HKCU:\ for retreiving OneDrive for Business personal folder path
	Install-IronTrigger.ps1
		Feature
			- Using Ironstone Intune PowerShell Generic Template
			- PowerShell transcript for logging
			- Creating scheduled task from pure PowerShell code
				- No more XML and VBScript
		Bugs
			- Fix bug where previous Scheduled Tasks where not deleted
		

### v1.2.3 - 2018.04.30
	Enable-BitLocker.ps1
		- Hide the OneDrive for Business recovery Folder
		- Clean up syntax, lowercase if, try and [string]

	
### v1.2.2 - 2018.04.26
	Install-IronTrigger.ps1
		- Surpress BitLocker Toast Notifications
		
		
### v1.2.1 - 2018.02.22
- Added
	- Better function for handling Scheduled Task removal and editing. "Edit-ScheduledTask"
		- Uses "[bool] $Script:BoolRemoveScheduledTaskAfterFirstSuccess" to decide wheather to delete or edit task.
- Bugfixes
	- Don't remove scheduled task after 30 fails if "[bool] $Script:BoolRemoveScheduledTaskAfterFirstSuccess = $false"
	- Bug when outputting success status of OneDrive for Business backup

		
### v1.2.0 - 2018.02.06
- Major rewrite - Again
	- Less reuse of code, more functions and dynamic variables
	- Even less Aliases
- After completion, will now continuously check for changes at 12:00pm
- Prepared for future additions
	- Dynamic naming of variables, based on drive-letter

	
### v1.0.1 - 2018.01.26
- New name, log path, install path
- Updated 
	[X] EnableBitlocker.xml
	[ ] EnableBitlocker.vbs
	[ ] EnableBitlocker.ps1
	[ ] Install-IronTrigger.ps1

	
### v1.0.0 - 2018.01.16 - "AllPowerShell Edition"
I've perfomed a major rewrite of the TriggerBitlocker script. For starters, I've moved from MSI to PS1 for installing the PS1, VBS and XML file. This is great because:
- More maintainable:  No need for MSI packaging (I honestly don't know how to do it)
- Easier to clean up: MSIs through Intune Mobile Apps must be Assigned->"Required", which means BitLockerTrigger will still be there even if it's done doing it's job


## Flaws / Bugs with original MSI
Other flaws I have looked at
- MSI remains/ reinstalls even if task is done (required in Azure Mobile Apps). Therefore I use a powershell-script to install the files.
	- PS1, VBS and XML files are stored as base64 encoded strings inside the Install-BitLockerTrigger.ps1
- Use of Aliases. It's now 100% Alias free.
- Created a new Recovery Password every run, no test to see if there already were password(s). 
	- My original device had 27 (!) BitLocker Recovery Passwords!
	- Will delete all but one, if more than 1 BitLocker Recovery Password exist
- ‎Files and scheduled task remained even if done
	- Better logic and cleaning, will remove files and scheduled tasks if everything finish successfully
- ‎Schedule now runs every 15 minute (edited the XML)
	- Thanks to Niklas Jern and Sebastian Thörnblad
- Did not check if backup already existed in OneDrive for Business and Azure AD
- Backup for OneDrive and Azure were handled in one big try-block. 
	- They are logically two different operations, and should be treated as such.
- No logic to catch x fail attempts
	- Add stats / history to programfile(x86)\BitLockerTrigger\stats.txt
		- With this you can add action(s) when counter reaches X
			- Like Email (coming)
			
			
## RESOURCES
* Base64Encode.org (https://www.base64encode.org/) for Base64 encoding of the files