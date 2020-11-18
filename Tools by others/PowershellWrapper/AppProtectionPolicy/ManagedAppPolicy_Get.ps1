Function Get-ManagedAppPolicy(){

<#
.SYNOPSIS
This function is used to get managed app policies from the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and gets any managed app policies
.EXAMPLE
Get-ManagedAppPolicy
Returns any managed app policies configured in Intune
.NOTES
NAME: Get-ManagedAppPolicy
#>

[cmdletbinding()]

param
(
    $Name
)

$graphApiVersion = "Beta"
$Resource = "deviceAppManagement/managedAppPolicies"

    try {
    
        if($Name){
    
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value | Where-Object { ($_.'displayName').contains("$Name") }
    
        }
    
        else {
    
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value | Where-Object { ($_.'@odata.type').contains("ManagedAppProtection") -or ($_.'@odata.type').contains("InformationProtectionPolicy") }
    
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

####################################################

Function Get-ManagedAppProtection(){

<#
.SYNOPSIS
This function is used to get managed app protection configuration from the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and gets any managed app protection policy
.EXAMPLE
Get-ManagedAppProtection -id $id -OS "Android"
Returns a managed app protection policy for Android configured in Intune
Get-ManagedAppProtection -id $id -OS "iOS"
Returns a managed app protection policy for iOS configured in Intune
Get-ManagedAppProtection -id $id -OS "WIP_WE"
Returns a managed app protection policy for Windows 10 without enrollment configured in Intune
.NOTES
NAME: Get-ManagedAppProtection
#>

[cmdletbinding()]

param
(
    $id,
    $OS    
)

$graphApiVersion = "Beta"

    try {
    
        if($id -eq "" -or $id -eq $null){
    
        write-host "No Managed App Policy id specified, please provide a policy id..." -f Red
        break
    
        }
    
        else {
    
            if($OS -eq "" -or $OS -eq $null){
    
            write-host "No OS parameter specified, please provide an OS. Supported value are Android,iOS,WIP_WE,WIP_MDM..." -f Red
            Write-Host
            break
    
            }
    
            elseif($OS -eq "Android"){
    
            $Resource = "deviceAppManagement/androidManagedAppProtections('$id')/?`$expand=deploymentSummary,apps,assignments"
    
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
            Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get
    
            }
    
            elseif($OS -eq "iOS"){
    
            $Resource = "deviceAppManagement/iosManagedAppProtections('$id')/?`$expand=deploymentSummary,apps,assignments"
    
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
            Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get
    
            }

            elseif($OS -eq "WIP_WE"){
    
            $Resource = "deviceAppManagement/windowsInformationProtectionPolicies('$id')?`$expand=protectedAppLockerFiles,exemptAppLockerFiles,assignments"
    
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
            Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get
    
            }

            elseif($OS -eq "WIP_MDM"){
    
            $Resource = "deviceAppManagement/mdmWindowsInformationProtectionPolicies('$id')?`$expand=protectedAppLockerFiles,exemptAppLockerFiles,assignments"
    
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
            Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get

            }
    
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

####################################################


write-host "Running query against Microsoft Graph for App Protection Policies" -f Yellow

$ManagedAppPolicies = Get-ManagedAppPolicy

write-host

foreach($ManagedAppPolicy in $ManagedAppPolicies){

write-host "Managed App Policy:"$ManagedAppPolicy.displayName -f Yellow

$ManagedAppPolicy

    # If Android Managed App Policy
    
    if($ManagedAppPolicy.'@odata.type' -eq "#microsoft.graph.androidManagedAppProtection"){
    
        $AndroidManagedAppProtection = Get-ManagedAppProtection -id $ManagedAppPolicy.id -OS "Android"
    
        write-host "Managed App Policy - Assignments" -f Cyan
    
        $AndroidAssignments = ($AndroidManagedAppProtection | select assignments).assignments
    
            if($AndroidAssignments){
    
                foreach($Group in $AndroidAssignments.target.groupId){
    
                (Get-AADGroup -id $Group).displayName
    
                }
    
                Write-Host
    
            }
    
            else {
    
            Write-Host "No assignments set for this policy..." -ForegroundColor Red
            Write-Host
    
            }
    
        write-host "Managed App Policy - Mobile Apps" -f Cyan
            
        if($ManagedAppPolicy.deployedAppCount -ge 1){
    
        ($AndroidManagedAppProtection | select apps).apps.mobileAppIdentifier
    
        }
    
        else {
    
        Write-Host "No Managed Apps targeted..." -ForegroundColor Red
        Write-Host
    
        }
    
    }

    # If iOS Managed App Policy
    
    elseif($ManagedAppPolicy.'@odata.type' -eq "#microsoft.graph.iosManagedAppProtection"){
    
        $iOSManagedAppProtection = Get-ManagedAppProtection -id $ManagedAppPolicy.id -OS "iOS"
    
        write-host "Managed App Policy - Assignments" -f Cyan
    
        $iOSAssignments = ($iOSManagedAppProtection | select assignments).assignments
    
            if($iOSAssignments){
    
                foreach($Group in $iOSAssignments.target.groupId){
    
                (Get-AADGroup -id $Group).displayName
    
                }
    
                Write-Host
    
            }
    
            else {
    
            Write-Host "No assignments set for this policy..." -ForegroundColor Red
            Write-Host
    
            }
    
        write-host "Managed App Policy - Mobile Apps" -f Cyan
            
        if($ManagedAppPolicy.deployedAppCount -ge 1){
    
        ($iOSManagedAppProtection | select apps).apps.mobileAppIdentifier
    
        }
    
        else {
    
        Write-Host "No Managed Apps targeted..." -ForegroundColor Red
        Write-Host
    
        }
    
    }

    # If WIP Without Enrollment Managed App Policy
    
    elseif($ManagedAppPolicy.'@odata.type' -eq "#microsoft.graph.windowsInformationProtectionPolicy"){
    
        $Win10ManagedAppProtection = Get-ManagedAppProtection -id $ManagedAppPolicy.id -OS "WIP_WE"
    
        write-host "Managed App Policy - Assignments" -f Cyan
    
        $Win10Assignments = ($Win10ManagedAppProtection | select assignments).assignments
    
            if($Win10Assignments){
    
                foreach($Group in $Win10Assignments.target.groupId){
    
                (Get-AADGroup -id $Group).displayName
    
                }
    
                Write-Host
    
            }
    
            else {
    
            Write-Host "No assignments set for this policy..." -ForegroundColor Red
            Write-Host
    
            }
    
        write-host "Protected Apps" -f Cyan
            
        if($Win10ManagedAppProtection.protectedApps){
    
        $Win10ManagedAppProtection.protectedApps.displayName
    
        Write-Host

        }
    
        else {
    
        Write-Host "No Protected Apps targeted..." -ForegroundColor Red
        Write-Host
    
        }

        
        write-host "Protected AppLocker Files" -ForegroundColor Cyan

        if($Win10ManagedAppProtection.protectedAppLockerFiles){
    
        $Win10ManagedAppProtection.protectedAppLockerFiles.displayName

        Write-Host
    
        }
    
        else {
    
        Write-Host "No Protected Applocker Files targeted..." -ForegroundColor Red
        Write-Host
    
        }
    
    }

    # If WIP with Enrollment (MDM) Managed App Policy
    
    elseif($ManagedAppPolicy.'@odata.type' -eq "#microsoft.graph.mdmWindowsInformationProtectionPolicy"){
    
        $Win10ManagedAppProtection = Get-ManagedAppProtection -id $ManagedAppPolicy.id -OS "WIP_MDM"
    
        write-host "Managed App Policy - Assignments" -f Cyan
    
        $Win10Assignments = ($Win10ManagedAppProtection | select assignments).assignments
    
            if($Win10Assignments){
    
                foreach($Group in $Win10Assignments.target.groupId){
    
                (Get-AADGroup -id $Group).displayName
    
                }
    
                Write-Host
    
            }
    
            else {
    
            Write-Host "No assignments set for this policy..." -ForegroundColor Red
            Write-Host
    
            }
    
        write-host "Protected Apps" -f Cyan
            
        if($Win10ManagedAppProtection.protectedApps){
    
        $Win10ManagedAppProtection.protectedApps.displayName
    
        Write-Host

        }
    
        else {
    
        Write-Host "No Protected Apps targeted..." -ForegroundColor Red
        Write-Host
    
        }

        
        write-host "Protected AppLocker Files" -ForegroundColor Cyan

        if($Win10ManagedAppProtection.protectedAppLockerFiles){
    
        $Win10ManagedAppProtection.protectedAppLockerFiles.displayName

        Write-Host
    
        }
    
        else {
    
        Write-Host "No Protected Applocker Files targeted..." -ForegroundColor Red
        Write-Host
    
        }
    
    }

}