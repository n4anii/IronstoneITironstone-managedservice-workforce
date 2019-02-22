#Requires -RunAsAdministrator

# Path
$Paths = [string[]]@(
    [string]('Registry::HKEY_LOCAL_MACHINE\Software\Policies\Google\Chrome'),
    [string]('Registry::HKEY_USERS\{0}\Software\Policies\Google\Chrome' -f [string]([System.Security.Principal.NTAccount]::new((Get-Process -Name 'explorer' -IncludeUserName | Select-Object -ExpandProperty 'UserName' -First 1)).Translate([System.Security.Principal.SecurityIdentifier]).Value))
)
foreach ($Path in $Paths) {if (-not(Test-Path -Path $Path)){$null = New-Item -Path $Path -ItemType 'Directory' -Force -ErrorAction 'Stop'}}


# Set registry values
foreach ($Path in $Paths) {
    # DefaultBrowserSettingEnabled
    $null = Set-ItemProperty -Path $Path -Name 'DefaultBrowserSettingEnabled' -Value 0 -Type 'DWord' -Force

    # HomepageLocation
    $null = Set-ItemProperty -Path $Path -Name 'HomepageLocation' -Value 'https://portal.ironstoneit.com/ironstoneit' -Type 'String' -Force

    # HomepageIsNewTabPage
    $null = Set-ItemProperty -Path $Path -Name 'HomepageIsNewTabPage' -Value 0 -Type 'DWord' -Force

    # ShowHomeButton
    $null = Set-ItemProperty -Path $Path -Name 'ShowHomeButton' -Value 1 -Type 'DWord' -Force

    # WelcomePageOnOSUpgradeEnabled
    $null = Set-ItemProperty -Path $Path -Name 'WelcomePageOnOSUpgradeEnabled' -Value 0 -Type 'DWord' -Force
}