Function Get-DeviceManagementScripts(){

<#
.SYNOPSIS
This function is used to get device management scripts from the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and gets any device management scripts
.EXAMPLE
Get-DeviceManagementScripts
Returns any device management scripts configured in Intune
Get-DeviceManagementScripts -ScriptId $ScriptId
Returns a device management script configured in Intune
.NOTES
NAME: Get-DeviceManagementScripts
#>

[cmdletbinding()]

param (

    [Parameter(Mandatory=$false)]
    $ScriptId

)

$graphApiVersion = "beta"
$Resource = "deviceManagement/deviceManagementScripts"

$UriAll = "https://graph.microsoft.com/$graphApiVersion/$Resource"
[array]$AllIds =  (Invoke-RestMethod -Uri $UriAll -Headers $authToken -Method Get).Value.foreach{$_.id}


    try {

        if($AllIds.Contains($ScriptId)){

        $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource/$ScriptId"

        Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get

        }

        else {

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)?`$expand=groupAssignments"
        (Invoke-RestMethod -Uri $uri –Headers $authToken –Method Get).Value

        }
    
    }
    
    catch {

    $ex = $_.Exception
    $errorResponse = $ex.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($errorResponse)
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $responseBody = $reader.ReadToEnd();
    Write-Host "Response content:`n$responseBody" -f Red
    Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
    write-host
    break

    }

}
