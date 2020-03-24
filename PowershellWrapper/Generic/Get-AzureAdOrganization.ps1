Function Get-AzureADOrganization() {

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
        [Parameter(Mandatory = $true, HelpMessage = 'Enter tenantid (guid) for the tenant')]
        $tenantid
    )

    $graphApiVersion = 'v1.0'
    $DCP_resource = 'organization'

    try {

        $uri = ('https://graph.microsoft.com/{0}/{1}' -f $graphApiVersion, ($DCP_resource))
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