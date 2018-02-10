
<#

.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.

#>

####################################################

function Get-AuthToken {

    <#
.SYNOPSIS
This function is used to authenticate with the Graph API REST interface
.DESCRIPTION
The function authenticate with the Graph API Interface with the tenant name
.EXAMPLE
Get-AuthToken
Authenticates you with the Graph API interface
.NOTES
NAME: Get-AuthToken
#>

    [cmdletbinding()]

    param
    (
        [Parameter(Mandatory = $true)]
        $User
    )

    $userUpn = New-Object -TypeName 'System.Net.Mail.MailAddress' -ArgumentList $User

    $tenant = $userUpn.Host

    Write-Verbose -Message 'Checking for AzureAD module...'

    $AadModule = Get-Module -Name 'AzureAD' -ListAvailable

    if ($AadModule -eq $null) {

        Write-Verbose -Message 'AzureAD PowerShell module not found, looking for AzureADPreview'
        $AadModule = Get-Module -Name 'AzureADPreview' -ListAvailable

    }

    if ($AadModule -eq $null) {
        Write-Verbose -Message 'AzureAD Powershell module not installed...'
        Write-Verbose -Message "Install by running 'Install-Module AzureAD' or 'Install-Module AzureADPreview' from an elevated PowerShell prompt"
        Write-Verbose -Message "Script can't continue..."
        exit
    }

    # Getting path to ActiveDirectory Assemblies
    # If the module count is greater than 1 find the latest version

    if ($AadModule.count -gt 1) {

        $Latest_Version = ($AadModule | Select-Object -Property version | Sort-Object)[-1]

        $aadModule = $AadModule | Where-Object { $_.version -eq $Latest_Version.version }

        # Checking if there are multiple versions of the same module found

        if ($AadModule.count -gt 1) {

            $aadModule = $AadModule | Select-Object -Unique

        }

        $adal = Join-Path -Path $AadModule.ModuleBase -ChildPath 'Microsoft.IdentityModel.Clients.ActiveDirectory.dll'
        $adalforms = Join-Path -Path $AadModule.ModuleBase -ChildPath 'Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll'

    }

    else {

        $adal = Join-Path -Path $AadModule.ModuleBase -ChildPath 'Microsoft.IdentityModel.Clients.ActiveDirectory.dll'
        $adalforms = Join-Path -Path $AadModule.ModuleBase -ChildPath 'Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll'

    }

    [System.Reflection.Assembly]::LoadFrom($adal) | Out-Null

    [System.Reflection.Assembly]::LoadFrom($adalforms) | Out-Null

    $clientId = 'd1ddf0e4-d672-4dae-b554-9d5bdfd93547'

    $redirectUri = 'urn:ietf:wg:oauth:2.0:oob'

    $resourceAppIdURI = 'https://graph.microsoft.com'

    $authority = ('https://login.microsoftonline.com/{0}' -f $Tenant)

    try {

        $authContext = New-Object -TypeName 'Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext' -ArgumentList $authority

        # https://msdn.microsoft.com/en-us/library/azure/microsoft.identitymodel.clients.activedirectory.promptbehavior.aspx
        # Change the prompt behaviour to force credentials each time: Auto, Always, Never, RefreshSession

        $platformParameters = New-Object -TypeName 'Microsoft.IdentityModel.Clients.ActiveDirectory.PlatformParameters' -ArgumentList 'Auto'

        $userId = New-Object -TypeName 'Microsoft.IdentityModel.Clients.ActiveDirectory.UserIdentifier' -ArgumentList ($User, 'OptionalDisplayableId')

        $authResult = $authContext.AcquireTokenAsync($resourceAppIdURI, $clientId, $redirectUri, $platformParameters, $userId).Result

        # If the accesstoken is valid then create the authentication header

        if ($authResult.AccessToken) {

            # Creating header for Authorization token

            $authHeader = @{
                'Content-Type'  = 'application/json'
                'Authorization' = 'Bearer ' + $authResult.AccessToken
                'ExpiresOn'     = $authResult.ExpiresOn
            }

            return $authHeader

        }

        else {

            Write-Verbose -Message 'Authorization Access Token is null, please re-run authentication...'
            break

        }

    }

    catch {

        Write-Verbose -Message $_.Exception.Message
        Write-Verbose -Message $_.Exception.ItemName
        break

    }

}

####################################################

