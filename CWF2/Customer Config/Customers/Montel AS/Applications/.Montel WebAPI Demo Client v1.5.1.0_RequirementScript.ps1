#Requires -RunAsAdministrator
<#
    .SYNOPSIS
        Return $true if computer is Intune enrolled and at least one Intune user profile has been created.
#>

# Input parameters
[OutputType([bool])]
Param ()

# Find Intune user SIDs
$UserSIDs = [string[]](
    $(
        [string[]](
            Get-ChildItem -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' -Recurse:$false
        ).'Name'
    ).ForEach{
        $_.Split('\')[-1]
    }.Where{
        $_ -like 'S-1-12-*'
    }
)

# Find user folders
$UserFolders = [string[]](
    $(Get-ChildItem -Path ('{0}\Users'-f$env:SystemDrive) -Directory).Where{
        $_.'Name' -notlike 'default*' -and $_.'Name' -notlike 'public'
    }
)

# Find OneDrive for Business folders
$UserOneDriveForBusinessFolders = [string[]](
    $(Get-ChildItem -Path ('{0}\Users'-f$env:SystemDrive) -Directory).Where{
        $_.'Name' -notlike 'default*' -and $_.'Name' -notlike 'public'
    }.ForEach{
        Get-ChildItem -Path $_.'FullName' -Filter 'OneDrive - *' -Directory
    }.'FullName'
)


# Return results
Write-Output -InputObject (
    $UserSIDs.'Count' -gt 0 -and 
    $UserFolders.'Count' -gt 0 -and
    $UserOneDriveForBusinessFolders.'Count' -gt 0
)
