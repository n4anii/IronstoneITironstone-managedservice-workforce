#Connect-AzureAD

$users = Import-Csv "..\import\masterdata.csv" -Delimiter ';'

$passwordprofile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
$passwordprofile.ForceChangePasswordNextLogin = $true

foreach ($user in $users) {
    $passwordprofile.Password = $user.Password
    New-AzureADUser -UserPrincipalName $user.destinationTmpUPN -PasswordProfile $passwordprofile -GivenName $user.firstName -Surname $user.lastName -DisplayName $user.destinationDisplayName -UsageLocation "NO" -AccountEnabled $true -MailNickName $user.destinationUPN.Split('@')[0]

    $group = Get-AzureADGroup -SearchString $user.licenseGroup
    Add-AzureADGroupMember -ObjectId $group.ObjectId -RefObjectId (Get-AzureADUser -SearchString $user.destinationTmpUPN).ObjectId
}