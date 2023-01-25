# Connect to Azure AD
Connect-AzureAD

#Only edit this parameter
$customerPrefix = "MAL"

# Get all groups that contain "IST-MAL-CWO" in the name
$groups = Get-AzureADGroup -All $true | Where-Object {$_.DisplayName -like "*IST-MAL-CWO*"}

foreach($group in $groups){
    # Update the group's name
    $newName = $group.DisplayName -replace "MAL",$customerPrefix
    $group.DisplayName = $newName
    Set-AzureADGroup -ObjectId $group.ObjectId -DisplayName $newName
    # Confirm the group's name has been updated
    $updatedGroup = Get-AzureADGroup -ObjectId $group.ObjectId
    Write-Output "Group name has been changed to: $($updatedGroup.DisplayName)"
}

Add-AzureADGroupMember `
    -ObjectId (Get-AzureADMSGroup -Filter "DisplayName eq 'IST-$customerPrefix-CWO-Prod-Windows'").Id `
    -RefObjectId (Get-AzureADMSGroup -Filter "DisplayName eq 'IST-$customerPrefix-CWO-Prod-AutoPilotKomplett'").Id

Add-AzureADGroupMember `
    -ObjectId (Get-AzureADMSGroup -Filter "DisplayName eq 'IST-$customerPrefix-CWO-Prod-Windows'").Id `
    -RefObjectId (Get-AzureADMSGroup -Filter "DisplayName eq 'IST-$customerPrefix-CWO-Prod-Autopilot-Convert'").Id