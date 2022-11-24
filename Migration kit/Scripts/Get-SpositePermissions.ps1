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
        requires SharePoint Site Collection Administrator
#>

#update these parameters with correct URLs before runningscript
$targetTmpDomain = "datavara.onmicrosoft.com"
$sourceTmpDomain = (Get-AzureADDomain | Where-Object -Property Name -Like *onmicrosoft.com).Name
$sourceSPOAdminURL = "https://datavara-admin.sharepoint.com/"
$sourcespositeurl      = "https://datavara.sharepoint.com/"
$destinationspositeurl = "https://dlsoftware.sharepoint.com/"

#Site collection URL
$CSVPath = "C:\Users\VegardØdegaard\Ironstone\Migration Projects - Documents\Confirmasoft\Reports\Crona Lön\Migration\Reports\SPOPermissionReport.csv"
 
 
$GroupsData = @()
 
#Get all Site collections
Get-SPOSite -Limit ALL | ForEach-Object {
    Write-Host -f Yellow "Processing Site Collection:"$_.URL
  
    #get sharepoint online groups powershell
    $SiteGroups = Get-SPOSiteGroup -Site $_.URL
 
    Write-host "Total Number of Groups Found:"$SiteGroups.Count
 
    ForEach($Group in $SiteGroups)
    {
        $GroupsData += New-Object PSObject -Property @{
            'Site URL' = $_.URL
            'Group Name' = $Group.Title
            'Permissions' = $Group.Roles -join ","
            'Users' =  $Group.Users -join ","
        }
    }
}
#Export the data to CSV
$GroupsData | Export-Csv $CSVPath -NoTypeInformation -Encoding UTF8
 
Write-host -f Green "Groups Report Generated Successfully!"