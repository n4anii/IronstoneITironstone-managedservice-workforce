#Connect-ExchangeOnline

$users = Import-Csv "..\import\masterdata.csv" -Delimiter ';'

foreach ($user in $users) {
    $proxyAddresses = $user.sourceAddAlias -split '&'
    Set-Mailbox -Identity $user.sourcePrimarySMTP -EmailAddresses @{add= $proxyAddresses}
}