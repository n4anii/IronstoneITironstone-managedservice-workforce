#Requires -RunAsAdministrator
<#
    .SYNOPSIS
        Detects whether HP Support Assistant is installed, either as Win32 app, or as UWP.
#>



# PowerShell Preferences
$ConfirmPreference     = 'None'
$DebugPreference       = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'
$InformationPreference = 'SilentlyContinue'
$ProgressPreference    = 'Ignore'
$VerbosePreference     = 'SilentlyContinue'
$WarningPreference     = 'Continue'



# Check if installed
$IsInstalled = [bool](
    [System.IO.File]::Exists('{0}\Hewlett-Packard\HP Support Framework\HPSF.exe'-f${env:ProgramFiles(x86)}) -or
    $(
        [array](
            Get-ChildItem -Path ('{0}\WindowsApps'-f$env:ProgramW6432) -Directory | Where-Object -Property 'Name' -Like '*HPSupportAssistant*'
        )
    ).'Count' -gt 0
)



# Exit
if ($IsInstalled) {
    Write-Output -InputObject 'Installed.'
    Exit 0
}
else {
    Write-Error -ErrorAction 'Continue' -Message 'Not installed.'
    Exit 1
}
