# Prerequisite parameters
$securityBaselineTemplateName = "MDM Security Baseline for Windows 10 and later for Decemeber 2020"

# Token settings (Fetch this from your browser now while testing! The URL to Endpoint Manager is: https://endpoint.microsoft.com/#home) 
$token = "Bearer eyJ0eXAiOiJKV1QiLCJub25jZSI6InVsVVR4Ym5qemdkR2E0LVFXN2JNeHZOc2RLRzRheUNieHVsbGRwM2UwaE0iLCJhbGciOiJSUzI1NiIsIng1dCI6Imwzc1EtNTBjQ0g0eEJWWkxIVEd3blNSNzY4MCIsImtpZCI6Imwzc1EtNTBjQ0g0eEJWWkxIVEd3blNSNzY4MCJ9.eyJhdWQiOiJodHRwczovL2dyYXBoLm1pY3Jvc29mdC5jb20vIiwiaXNzIjoiaHR0cHM6Ly9zdHMud2luZG93cy5uZXQvNTc0NTVhYWQtMGIwZi00YzExLTljNTQtNmNkMDFmNzI1MGViLyIsImlhdCI6MTYzOTE1MjAwMSwibmJmIjoxNjM5MTUyMDAxLCJleHAiOjE2MzkxNTY0ODcsImFjY3QiOjAsImFjciI6IjEiLCJhaW8iOiJBVVFBdS84VEFBQUFLc0VISXVVV1BTaWxHM0RUMnliR3pwTE1HRXoybU9TYWRHYXZyYitlamEvSnpIQTFiZ0FjL2dPWE91SGZPd0M4SXFUMHFPTXUvdGNIak02cjVKcHBKUT09IiwiYW1yIjpbInB3ZCIsIm1mYSJdLCJhcHBfZGlzcGxheW5hbWUiOiJNaWNyb3NvZnQgSW50dW5lIHBvcnRhbCBleHRlbnNpb24iLCJhcHBpZCI6IjU5MjZmYzhlLTMwNGUtNGY1OS04YmVkLTU4Y2E5N2NjMzlhNCIsImFwcGlkYWNyIjoiMiIsImNvbnRyb2xzIjpbImNhX2VuZiJdLCJmYW1pbHlfbmFtZSI6IkFuZGVyc3NvbiIsImdpdmVuX25hbWUiOiJKZW5zIiwiaWR0eXAiOiJ1c2VyIiwiaXBhZGRyIjoiODEuMTkxLjIwMC4xMDYiLCJuYW1lIjoiSmVucyBBbmRlcnNzb24iLCJvaWQiOiI0MzBiYWRiYi1mNGIwLTQ2MDQtYTczNS01NWU3YWUzMWIxZTMiLCJwbGF0ZiI6IjMiLCJwdWlkIjoiMTAwMzIwMDE5RTczRURBOCIsInJoIjoiMC5BVTRBclZwRlZ3OExFVXljVkd6UUgzSlE2NDc4SmxsT01GbFBpLTFZeXBmTU9hUk9BQ2suIiwic2NwIjoiQ2xvdWRQQy5SZWFkLkFsbCBDbG91ZFBDLlJlYWRXcml0ZS5BbGwgRGV2aWNlTWFuYWdlbWVudEFwcHMuUmVhZFdyaXRlLkFsbCBEZXZpY2VNYW5hZ2VtZW50Q29uZmlndXJhdGlvbi5SZWFkV3JpdGUuQWxsIERldmljZU1hbmFnZW1lbnRNYW5hZ2VkRGV2aWNlcy5Qcml2aWxlZ2VkT3BlcmF0aW9ucy5BbGwgRGV2aWNlTWFuYWdlbWVudE1hbmFnZWREZXZpY2VzLlJlYWRXcml0ZS5BbGwgRGV2aWNlTWFuYWdlbWVudFJCQUMuUmVhZFdyaXRlLkFsbCBEZXZpY2VNYW5hZ2VtZW50U2VydmljZUNvbmZpZ3VyYXRpb24uUmVhZFdyaXRlLkFsbCBEaXJlY3RvcnkuQWNjZXNzQXNVc2VyLkFsbCBlbWFpbCBvcGVuaWQgcHJvZmlsZSBTaXRlcy5SZWFkLkFsbCIsInN1YiI6IktVdFJrY2psNXU4Wm5wal9OUXpGWVZWNzhPSExZeVlrZnVRQUVGSkpPVkkiLCJ0ZW5hbnRfcmVnaW9uX3Njb3BlIjoiRVUiLCJ0aWQiOiI1NzQ1NWFhZC0wYjBmLTRjMTEtOWM1NC02Y2QwMWY3MjUwZWIiLCJ1bmlxdWVfbmFtZSI6IkplbnNAaXJvbnN0b25lbWFsLm9ubWljcm9zb2Z0LmNvbSIsInVwbiI6IkplbnNAaXJvbnN0b25lbWFsLm9ubWljcm9zb2Z0LmNvbSIsInV0aSI6InBLdGdjcXEwV0VHODJkR2IxY0RCQUEiLCJ2ZXIiOiIxLjAiLCJ3aWRzIjpbIjYyZTkwMzk0LTY5ZjUtNDIzNy05MTkwLTAxMjE3NzE0NWUxMCIsImI3OWZiZjRkLTNlZjktNDY4OS04MTQzLTc2YjE5NGU4NTUwOSJdLCJ4bXNfc3QiOnsic3ViIjoieS10dUhvcmQxU25qeTVDaHg5cVotTWFjTFEzNWp6RUdaX20yUWFIV0JKVSJ9LCJ4bXNfdGNkdCI6MTYzNTQxNTA2NX0.jTGyCs4T6JaKz3rqMlwXhbR6Mr8ZNA-xkOAU4j2LsvwTBFFyVqHueGNpzp2J0f0QCrNU4NaR32cddQes7FGDuBngS3cwfQzpwYIaQf6HzGQ9uxr7E_iF56Lj0HEdFv-XYNXNWjfTgpHTY1IFuRh1rRyO3daJ3BcdziYG06P4Iwfkpc9C-Su7_d0TRrKWVs2Ww27sXIvou5VK6c-70-uz5eGkq24M66i1lWG4_FA4ZWSSUXwo00aKlcce-EZsSHqYDV3BgrD2a2DpQ6DCdFiYo_2r9ga8Lfrfu-5eBQJ3WeMIccBIeNpkB5CUF5iKk15RecCA0c56DnedGiAbObmPPQ"
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization", $token)

