Function Get-DeviceCompliancePolicy() {

    <#
    .SYNOPSIS
    This function is used to get device compliance policies from the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets any device compliance policies
    .EXAMPLE
    Get-DeviceCompliancePolicy
    Returns any device compliance policies configured in Intune
    .EXAMPLE
    Get-DeviceCompliancePolicy -Android
    Returns any device compliance policies for Android configured in Intune
    .EXAMPLE
    Get-DeviceCompliancePolicy -iOS
    Returns any device compliance policies for iOS configured in Intune
    .NOTES
    NAME: Get-DeviceCompliancePolicy
    #>

    [cmdletbinding()]

    param
    (
        $Name,
        [switch]$Android,
        [switch]$iOS,
        [switch]$Win10
    )

    $graphApiVersion = 'Beta'
    $Resource = 'deviceManagement/deviceCompliancePolicies'

    try {

        $Count_Params = 0

        if ($Android.IsPresent) { $Count_Params++ }
        if ($iOS.IsPresent) { $Count_Params++ }
        if ($Win10.IsPresent) { $Count_Params++ }
        if ($Name.IsPresent) { $Count_Params++ }

        if ($Count_Params -gt 1) {

            Write-Verbose -Message 'Multiple parameters set, specify a single parameter -Android -iOS or -Win10 against the function'

        }

        elseif ($Android) {

            $uri = ('https://graph.microsoft.com/{0}/{1}' -f $graphApiVersion, ($Resource))
            (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value | Where-Object { ($_.'@odata.type').contains('android') }

        }

        elseif ($iOS) {

            $uri = ('https://graph.microsoft.com/{0}/{1}' -f $graphApiVersion, ($Resource))
            (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value | Where-Object { ($_.'@odata.type').contains('ios') }

        }

        elseif ($Win10) {

            $uri = ('https://graph.microsoft.com/{0}/{1}' -f $graphApiVersion, ($Resource))
            (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value | Where-Object { ($_.'@odata.type').contains('windows10CompliancePolicy') }

        }

        elseif ($Name) {

            $uri = ('https://graph.microsoft.com/{0}/{1}' -f $graphApiVersion, ($Resource))
            (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value | Where-Object { ($_.'displayName').contains(('{0}' -f $Name)) }

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