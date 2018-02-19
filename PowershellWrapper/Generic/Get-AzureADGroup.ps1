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