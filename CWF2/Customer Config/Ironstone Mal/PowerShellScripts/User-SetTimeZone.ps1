<#
    .NAME
        User-SetTimeZone.ps1

    .SYNOPSIS
        Sets TimeZone for users to the value of $timeZone

    .DESCRIPTION
        To make sure all users have the correct timezone set since it doesn't always get properly set during setup

        For a list of available variables run "Get-TimeZone -ListAvailable", or if you only need the names "Get-TimeZone -ListAvailable | Select-Object Id"

    .NOTES
        You need to run this script in the USER context in Intune.
#>


$timeZone = "W. Europe Standard Time"


if ((Test-Path HKCU:\Software\IronstoneIT\Intune\DeviceConfiguration\SetTimeZone) -eq $false) {
    Set-TimeZone -Id $timeZone
    New-Item HKCU:\Software\IronstoneIT\Intune\DeviceConfiguration\SetTimeZone
}