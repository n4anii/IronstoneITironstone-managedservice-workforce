Based on article : https://oliverkieselbach.com/2020/05/13/powershell-helpers-to-convert-azure-ad-object-ids-and-sids/

In a AzureAD Join scenario there are 2 user SIDS that will be automatically added to the local administrators group on the device. Specifically for the roles "Global Administrator" and "Device Administrator".

These SIDs are unique for every tenant, so to be able to add these back to the local admin group when configuring a local admin policy in Intune you need to run the provided powershell script.

Steps:

1. Connect to the AzureAD module
2. Run the Get-AzureADDirectoryRole command to identify the ObjectID for the desired role
3. Run the script "Convert-AzureADObjectIDtoSID" replacing the ObjectID parameter with the ObjectID in step 2.
4. Repeat for both roles
