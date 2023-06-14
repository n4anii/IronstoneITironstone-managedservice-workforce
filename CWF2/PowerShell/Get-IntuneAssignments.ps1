#Check below for known missing settings
#Will filter out Applications from ManagedAndroidStoreApp and ManagedIosStoreApps


# Enrollment restrictions
# Connect and change schema 
#Connect-MSGraph -ForceInteractive
#Update-MSGraphEnvironment -SchemaVersion beta
#Connect-MSGraph

$Groups = Get-AADGroup | Get-MSGraphAllPages

# Get All resources
$AllApps = Get-IntuneMobileApp -Select id, displayName, lastModifiedDateTime, assignments -Expand assignments
$AllDeviceCompliance = Get-IntuneDeviceCompliancePolicy -Select id, displayName, lastModifiedDateTime, assignments -Expand assignments
$AllDeviceConfig = Get-IntuneDeviceConfigurationPolicy -Select id, displayName, lastModifiedDateTime, assignments -Expand assignments

#Managed Apps

#Powershell Scripts
$Resource = "deviceManagement/deviceManagementScripts"
$graphApiVersion = "Beta"
$uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)?`$expand=Assignments"
$DMS = Invoke-MSGraphRequest -HttpMethod GET -Url $uri
$AllDeviceConfigScripts = $DMS.value

#Shell Scripts
$Resource = "deviceManagement/deviceShellScripts"
$graphApiVersion = "Beta"
$uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)?`$expand=Assignments"
$DSS = Invoke-MSGraphRequest -HttpMethod GET -Url $uri
$AllDeviceShellScripts = $DSS.value

#Administrative Templates
$Resource = "deviceManagement/groupPolicyConfigurations"
$uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)?`$expand=Assignments"
$ADMT = Invoke-MSGraphRequest -HttpMethod GET -Url $uri
$AllADMT = $ADMT.value

# Proactive Remediation
$Resource = "deviceManagement/deviceHealthScripts"
$uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)?`$expand=Assignments"
$Proactive = Invoke-MSGraphRequest -HttpMethod GET -Url $uri
$AllProactive = $Proactive.value

# Settings Catalogs
$Resource = "deviceManagement/configurationPolicies"
$uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)?`$expand=Assignments"
$SC = Invoke-MSGraphRequest -HttpMethod GET -Url $uri
$AllSC = $SC.value

#Baseline / Intents
#Assignments only shown when calling one intent at a time
$Resource = "deviceManagement/intents"
$uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
$ES = Invoke-MSGraphRequest -HttpMethod GET -Url $uri
$AllES = $ES.value

#Feature Update policies Windows
$Resource = "deviceManagement/windowsFeatureUpdateProfiles"
$uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)?`$expand=Assignments"
$WFU = Invoke-MSGraphRequest -HttpMethod GET -Url $uri
$AllWFU = $WFU.value

#Update Rings for Windows
$Resource = "deviceManagement/deviceConfigurations"
$uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)?`$filter=isof('microsoft.graph.windowsUpdateForBusinessConfiguration')"
$WUR = Invoke-MSGraphRequest -HttpMethod GET -Url $uri
$AllWUR = $WUR.value

#MacOS Updates
$Resource = "deviceManagement/deviceConfigurations"
$uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)?`$filter=isof('microsoft.graph.macOSSoftwareUpdateConfiguration')"
$MacUpdateRing = Invoke-MSGraphRequest -HttpMethod GET -Url $uri
$AllMacUpdateRing = $MacUpdateRing.value

#Autopilot
$Resource = "deviceManagement/windowsAutopilotDeploymentProfiles"
$uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)?`$expand=Assignments"
$Autopilot = Invoke-MSGraphRequest -HttpMethod GET -Url $uri
$AllAutopilot = $Autopilot.value

#ESP
$Resource = "deviceManagement/deviceEnrollmentConfigurations"
$uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)?`$expand=assignments&`$filter=deviceEnrollmentConfigurationType%20eq%20%27Windows10EnrollmentCompletionPageConfiguration%27"
$ESP = Invoke-MSGraphRequest -HttpMethod GET -Url $uri
$AllESP = $ESP.value

#App Protection iOS
$Resource = "deviceAppManagement/iosManagedAppProtections"
$uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)?`$expand=Assignments"
$AppProtectiOS = Invoke-MSGraphRequest -HttpMethod GET -Url $uri
$AllAppProtectiOS = $AppProtectiOS.value

#App Protection Android
$Resource = "deviceAppManagement/androidManagedAppProtections"
$uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)?`$expand=Assignments"
$AppProtectAndroid = Invoke-MSGraphRequest -HttpMethod GET -Url $uri
$AllAppProtectAndroid = $AppProtectAndroid.value

#Windows Security Baseline
$Resource = "deviceManagement/intents"
$uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)?`$filter=templateId%20eq%20%27034ccd46-190c-4afc-adf1-ad7cc11262eb%27"
$Baseline = Invoke-MSGraphRequest -HttpMethod GET -Url $uri
$AllBaseline = $Baseline.value

$results = @()

# Creating a helper function to get group names for a resource
function Get-AssignedGroups {
    param($resource)
    $assignedGroups = $Groups | Where-Object {$resource.assignments -match $_.id} | ForEach-Object {$_.displayName}
    return $assignedGroups -join ", "
}

