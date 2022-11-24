<#
    .NAME
        DiscoverSourceData.ps1

    .SYNOPSIS
        Gets important data from source tenant when preparing to migrate data from one tenant to another

    .DESCRIPTION
        Before running the script you need to connect to the following services
        Connect-AzureAD
        Connect-SPOService -URL $sourceSPOAdminURL


    .NOTES
        Script is still a work in progress, input on how to make it better is welcome.
#>

#update these parameters with correct URLs before runningscript
$targetTmpDomain = "datavara.onmicrosoft.com"
$sourceTmpDomain = (Get-AzureADDomain | Where-Object -Property Name -Like *onmicrosoft.com).Name
$sourceSPOAdminURL = "https://datavara-admin.sharepoint.com/"
$sourcespositeurl      = "https://datavara.sharepoint.com/"
$destinationspositeurl = "https://dlsoftware.sharepoint.com/"




# Get SPO overview
#$sourcespositeurl      = "https://datavara.sharepoint.com/"
#$destinationspositeurl = "https://dlsoftware.sharepoint.com/
#Get sites
$sposites = Get-SPOSite -Limit all

$spositedata  = [System.Collections.Generic.List[Object]]::new()
foreach ($sposite in $sposites){
    if ([string]::IsNullOrWhiteSpace($sposite.relatedgroupid) -or $sposite.relatedgroupid -eq "00000000-0000-0000-0000-000000000000"){
        $spogroup = $null
    }
    else {
        $spogroup = Get-AzureADGroup -objectid $sposite.relatedgroupid
    }
    if ($sposite.url -like '*/sites/*'){
        $destinationsite = $sposite.url.replace("$sourcespositeurl","$destinationspositeurl")
    }
    else {
        $destinationsite = $sposite.url.replace("$sourcespositeurl","$destinationspositeurl")+"-Root"
    }
    $spostorageusage = @($sposite.StorageUsageCurrent /1024)

#Create data table
$spositeinfo = [PSCustomObject]@{
    SiteName            = $sposite.title
    SourceSite          = $sposite.url
    DestinationSite     = $destinationsite
    M365Group           = $spogroup.displayname
    M365Email           = $spogroup.mail
    StorageUsed         = $sposite.StorageUsageCurrent
    Template            = $sposite.Template
    ExternalSharing     = $sposite.SharingCapability
}
    $spositedata.Add($spositeinfo)
    
}
$spositedata | Export-CSV -NoTypeInformation -Path "C:\Users\VegardØdegaard\Ironstone\Migration Projects - Documents\Confirmasoft\Reports\Crona Lön\Migration\Reports\spositedetails.csv" -Delimiter ',' -Encoding UTF8
