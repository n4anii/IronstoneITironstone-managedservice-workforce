# IronSync



## Introduction
### What is it
IronSync is a solution that let's you sync/ download files from Azure Storage to clients controlled with Azure Intune MDM.

### Reliable and fast
It relies on AzCopy.exe from "Microsoft Azure Storage Tools".

### Safe 
It uses SAS Tokens to authenticate against Azure Storage.



## Setup overview / dependency chain
### 1 - Azure Storage Account
* Why: To host files synced down using IronSync.
* How: See this guide.

### 2 - AzCopy
* Why: To sync files reliably, fast and safe from Azure Storage Account.
* How: AzCopy v10 Win32 installer. Instructions are found inside separate ```Win32 Install Parameters.md```.
	* Generic binary that can be used for other products as well. Thus is why it's hosted outside the IronSync project.

### 3 - IronSync
* Why: Logic for syncing files from Azure Storage Account using AzCopy.
* How: IronSync Win32 installer. Instructions are found inside separate ```Win32 Install Parameters.md```.

### 4 - Teams Backgrounds (optional)
* Why: Logic for syncing Teams backgrounds from IronSync folder, in to Teams backgrounds folder inside ```%appdata%\Microsoft\Teams\Backgrounds\Uploads``` folder.
* How: IronSync Teams Backgrounds Win32 installer. Instructions are found inside separate ```Win32 Install Parameters.md```.



## How it works
### Device_Install-IronSync.ps1
Installs IronSync (Run-IronSync.ps1), creates scheduled task.

### Run-IronSync.ps1
Runs AzCopy.exe with provided parameters, such as URL, SAS Token.



## Onboard new customer
### 1. Azure Storage Account
Azure \ Storage Account

#### Create Storage Account
(Example from our own tenant)
* **Tenant:** ironstoneit.onmicrosoft.com
* **Subscription:** Ironstone-MPN-SE-Production
* **Resource group:** IST-P-NOE-BPTW-IronSync-RG
  * **Location:** Norway East
* **Storage Account:** istnoebptwironsync
  * Basics
    * **Location:** Norway East
    * **Performance:** Standard
    * **Account kind:** BlobStorage
    * **Replication:** Locally-redundant storage (LRS)
    * **Access tier:** Hot
  * Networking
    * **Connectivity method:** Public endpoint (all networks)
  * Advanced
    * **Secure transfer required:** Enabled
	* **Blob soft delete:** Disabled
	* **Versioning:** Disabled
	* **Hierarchical namespace:** Disabled
	* **NFS v3:** Disabled
* Container
  * **Name:** files
  * **Public access level:** Private (no anonymous access)

#### Upload Files
Files to sync, must be configured on customer tenant as such
* Azure Storage Account -> Blog Storage with a Private Blob Container where the files will reside
  * Storage Account name, blob name and SAS token are input parameter to IronSync installer script/ Win32 package.
  * Each file should use Access Tier "Hot", Blob Type "Block based".
  * Copy out storage account name (taken from the storage account), and SAS token for the blob container (creat under "Access policy").

#### Create SAS (Shared Access Signature) Token
First create a Access Policy on the Azure Storage Container where the Office365 templates resides
* Public Access Level: Private.
* Stored access policies: Create a storage policy named "users", no start or expiry time, permissions Read and List only.
* Immutable blob storage: No policies configured.

Then create a SAS token on the Storage Account
* Go to the Storage Account \ Shared access signature
  * **Allowed services:** Blob
  * **Allowed resource types:** Container
  * **Allowed permissions:** Read, List
  * **Blobl versioning permissions:**
  * **Start:**
  * **End:** +5 years
  * **Timezone:** Current
  * **Allowed IP addresses:**
  * **Allowed protocols:** HTTPS only
  * **Signing key:** Key 1

### 2. AzCopy
Intune \ Client Apps
* Add Microsoft Azure Storage Tools as Win32 to Intune, set up according to the ```Win32 Install Parameters.md``` file.

### 3. IronSync Installer
Intune \ Client Apps
* Upload the Win32 package containing IronSync installer script, set up according to the ```Win32 Install Parameters.md``` file.

### 4. Extension - Teams Backgrounds (optional)
Intune \ Client Apps
* Upload the Win32 package containing Teams Backgrounds sync script, set up according to the ```Win32 Install Parameters.md``` file.



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