#Requires -RunAsAdministrator
<#
    .SYNOPSIS
        Will check if IronSync is installed.
#>



# Input parameters
[OutputType($null)]
Param ()



# Assets
## Manual
$Author   = 'Ironstone'
$Product  = 'IronSync'
$Version  = '200525'
## Dynamic
$DirPath  = [string]('{0}\IronstoneIT\{1}' -f ($env:ProgramW6432,$Product))
$RegPath  = [string]('Registry::\HKEY_LOCAL_MACHINE\SOFTWARE\IronstoneIT\Intune\{0}' -f ($Product))



# Check
$Success = [bool[]]$(
    # Scheduled task
    [bool](
        $(Get-ScheduledTask).Where{
            $_.'Author' -like ('*{0}*' -f ($Author)) -and
            $_.'TaskName' -like ('*{0}*' -f ($Product))
        }.'Count' -gt 0
    ),

    # Files
    [bool](
        $(Get-ChildItem -Path $DirPath -Filter '*.ps1').Where{
            $_.'Name' -like ('*{0}*' -f ($Product))
        }.'Count' -gt 0
    ),


    # Version
    [bool](
        $([string](Get-ItemProperty -Path $RegPath -Name 'Version' -ErrorAction 'SilentlyContinue').'Version') -eq $Version
    )
)



# Exit
if ($Success -notcontains $false) {
    Write-Output -InputObject 'Installed.'
    Exit 0
}
else {
    Write-Error -Message 'Not installed.' -Exception 'Not installed.' -ErrorAction 'Continue'
    Exit 1
}
