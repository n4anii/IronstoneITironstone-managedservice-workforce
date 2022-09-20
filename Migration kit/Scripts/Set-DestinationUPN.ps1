#Connect-AzureAD

$users = Import-Csv "..\import\masterdata.csv"

foreach ($user in $users){
    Write-Host "Changing UPN value from: "$upn" to: " $newupn -ForegroundColor Yellow
    Set-AzureADUser -ObjectId $user.destinationTmpUPN  -UserPrincipalName $user.destinationUPN
}