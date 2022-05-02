<#
.SYNOPSIS
This script copies the security base line from one tenant to another

.DESCRIPTION
For this to you work you need to have an Azure AD Application in both the source and destination
tenant. The Azure AD Application need to have the permissions which you have stated in the
$NeededScopes variable. The current scopes are based on that you want to first export a baseline
and then import this baseline into another tenant.
#>
Param (
    [Parameter(HelpMessage = '[COPY FROM] ID for the Azure AD Application with access to Intune')]
    [String][ValidateNotNullOrEmpty()]$CopyFrom_ApplicationID = "03294f6a-e59f-46e6-9505-2a3e8c4f72e5",

    [Parameter(HelpMessage = '[COPY FROM] Key for the Azure AD Application with access to Intune')]
    [String][ValidateNotNullOrEmpty()]$CopyFrom_ApplicationKey = "9Kp8Q~.N3y~NZzS9sOOtaCyxPZG15KzuspTyAaa8",

    [Parameter(HelpMessage = '[COPY FROM] Tenant ID where the Azure AD Application resides')]
    [String][ValidateNotNullOrEmpty()]$CopyFrom_TenantID = "3eaaf1d3-6f9e-40fd-b7e9-60b45e55e125",

    [Parameter(HelpMessage = '[COPY TO] ID for the Azure AD Application with access to Intune')]
    [String][ValidateNotNullOrEmpty()]$CopyTo_ApplicationID = "03294f6a-e59f-46e6-9505-2a3e8c4f72e5",

    [Parameter(HelpMessage = '[COPY TO] Key for the Azure AD Application with access to Intune')]
    [String][ValidateNotNullOrEmpty()]$CopyTo_ApplicationKey = "9Kp8Q~.N3y~NZzS9sOOtaCyxPZG15KzuspTyAaa8",

    [Parameter(HelpMessage = '[COPY TO] Tenant ID where the Azure AD Application resides')]
    [String][ValidateNotNullOrEmpty()]$CopyTo_TenantID = "3eaaf1d3-6f9e-40fd-b7e9-60b45e55e125",

    [Parameter(HelpMessage = 'Scopes needed for on the tokens')]
    [String][ValidateNotNullOrEmpty()]$NeededScopes = "CloudPC.Read.All CloudPC.ReadWrite.All DeviceManagementApps.ReadWrite.All DeviceManagementConfiguration.ReadWrite.All DeviceManagementManagedDevices.PrivilegedOperations.All DeviceManagementManagedDevices.ReadWrite.All DeviceManagementRBAC.ReadWrite.All DeviceManagementServiceConfig.ReadWrite.All Directory.AccessAsUser.All email openid profile Sites.Read.All",
    
    [Parameter(HelpMessage = 'Name of the assignment you want to export')]
    [String][ValidateNotNullOrEmpty()]$SecurityBaselineTemplateName = "MDM Security Baseline for Windows 10 and later for November 2021",

    [Parameter(HelpMessage = 'Name of the assignment you want to export')]
    [String][ValidateNotNullOrEmpty()]$SecurityBaselineAssignmentName = "TestProfilByJens", #"CW 2.0 - Security Baseline"

    [Parameter(HelpMessage = 'Export the settings as a json-file to your desktop? ($true=yes | $false=no)')]
    [bool][ValidateNotNullOrEmpty()]$ExportToDesktop = $true
)

<#
.HISTORY
Most of this script was taken from: https://www.lee-ford.co.uk/getting-started-with-microsoft-graph-with-powershell/
and were then rewritten to fit the purpose that we need to accomplish

