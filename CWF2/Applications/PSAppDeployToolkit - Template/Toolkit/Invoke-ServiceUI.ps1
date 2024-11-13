<#
.SYNOPSIS
This is a helper script to launch Deploy-Application.exe via ServiceUI to force the process to become visible when deployed by Intune, or other deployment systems that run in session 0.
.DESCRIPTION
This will launch the toolkit silently if the chosen process (explorer.exe by default) is not running. If it is running, then it will launch the toolkit interactively, and use ServiceUI to do so if the current process is non-interactive.
An alternate ProcessName can be specified if you only want the toolkit to be visible when a specific application is running.
Download MDT here: https://www.microsoft.com/en-us/download/details.aspx?id=54259
There are x86 and x64 builds of ServiceUI available in MDT under 'Microsoft Deployment Toolkit\Templates\Distribution\Tools'. Rename these to ServiceUI_x86.exe and ServiceUI_x64.exe and place them with this script in the root of the toolkit next to Deploy-Application.exe.
.PARAMETER ProcessName
Specifies the name of the process check for to trigger the interactive installation. Default value is 'explorer'. Multiple values can be supplied such as 'app1','app2'. The .exe extension must be omitted.
.PARAMETER DeploymentType
Specifies the type of deployment. Valid values are 'Install', 'Uninstall', or 'Repair'. Default value is 'Install'.
.PARAMETER AllowRebootPassThru
Passthru of switch to Deploy-Application.exe, will instruct the toolkit to not to mask a 3010 return code with a 0.
.PARAMETER TerminalServerMode
Passthru of switch to Deploy-Application.exe to enable terminal server mode.
.PARAMETER DisableLogging
Passthru of switch to Deploy-Application.exe to disable logging.
.EXAMPLE
.\Invoke-ServiceUI.ps1 -ProcessName 'WinSCP' -DeploymentType 'Install' -AllowRebootPassThru -AppWizName 'Value1'
Invoking the script from the command line with custom parameters.
.EXAMPLE
%SystemRoot%\System32\WindowsPowerShell\v1.0\PowerShell.exe -ExecutionPolicy Bypass -NoProfile -File Invoke-ServiceUI.ps1 -DeploymentType Install -AllowRebootPassThru -CustomParameter 'Value2'
An example command line to use in Intune with custom parameters.
#>
param (
    [string[]]$ProcessName = @('explorer'),
    [ValidateSet('Install', 'Uninstall', 'Repair')]
    [string]$DeploymentType = 'Install',
    [switch]$AllowRebootPassThru,
    [switch]$TerminalServerMode,
    [switch]$DisableLogging,
    [string]$AppWizName,
    [string]$WingetID,
    [string]$CustomParameter
)

Push-Location $PSScriptRoot

if ($env:PROCESSOR_ARCHITECTURE -eq 'AMD64' -or $env:PROCESSOR_ARCHITEW6432 -eq 'AMD64') {
    $Architecture = 'x64'
} else {
    $Architecture = 'x86'
}

if (Get-Process -Name $ProcessName -ErrorAction SilentlyContinue) {
    if ([Environment]::UserInteractive) {
        # Start-Process is used here otherwise script does not wait for completion
        $Arguments = "-DeploymentType $DeploymentType -DeployMode Interactive -AllowRebootPassThru:`$$AllowRebootPassThru -TerminalServerMode:`$$TerminalServerMode -DisableLogging:`$$DisableLogging"
        if ($AppWizName) { $Arguments += " -AppWizName $AppWizName" }
        if ($WingetID) { $Arguments += " -WingetID $WingetID" }
        if ($CustomParameter) { $Arguments += " -CustomParameter $CustomParameter" }
        $Process = Start-Process -FilePath '.\Deploy-Application.exe' -ArgumentList $Arguments -NoNewWindow -Wait -PassThru
        $ExitCode = $Process.ExitCode
    } else {
        # Using Start-Process with ServiceUI results in Error Code 5 (Access Denied)
        $Arguments = "-DeploymentType $DeploymentType -DeployMode Interactive -AllowRebootPassThru:`$$AllowRebootPassThru -TerminalServerMode:`$$TerminalServerMode -DisableLogging:`$$DisableLogging"
        if ($AppWizName) { $Arguments += " -AppWizName $AppWizName" }
        if ($WingetID) { $Arguments += " -WingetID $WingetID" }
        if ($CustomParameter) { $Arguments += " -CustomParameter $CustomParameter" }
        &".\ServiceUI_$Architecture.exe" -process:explorer.exe Deploy-Application.exe $Arguments
        $ExitCode = $LastExitCode
    }
} else {
    $Arguments = "-DeploymentType $DeploymentType -DeployMode Silent -AllowRebootPassThru:`$$AllowRebootPassThru -TerminalServerMode:`$$TerminalServerMode -DisableLogging:`$$DisableLogging"
    if ($AppWizName) { $Arguments += " -AppWizName $AppWizName" }
    if ($WingetID) { $Arguments += " -WingetID $WingetID" }
    if ($CustomParameter) { $Arguments += " -CustomParameter $CustomParameter" }
    $Process = Start-Process -FilePath '.\Deploy-Application.exe' -ArgumentList $Arguments -NoNewWindow -Wait -PassThru
    $ExitCode = $Process.ExitCode
}

Pop-Location
exit $ExitCode