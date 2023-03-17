#Requires -Version 5.1
<#
    .SYNOPSIS
        Adds reference to IronSync folder for the Microsoft Office suite, if the folder exists and holds templates.

    .EXAMPLE
        # From Intune Win32
        "%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy "Bypass" -NoLogo -NonInteractive -NoProfile -WindowStyle "Hidden" -Command "& '.\User_Install-IronSync_Extension_OfficeTemplates.ps1'; exit $LASTEXITCODE"
    
    .EXAMPLE
        # From PowerShell ISE
        & $psISE.'CurrentFile'.'FullPath'
#>



# Input parameters
[OutputType($null)]
Param()



# PowerShell Preferences
$ErrorActionPreference = 'Stop'



# Assets
$Path = [string] '{0}\IronSync' -f $env:PUBLIC



# Create registry values
$RegValues = [PSCustomObject[]]$(
    $([string[]]('Excel','PowerPoint','Word')).ForEach{
        # Assets
        $ChildDirectories = [string[]]((Get-ChildItem -Path $Path -Force -Directory -Filter ('*{0}*'-f$_) -ErrorAction 'SilentlyContinue').'FullName')
        $ChildDirectory   = [string]$(
            if ($? -and $ChildDirectories.Where{$_}.'Count' -eq 1) {
                $ChildDirectories
            }
            else {
                $Path
            }
        )
        # Output
        [PSCustomObject]@{
            'Path'  = [string]'Registry::HKEY_CURRENT_USER\Software\Microsoft\Office\16.0\{0}\Options' -f $_
            'Name'  = [string]'PersonalTemplates'
            'Value' = $ChildDirectory
            'Type'  = [string]'ExpandString'
        }
    }
)



# Check if installed values are different then what was created this run
$IsInstalled = [bool](
    $RegValues.ForEach{
        $ExistingValue = [string] (Get-ItemPropertyValue -Path $_.'Path' -Name $_.'Name' -ErrorAction 'SilentlyContinue')
        $? -and -not [string]::IsNullOrEmpty($ExistingValue) -and $_.'Value' -eq $ExistingValue
    } -notcontains $false
)



# Exit
if ($IsInstalled) {
    Write-Output -InputObject 'Success, is installed.'
    Exit 0
}
else {
    Write-Error -ErrorAction 'Continue' -Message 'Fail, is not installed.'
    Exit 1
}