Function Get-DeviceConfigurationPolicy() {

    <#
.SYNOPSIS
This function is used to get device configuration policies from the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and gets any device configuration policies
.EXAMPLE
Get-DeviceConfigurationPolicy
Returns any device configuration policies configured in Intune
.NOTES
NAME: Get-DeviceConfigurationPolicy
#>

    [cmdletbinding()]

    param
    (
        $name
    )

    $graphApiVersion = 'v1.0'
    $DCP_resource = 'deviceManagement/deviceConfigurations'

    try {

        if ($Name) {

            $uri = ('https://graph.microsoft.com/{0}/{1}' -f $graphApiVersion, ($DCP_resource))
            (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value | Where-Object { ($_.'displayName').contains(('{0}' -f $Name)) }

        }

        else {

            $uri = ('https://graph.microsoft.com/{0}/{1}' -f $graphApiVersion, ($DCP_resource))
            (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value

        }

    }

    catch {

        $ex = $_.Exception
        $errorResponse = $ex.Response.GetResponseStream()
        $reader = New-Object -TypeName System.IO.StreamReader -ArgumentList ($errorResponse)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd()

        Write-Verbose -Message ("Response content:`n{0}" -f $responseBody)
        Write-Error -Message ('Request to {0} failed with HTTP Status {1} {2}' -f $Uri, $ex.Response.StatusCode, $ex.Response.StatusDescription)
        break

    }

}

####################################################

Function Get-DeviceConfigurationPolicyAssignment() {

    <#
.SYNOPSIS
This function is used to get device configuration policy assignment from the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and gets a device configuration policy assignment
.EXAMPLE
Get-DeviceConfigurationPolicyAssignment $id guid
Returns any device configuration policy assignment configured in Intune
.NOTES
NAME: Get-DeviceConfigurationPolicyAssignment
#>

    [cmdletbinding()]

    param
    (
        [Parameter(Mandatory = $true, HelpMessage = 'Enter id (guid) for the Device Configuration Policy you want to check assignment')]
        $id
    )

    $graphApiVersion = 'v1.0'
    $DCP_resource = 'deviceManagement/deviceConfigurations'

    try {

        $uri = ('https://graph.microsoft.com/{0}/{1}/{2}/Assignments' -f $graphApiVersion, ($DCP_resource), $id)
        (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value

    }

    catch {

        $ex = $_.Exception
        $errorResponse = $ex.Response.GetResponseStream()
        $reader = New-Object -TypeName System.IO.StreamReader -ArgumentList ($errorResponse)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd()

        Write-Verbose -Message ("Response content:`n{0}" -f $responseBody)
        Write-Error -Message ('Request to {0} failed with HTTP Status {1} {2}' -f $Uri, $ex.Response.StatusCode, $ex.Response.StatusDescription)
        break

    }

}

####################################################

Function Get-AADGroup() {

    <#
.SYNOPSIS
This function is used to get AAD Groups from the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and gets any Groups registered with AAD
.EXAMPLE
Get-AADGroup
Returns all users registered with Azure AD
.NOTES
NAME: Get-AADGroup
#>

    [cmdletbinding()]

    param
    (
        $GroupName,
        $id,
        [switch]$Members
    )

    # Defining Variables
    $graphApiVersion = 'v1.0'
    $Group_resource = 'groups'

    try {

        if ($id) {

            $uri = ("https://graph.microsoft.com/{0}/{1}?`$filter=id eq '{2}'" -f $graphApiVersion, ($Group_resource), $id)
            (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value

        }

        elseif ($GroupName -eq '' -or $GroupName -eq $null) {

            $uri = ('https://graph.microsoft.com/{0}/{1}' -f $graphApiVersion, ($Group_resource))
            (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value

        }

        else {

            if (!$Members) {

                $uri = ("https://graph.microsoft.com/{0}/{1}?`$filter=displayname eq '{2}'" -f $graphApiVersion, ($Group_resource), $GroupName)
                (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value

            }

            elseif ($Members) {

                $uri = ("https://graph.microsoft.com/{0}/{1}?`$filter=displayname eq '{2}'" -f $graphApiVersion, ($Group_resource), $GroupName)
                $Group = (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value

                if ($Group) {

                    $GID = $Group.id

                    $Group.displayName

                    $uri = ('https://graph.microsoft.com/{0}/{1}/{2}/Members' -f $graphApiVersion, ($Group_resource), $GID)
                    (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value

                }

            }

        }

    }

    catch {

        $ex = $_.Exception
        $errorResponse = $ex.Response.GetResponseStream()
        $reader = New-Object -TypeName System.IO.StreamReader -ArgumentList ($errorResponse)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd()

        Write-Verbose -Message ("Response content:`n{0}" -f $responseBody)
        Write-Error -Message ('Request to {0} failed with HTTP Status {1} {2}' -f $Uri, $ex.Response.StatusCode, $ex.Response.StatusDescription)
        break

    }

}

####################################################

#region Authentication

# Checking if authToken exists before running authentication
if ($global:authToken) {

    # Setting DateTime to Universal time to work in all timezones
    $DateTime = (Get-Date).ToUniversalTime()

    # If the authToken exists checking when it expires
    $TokenExpires = ($authToken.ExpiresOn.datetime - $DateTime).Minutes

    if ($TokenExpires -le 0) {

        Write-Verbose -Message 'Authentication Token expired'

        # Defining User Principal Name if not present

        if ($User -eq $null -or $User -eq '') {

            $User = Read-Host -Prompt 'Please specify your user principal name for Azure Authentication'

        }

        $global:authToken = Get-AuthToken -User $User

    }
}

# Authentication doesn't exist, calling Get-AuthToken function

else {

    if ($User -eq $null -or $User -eq '') {

        $User = Read-Host -Prompt 'Please specify your user principal name for Azure Authentication'

    }

    # Getting the authorization token
    $global:authToken = Get-AuthToken -User $User

}

#endregion

####################################################

$DCPs = Get-DeviceConfigurationPolicy

[array]$Output = $null
foreach ($DCP in $DCPs) {
    
    [array]$Assignments = Get-DeviceConfigurationPolicyAssignment -id $DCP.id
    [array]$AssignedToGroups = $null
    if ($Assignments) {
        foreach ($Assignment in $Assignments) {
            #Write-Output "group"
            #Write-output -InputObject $group
            $GroupInfo = Get-AADGroup -id $Assignment.target.GroupId
            $GroupInfoobject = @{
                'GroupID'     = $GroupInfo.id
                'displayName' = $GroupInfo.displayName
            }
            $object = New-Object -TypeName PSObject -Property $GroupInfoobject
            $AssignedToGroups += $object
        }
    }
    else {
        $AssignedToGroups += 'None'
    }

    $DCP | Add-Member -NotePropertyName AssignedToGroups -NotePropertyValue $AssignedToGroups -force
    $Output += $DCP 
}

return $Output