Function Get-ApplicationAssignment() {

    <#
.SYNOPSIS
This function is used to get an application assignment from the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and gets an application assignment
.EXAMPLE
Get-ApplicationAssignment
Returns an Application Assignment configured in Intune
.NOTES
NAME: Get-ApplicationAssignment
#>

    [cmdletbinding()]

    param
    (
        $ApplicationId
    )

    $graphApiVersion = 'v1.0'
    $Resource = ('deviceAppManagement/mobileApps/{0}/assignments' -f $ApplicationId)

    try {

        if (!$ApplicationId) {

            Write-Verbose -Message 'No Application Id specified, specify a valid Application Id'
            break

        }

        else {

            $uri = ('https://graph.microsoft.com/{0}/{1}' -f $graphApiVersion, ($Resource))
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