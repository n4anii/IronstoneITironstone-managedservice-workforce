Function Get-SoftwareUpdatePolicy() {

    <#
.SYNOPSIS
This function is used to get Software Update policies from the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and gets any Software Update policies
.EXAMPLE
Get-SoftwareUpdatePolicy -Windows10
Returns Windows 10 Software Update policies configured in Intune
.EXAMPLE
Get-SoftwareUpdatePolicy -iOS
Returns iOS update policies configured in Intune
.NOTES
NAME: Get-SoftwareUpdatePolicy
#>

    [cmdletbinding()]

    param
    (
        [switch]$Windows10,
        [switch]$iOS
    )

    $graphApiVersion = 'Beta'

    try {

        $Count_Params = 0

        if ($iOS.IsPresent) { $Count_Params++ }
        if ($Windows10.IsPresent) { $Count_Params++ }

        if ($Count_Params -gt 1) {

            Write-Verbose -Message 'Multiple parameters set, specify a single parameter -iOS or -Windows10 against the function'

        }

        elseif ($Count_Params -eq 0) {

            Write-Verbose -Message 'Parameter -iOS or -Windows10 required against the function...'
            break

        }

        elseif ($Windows10) {

            $Resource = "deviceManagement/deviceConfigurations?`$filter=isof('microsoft.graph.windowsUpdateForBusinessConfiguration')&`$expand=groupAssignments"

            $uri = ('https://graph.microsoft.com/{0}/{1}' -f $graphApiVersion, ($Resource))
            (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).value

        }

        elseif ($iOS) {

            $Resource = "deviceManagement/deviceConfigurations?`$filter=isof('microsoft.graph.iosUpdateConfiguration')&`$expand=groupAssignments"

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