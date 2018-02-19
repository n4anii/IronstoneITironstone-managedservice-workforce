Function Get-IntuneBrand() {

    <#
    .SYNOPSIS
    This function is used to get the Company Intune Branding resources from the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets the Intune Branding Resource
    .EXAMPLE
    Get-IntuneBrand
    Returns the Company Intune Branding configured in Intune
    .NOTES
    NAME: Get-IntuneBrand
    #>

    [cmdletbinding()]

    $graphApiVersion = 'Beta'
    $Resource = 'deviceManagement/intuneBrand'

    try {

        $uri = ('https://graph.microsoft.com/{0}/{1}' -f $graphApiVersion, ($resource))
        Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get
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