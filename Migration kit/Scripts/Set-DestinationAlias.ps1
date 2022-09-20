#Connect-ExchangeOnline

$users = Import-Csv "..\import\masterdata.csv" 

foreach ($user in $users) {
    $proxyAddresses = $user.destinationAlias -split '&'
    Set-Mailbox -Identity $user.destinationUPN -EmailAddresses @{add= $proxyAddresses}
}