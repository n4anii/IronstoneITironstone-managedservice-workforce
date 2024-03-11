#Connect-ExchangeOnline

# Iterate through each row in the CSV

$users = Get-Mailbox -Filter {EmailAddresses -like '*@jensenscandinavia.com' -and UserPrincipalName -like '*@eltekholding.onmicrosoft.com'}


foreach ($user in $users) {
    $userPrincipalName = $user.UserPrincipalName
    $alias = $user.EmailAddresses
    Write-Host "removing $alias from $userPrincipalName"
    try {
        Set-Mailbox -Identity $userPrincipalName -EmailAddresses SMTP:$userPrincipalName
        Write-Host "Removed alias for $userPrincipalName"
    }
    catch {
        Write-Host "Failed to remove alias for $userPrincipalName"
    }
}


Get-Mailbox -Filter {EmailAddresses -like '*@jensenscandinavia.com' -and UserPrincipalName -notlike '*@eltekholding.onmicrosoft.com'}

Get-Mailbox -Filter {UserPrincipalName -like 'support@eltekholding.onmicrosoft.com'}