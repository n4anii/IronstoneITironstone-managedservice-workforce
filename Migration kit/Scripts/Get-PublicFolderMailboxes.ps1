#Connect to Exchange Online
Connect-ExchangeOnline

#Set source domain after removal
$sourcedomain = "dokumera.onmicrosoft.com"
$targetdomain = "dlsoftware.onmicrosoft.com"

#Get mailboxes and required properties
$publicfolders    = Get-PublicFolder –Recurse –ResultSize Unlimited 

$publicfolderdata  = [System.Collections.Generic.List[Object]]::new()
foreach ($publicfolder in $publicfolders){
    if  ($publicfolder.MailEnabled -eq $true) {
        $mailpublicfolder = Get-MailPublicFolder -Identity $publicfolder.identity
    } 
    else {
        $mailpublicfolder = ""
    }
    if  ($publicfolder.parentpath -eq "\")
    {
	    $folderpath = "\" + ($publicfolder.name.trim())
	    $folderpath = $folderpath.Replace(' \', '\')
        $folderpath = $folderpath.Replace('\ ', '\')
    }
    else
    {
        $folderpath = ($publicfolder.parentpath.trim()) + "\" + ($publicfolder.name.trim())
    }
#Create data table
$publicfolderinfo = [PSCustomObject]@{
    Name                = $publicfolder.Name
    Identity            = $publicfolder.Identity
    MailEnabled         = $publicfolder.MailEnabled
    PrimarySMTPAddress  = $mailpublicfolder.PrimarySMTPAddress
    EmailAddresses      = $mailpublicfolder.EmailAddresses
    ContentMailboxName  = $publicfolder.ContentMailboxName
    Size                = $publicfolder.FolderSize
    FolderPath          = $folderpath
}
    $publicfolderdata.Add($publicfolderinfo)
    
}
$publicfolderdata | Export-CSV -NoTypeInformation -Path "C:\Users\VegardØdegaard\Ironstone\Migration Projects - Documents\Confirmasoft\Reports\DokuMera\Migration\Reports\publicfolders.csv" -Delimiter ',' -Encoding UTF8


################################################################# BIT TITAN RECOMMENDATIONS #################################################################
# https://help.bittitan.com/hc/en-us/articles/360045186353-Public-Folder-Migration-Best-Practices
# If the tenant has more than 1000 public folders, submit a ticket to bittitan support and attach the exported file: 
Get-PublicFolder -Recurse -Resultsize Unlimited | select Identity | Export-Csv "C:\Users\VegardØdegaard\Ironstone\Migration Projects - Documents\Confirmasoft\Reports\DokuMera\Migration\Reports\pfolders.csv" -NoTypeInformation -encoding UTF8 -Delimiter ','

# You do not need to create separate projects for differing item types. Projects are based on folder size and number. The same project can be used when migrating folders containing different item types.
Get-PublicFolder -Recurse | Get-PublicFolderItemStatistics | Group-Object -Property ItemType -NoElement | Export-Csv "C:\Users\VegardØdegaard\Ironstone\Migration Projects - Documents\Confirmasoft\Reports\DokuMera\Migration\Reports\itemcount.csv" -NoTypeInformation -encoding UTF8 -Delimiter ','

# When migrating to Exchange Online (Office 365), ensure that all of your Public Folders are within the stated limits for public folders​.
Get-PublicFolderStatistics | Select-Object Name, FolderPath, ItemCount, TotalItemSize | Export-csv "C:\Users\VegardØdegaard\Ironstone\Migration Projects - Documents\Confirmasoft\Reports\DokuMera\Migration\Reports\PFStatistics.csv" -NoTypeInformation -encoding UTF8 -Delimiter ','

# When your project is split by BitTitan Support - Office 365 as the Destination. Increase the public folder quotas to Unlimited.
#Set-OrganizationConfig -DefaultPublicFolderProhibitPostQuota Unlimited -DefaultPublicFolderIssueWarningQuota Unlimited

# If running a Public Folder migration, and there is more than 20GB of data that you are migrating, contact BitTitan Support so that we can generate the PowerShell scripts necessary to properly provision the Public Folder mailboxes
#Dokumera mailbox is 1.65GB

#Migrating mail-enabled public folder email addresses: https://help.bittitan.com/hc/en-us/articles/115008257228-Migrating-Mail-Enabled-Public-Folder-Email-Addresses