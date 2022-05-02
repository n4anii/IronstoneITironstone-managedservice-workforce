#Connect-AzureAD
#you need to use the Install-Module -Name AzureADPreview since the general release does not support dynamic groups

#Create default groups used in Cloud Workforce 2.0

$groupnames = @(
    "CW2.0 - Device - Prod - Windows"
    "CW2.0 - Device - Test - Windows"
    "CW2.0 - User - Prod"
    "CW2.0 - User - Test"
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
    -DisplayName "CW2.0 - Device - Prod - Windows - Komplett" `
    -MailEnabled $false `
    -MailNickname "none" `
    -SecurityEnabled $true `
    -GroupTypes "DynamicMembership" `
    -MembershipRule $rule `
    -MembershipRuleProcessingState "On"


Add-AzureADGroupMember `
    -ObjectId (Get-AzureADMSGroup -Filter "DisplayName eq 'CW2.0 - Device - Prod - Windows'").Id `
    -RefObjectId (Get-AzureADMSGroup -Filter "DisplayName eq 'CW2.0 - Device - Prod - Windows - Komplett'").Id
