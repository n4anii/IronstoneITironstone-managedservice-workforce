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
$Files = [string[]](
    # Deeper    
    'plugins\ScreenConnectRemotePlugin.dll',
    # Root
    'LTSVC.exe',
    'LTErrors.txt'    
)
## Check
$IsInstalled = [bool](
    [bool[]]($Files.ForEach{[System.IO.File]::Exists('{0}\{1}'-f($Path,$_))}) -notcontains $false
)



# Configured wrong
## Assets
$Path  = [string] 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\LabTech\Service'
$Names = [string[]]('LocationID','Server Address','ServerPassword')
## Check
$IsConfigured = [bool](
    [bool[]](
        $Names.ForEach{
            $Value = [string](Get-ItemPropertyValue -Path $Path -Name $_ -ErrorAction 'SilentlyContinue')
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



# Successfully talking with backend server
## Assets
$Name = [string] 'LastSuccessStatus'
## Check
$LastSuccessStatus = [datetime]$(Get-ItemPropertyValue -Path $Path -Name $Name) 
## Create boolean
$SuccessfullyTalkingWithServer = [bool] $? -and $LastSuccessStatus -gt [datetime]::Now.AddDays(-5)



# Return result
[bool] $IsInstalled -and -not ($IsConfigured -and $SuccessfullyTalkingWithServer)
