<#
    .SYNOPSIS
        Will check if Automate has to be uninstalled.
#>



# Input parameters
[OutputType([bool])]
Param ()



# PowerShell Preference
$ErrorActionPreference = 'Continue'



# Installed
## Assets
$Path  = [string] '{0}\LTSvc' -f $env:windir
$Files = [string[]]('LTSVC.exe','LTErrors.txt')
## Check
$IsInstalled = [bool](
    [bool[]]($Files.ForEach{[System.IO.File]::Exists('{0}\{1}'-f($Path,$_))}) -notcontains $false
)



# Configured wrong
## Assets
$RegPath      = [string] 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\LabTech\Service'
$Names        = [string[]]('LocationID','Server Address','ServerPassword')
## Check
$IsConfigured = [bool](
    [bool[]](
        $Names.ForEach{
            $Value = [string] $(Get-ItemProperty -Path $RegPath -Name $_ -ErrorAction 'SilentlyContinue').$_
            [bool](
                    -not [string]::IsNullOrEmpty($Value) -and $Value -notlike 'Insert *' -and $(
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



# Return result
[bool] $IsInstalled -and -not $IsConfigured
