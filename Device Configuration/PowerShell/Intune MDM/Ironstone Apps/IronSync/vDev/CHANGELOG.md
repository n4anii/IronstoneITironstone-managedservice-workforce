# Changelog - IronSync



## Information
Author: 	Olav Rønnestad Birkeland
Company: 	Ironstone IT

	
	
## Changelog
### v3.2.0.0 200520
#### Run-IronSync
* Added
	* Support for AzCopy v10, fallback to v8.1.0
	* More tests for failproofing AzCopy, like clean up previous failed attempts
	
#### Install-IronSync(Customer).ps1
* Added
	* Input parameters, can now be used with Win32 package
	
	

### v3.1.0.0 190311
#### Run-IronSync(Application_Customer).ps1
* Added check for internet connectivity.



### v3.0.0.0 190308
#### Both
* Variable type is now specified AFTER the equal, because "[byte] $Var = 16" turns into a freakin Int32

#### Install-IronSync(Application_Customer).ps1
* Newest Ironstone Intune MDM Template, ensures higher success rate when writing to HKCU from System context
* Will not delete previous folder, AzCopy will simply overwrite the content.
* All customer variables is only written in top of the install-script, gets "slipstreamed" into the Run-IronSync(Application_Customer).ps1

#### Run-IronSync(Application_Customer).ps1
* All customer variables is only written in top of the install-script, gets "slipstreamed" into the Run-IronSync(Application_Customer).ps1
* Changed logging filename to use 24 hours instead of 12 hours in log name
* Changed logic around detection AzCopy success.


	
### v2.0.0.0 181031
#### Both
* Name change, from "IronSync(<Customer>_OfficeTemplates)" to "IronSync(OfficeTemplates_<Customer>)".

#### Install-IronSync(Customer_Application).ps1
* Newest Ironstone Intune MDM Template
* Now only uses PowerShell to schedule script to run. No more VBS or XML!
* Better writing to HKCU from System/ Device Context
* Use ScriptBlock instead of Base64 for content of "Run-IronSync(OfficeTemplates_Metier).ps1"
* Better error handling when deleting and creating paths and registry keys

#### Run-IronSync(Customer_Application).ps1
* Minor bug fixes and name changes
* Tested and works against Microsoft Azure Storage Tools v7.1.0, v7.3.1 and v8.1.0
