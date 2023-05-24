# Connect and change schema 
#Connect-MSGraph -ForceInteractive
#Update-MSGraphEnvironment -SchemaVersion beta
#Connect-MSGraph

$Groups = Get-AADGroup | Get-MSGraphAllPages

# Get All resources
$AllApps = Get-IntuneMobileApp -Filter "isAssigned eq true" -Select id, displayName, lastModifiedDateTime, assignments -Expand assignments
$AllDeviceCompliance = Get-IntuneDeviceCompliancePolicy -Select id, displayName, lastModifiedDateTime, assignments -Expand assignments
$AllDeviceConfig = Get-IntuneDeviceConfigurationPolicy -Select id, displayName, lastModifiedDateTime, assignments -Expand assignments

$Resource = "deviceManagement/deviceManagementScripts"
$graphApiVersion = "Beta"
$uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)?`$expand=groupAssignments"
$DMS = Invoke-MSGraphRequest -HttpMethod GET -Url $uri
$AllDeviceConfigScripts = $DMS.value

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

$results = @()

# Creating a helper function to get group names for a resource
function Get-AssignedGroups {
    param($resource)
    $assignedGroups = $Groups | Where-Object {$resource.assignments -match $_.id} | ForEach-Object {$_.displayName}
    return $assignedGroups -join ", "
}

# Iterating through resources and adding their assignments to results

Foreach ($App in $AllApps) {
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

    $results += $result


$results | Export-Csv -Path "c:\temp\ResourceAssignments.csv" -NoTypeInformation
