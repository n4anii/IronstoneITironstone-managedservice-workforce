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
### Schedule-IronSync.ps1
Runs AzCopy.exe with provided parameters, such as URL, SAS Token.
### Run-IronSync.vbs
Runs the Schedule-IronSync.ps1, triggered from a scheduled task. Ensures that IronSync run with sufficient privileges (-ExecutionPolicy bypass).

## How to use
Device_Install-IronSync.ps1 is the script you deploy through Intune MDM -> PowerShell Scripts.
* Deploy using SYSTEM user
* It has two files embedded as base64 encoded strings, which get's installed to "C:\Program Files\IronstoneIT\IronSync\".
  * Scheduled script 
  * VBScript to run the scheduled script from a scheduled task.
* It creates two additional folders, one for logs (only kept if the scheduled script fails), and one for AzCopy journal files.
* It creates a scheduled task "IronSync" which is going to run daily at 13:00.


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
