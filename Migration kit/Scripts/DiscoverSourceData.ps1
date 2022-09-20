<#
    .NAME
        DiscoverSourceData.ps1

    .SYNOPSIS
        Gets important data from source tenant when preparing to migrate data from one tenant to another

    .DESCRIPTION
        Before running the script you need to connect to the following services
        Connect-AzureAD
        Connect-ExchangeOnline
        Connect-SPOService -URL "https://example.sharepoint.com/"
        Connect-MicrosoftTeams

    .NOTES
        Script is still a work in progress, input on how to make it better is welcome.
#>

#update these parameters with correct URLs before runningscript
$targetTmpDomain = "handverksgruppen.onmicrosoft.com"
$sourceSPOAdminURL = "https://example-admin.sharepoint.com"

Connect-AzureAD
Connect-ExchangeOnline
Connect-SPOService -URL $sourceSPOAdminURL
Connect-MicrosoftTeams

$sourceTmpDomain = (Get-AzureADDomain | Where-Object -Property Name -Like *onmicrosoft.com).Name

#Get all users in tenant
$users = Get-AzureADUser -All $true | Where-Object -Property UserType -ne Guest

#Get all OneDrive Sites
$ODFBSites = Get-SPOSite -IncludePersonalSite $True -Limit All -Filter "Url -like '-my.sharepoint.com/personal/'" | Select-Object Owner, Title, URL, StorageUsageCurrent | Sort-Object Owner -Desc
$TotalODFBGBUsed = [Math]::Round(($ODFBSites.StorageUsageCurrent | Measure-Object -Sum).Sum / 1024, 2)
Write-Output "Total ODFB Used: $TotalODFBGBUsed"
$ODFBReport = [System.Collections.Generic.List[Object]]::new()
ForEach ($Site in $ODFBSites) {
    $ReportLine = @{
        Owner  = $Site.Title
        Email  = $Site.Owner
        URL    = $Site.URL
        UsedGB = [Math]::Round($Site.StorageUsageCurrent / 1024, 4)
    }
    $ODFBReport.Add($ReportLine) 
}

$userList = [System.Collections.Generic.List[Object]]::new()
foreach ($user in $users) {
    #Get Mailbox size
    if ($null -ne ($user | Select-Object -ExpandProperty ProxyAddresses)) {
        $primarySMTP = ($user | Select-Object -ExpandProperty ProxyAddresses | Where-Object { $_ -clike "SMTP:*" }).split(':')[1]
        $mailboxSize = Get-EXOMailboxStatistics -Identity $primarySMTP
        $mailboxMoveTime = "{0} Hours" -f ($mailboxSize.TotalItemSize.Value.ToGB() / 1.5)
    }
    else {
        $mailboxSize = ""
        $mailboxMoveTime = ""
    }

    #Get oneDriveSize
    $oneDrive = ""
    $oneDrive = $ODFBReport | Where-Object -Property Email -EQ $user.UserPrincipalName 


    #if a user has no GivenName or Surname it raises a null-value exception so setting them here in case they are missing
    if ($null -eq $user.GivenName) {
        $user.GivenName = "NA"
    }
    if ($null -eq $user.Surname) {
        $user.Surname = "NA"
    }

    #Create unique password for each user
    $passwordArray = @()
    $passwordArray += ((65..90) | Get-Random)
    $passwordArray += ((97..122) | Get-Random -Count 3)
    $passwordArray += ((48..57) | Get-Random -Count 4)
    $password = -join ($passwordArray | ForEach-Object { [char]$_ })

    $sourceAddAlias = "{0}.{1}@{2}" -f ($user.GivenName.Split(" ")[0], $user.Surname.Replace(" ", "."), $sourceTmpDomain)
    $sourceAddAlias = $sourceAddAlias.Replace("å", "a").Replace("ø", "o").Replace("æ", "a").ToLower()
    $destinationUPN = "{0}.{1}@{2}" -f ($user.GivenName.Split(" ")[0], $user.Surname.Replace(" ", "."), $user.UserPrincipalName.Split("@")[1])
    $destinationUPN = $destinationUPN.Replace("å", "a").Replace("ø", "o").Replace("æ", "a").ToLower()
    $destinationTmpUPN = "{0}.{1}@{2}" -f ($user.GivenName.Split(" ")[0], $user.Surname.Replace(" ", "."), $targetTmpDomain)
    $destinationTmpUPN = $destinationTmpUPN.Replace("å", "a").Replace("ø", "o").Replace("æ", "a").ToLower()

    $userInfo = [PSCustomObject]@{
        sourceUPN              = $user.UserPrincipalName
        isLicensed             = $user.AssignedLicenses.Count
        mailboxSize            = $mailboxSize.TotalItemSize.Value
        mailboxMoveTime        = $mailboxMoveTime
        oneDriveSize           = "{0} GB" -f $oneDrive.UsedGB
        oneDriveMoveTime       = "{0} Hours" -f ($oneDrive.UsedGB / 2)
        firstName              = $user.GivenName
        lastName               = $user.Surname
        sourceDisplayName      = $user.DisplayName
        sourcePrimarySMTP      = $primarySMTP
        sourceProxy            = $user.ProxyAddresses -join "&"
        sourceAddAlias         = $sourceAddAlias
        destinationUPN         = $destinationUPN
        destinationTmpUPN      = $destinationTmpUPN
        destinationAlias       = $user.ProxyAddresses -join "&"
        destinationDisplayName = $user.DisplayName
        licenseGroup           = ""
        ObjectId               = $user.ObjectId
        Password               = $password
        MobileNumber           = $user.Mobile
    }
    $userList.Add($userInfo)
}

