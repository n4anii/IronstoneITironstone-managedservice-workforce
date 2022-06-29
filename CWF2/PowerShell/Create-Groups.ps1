#Connect-AzureAD
#you need to use the Install-Module -Name AzureADPreview since the general release does not support dynamic groups

#Create default groups used in Cloud Workforce 2.0

$customer = "XXX"

$groupnames = @(
    "IST-$customer-CW2-Prod-Windows"
    "IST-$customer-CW2-Pilot-Windows"
    "IST-$customer-CW2-Prod"
    "IST-$customer-CW2-Pilot"
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
    -DisplayName "IST-$customer-CW2-Prod-Windows-Komplett" `
    -MailEnabled $false `
    -MailNickname "none" `
    -SecurityEnabled $true `
    -GroupTypes "DynamicMembership" `
    -MembershipRule $rule `
    -MembershipRuleProcessingState "On"


Add-AzureADGroupMember `
    -ObjectId (Get-AzureADMSGroup -Filter "DisplayName eq 'IST-$customer-CW2-Prod-Windows'").Id `
    -RefObjectId (Get-AzureADMSGroup -Filter "DisplayName eq 'IST-$customer-CW2-Prod-Windows-Komplett'").Id
