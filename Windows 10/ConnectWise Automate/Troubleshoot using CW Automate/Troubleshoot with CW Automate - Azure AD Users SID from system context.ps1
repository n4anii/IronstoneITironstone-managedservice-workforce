#Requires -RunAsAdministrator
<#
    .SYNOPSIS
        Troubleshoot Azure AD users SID and similar for Intune devices from System context.
#>


# System context
## Join info
$JoinInfoPath = [string] 'Registry::{0}' -f (Get-ChildItem -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo').'Name'
[PSCustomObject]@{    
    'TenantId'    = [string](Get-ItemPropertyValue -Path $JoinInfoPath -Name 'TenantId')
    'DeviceOwner' = [string](Get-ItemPropertyValue -Path $JoinInfoPath -Name 'UserEmail')
} | Format-List


## All users
(Get-ChildItem -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList').Where{$_.'PSChildName'.'Length' -gt 8}.ForEach{
    [PSCustomObject]@{
        'SID'         = [string] $_.'PSChildName'
        'ProfilePath' = [string](Get-ItemPropertyValue -Path ('Registry::{0}'-f$_.'Name') -Name 'ProfileImagePath')
        'Username'    = [string] [System.Security.Principal.SecurityIdentifier]::new($_.'PSChildName').Translate([System.Security.Principal.NTAccount]).'Value'
    }
} | Sort-Object -Property 'Username' | Format-List



# User context
## All username and SID using the computer right now
[string[]](
    Get-WmiObject -Class 'Win32_Process' -Filter "Name='Explorer.exe'" -ErrorAction 'SilentlyContinue' | ForEach-Object -Process {
        $_.GetOwner()
    } | Where-Object -Property 'ReturnValue' -EQ 0 | Select-Object -Property @{'Name'='Username';'Expression'={[string]'{0}\{1}' -f $_.'Domain',$_.'User'}}
).'Username' | Sort-Object -Unique | ForEach-Object -Process {
    # Initial attributes
    $X = [PSCustomObject]@{
        'Username' = [string]$_
        'SID'      = [string][System.Security.Principal.NTAccount]::new($_).Translate([System.Security.Principal.SecurityIdentifier]).'Value'
    }
    # More attributes based on initial attributes
    ## Workplace Join
    $H = [string] 'Registry::{0}' -f (Get-ChildItem -Path ('Registry::HKEY_USERS\{0}\Software\Microsoft\Windows NT\CurrentVersion\WorkplaceJoin\AADNGC'-f$x.'SID') -ErrorAction 'SilentlyContinue').'Name'
    $null = Add-Member -InputObject $X -MemberType 'NoteProperty' -Name 'WorkplaceJoinTenantId' -Force -Value (
        $(if(Test-Path -Path $H){Try{Get-ItemPropertyValue -Path $H -Name 'TenantDomain'}Catch{''}}else{''})
    )
    $null = Add-Member -InputObject $X -MemberType 'NoteProperty' -Name 'WorkplaceJoinUserId' -Force -Value (
        $(if(Test-Path -Path $H){Try{Get-ItemPropertyValue -Path $H -Name 'UserId'}Catch{''}}else{''})
    )
    # OneDrive for Business
    $H = [string] 'Registry::HKEY_USERS\{0}\SOFTWARE\Microsoft\OneDrive\Accounts\Business1' -f $X.'SID'
    $null = Add-Member -InputObject $X -MemberType 'NoteProperty' -Force -Name 'OD4BUserName' -Value (Get-ItemPropertyValue -Path $H -Name 'UserName')
    $null = Add-Member -InputObject $X -MemberType 'NoteProperty' -Force -Name 'OD4BUserEmail' -Value (Get-ItemPropertyValue -Path $H -Name 'UserEmail')
    $null = Add-Member -InputObject $X -MemberType 'NoteProperty' -Force -Name 'OD4BTeamSiteSPOResourceId' -Value (Get-ItemPropertyValue -Path $H -Name 'TeamSiteSPOResourceId')
    # Return object
    $X
} | Format-List