$userList | Export-CSV -NoTypeInformation -Path "..\Reports\masterdata.csv" -Delimiter ',' -Encoding UTF8


<#
Device list
#>

Get-AzureADDevice | Select-Object DisplayName, ProfileType, DeviceTrustType, DeviceId, ApproximateLastLogonTimeStamp | Export-Csv -Path "..\Reports\Devices.csv" -NoTypeInformation -Delimiter ',' -Encoding UTF8


<#
Teams export
#>
$teams = Get-Team

#All Teams
$TeamsResult = ""  
$TeamsResults = @() 
$userResult = ""
$userResults = @()
$Count = 0
$TeamsCount = $teams.Count
foreach ($team in $teams) {
    $TeamName = $team.DisplayName
    $Count++
    Write-Progress -Activity "`n     Processing Team: $Count of: $TeamsCount "`n"  Currently Processing: $TeamName"
    $Visibility = $team.Visibility
    $MailNickName = $team.MailNickName
    $Description = $team.Description
    $Archived = $team.Archived
    $GroupId = $team.GroupId
    $ChannelCount = (Get-TeamChannel -GroupId $GroupId).count
    $TeamUser = Get-TeamUser -GroupId $GroupId
    $TeamMemberCount = $TeamUser.Count
    $TeamOwnerCount = ($TeamUser | Where-Object { $team.role -eq "Owner" }).count
    $TeamsResult = @{'Teams Name' = $TeamName; 'Team Type' = $Visibility; 'Mail Nick Name' = $MailNickName; 'Description' = $Description; 'Archived Status' = $Archived; 'Channel Count' = $ChannelCount; 'Team Members Count' = $TeamMemberCount; 'Team Owners Count' = $TeamOwnerCount }
    $TeamsResults = New-Object psobject -Property $TeamsResult
    $TeamsResults | Select-Object 'Teams Name', 'Team Type', 'Mail Nick Name', 'Description', 'Archived Status', 'Channel Count', 'Team Members Count', 'Team Owners Count' | Export-Csv -Path "..\Reports\AllTeamsReport.csv" -NoTypeInformation -Append -Delimiter ','

    foreach ($user in $TeamUser) {
        $Name = $user.Name
        $MemberMail = $user.User
        $Role = $user.Role
        $userResult = @{'Teams Name' = $TeamName; 'Member Name' = $Name; 'Member Mail' = $MemberMail; 'Role' = $Role }
        $userResults = New-Object psobject -Property $userResult
        $userResults | Select-Object 'Teams Name', 'Member Name', 'Member Mail', 'Role' | Export-Csv -Path "..\Reports\TeamsUserReport.csv" -NoTypeInformation -Append -Delimiter ',' -Encoding UTF8
    }
}


#List all groups with members and owners
$groups = Get-AzureADGroup

foreach ($group in $groups) {
    $groupOwners = Get-AzureADGroupOwner -ObjectId $group.ObjectId
    $groupMembers = Get-AzureADGroupMember -ObjectId $group.ObjectId

    foreach ($owner in $groupOwners) {
        $ownerResult = @{"GroupName" = $group.DisplayName; "GroupObjectId" = $group.ObjectId; "MemberName" = $owner.DisplayName; "MemberUPN" = $owner.UserPrincipalName; "MemberObjectId" = $owner.ObjectId; "Role" = "Owner" }
        $ownerResults = New-Object psobject -Property $ownerResult
        $ownerResults | Select-Object "GroupName", "GroupObjectId", "MemberName", "MemberUPN", "MemberObjectId", "Role" | Export-Csv -Path "..\Reports\GroupUserReport.csv" -NoTypeInformation -Append -Delimiter ','
    }

    foreach ($member in $groupMembers) {
        $memberResult = @{"GroupName" = $group.DisplayName; "GroupObjectId" = $group.ObjectId; "MemberName" = $member.DisplayName; "MemberUPN" = $member.UserPrincipalName; "MemberObjectId" = $member.ObjectId; "Role" = "Member" }
        $memberResults = New-Object psobject -Property $memberResult
        $memberResults | Select-Object "GroupName", "GroupObjectId", "MemberName", "MemberUPN", "MemberObjectId", "Role" | Export-Csv -Path "..\Reports\GroupUserReport.csv" -NoTypeInformation -Append -Delimiter ','
    }
}

<#
Get all SharePoint Sites with Size
#>

Get-SPOSite -Limit All | Export-Csv -Path "..\Reports\SPOSites.csv" -NoTypeInformation -Delimiter ','
