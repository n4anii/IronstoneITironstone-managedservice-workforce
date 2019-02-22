#Requires -RunAsAdministrator

<# 
.NAME
    Set-CountryTime&Settings

.SYNAPSIS
    Sets culture, locale, time zone, enables automatic time sync and adjustment of time zone, and forces time resync.

.RESOURCES
    http://www.thewindowsclub.com/windows-10-clock-time-wrong-fix

.TODO
    * Set automatically no matter language using Keyboard input method as source
    $KeyboardLayoutID = Get-Culture | Select-Object -ExpandProperty KeyboardLayoutId

#>



# Assets
$CultureNameWanted = 'nb-NO'
$LocaleLCIDWanted  = '1044'
$TimeZoneIdWanted  = 'W. Europe Standard Time'


# Culture - Format for time, date etc
Write-Output -InputObject ('Current Culture:   {0}' -f (($CultureCurrent = Get-Culture).DisplayName))
if ($CultureCurrent.Name -ne $CultureNameWanted) {
    Set-Culture -CultureInfo $CultureNameWanted
    Write-Output -InputObject ('   Changed to {0}' -f ($CultureNameWanted))
}


# Locale - Format for time, date etc
Write-Output -InputObject ('Current Locale:    {0}' -f (($LocaleCurrent = Get-WinSystemLocale).DisplayName))
if ($LocaleCurrent.LCID -ne $LocaleLCIDWanted) {
    Set-WinSystemLocale -SystemLocale $CultureNameWanted
    Write-Output -InputObject ('   Changed to {0}' -f ($CultureNameWanted))
}


# TimeZone
Write-Output -InputObject ('Current TimeZone:  {0}' -f (($TimeZoneCurrent = Get-TimeZone).Id))
if ($TimeZoneCurrent.Id -ne $TimeZoneIdWanted) {
    Set-TimeZone -Id $TimeZoneIdWanted
    Write-Output -InputObject ('   Changed to {0}' -f ($TimeZoneIdWanted))
}


# NTP Servers - Set default Microsoft NTP Servers & Add 'no.pool.ntp.org' and 'time.google.com' as backup servers
$PathDirReg    = [string]('Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\DateTime\Servers')
$URLNTPServers = [string[]]@('time.windows.com','time.nist.gov','no.pool.ntp.org','time.google.com')
$C = [byte](1)
foreach ($URL in $URLNTPServers) {
    $null = Set-ItemProperty -Path $PathDirReg -Name $C.ToString() -Value $URL -Type 'String'
    Write-Output -InputObject ('Adding "{0}" as time server number {1}.' -f ($URL,($C++).ToString()))
}


# Make sure "Set time automatically" is enabled
$null = Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\W32Time\Parameters' -Name 'Type' -Value 'NTP' -Type 'String' -Force

# Make sure "Set time zone automatically" is disabled                    (3 = Enabled, 4 = Disabled)
$null = Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\tzautoupdate' -Name 'Start' -Value 4 -Type 'DWord' -Force

# Make sure "Adjust for daylight saving time automatically" is enabled   (0 = Enabled, 1 = Disabled)
$null = Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\TimeZoneInformation' -Name 'DynamicDaylightTimeDisabled' -Value 0 -Type 'DWord' -Force


# Resync time
$null = Start-Process -FilePath ('{0}\w32tm.exe' -f ([System.Environment]::SystemDirectory)) -ArgumentList ('/resync /force') -NoNewWindow