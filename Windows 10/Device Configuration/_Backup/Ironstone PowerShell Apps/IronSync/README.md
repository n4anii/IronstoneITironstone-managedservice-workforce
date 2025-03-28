# IronSync


## Introduction
IronSync is a solution that let's you sync/ download files from Azure Storage to clients controlled with Azure Intune MDM.
### Reliable
It relies on AzCopy.exe from "Microsoft Azure Storage Tools".
### Safe 
It uses SAS Tokens to authenticate against Azure Storage.


## How it works
### Device_Install-IronSync.ps1
Installs IronSync, creates scheduled task.
### Run-IronSync.ps1
Runs AzCopy.exe with provided parameters, such as URL, SAS Token.


## How to use
### Quick Overview
Device_Install-IronSync.ps1 is the script you deploy through Intune MDM -> PowerShell Scripts.
* Deploy using SYSTEM user
* It has a file embedded as a ScriptBlock, which get's installed to "C:\Program Files\IronstoneIT\IronSync".
  * Run-Ironsync.ps1
* It creates two additional folders, one for logs (only kept if the scheduled script fails), and one for AzCopy journal files.
* It creates a scheduled task "IronSync" which is going to run daily at 13:00.

### Onboard new customer - OfficeTemplates edition
#### Azure Storage Account \ Blog Storage
##### Upload Files
Files to sync, must be configured on customer tenant as such
* Azure Storage Account -> Blog Storage with a Private Blob Container where the files will reside
  * Storage Container MUST be names "office365-templates"
  * Each file should use Access Tier "Hot", Blob Type "Block based"
  * Copy out storage account name (taken from the storage account), and SAS token for the blob container (creat under "Access policy")
##### Create SAS (Shared Access Signature) Token
First create a Access Policy on the Azure Storage Container where the Office365 templates resides
* Public Access Level: Private.
* Stored access policies: Create a storage policy named "users", no start or expiry time, permissions Read and List only.
* Immutable blob storage: No policies configured.

Then create a SAS token on the Storage Account
* Go to the Storage Account \ Shared access signature
  * Allowed services: Blob.
  * Allowed resource types: Container and Object only.
  * Allowed permissions: Read and List only.
  * Start time: Now.
  * End time: In two years or to your preference.
  * Time zone: UTC+1.
  * Allowed protocols: HTTPS only.
  * Signing key: Which ever, but note that: Regenerating the key will break the SAS token.
#### Modify Scripts
##### Run-IronSync(OfficeTemplates_<company>).ps1
* Rename script file and script name inside it ($NameScript)
* Add Storage Account name and SAS Token for access to the blob storage container
##### Install-IronSync(OfficeTemplates_<customer>).ps1
* Rename script file and script name inside it ($NameScript)
* Edit region "Variables - Case Specific" with content from Run-IronSync(OfficeTemplates_<company>).ps1
#### Deploy
* Deploy both Azure Storage Tools and "Install-IronSync(OfficeTemplates_<customer>).ps1" to the same group
##### AzSync
Intune \ Client Apps
* Add Microsoft Azure Storage Tools as MSI to Intune, and deploy
##### Script
Intune \ Device Configuration \ PowerShell
* Upload the "Install-IronSync(OfficeTemplates_<customer>).ps1" script


## To Do
* (Maybe) NTFS Permissions ReadOnly for AzureAD\<users> on the IronSync download folder
  * For now it only uses directory labels

## Resources
### AzCopy - Microsoft Azure Storage Tools
* Microsoft Docs: Transfer data with the AzCopy on Windows
  * [aka.ms/AzCopy](https://aka.ms/AzCopy)
  * [Full link](https://docs.microsoft.com/en-us/azure/storage/common/storage-use-azcopy)
* [GitHub: Azure Storage Net Data Movement](https://github.com/Azure/azure-storage-net-data-movement)
  * Used in Microsoft Azure Storage Tools
* [Download Current Latest Version](http://aka.ms/downloadazcopy)
  * [Version used when developing this script (v7.1.0)](https://azcopy.azureedge.net/azcopy-7-1-0/MicrosoftAzureStorageTools.msi)
### Microsoft Docs
* [Using shared access signatures (SAS)](https://docs.microsoft.com/en-us/azure/storage/common/storage-dotnet-shared-access-signature-part-1)
