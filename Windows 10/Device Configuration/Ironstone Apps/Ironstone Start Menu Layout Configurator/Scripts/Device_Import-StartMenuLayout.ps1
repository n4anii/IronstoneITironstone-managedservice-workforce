#Requires -Version 5.1 -RunAsAdministrator
<#  
    .NAME
        Device_Import-StartMenuLayout.ps1
    
    .NOTES
        Requires "StartMenuLayout.xml" to be in the same folder as this script in order for function.

        Install from Intune
            "%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy "Bypass" -NoLogo -NonInteractive -NoProfile -WindowStyle "Hidden" -Command "& '.\Device_Import-StartMenuLayout.ps1'; exit $LASTEXITCODE"

        Uninstall from Intune
            cmd /c "del /f "%SystemDrive%\Users\Default\AppData\Local\Microsoft\Windows\Shell\LayoutModification.xml""
#>

# Parameters
[CmdletBinding()]
Param()

# PowerShell Preferences
$ConfirmPreference      = 'None'
$InformationPreference  = 'SilentlyContinue'
$ProgressPreference     = 'SilentlyContinue'

# Asset
$ScriptWorkingDirectory = [string]$([string]$($MyInvocation.'MyCommand'.'Path').Replace(('\{0}' -f ($MyInvocation.'MyCommand'.'Name')),''))
$LayoutPath   = [string]$('{0}\StartMenuLayout.xml' -f ($ScriptWorkingDirectory))
$MountPath    = [string]$('{0}\Users\Default\AppData\Local\Microsoft\Windows\Shell\LayoutModification.xml' -f ($env:SystemDrive))

# Check if start layout exist
$LayoutExists = [bool]$(Test-Path -Path $LayoutPath)

# Verbose - "StartMenuLayout.xml" exist
Write-Verbose -Message ('"{0}" exists? {1}.' -f ($LayoutPath,$LayoutExists.ToString()))

# Import "StartMenuLayout.xml"
$Success = [bool]$(
    if ($LayoutExists) {
        Try{
            $null = Copy-Item -Path $LayoutPath -Destination $MountPath -Force;$?
        }
        Catch{
            $false
        }
    }
    else{
        $false
    }
)

# Verbose - Success importing StartLayout
Write-Verbose -Message ('Success importing Start Menu Layout? {0}.' -f ($Success.ToString()))

# Exit script, 0 if success, 1 if fail
Exit [byte]$(if($Success){0}else{1})