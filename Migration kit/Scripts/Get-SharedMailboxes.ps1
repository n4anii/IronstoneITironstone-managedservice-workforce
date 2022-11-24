#Connect to Exchange Online
Connect-ExchangeOnline

#Set source domain after removal
$sourcedomain = "dokumera.onmicrosoft.com"
$targetdomain = "dlsoftware.onmicrosoft.com"

#Get mailboxes and required properties
$sharedmailboxes    = get-mailbox -resultsize unlimited -recipienttypedetails sharedmailbox

$sharedmailboxdata  = [System.Collections.Generic.List[Object]]::new()
foreach ($sharedmailbox in $sharedmailboxes){
        $newsourceemail          = "{0}@{1}" -f ($sharedmailbox.PrimarySMTPAddress.split("@")[0],$sourcedomain)
        $tempdestinationemail    = "dokumera-" + "{0}@{1}" -f ($sharedmailbox.PrimarySMTPAddress.split("@")[0],$targetdomain)
    if (($_.ForwardingAddress -ne $null) -and ($_.forwardingSMTPaddress -ne $null) -and ($_.DeliverToMailboxAndForward -ne $false)){
        $forwarding = "True"
    }
    else {
        $forwarding = "False"
    }
        $sharedmailboxfullaccess = Get-mailboxpermission -identity $sharedmailbox.alias | where {$_.user -ne 'NT Authority\Self' -and $_.AccessRights -like "*fullaccess*"}
        $fullaccessusers         = ([string]$sharedmailboxfullaccess.user).replace(" ", ",")
        $sharedmailboxsendas = Get-recipientpermission -identity $sharedmailbox.alias -accessrights sendas | where {$_.trustee -ne 'NT Authority\Self' -and $_.trustee -notlike '*\*'}
        $sendasusers         = ([string]$sharedmailboxsendas.trustee).replace(" ", ",")

#Create data table
$sharedmailboxinfo = [PSCustomObject]@{
    Name                = $sharedmailbox.Name
    Email               = $sharedmailbox.PrimarySMTPAddress
    EmailAlias          = $sharedmailbox.EmailAddresses
    NewSourceEmail      = $newsourceemail
    TmpDestinatioNEmail = $tempdestinationemail
    Forwarding          = $forwarding
    HideInGAL           = $sharedmailbox.hiddenfromaddresslistsenabled
    FullAccess          = $fullaccessusers
    SendAs              = $sendasusers

}
    $sharedmailboxdata.Add($sharedmailboxinfo)
    
}
$sharedmailboxdata | Export-CSV -NoTypeInformation -Path "C:\Users\VegardØdegaard\Ironstone\Migration Projects - Documents\Confirmasoft\Reports\Dokumera\Migration\Reports\sharedmailboxes.csv" -Delimiter ',' -Encoding UTF8

