# Prerequisite parameters
$securityBaselineTemplateName = "MDM Security Baseline for Windows 10 and later for Decemeber 2020"

# Token settings (Fetch this from your browser now while testing!)
$token = "Bearer eyJ0eXAiOiJKV1QiLCw...."
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization", $token)

Write-Output "Geting all security baseline templates on the tenant and then create variable wiht the one we care about"
$getSecurityBaselineTemplates = "https://graph.microsoft.com/beta/deviceManagement/templates"
$getSecurityBaselineTemplatesResponse = Invoke-RestMethod  -Method 'GET' -Headers $headers -Uri $getSecurityBaselineTemplates
$allSeurityBaselineTemplates = $getSecurityBaselineTemplatesResponse.value
$securityBaselineObject = $allSeurityBaselineTemplates.Where{ $_.displayName -eq $securityBaselineTemplateName }

Write-Output "Geting all the settings available on the selected security baseline"
$getSecurityBaselineCategories = "https://graph.microsoft.com/beta/deviceManagement/templates/$($securityBaselineObject.id)/categories"
$getSecurityBaselineCategoriesResponse = Invoke-RestMethod  -Method 'GET' -Headers $headers -Uri $getSecurityBaselineCategories
$securityBaselineCategories = $getSecurityBaselineCategoriesResponse.value

Write-Output "Getting the intents (assignments) of the security baseline we have selected"
$getIntents = "https://graph.microsoft.com/beta/deviceManagement/intents"
$getIntentsResponse = Invoke-RestMethod  -Method 'GET' -Headers $headers -Uri $getIntents
$allIntents = $getIntentsResponse.value
$selecedBaselineIntent = $allIntents.where{ $_.templateId -eq $securityBaselineObject.id }
Write-Output "Found $($selecedBaselineIntent.displayName)"

# https://docs.microsoft.com/en-us/graph/api/resources/intune-deviceintent-devicemanagementintent?view=graph-rest-beta
Write-Output "Getting all settings for the intent (baseline assignment)"
$allSecurityBaselineSettings = @()
foreach ($securityBaselineCategory in $securityBaselineCategories) {
    $getSetting = "https://graph.microsoft.com/beta/deviceManagement/intents/$($selecedBaselineIntent.id)/categories/$($securityBaselineCategory.id)/settings"
    $getSettingResponse = Invoke-RestMethod  -Method 'GET' -Headers $headers -Uri $getSetting
    $allSecurityBaselineSettings += $getSettingResponse.value
}

Write-Output "Found $($allSecurityBaselineSettings.Length) settings"

# Create new intent
$postIntent = "https://graph.microsoft.com/beta/deviceManagement/intents"
$postIntentBody = @{
    id = (New-Guid).Guid
    displayName = "CWF2-2"
    description = "Cloud Workforce 2.0 testing"
    isAssigned = $false
    templateId = $securityBaselineObject.id
    roleScopeTagIds = @("")
}
$postIntentResponse = Invoke-RestMethod -Method 'POST' -Headers $headers -Uri $postIntent -Body (ConvertTo-Json $postIntentBody)

Write-Output $postIntentResponse