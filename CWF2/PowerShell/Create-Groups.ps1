#Connect-AzureAD
#you need to use the Install-Module -Name AzureADPreview since the general release does not support dynamic groups

#Create default groups used in Cloud Workforce 2.0

$customer = "XXX"

$groupnames = @(
    "IST-$customer-CWO-Prod-Windows"
    "IST-$customer-CWO-Pilot-Windows"
    "IST-$customer-CWO-Prod-User"
    "IST-$customer-CWO-Pilot-User"
)

foreach ($group in $groupnames) {
    New-AzureADMSGroup `
        -DisplayName $group `
        -MailEnabled $false `
        -MailNickname "none" `
        -SecurityEnabled $true
}

#Dynamic group for devices bought through Komplett
$rule = '(device.devicePhysicalIds -any _ -eq "[OrderID]:CW2") -or (device.devicePhysicalIds -any _ -eq "[OrderID]:Komplett")'
New-AzureADMSGroup `
    -DisplayName "IST-$customer-CWO-Prod-Windows-Komplett" `
    -MailEnabled $false `
    -MailNickname "none" `
    -SecurityEnabled $true `
    -GroupTypes "DynamicMembership" `
    -MembershipRule $rule `
    -MembershipRuleProcessingState "On"

Add-AzureADGroupMember `
    -ObjectId (Get-AzureADMSGroup -Filter "DisplayName eq 'IST-$customer-CWO-Prod-Windows'").Id `
    -RefObjectId (Get-AzureADMSGroup -Filter "DisplayName eq 'IST-$customer-CWO-Prod-Windows-Komplett'").Id


#Dynamic group to add devices to autopilot if they are enrolled manually
$rule = '(device.accountEnabled -eq true) -and (device.managementType -eq "MDM") -and (device.deviceOwnership -eq "Company") -and (device.deviceOSType -eq "Windows")'
New-AzureADMSGroup `
    -DisplayName "IST-$customer-CWO-Prod-Autopilot-Convert" `
    -MailEnabled $false `
    -MailNickname "none" `
    -SecurityEnabled $true `
    -GroupTypes "DynamicMembership" `
    -MembershipRule $rule `
    -MembershipRuleProcessingState "On"

Add-AzureADGroupMember `
    -ObjectId (Get-AzureADMSGroup -Filter "DisplayName eq 'IST-$customer-CWO-Prod-Windows'").Id `
    -RefObjectId (Get-AzureADMSGroup -Filter "DisplayName eq 'IST-$customer-CWO-Prod-Autopilot-Convert'").Id