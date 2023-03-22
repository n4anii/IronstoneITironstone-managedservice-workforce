#Requires -Version 5.1
<#
    .SYNOPSIS
        Will check if Automate has to be uninstalled.
#>



# Input parameters
[OutputType([bool])]
Param ()



# PowerShell Preference
$ErrorActionPreference = 'Continue'
$InformationPreference = 'Continue'



# Installed
## Assets
$Path  = [string] '{0}\LTSvc' -f $env:windir
$Files = [string[]](
    # Deeper    
    'plugins\ScreenConnectRemotePlugin.dll',
    # Root
    'LTSVC.exe',
    'LTErrors.txt'
)

## Check
$IsInstalled = [bool](
    $Files.ForEach{[bool][System.IO.File]::Exists('{0}\{1}'-f($Path,$_))} -notcontains $false
)



# Configured wrong
## Assets
$Path  = [string] 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\LabTech\Service'
$Names = [string[]](
    'LocationID',
    'Server Address',
    'ServerPassword'
)

## Check
$IsConfigured = [bool](
    [bool[]](
        $Names.ForEach{
            $Value = [string](Get-ItemPropertyValue -Path $Path -Name $_ -ErrorAction 'SilentlyContinue')
            [bool](
                $? -and -not [string]::IsNullOrEmpty($Value) -and $Value -notlike 'Insert *' -and $(
                    if ($_ -eq 'ServerPassword') {
                        $Value.'Length' -gt 32
                    }
                    else {
                        $true
                    }
                )
            )
        }
    ) -notcontains $false
)



# Successfully talking with backend server
## Assets
$Path = [string] 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\LabTech\Service'
$Name = [string] 'LastSuccessStatusFT'

## Get registry value
$LastSuccessStatus = [datetime]$(
    if ([bool]$(Try{$null=Get-ItemPropertyValue -Path $Path -Name $Name 2>$null;$?}Catch{$false})) {
        [datetime]::FromFileTimeUtc((Get-ItemPropertyValue -Path $Path -Name $Name))
    }
    else {
        [datetime]::MinValue
    }
)

## IsAlive
$IsAlive = [bool]($LastSuccessStatus -ge [datetime]::Now.AddDays(-7))



# Create result
$RequiresUninstall = [bool] $IsInstalled -and -not ($IsConfigured -and $IsAlive)



# Write information
Write-Information -MessageData ('$IsInstalled = {0}' -f $IsInstalled.ToString())
Write-Information -MessageData ('$IsConfigured = {0}' -f $IsConfigured.ToString())
Write-Information -MessageData ('$LastSuccessStatus = {0}' -f $LastSuccessStatus.ToString('yyyyMMdd-HHmmss'))
Write-Information -MessageData ('$IsAlive = {0}' -f $IsAlive)
Write-Information -MessageData ('$RequiresUninstall = {0}' -f $RequiresUninstall.ToString())



# Return result
$RequiresUninstall
