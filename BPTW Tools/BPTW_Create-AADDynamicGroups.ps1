# AzureAD Module
Connect-AzureAD

$AADGroupsAll = Get-AzureADGroup -All:$true
$AADGroupsDynamic = $AADGroupsAll | Where-Object -Property 'DisplayName' -Like 'Dyn *'

$AADMSGroupsAll = Get-AzureADMSGroup -All:$true
$AADMSGroupsDynamic = $AADMSGroupsAll | Where-Object -Property 'DisplayName' -Like 'Dyn *'

Disconnect-AzureAD



# Msol Module
Connect-MsolService
$MsolGroupsAll = Get-MsolGroup -All
$MsolGroupsDynamic = $MsolGroupsAll | Where-Object -Property 'DisplayName' -Like 'Dyn *'