.SYNOPSIS
This is a function which will let the user login to get the AuthN code and then exchange this code for a AuthZ token where we get the
permissions/access requested. One thing to understand is that there are several permissions that are not able to acquire from this flow
that you will have to get from an unattended Application permission. Application permissions first needs to be granted by an admin through
the admin consent flow and then you will be able to get the token without any login from the user. You can see on the permission on the
application in Azure AD if you need Application permission or if Delegated permissions is enough (Azure AD -> App Registrations -> API permissions ->
Add permission -> Find the permission under Delegated or Application permissions.
If you want unattended access to a permission you need to use the function AdminConsent and then you are able to get the token from a
REST call to the default endpoint: "https://graph.microsoft.com/.default". You use the default endpoint because you will always get the
full set of permissions when you request unattended Application permissions for your we application.

.DEPENDENCIES
If you want to use this code you need to add the following redirect uri to the application: Web - https://login.microsoftonline.com/common/oauth2/nativeclient

.EXAMPLES
Get a token for Microsoft Graph that have access to read and write on the Azure AD directory, also show me all the browser URLs as we get the AuthN code and AuthZ token
$token = Get-DelegatedAccessToken -applicationId $applicationId -applicationKey $applicationKey -tenantId $tenantId -scope "https://graph.microsoft.com/Directory.ReadWrite.All" -debugBrowser $true
#>
function Get-DelegatedAccessToken() {
    param(
        [parameter(Mandatory = $false, HelpMessage = "The application ID of the application that will be used to authenticate to Azure AD. Example: c7a00ba1-71fa-42ed-9d45-fc42a4bfa4ef")]
        [string]$applicationId, 

        [parameter(Mandatory = $false, HelpMessage = "The key that have been created for the application in Azure AD")]
        [string]$applicationKey, 

        [parameter(Mandatory = $false, HelpMessage = "The tenant ID of the tenant where you would like to authenticate against. If you want to use the common endpoint you type Common here. Example: 491e8cc4-2204-4312-8565-17f85046df01 or Common")]
        [string]$tenantId,

        [parameter(Mandatory = $false, HelpMessage = "The scope you would like to aqcuire a token for. You can add more than one scope by adding a space between the scopes. Example: `"User.Read.All Group.Read.All`"")]
        [string]$scope,

        [parameter(Mandatory = $false, HelpMessage = "[OPTIONAL]: Indicates the type of user interaction that is required. The only valid values at this time are 'login', 'none', 'select_account', and 'consent'. prompt=login will force the user to enter their credentials on that request, negating single-sign on. prompt=none is the opposite - it will ensure that the user isn't presented with any interactive prompt whatsoever. If the request can't be completed silently via single-sign on, the Microsoft identity platform endpoint will return an error. prompt=select_account sends the user to an account picker where all of the accounts remembered in the session will appear. prompt=consent will trigger the OAuth consent dialog after the user signs in, asking the user to grant permissions to the app.")]
        [string]$prompt = "select_account",

        [parameter(Mandatory = $false, HelpMessage = "[OPTIONAL]: If true you will get information about each update of the browser window during a login procedure")]
        [bool]$debugBrowser = $false
    )

    # Variables:
    # This is only used when we get an auth code but still have a problem because the application have not been given the correct permissions in Azure AD
    # Using $script: so that we can reach this variable from within the event handler
    $script:invalidGrant = $false 

    # Add required assemblies to create windows for loggin in using Azure AD
    Add-Type -AssemblyName System.Web, PresentationFramework, PresentationCore

    # Redirect uri needs to be set on the application in Azure AD: Azure AD --> Application --> Authentication --> Redirect URIs --> Add Type:Web RedirectUri: https://login.microsoftonline.com/common/oauth2/nativeclient
    # This needs to be done when you are using a native application (PowerShell) to get the token, otherwise you would be blocked.
    # If you are using a web application you will ahve to add its redirect uris to the list of uris at the same place and then change this redirect uri in the code to the web applications uri
    $redirectUri = "https://login.microsoftonline.com/common/oauth2/nativeclient"

    # Random State - state is included in response, if you want to verify response is valid
    $state = Get-Random

    # Encode scope to fit inside query string 
    $scopeEncoded = [System.Web.HttpUtility]::UrlEncode($scope)

    # Redirect URI (encode it to fit inside query string)
    $redirectUriEncoded = [System.Web.HttpUtility]::UrlEncode($redirectUri)

    # Create Window for User Sign-In
    $signInWindow = New-Object System.Windows.Window -Property @{ Width = 500; Height = 700 }
    
    # Create WebBrowser for Window
    $signInBrowser = New-Object System.Windows.Controls.WebBrowser -Property @{ Width = 480; Height = 680 }

    # Construct URI for requesting individual user consent: https://docs.microsoft.com/en-us/azure/active-directory/develop/v2-permissions-and-consent#requesting-individual-user-consent
    $uri = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/authorize?client_id=$applicationId&response_type=code&redirect_uri=$redirectUriEncoded&response_mode=query&scope=$scopeEncoded&state=$state&prompt=$prompt"

    # Navigate Browser to sign-in page for "requesting individual user consent"
    $signInBrowser.navigate($uri)
    
    # Create a condition to check after each page is loaded
    $pageLoaded = {
        # Once a URL contains "code=*", close the Window
        if ($signInBrowser.Source -match "code=[^&]*") {
            # With the form closed and complete with the code, parse the query string
            $urlQueryString = [System.Uri]($signInBrowser.Source).Query
            $script:urlQueryValues = [System.Web.HttpUtility]::ParseQueryString($urlQueryString)
            $signInWindow.Close()
        }

        # Check if the browser throws and error telling us that the application have not been given the correct permissions in Azure AD
        # Example:
        # We would get the applicationName "JensApp" and requiredScope "EduAssignments.ReadBasic.All" from:
        # "https://login.microsoftonline.com/common/oauth2/nativeclient?error=invalid_client&error_description=AADSTS650053:+The+application+'Harmonia'+asked+for+scope+'EduAssignments.ReadBasic.All'+that+doesn't+exist+on+the+resource+'00000003-0000-0000-c000-000000000000'.+Contact+the+app+vendor.%0d%0aTrace+ID:+80577df3-7237-4d1e-8c6b-85418cdb1600%0d%0aCorrelation+ID:+7f9da576-2348-4a06-9144-e070e1a0d9e5%0d%0aTimestamp:+2019-07-10+09:03:30Z&state=1098743132Query:?error=invalid_client&error_description=AADSTS650053%3a+The+application+%27Harmonia%27+asked+for+scope+%27EduAssignments.ReadBasic.All%27+that+doesn%27t+exist+on+the+resource+%2700000003-0000-0000-c000-000000000000%27.+Contact+the+app+vendor.%0d%0aTrace+ID%3a+80577df3-7237-4d1e-8c6b-85418cdb1600%0d%0aCorrelation+ID%3a+7f9da576-2348-4a06-9144-e070e1a0d9e5%0d%0aTimestamp%3a+2019-07-10+09%3a03%3a30Z&state=1098743132"
        if ($signInBrowser.Source -like "*AADSTS650053:+The+application+'*'+asked+for+scope+'*'+that+doesn't+exist+on+the+resource*") {
            $applicationName = [regex]::match($signInBrowser.Source, "AADSTS650053:\+The\+application\+\'(.*?)\'\+asked\+for\+scope\+").Groups[1].Value
            $requiredScope = [regex]::match($signInBrowser.Source, "\+asked\+for\+scope\+\'(.*?)\'\+that\+doesn\'t\+exist\+on\+the\+resource").Groups[1].Value
            Write-Host "AADSTS650053: The application $($applicationName) have not been given the scope $($requiredScope) in Azure AD. Please modify the application and retry getting the token." -ForegroundColor Yellow
            $signInWindow.Close()
            $script:invalidGrant = $true
        }
                        
        # If $debug is set to $true information about the browser will be shown at every update.
        if ($debugBrowser) {
            Write-Host "Browser Intformation:`nBrowser Source: $($signInBrowser.Source)`nQuery:$([System.Uri]($signInBrowser.Source).Query)`nParsed Query: $([System.Web.HttpUtility]::ParseQueryString($urlQueryString))" -ForegroundColor Yellow
        }
    }

    # Add condition to document completed
    $signInBrowser.Add_LoadCompleted($pageLoaded)

    # Add the browser to the window
    $signInWindow.AddChild($signInBrowser)
    
    # Show the window: Using this code because it otherwise crashes: https://gist.github.com/altrive/6227237
    $async = $signInWindow.Dispatcher.InvokeAsync({
            $signInWindow.ShowDialog() | Out-Null
        })
    $async.Wait() | Out-Null
    #$signInWindow.ShowDialog() | Out-Null # Out-Null to prevent that this window returns a bool that contaminates the output from the function

    # Extract code from query string
    $authCode = $script:urlQueryValues.GetValues(($script:urlQueryValues.keys | Where-Object { $_ -eq "code" }))

    # Checking if we got an error because the application haven't been given the correct permissions in Azure AD
    # if not we proceed with getting the token from trading the auth code
    if (!$invalidGrant) {
        # With Authorization Code we trade this for a Access Token
        if (![string]::IsNullOrEmpty($authCode)) {
            # Get OAuth 2.0 Token from the Azure AD token endpoint
            $tokenRequest = Invoke-WebRequest -Method Post `
                -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" `
                -ContentType "application/x-www-form-urlencoded" `
                -Body @{
                client_id     = $applicationId
                client_secret = $applicationKey
                scope         = $scope
                code          = $authCode[0]
                redirect_uri  = $redirectUri
                grant_type    = "authorization_code"
            }

            # Return the Access token that we received from the token endpoint
            $token = ($tokenRequest.Content | ConvertFrom-Json)
            return $token

        }
        else {
            Write-Error "Unable to obtain Auth Code!"
        }
    }
}



<#
Creates a dictionary containing a Authorization header that you can use on REST requests

Example
Key           Value
---           -----
Authorization Bearer eyJ0eXAiOiJKV1QiLCJub25jZSI6Ijdw
#>
function CreateAuthorizationHeader() {
    param(
        [parameter(Mandatory = $false, HelpMessage = "The type of token you want to create the header for (Bearer, Basic)")]
        [string]$TokenType = "Bearer",

        [parameter(Mandatory = $true, HelpMessage = "The token string you want to add to the Authorization header")]
        [string]$TokenString
    )
    return @{"Authorization" = "$TokenType $TokenString" }
}

<#
Returns a security baseline template for the template name you define
#>
function Get-SecurityBaselineTemplate() {
    param(
        [parameter(Mandatory = $false, HelpMessage = "Name of the security baseline template you want to fetch")]
        [string]$SecurityBaselineTemplateName = "MDM Security Baseline for Windows 10 and later for Decemeber 2020",

        [parameter(Mandatory = $true, HelpMessage = "Headers object containing a valid Authorization header and token. This is created using CreateAuthorizationHeader()")]
        [HashTable]$Headers
    )

    $getSecurityBaselineTemplates = "https://graph.microsoft.com/beta/deviceManagement/templates"
    $getSecurityBaselineTemplatesResponse = Invoke-RestMethod  -Method 'GET' -Headers $Headers -Uri $getSecurityBaselineTemplates
    $allSeurityBaselineTemplates = $getSecurityBaselineTemplatesResponse.value
    $securityBaselineObject = $allSeurityBaselineTemplates.Where{ $_.displayName -eq $SecurityBaselineTemplateName }

    return $securityBaselineObject
}

<#
Returns available categories from the choosen security baseline template
#>
function Get-SecurityBaselineTemplateCategories() {
    param(
        [parameter(Mandatory = $true, HelpMessage = "Security baseline template object fetched from Get-SecurityBaselineTemplate()")]
        [PSCustomObject]$SecurityBaselineTemplateObject,

        [parameter(Mandatory = $true, HelpMessage = "Headers object containing a valid Authorization header and token. This is created using CreateAuthorizationHeader()")]
        [HashTable]$Headers
    )

    $getSecurityBaselineCategories = "https://graph.microsoft.com/beta/deviceManagement/templates/$($SecurityBaselineTemplateObject.id)/categories"
    $getSecurityBaselineCategoriesResponse = Invoke-RestMethod  -Method 'GET' -Headers $Headers -Uri $getSecurityBaselineCategories
    $securityBaselineCategories = $getSecurityBaselineCategoriesResponse.value

    return $securityBaselineCategories
}

<#
Returns a security baseline intent (assignment) of the security baseline that is choosen
#>
function Get-SecurityBaselineTemplateIntent() {
    param(
        [parameter(Mandatory = $true, HelpMessage = "Security baseline template object fetched from Get-SecurityBaselineTemplate()")]
        [PSCustomObject]$SecurityBaselineTemplateObject,

        [parameter(Mandatory = $false, HelpMessage = "Name of the Security Baseline assignment you want to fetch")]
        [string]$SecurityBaselineAssignmentName = "MDM Security Baseline for Windows 10 and later for Decemeber 2020",

        [parameter(Mandatory = $true, HelpMessage = "Headers object containing a valid Authorization header and token. This is created using CreateAuthorizationHeader()")]
        [HashTable]$Headers
    )

    $getIntents = "https://graph.microsoft.com/beta/deviceManagement/intents"
    $getIntentsResponse = Invoke-RestMethod -Method 'GET' -Headers $Headers -Uri $getIntents
    $allIntents = $getIntentsResponse.value
    $selecedBaselineIntent = $allIntents.where{ $_.templateId -eq $SecurityBaselineTemplateObject.id -and $_.displayName -eq $SecurityBaselineAssignmentName }
    Write-Verbose "Found $($selecedBaselineIntent.displayName)"

    return $selecedBaselineIntent
}

<#
Returns all settings on a specific intent (assignment)
The variable returned can be added to github and then be used to create the policy on any other customer tenant
More info: https://docs.microsoft.com/en-us/graph/api/resources/intune-deviceintent-devicemanagementintent?view=graph-rest-beta
#>
function Get-SecurityBaselineIntentSettings() {
    param(
        [parameter(Mandatory = $true, HelpMessage = "Security baseline intent object fetched from Get-SecurityBaselineTemplateIntents()")]
        [PSCustomObject]$SecurityBaselineIntentObject,

        [parameter(Mandatory = $true, HelpMessage = "Security baseline template categories array fetched from Get-SecurityBaselineTemplateCategories()")]
        [PSCustomObject[]]$SecurityBaselineCategories,

        [parameter(Mandatory = $true, HelpMessage = "Headers object containing a valid Authorization header and token. This is created using CreateAuthorizationHeader()")]
        [HashTable]$Headers
    )

    $allSecurityBaselineSettings = @()
    foreach ($securityBaselineCategory in $SecurityBaselineCategories) {
        $getSetting = "https://graph.microsoft.com/beta/deviceManagement/intents/$($SecurityBaselineIntentObject.id)/categories/$($securityBaselineCategory.id)/settings"
        $getSettingResponse = Invoke-RestMethod  -Method 'GET' -Headers $Headers -Uri $getSetting
        $allSecurityBaselineSettings += $getSettingResponse.value
    }

    return $allSecurityBaselineSettings
}

<#
Create a new instance of a security baseline
#>
function New-SecurityBaseline() {
    param(
        [parameter(Mandatory = $true, HelpMessage = "Security baseline template object fetched from Get-SecurityBaselineTemplate()")]
        [PSCustomObject]$SecurityBaselineTemplateObject,

        [parameter(Mandatory = $true, HelpMessage = "Security baseline intent settings fetched from Get-SecurityBaselineIntentSettings()")]
        [PSCustomObject[]]$SecurityBaselineIntentSettings,

        [parameter(Mandatory = $true, HelpMessage = "Name of the Security Baseline assignment you want to create")]
        [string]$NewSecurityBaselineName,

        [parameter(Mandatory = $true, HelpMessage = "Headers object containing a valid Authorization header and token. This is created using CreateAuthorizationHeader()")]
        [HashTable]$Headers
    )

    $createNewInstanceOfBaseline = "https://graph.microsoft.com/beta/deviceManagement/templates/$($SecurityBaselineTemplateObject.id)/createInstance"
    $createNewInstanceOfBaselineBody = @{
        "displayName"     = $NewSecurityBaselineName
        "description"     = "Created automatically using Ironstone Cloud Workforce"
        "settingsDelta"   = $SecurityBaselineIntentSettings
        "roleScopeTagIds" = @("0")
    }
    $createNewInstanceOfBaselineResponse = Invoke-RestMethod -Method 'POST' -Headers $Headers -Uri $createNewInstanceOfBaseline `
        -Body (ConvertTo-Json $createNewInstanceOfBaselineBody) -ContentType "application/json"
    
    if ($createNewInstanceOfBaselineResponse) {
        Write-Verbose -Message "Created new baseline with name: '$($createNewInstanceOfBaselineResponse.displayName)'"
    }

    return $createNewInstanceOfBaselineResponse
}

<#
    Returning all the valuaes set by the script
    This is helpful when debugging
#>
function Get-CurrentParameters() {
    param()
    Write-Output "CURRENTLY SET PARAMETERS"
    Write-Output "----------------------------------------------------"
    Write-Output "`$CopyFrom_ApplicationID = '$CopyFrom_ApplicationID'"
    Write-Output "`$CopyFrom_ApplicationKey = '$CopyFrom_ApplicationKey'"
    Write-Output "`$CopyFrom_TenantID = '$CopyFrom_TenantID'"
    Write-Output "`$CopyTo_ApplicationID = '$CopyTo_ApplicationID'"
    Write-Output "`$CopyTo_ApplicationKey = '$CopyTo_ApplicationKey'"
    Write-Output "`$CopyTo_TenantID = '$CopyTo_TenantID'"
    Write-Output "`$NeededScopes = '$NeededScopes'"
    Write-Output "`$SecurityBaselineTemplateName = '$SecurityBaselineTemplateName'"
    Write-Output "----------------------------------------------------"
    Write-Output ""
    Write-Output ""
}

<#
Prints to output or to host depending on the variable
#>
function Write-Console() {
    param(
        [parameter(Mandatory = $false, HelpMessage = "output = print to output using Write-Output | host = print to host using yellow collor")]
        [string]$PrintToOutputOrHost = "host",

        [parameter(Mandatory = $true, HelpMessage = "string you want to print to the console")]
        [string]$Message,

        [parameter(Mandatory = $false, HelpMessage = "if set, this will add the text to the same line as the previous output")]
        [switch]$NoNewLine
    )

    if ($PrintToOutputOrHost -eq "output") {
        Write-Output $Message
    }
    else {
        if ($NoNewLine) {
            Write-Host $Message -ForegroundColor "Yellow" -NoNewline
        }
        else {
            Write-Host $Message -ForegroundColor "Yellow"
        }
    }
}

<#
Exports the security baseline settings to the desktop as a JSON-file
#>
function Export-SecurityBaseline() {
    param(
        [parameter(Mandatory = $true, HelpMessage = "Security baseline settings fetched from Get-SecurityBaselineIntentSettings()")]
        [PSCustomObject]$SecurityBaselineSettings
    )

    $filePath = "$([Environment]::GetFolderPath("Desktop"))\EndpointManagerSettings.json"
    $securitySettingsAsJSON = ConvertTo-Json -InputObject $allSecurityBaselineSettings -Depth 100
    Set-Content -Value $securitySettingsAsJSON -Path $filePath -Force

    return $filePath
}

#################################################
# SCRIPT START
#################################################
Clear-Host
Get-CurrentParameters
Write-Console -Message "[INFO] Please login with a user from the SOURCE tenant '$($CopyFrom_TenantID)'"
$tokens = Get-DelegatedAccessToken -applicationId $CopyFrom_ApplicationID -applicationKey $CopyFrom_ApplicationKey `
    -tenantId $CopyFrom_TenantID -scope $NeededScopes
$headers = CreateAuthorizationHeader -TokenType $tokens.token_type -TokenString $tokens.access_token

#################################################
# EXPORTING SECURITY BASELINE FROM MASTER TENANT
#################################################
Write-Console -Message "[INFO] Fetching all security baseline templates on the tenant and then creating variable with the one we care about" -NoNewLine
$securityBaselineTemplateObject = Get-SecurityBaselineTemplate -SecurityBaselineTemplateName $SecurityBaselineTemplateName -Headers $headers
Write-Console -Message "            [DONE]"

Write-Console -Message "[INFO] Getting all the settings available on the selected security baseline" -NoNewLine
$securityBaselineCategories = Get-SecurityBaselineTemplateCategories -SecurityBaselineTemplateObject $securityBaselineTemplateObject -Headers $headers
Write-Console -Message "                                                    [DONE]: Found $($securityBaselineCategories.Length) categories"

Write-Console -Message "[INFO] Getting the intents (assignments) of the security baseline we have selected" -NoNewLine
$securityBaselineIntent = Get-SecurityBaselineTemplateIntent -SecurityBaselineTemplateObject $securityBaselineTemplateObject `
    -SecurityBaselineAssignmentName $SecurityBaselineAssignmentName `
    -Headers $headers
Write-Console -Message "                                             [DONE]: Found $($securityBaselineIntent.displayName)"

Write-Output ""
Write-Console -Message "[ATTENTION] This will take a little while..."
Write-Console -Message "[INFO] Getting all settings for the intent (baseline assignment)" -NoNewLine
# The security baselines in the $allSecurityBaselineSettings variable here can be added to github and then be used to create the policy on any other customer tenant
$allSecurityBaselineSettings = Get-SecurityBaselineIntentSettings -SecurityBaselineIntentObject $securityBaselineIntent `
    -SecurityBaselineCategories $securityBaselineCategories `
    -Headers $headers
Write-Console -Message "                                                               [DONE]: Found $($allSecurityBaselineSettings.Length) settings"

#################################################
# EXPORTING SETTINGS TO FILE
#################################################

# Exporting the settings as a JSON-file which is placed on the desktop
if ($ExportToDesktop) {
Write-Console -Message "[INFO] Exporting settings as file to desktop" -NoNewLine
    $filePath = Export-SecurityBaseline -SecurityBaselineSettings $allSecurityBaselineSettings
    Write-Console -Message "                                                                                   [DONE]: File location: '$filePath'"
}

#################################################
# IMPORTING SECURITY BASELINE TO DESTINATION
#################################################

Write-Output ""
Write-Console -Message "[INFO] Please login with a user from the DESTINATION tenant '$($CopyTo_TenantID)'"
$tokens = Get-DelegatedAccessToken -applicationId $CopyTo_ApplicationID -applicationKey $CopyTo_ApplicationKey `
    -tenantId $CopyTo_TenantID -scope $NeededScopes
$headers = CreateAuthorizationHeader -TokenType $tokens.token_type -TokenString $tokens.access_token

# Getting the settings from the previously exported JSON file
if ($ExportToDesktop) {
    Write-Console -Message "[INFO] Getting security baseline settings from JSON-file" -NoNewLine
    $allSecurityBaselineSettingsAsJson = Get-Content $filePath
    $allSecurityBaselineSettings = ConvertFrom-Json $allSecurityBaselineSettingsAsJson -Depth 100
    Write-Console -Message "                                                                       [DONE]: Fetched from '$filePath'"
}

Write-Console -Message "[INFO] Creating new security baseline on the DESTINATION tenant" -NoNewLine
$newSecurityBaseline = New-SecurityBaseline -SecurityBaselineTemplateObject $securityBaselineTemplateObject `
    -SecurityBaselineIntentSettings $allSecurityBaselineSettings `
    -Headers $headers `
    -NewSecurityBaselineName "$($securityBaselineIntent.displayName)-copy"
Write-Console -Message "                                                                [DONE]"

#################################################
# FINISHED!
#################################################
# ---------------------------------------------------------------------------------------------------------------------------------

#################################################
# UNDER DEVELOPMENT
#################################################
<#
    THIS NEEDS TO BE TESTED!!
    UPGRADE BASELINE TO THE LATEST VERSION
        - This code updates the baseline to the latest version and keeps the changes that were made on the
            Microsoft version of the template when it was created.
#>
<#
$upgradeBaselineUrl = "https://graph.microsoft.com/beta/deviceManagement/intents/$($securityBaselineObject.id)/migrateToTemplate"
$upgradeBaselineBody = @{
    "newTemplateId"        = "034ccd46-190c-4afc-adf1-ad7cc11262eb"
    "preserveCustomValues" = $true
}

$upgradeBaselineResponse = Invoke-RestMethod -Method 'POST' -Headers $headers -Uri $upgradeBaselineUrl `
    -Body (ConvertTo-Json $upgradeBaselineBody) -ContentType "application/json"
#>