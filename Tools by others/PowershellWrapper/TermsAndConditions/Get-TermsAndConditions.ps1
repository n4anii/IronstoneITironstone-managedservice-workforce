Function Get-TermsAndConditions() {

    <#
.SYNOPSIS
This function is used to get the Get Terms And Conditions intune resource from the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and gets the Terms and Conditions Intune Resource
.EXAMPLE
Get-TermsAndConditions
Returns the Organization resource configured in Intune
.NOTES
NAME: Get-TermsAndConditions
#>

    [cmdletbinding()]

    param
    (
        $Name
    )

    $graphApiVersion = 'Beta'
    $resource = 'deviceManagement/termsAndConditions'

    try {

        if ($Name) {

            $uri = ('https://graph.microsoft.com/{0}/{1}' -f $graphApiVersion, ($resource))
            (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value | Where-Object { ($_.'displayName').contains(('{0}' -f $Name)) }

        }

        else {

            $uri = ('https://graph.microsoft.com/{0}/{1}' -f $graphApiVersion, ($resource))
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