# Iterating through resources and adding their assignments to results
$AllAppsFiltered = $AllApps | Where-Object -Property "@odata.type" -ne "#microsoft.graph.managedAndroidStoreApp" | Where-Object -Property "@odata.type" -ne "#microsoft.graph.managedIOSStoreApp"

Foreach ($App in $AllAppsFiltered) {
    $result = [PSCustomObject]@{
        "ResourceName" = $App.displayName
        "ResourceType" = "App"
        "AssignedGroups" = Get-AssignedGroups -resource $App
    }
    $results += $result
}

Foreach ($Config in $AllDeviceCompliance) {
    $result = [PSCustomObject]@{
        "ResourceName" = $Config.displayName
        "ResourceType" = "Device Compliance Policy"
        "AssignedGroups" = Get-AssignedGroups -resource $Config
    }
    $results += $result
}

Foreach ($Config in $AllDeviceConfig) {
    $result = [PSCustomObject]@{
        "ResourceName" = $Config.displayName
        "ResourceType" = "Device Configuration Policy"
        "AssignedGroups" = Get-AssignedGroups -resource $Config
    }
    $results += $result
}

Foreach ($Script in $AllDeviceConfigScripts) {
    $result = [PSCustomObject]@{
        "ResourceName" = $Script.displayName
        "ResourceType" = "Device Config Script"
        "AssignedGroups" = Get-AssignedGroups -resource $Script
    }
    $results += $result
}

Foreach ($Script in $AllDeviceShellScripts) {
    $result = [PSCustomObject]@{
        "ResourceName" = $Script.displayName
        "ResourceType" = "Device Shell Script"
        "AssignedGroups" = Get-AssignedGroups -resource $Script
    }
    $results += $result
}

Foreach ($Config in $AllADMT) {
    $result = [PSCustomObject]@{
        "ResourceName" = $Config.displayName
        "ResourceType" = "Administrative Templates"
        "AssignedGroups" = Get-AssignedGroups -resource $Config
    }
    $results += $result
}

Foreach ($Script in $AllProactive) {
    $result = [PSCustomObject]@{
        "ResourceName" = $Script.displayName
        "ResourceType" = "Proactive Remediation"
        "AssignedGroups" = Get-AssignedGroups -resource $Script
    }
    $results += $result
}

Foreach ($Config in $AllSC) {
    $result = [PSCustomObject]@{
        "ResourceName" = $Config.Name
        "ResourceType" = "Settings Catalog"
        "AssignedGroups" = Get-AssignedGroups -resource $Config
    }
    $results += $result
}

Foreach ($Update in $AllWFU) {
    $result = [PSCustomObject]@{
        "ResourceName" = $Update.displayName
        "ResourceType" = "Feature Updates"
        "AssignedGroups" = Get-AssignedGroups -resource $Config
    }
    $results += $result
}

Foreach ($Update in $AllWUR) {
    $result = [PSCustomObject]@{
        "ResourceName" = $Update.displayName
        "ResourceType" = "Update Ring"
        "AssignedGroups" = Get-AssignedGroups -resource $Config
    }
    $results += $result
}

Foreach ($Update in $AllMacUpdateRing) {
    $result = [PSCustomObject]@{
        "ResourceName" = $Update.displayName
        "ResourceType" = "Mac Updates"
        "AssignedGroups" = Get-AssignedGroups -resource $Config
    }
    $results += $result
}

Foreach ($Profile in $AllAutopilot) {
    $result = [PSCustomObject]@{
        "ResourceName" = $Profile.displayName
        "ResourceType" = "Autopilot"
        "AssignedGroups" = Get-AssignedGroups -resource $Config
    }
    $results += $result
}

Foreach ($Profile in $AllESP) {
    $result = [PSCustomObject]@{
        "ResourceName" = $Profile.displayName
        "ResourceType" = "Enrollment Status Page"
        "AssignedGroups" = Get-AssignedGroups -resource $Config
    }
    $results += $result
}

Foreach ($Profile in $AllAppProtectiOS) {
    $result = [PSCustomObject]@{
        "ResourceName" = $Profile.displayName
        "ResourceType" = "App Protection Policy"
        "AssignedGroups" = Get-AssignedGroups -resource $Config
    }
    $results += $result
}

Foreach ($Profile in $AllAppProtectAndroid) {
    $result = [PSCustomObject]@{
        "ResourceName" = $Profile.displayName
        "ResourceType" = "App Protection Policy"
        "AssignedGroups" = Get-AssignedGroups -resource $Config
    }
    $results += $result
}

Foreach ($Profile in $AllBaseline) {
    $result = [PSCustomObject]@{
        "ResourceName" = $Profile.displayName
        "ResourceType" = "App Protection Policy"
        "AssignedGroups" = Get-AssignedGroups -resource $Config
    }
    $results += $result
}

Foreach ($ES in $AllES) {
<#     Invoke-MSGraphRequest does not return the same as MS Graph Explorer. Assignments not showing in Powershell
    $Resource = "deviceManagement/intents"
    $id = $ES.id
    $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)/$($id)?`$expand=Assignments"
    $ESAssignment = Invoke-MSGraphRequest -HttpMethod GET -Url $uri #>
    
    $result = [PSCustomObject]@{
        "ResourceName" = $ES.displayName
        "ResourceType" = "Baseline/Intents"
        "AssignedGroups" = $ES.isAssigned
    }
    $results += $result
}

    $results += $result


$results | Export-Csv -Path "c:\temp\ResourceAssignments.csv" -NoTypeInformation
