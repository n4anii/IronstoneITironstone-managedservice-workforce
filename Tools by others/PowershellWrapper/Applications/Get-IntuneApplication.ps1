Function Get-IntuneApplication() {

    <#
.SYNOPSIS
This function is used to get applications from the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and gets any applications added
.EXAMPLE
Get-IntuneApplication
Returns any applications configured in Intune
.NOTES
NAME: Get-IntuneApplication
#>

    [cmdletbinding()]

    param
    (
        $Name
    )

    $graphApiVersion = 'beta' #'v1.0'
    Write-Warning 'Using BETA version of deviceAppManagement/mobileApps'
    $Resource = 'deviceAppManagement/mobileApps'

    try {

        if ($Name) {

            $uri = ('https://graph.microsoft.com/{0}/{1}' -f $graphApiVersion, ($Resource))
            (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value | Where-Object { ($_.'displayName').contains(('{0}' -f $Name)) -and (!($_.'@odata.type').Contains('managed')) -and (!($_.'@odata.type').Contains('#microsoft.graph.iosVppApp')) }

        }

        else {

            $uri = ('https://graph.microsoft.com/{0}/{1}' -f $graphApiVersion, ($Resource))
            (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value | Where-Object { (!($_.'@odata.type').Contains('managed')) -and (!($_.'@odata.type').Contains('#microsoft.graph.iosVppApp')) }

        }

    }

    catch {

        $ex = $_.Exception
        Write-Verbose -Message ('Request to {0} failed with HTTP Status {1} {2}' -f $Uri, ([int]$ex.Response.StatusCode), $ex.Response.StatusDescription)
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