Write-Output "Geting all security baseline templates on the tenant and then create variable with the one we care about"
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

<#
    The security baselines in the $allSecurityBaselineSettings variable here can be added to github
        and then be used to create the policy on any other customer tenant
#>
Write-Output "Found $($allSecurityBaselineSettings.Length) settings"

# ---------------------------------------------------------------------------------------------------------------------------------

<#
    CREATE NEW SECURITY BASELINE
        - To run this code you need the object or JSON from the $allSecurityBaselineSettings variable
            that you got from the script which fetches the baseline template
#>

<#
    Create a new instance of a security baseline
        - If we have a Microsoft security baseline that we work out of we are able to use this to deploy our own 
            version of it that might not contain all the recommended settings that Microsoft recommends.
#>
$createNewInstanceOfBaseline = "https://graph.microsoft.com/beta/deviceManagement/templates/$($securityBaselineObject.id)/createInstance"
$createNewInstanceOfBaselineBody = @{
    "displayName" = "TestJens2"
    "description" = ""
    "settingsDelta" = $allSecurityBaselineSettings
    "roleScopeTagIds" = @("0")
}
$createNewInstanceOfBaselineResponse = Invoke-RestMethod -Method 'POST' -Headers $headers -Uri $createNewInstanceOfBaseline `
                                                         -Body (ConvertTo-Json $createNewInstanceOfBaselineBody) -ContentType "application/json"

if($createNewInstanceOfBaselineResponse) {
    Write-Output "Created new baseline with name: '$($createNewInstanceOfBaselineResponse.displayName)'"
}

# ---------------------------------------------------------------------------------------------------------------------------------

<#
    THIS NEEDS TO BE TESTED!!
    UPGRADE BASELINE TO THE LATEST VERSION
        - This code updates the baseline to the latest version and keeps the changes that were made on the
            Microsoft version of the template when it was created.
#>

$upgradeBaselineUrl = "https://graph.microsoft.com/beta/deviceManagement/intents/$($securityBaselineObject.id)/migrateToTemplate"
$upgradeBaselineBody = @{
    "newTemplateId" = "034ccd46-190c-4afc-adf1-ad7cc11262eb"
    "preserveCustomValues" = $true
}

$upgradeBaselineResponse = Invoke-RestMethod -Method 'POST' -Headers $headers -Uri $upgradeBaselineUrl `
                                             -Body (ConvertTo-Json $upgradeBaselineBody) -ContentType "application/json"
