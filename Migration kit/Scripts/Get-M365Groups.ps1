#Connect
Connect-ExchangeOnline

#Set source domain after removal
$sourcedomain = "dokumera.onmicrosoft.com"
$targetdomain = "dlsoftware.onmicrosoft.com"

#Get unifiedgroups
$unifiedgroups = Get-unifiedgroup -resultsize unlimited

$unifiedgroupdata  = [System.Collections.Generic.List[Object]]::new()
foreach ($unifiedgroup in $unifiedgroups){
        $newsourceemail           = "{0}@{1}" -f ($unifiedgroup.PrimarySMTPAddress.split("@")[0],$sourcedomain)
        $tempdestinationemail     = "crona-" + "{0}@{1}" -f ($unifiedgroup.PrimarySMTPAddress.split("@")[0],$targetdomain)
        if ([string]::IsNullOrWhiteSpace($unifiedgroup.PrimarySMTPAddress)){
            $unifiedgroupsize     = ""
            $unifiedgroupmovetime = ""
        }
        else {
            $mailbox                  = Get-MailboxStatistics $unifiedgroup.PrimarySMTPAddress
            $unifiedgroupsize         = [math]::Round(([long]((($mailbox.totalitemsize.value -split "\(")[1] -split " ")[0] -split "," -join ""))/[math]::Pow(1024,3),3)
            $unifiedgroupmovetime     = $mailboxMoveTime = "{0} Hours" -f ($mailboxSize.TotalItemSize.Value.ToGB() / 1.5)
        }
#Create data table
$unifiedgroupinfo = [PSCustomObject]@{
    Name                    = $unifiedgroup.DisplayName
    Description             = $unifiedgroup.Description
    Privacy                 = $unifiedgroup.AccessType
    Email                   = $unifiedgroup.PrimarySMTPAddress
    EmailAlias              = $unifiedgroup.EmailAddresses
    NewSourceEmail          = $newsourceemail
    TmpDestinatioNEmail     = $tempdestinationemail
    SharePointSiteURL       = $unifiedgroup.SharePointSiteURL
    mailboxSize             = $unifiedgroupsize
    mailboxMoveTime         = $unifiedgroupmovetime
}
    $unifiedgroupdata.Add($unifiedgroupinfo)
    
}
$unifiedgroupdata | Export-CSV -NoTypeInformation -Path "C:\Users\VegardØdegaard\Ironstone\Migration Projects - Documents\Confirmasoft\Reports\Crona Lön\Migration\Reports\unifiedgroups.csv" -Delimiter ',' -Encoding UTF8
