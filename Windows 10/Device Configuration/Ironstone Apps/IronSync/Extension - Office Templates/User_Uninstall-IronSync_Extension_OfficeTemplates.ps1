#Requires -Version 5.1
<#
    .SYNOPSIS
        Uninstalls IronSync - Extension - Office Templates.
#>


# PowerShell preferences
$ErrorActionPreference = 'Stop'


# Uninstall
$(
    [array](
        $([string[]]('Excel','PowerPoint','Word')).ForEach{
            [PSCustomObject]@{
                'Path'  = [string]'Registry::HKEY_CURRENT_USER\Software\Microsoft\Office\16.0\{0}\Options' -f $_
                'Name'  = [string]'PersonalTemplates'
            }
        }
    )
).ForEach{
    if ([bool]$(Get-ItemPropertyValue -Path $_.'Path' -Name $_.'Name' -ErrorAction 'SilentlyContinue';$?)) {
        $null = Remove-ItemProperty -Path $_.'Path' -Name $_.'Name' -Force
    }
}
