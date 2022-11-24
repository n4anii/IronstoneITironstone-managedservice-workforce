#Connect to Exchange Online
Connect-ExchangeOnline

#Connect to AzureAD
Connect-AzureAD

#Set source domain after removal
$sourcedomain = "dokumera.onmicrosoft.com"
$targetdomain = "dlsoftware.onmicrosoft.com"

#Get mailboxes and required properties
$resourcemailboxes    = get-mailbox -resultsize unlimited |  Where { $_.IsResource -eq 'true' }

$resourcemailboxdata  = [System.Collections.Generic.List[Object]]::new()
foreach ($resourcemailbox in $resourcemailboxes){
        $newsourceemail          = "{0}@{1}" -f ($resourcemailbox.PrimarySMTPAddress.split("@")[0],$sourcedomain)
        $tempdestinationemail    = "crona-" + "{0}@{1}" -f ($resourcemailbox.PrimarySMTPAddress.split("@")[0],$targetdomain)
        $aaduserforphone         = Get-azureaduser -objectid $resourcemailbox.userprincipalname
        $resourcemailboxcalendar = get-calendarprocessing $resourcemailbox.alias
        $settings                = $resourcemailboxcalendar | convertto-json
#Create data table
$resourcemailboxinfo = [PSCustomObject]@{
    Name                = $resourcemailbox.Name
    Email               = $resourcemailbox.PrimarySMTPAddress
    EmailAlias          = $resourcemailbox.EmailAddresses
    NewSourceEmail      = $newsourceemail
    TmpDestinatioNEmail = $tempdestinationemail
    Type                = $resourcemailbox.RecipientTypeDetails
    Capacity            = $resourcemailbox.ResourceCapacity
    Location            = $resourcemailbox.Location
    PhoneNumber         = $aaduserforphone.phonenumber
    Delegates           = $resourcemailboxcalendar.ResourceDelegates
    Settings            = $settings
}
    $resourcemailboxdata.Add($resourcemailboxinfo)
    
}
$resourcemailboxdata | Export-CSV -NoTypeInformation -Path "C:\Users\VegardØdegaard\Ironstone\Migration Projects - Documents\Confirmasoft\Reports\Crona Lön\Migration\Reports\resourcemailboxes.csv" -Delimiter ',' -Encoding UTF8

