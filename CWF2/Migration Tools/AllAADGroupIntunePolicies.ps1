# Connect and change schema 
#Connect-MSGraph -ForceInteractive
#Update-MSGraphEnvironment -SchemaVersion beta
#Connect-MSGraph
 
$Groups = Get-AADGroup | Get-MSGraphAllPages
 
$outfile = "policyoverview.csv"
Set-Content -Path $outfile -Value "Type,AAD Group,Policy Name" -Encoding UTF8

# Apps
$AllAssignedApps = Get-IntuneMobileApp -Filter "isAssigned eq true" -Select id, displayName, lastModifiedDateTime, assignments -Expand assignments
Write-host "Number of Apps found: $($AllAssignedApps.DisplayName.Count)" -ForegroundColor cyan

# Device Compliance
$AllDeviceCompliance = Get-IntuneDeviceCompliancePolicy -Select id, displayName, lastModifiedDateTime, assignments -Expand assignments 
Write-host "Number of Device Compliance policies found: $($AllDeviceCompliance.DisplayName.Count)" -ForegroundColor cyan

# Device Configuration
$AllDeviceConfig = Get-IntuneDeviceConfigurationPolicy -Select id, displayName, lastModifiedDateTime, assignments -Expand assignments
Write-host "Number of Device Configurations found: $($AllDeviceConfig.DisplayName.Count)" -ForegroundColor cyan

# Device Configuration Powershell Scripts 
$Resource = "deviceManagement/deviceManagementScripts"
$graphApiVersion = "Beta"
$uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)?`$expand=groupAssignments"
$DMS = Invoke-MSGraphRequest -HttpMethod GET -Url $uri
$AllDeviceConfigScripts = $DMS.value
Write-host "Number of Device Configurations Powershell Scripts found: $($AllDeviceConfigScripts.DisplayName.Count)" -ForegroundColor cyan

# Administrative templates
$Resource = "deviceManagement/groupPolicyConfigurations"
$graphApiVersion = "Beta"
$uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)?`$expand=Assignments"
$ADMT = Invoke-MSGraphRequest -HttpMethod GET -Url $uri
$AllADMT = $ADMT.value
Write-host "Number of Device Administrative Templates found: $($AllADMT.DisplayName.Count)" -ForegroundColor cyan

#### Config 
Foreach ($Group in $Groups) {
    Write-host "AAD Group Name: $($Group.displayName)" -ForegroundColor Green
    
    Foreach ($Config in ($AllAssignedApps  | Where-Object { $_.assignments -match $Group.id })) {
        Write-host $Config.displayName -ForegroundColor Yellow
        Add-Content -Path $outfile -Value ("App,{0},{1}" -f ($Group.displayName, $Config.displayName))
    }
  
    Foreach ($Config in ($AllDeviceCompliance | Where-Object { $_.assignments -match $Group.id })) {
 
        Write-host $Config.displayName -ForegroundColor Yellow
        Add-Content -Path $outfile -Value ("Device Compliance,{0},{1}" -f ($Group.displayName, $Config.displayName))
    }
 
    Foreach ($Config in ($AllDeviceConfig | Where-Object { $_.assignments -match $Group.id })) {
 
        Write-host $Config.displayName -ForegroundColor Yellow
        Add-Content -Path $outfile -Value ("Device Configuration,{0},{1}" -f ($Group.displayName, $Config.displayName))
    }
 
    
 
    Foreach ($Config in ($AllDeviceConfigScripts | Where-Object { $_.assignments -match $Group.id })) {
 
        Write-host $Config.displayName -ForegroundColor Yellow
        Add-Content -Path $outfile -Value ("Device Configuration PS scripts,{0},{1}" -f ($Group.displayName, $Config.displayName))
    }
 
 
 
    
    Foreach ($Config in ($AllADMT | Where-Object { $_.assignments -match $Group.id })) {
 
        Write-host $Config.displayName -ForegroundColor Yellow
        Add-Content -Path $outfile -Value ("Administrative templates,{0},{1}" -f ($Group.displayName, $Config.displayName))
    }

    
}

# Endpoint security

$Resource = "deviceManagement/intents"
$graphApiVersion = "Beta"
$uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
$ESIntents = Invoke-MSGraphRequest -HttpMethod GET -Url $uri
foreach ($intent in $ESIntents.value) {
    if ($intent.isAssigned) {
        $uri = ("https://graph.microsoft.com/{0}/{1}/{2}/assignments" -f $graphApiVersion, $Resource, $intent.id)
        $intentdetail = Invoke-MSGraphRequest -HttpMethod GET -Url $uri
        Write-host "New Intent" -ForegroundColor Cyan
        Write-host $intent
        $intentdetail | ConvertTo-Json
        foreach ($assignment in $intentdetail.value) {
            Write-host "Assignment" -ForegroundColor Yellow
            Write-host $assignment

            $group = $groups | Where-Object { $_.Id -match $assignment.target.groupId }
            Add-Content -Path $outfile -Value ("Endpoint Security,{0},{1}" -f ($Group.displayName, $intent.displayName))
        }
       
    }
}