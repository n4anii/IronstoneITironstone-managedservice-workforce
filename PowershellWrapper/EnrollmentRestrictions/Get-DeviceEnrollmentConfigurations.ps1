Function Get-DeviceEnrollmentConfigurations() {
    
    <#
.SYNOPSIS
This function is used to get Deivce Enrollment Configurations from the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and gets Device Enrollment Configurations
.EXAMPLE
Get-DeviceEnrollmentConfigurations
Returns Device Enrollment Configurations configured in Intune
.NOTES
NAME: Get-DeviceEnrollmentConfigurations
#>
    
    [cmdletbinding()]
    
    $graphApiVersion = 'Beta'
    $Resource = 'deviceManagement/deviceEnrollmentConfigurations'
        
    try {
            
        $uri = ('https://graph.microsoft.com/{0}/{1}' -f $graphApiVersion, ($Resource))
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
