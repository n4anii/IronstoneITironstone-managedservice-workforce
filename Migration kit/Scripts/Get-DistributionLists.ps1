#Connect to Exchange Online
Connect-ExchangeOnline

#Connect to AzureAD
Connect-AzureAD

#Set source domain after removal
$sourcedomain = "dokumera.onmicrosoft.com"
$targetdomain = "dlsoftware.onmicrosoft.com"

#Get mailboxes and required properties
$Distributiongroups   = Get-DistributionGroup -resultsize unlimited

$Distributiongroupdata  = [System.Collections.Generic.List[Object]]::new()
foreach ($Distributiongroup in $Distributiongroups){
        $newsourceemail          = "{0}@{1}" -f ($distributiongroup.PrimarySMTPAddress.split("@")[0],$sourcedomain)
        $tempdestinationemail    = "dokumera-" + "{0}@{1}" -f ($distributiongroup.PrimarySMTPAddress.split("@")[0],$targetdomain)
        $aaduserforphone         = 
        $distributiongroupcalendar = 
        $settings                = 
#Create data table
$distributiongroupinfo = [PSCustomObject]@{
    Name                    = $Distributiongroup.Name
    Email                   = $Distributiongroup.PrimarySMTPAddress
    EmailAlias              = $Distributiongroup.EmailAddresses
    NewSourceEmail          = $newsourceemail
    TmpDestinatioNEmail     = $tempdestinationemail
    BlockExternalSenders    = $Distributiongroup.RequireSenderAuthenticationEnabled
}
    $distributiongroupdata.Add($distributiongroupinfo)
    
}
$distributiongroupdata | Export-CSV -NoTypeInformation -Path "C:\Users\VegardØdegaard\Ironstone\Migration Projects - Documents\Confirmasoft\Reports\Dokumera\Migration\Reports\distributiongroups.csv" -Delimiter ',' -Encoding UTF8

