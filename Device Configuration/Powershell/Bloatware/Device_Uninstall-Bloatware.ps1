﻿<#

Device_Uninstall-Bloatware

.SYNOPSIS
Removes all specified pre-installed appxprovisionedpackages from the device.

.DESCRIPTION
Removes all specified pre-installed appxprovisionedpackages from the device. This script MUST be deployed together with User_Uninstall-Bloatware.ps1, else the apps won't be removed from the user profile.

.NOTES
You need to run this script in the DEVICE context in Intune.

#>


# Script Variables
[bool]   $DeviceContext = $true
[string] $NameScript    = 'Uninstall-Bloatware'

# Settings - PowerShell - Output Preferences
$DebugPreference       = 'SilentlyContinue'
$InformationPreference = 'SilentlyContinue'
$VerbosePreference     = 'SilentlyContinue'
$WarningPreference     = 'Continue'



#region    Don't Touch This
# Settings - PowerShell - Interaction
$ConfirmPreference     = 'None'
$ProgressPreference    = 'SilentlyContinue'

# Settings - PowerShell - Behaviour
$ErrorActionPreference = 'Continue'

# Dynamic Variables - Process & Environment
[string] $NameScriptFull      = ('{0}_{1}' -f ($(if($DeviceContext){'Device'}Else{'User'}),$NameScript))
[string] $NameScriptVerb      = $NameScript.Split('-')[0]
[string] $NameScriptNoun      = $NameScript.Split('-')[-1]
[string] $ProcessArchitecture = $(if([System.Environment]::Is64BitProcess){'64'}Else{'32'})
[string] $OSArchitecture      = $(if([System.Environment]::Is64BitOperatingSystem){'64'}Else{'32'})

# Dynamic Variables - User
[string] $StrIsAdmin       = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
[string] $StrUserName      = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
[string] $SidCurrentUser   = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
[string] $SidSystemUser    = 'S-1-5-18'
[bool] $CurrentUserCorrect = $(
    if($DeviceContext -and $SIDCurrentUser -eq $SIDSystemUser){$true}
    elseif (-not($DeviceContext) -and $SIDCurrentUser -ne $SIDSystemUser){$true}
    else {$false}
)

# Dynamic Logging Variables
$Timestamp    = [DateTime]::Now.ToString('yyMMdd-HHmmssffff')
$PathDirLog   = ('{0}\IronstoneIT\Intune\DeviceConfiguration\' -f ($(if($DeviceContext -and $CurrentUserCorrect){$env:ProgramW6432}else{$env:APPDATA})))
$PathFileLog  = ('{0}{1}-{2}bit-{3}.txt' -f ($PathDirLog,$NameScriptFull,$ProcessArchitecture,$Timestamp))

# Start Transcript
if (-not(Test-Path -Path $PathDirLog)) {New-Item -ItemType 'Directory' -Path $PathDirLog -ErrorAction 'Stop'}
Start-Transcript -Path $PathFileLog

# Output User Info, Exit if not $CurrentUserCorrect
Write-Output -InputObject ('Running as user "{0}". Has admin privileges? {1}. $DeviceContext = {2}. Running as correct user? {3}.' -f ($StrUserName,$StrIsAdmin,$DeviceContext.ToString(),$CurrentUserCorrect.ToString()))
if (-not($CurrentUserCorrect)){Throw 'Not running as correct user!'} 

# Output Process and OS Architecture Info
Write-Output -InputObject ('PowerShell is running as a {0} bit process on a {1} bit OS.' -f ($ProcessArchitecture,$OSArchitecture))


# Wrap in Try/Catch, so we can always end the transcript
Try {    
    # If OS is 64 bit, and PowerShell got launched as x86, relaunch as x64
    if ( (-not([System.Environment]::Is64BitProcess))  -and [System.Environment]::Is64BitOperatingSystem) {
        write-Output -InputObject (' * Will restart this PowerShell session as x64.')
        if ($myInvocation.Line) {
            &"$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile $myInvocation.Line
        }
        else {
            &"$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile -File ('{0}' -f ($myInvocation.InvocationName)) $args
        }
        exit $lastexitcode
    }
    
    # End the Initialize Region
    Write-Output -InputObject ('**********************')
#endregion Don't Touch This
################################################
#region    Your Code Here
################################################
  
    
    # Registry Values to Check / Write
    $RegistryPath = 'HKLM:\SOFTWARE\IronstoneIT\Intune\DeviceConfiguration'
    $RegistryKey = 'DeviceUninstallBloatware'


    # Only uninstall apps if it has not been attempted before
    if (Test-Path -Path ('{0}\{1}' -f ($RegistryPath,$RegistryKey))) {
        Write-Output -InputObject ('Registry {0} already set' -f ($RegistryKey))
    }
    else {
        # List of apps we want to remove
        $AppsToRemove = @(
            'Microsoft.BingFinance*',
            'Microsoft.BingNews*',
            'Microsoft.BingSports*',
            'Microsoft.BingWeather*', 
            'Microsoft.Messaging',
            'Microsoft.People',
            'Microsoft.SkypeApp',
            'Microsoft.windowscommunicationsapps'
        )


        # Remove installed packages matching $AppsToRemove
        $AppxProvisionedPackages = @(Get-AppxProvisionedPackage -Online | Where-Object {$AppsToRemove.Contains($_.DisplayName)} | Select-Object -Property 'DisplayName','PackageName' | Sort-Object -Property 'DisplayName')
        Write-Output -InputObject ('{0} ProvisionedApps will be removed.' -f ($AppxProvisionedPackages.Count.ToString()))
        foreach ($App in $AppxProvisionedPackages) {
            $null = Remove-AppxProvisionedPackage -PackageName	$App.PackageName -Online -AllUsers
            Write-Output -InputObject ('Removing "{0}"... Success? {1}' -f ($App.DisplayName,$?.ToString()))
        }


        # Save to registry that this script has run
        Write-Output -InputObject ('Creating registry path "{0}" key "{1}".' -f ($RegistryPath,$RegistryKey))
        $null = New-Item -Path ('{0}\{1}' -f ($RegistryPath,$RegistryKey)) -Force
    }


################################################
#endregion Your Code Here
################################################   
#region    Don't touch this
}
Catch {
    # Construct Message
    $ErrorMessage = ('{0} finished with errors:' -f ($NameScriptFull))
    $ErrorMessage += " `n"
    $ErrorMessage += 'Exception: '
    $ErrorMessage += $_.Exception
    $ErrorMessage += " `n"
    $ErrorMessage += 'Activity: '
    $ErrorMessage += $_.CategoryInfo.Activity
    $ErrorMessage += " `n"
    $ErrorMessage += 'Error Category: '
    $ErrorMessage += $_.CategoryInfo.Category
    $ErrorMessage += " `n"
    $ErrorMessage += 'Error Reason: '
    $ErrorMessage += $_.CategoryInfo.Reason
    Write-Error -Message $ErrorMessage
}
Finally {
    Stop-Transcript
}
#endregion Don't touch this