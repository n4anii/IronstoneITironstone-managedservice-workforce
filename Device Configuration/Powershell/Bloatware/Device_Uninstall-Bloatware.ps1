<#

.SYNOPSIS
Removes all specified pre-installed appxprovisionedpackages from the device.

.DESCRIPTION
Removes all specified pre-installed appxprovisionedpackages from the device. This script MUST be deployed together with User_Uninstall-Bloatware.ps1, else the apps won't be removed from the user profile.

.NOTES
You need to run this script in the DEVICE context in Intune.

#>
$AppName = 'Device_Uninstall_Bloatware'
$Timestamp = Get-Date -Format 'HHmmssffff'
$LogDirectory = ('{0}\Program Files\IronstoneIT\Intune\DeviceConfiguration' -f $env:SystemDrive)
$Transcriptname = ('{2}\{0}_{1}.txt' -f $AppName, $Timestamp, $LogDirectory)
$ErrorActionPreference = 'continue'

if (!(Test-Path -Path $LogDirectory)) {
    New-Item -ItemType Directory -Path $LogDirectory -ErrorAction Stop
}

Start-Transcript -Path $Transcriptname
#Wrap in a try/catch, so we can always end the transcript
Try {
    # Get the ID and security principal of the current user account
    $myWindowsID = [Security.Principal.WindowsIdentity]::GetCurrent()
    $myWindowsPrincipal = new-object -TypeName System.Security.Principal.WindowsPrincipal -ArgumentList ($myWindowsID)
 
    # Get the security principal for the Administrator role
    $adminRole = [Security.Principal.WindowsBuiltInRole]::Administrator
 
    # Check to see if we are currently running "as Administrator"
    if (!($myWindowsPrincipal.IsInRole($adminRole))) {
        # We are not running "as Administrator" - so relaunch as administrator
   
        # Create a new process object that starts PowerShell
        $newProcess = new-object -TypeName System.Diagnostics.ProcessStartInfo -ArgumentList 'PowerShell'
   
        # Specify the current script path and name as a parameter
        $newProcess.Arguments = $myInvocation.MyCommand.Definition
   
        # Indicate that the process should be elevated
        $newProcess.Verb = 'runas'
   
        # Start the new process
        [Diagnostics.Process]::Start($newProcess)
   
        # Exit from the current, unelevated, process
        Write-Output -InputObject 'Restart in elevated'
        exit
   
    }

    #64-bit invocation
    if ($env:PROCESSOR_ARCHITEW6432 -eq 'AMD64') {
        write-Output -InputObject "Y'arg Matey, we're off to the 64-bit land....."
        if ($myInvocation.Line) {
            &"$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile $myInvocation.Line
        }
        else {
            &"$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile -file ('{0}' -f $myInvocation.InvocationName) $args
        }
        exit $lastexitcode
    }
 
 
    #Remove bloatware
    $Installdate = [timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($(get-itemproperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion').InstallDate))
    $CurrentDate = Get-date 
    $Timespan = New-Timespan -Start $Installdate -End $CurrentDate
    [string]$HumanTimespan = ('Days: {0}. Hours: {1}' -f $Timespan.days, $Timespan.hours)
    
    if ($timespan.days -lt 1) {
        #Remove bloatware	
        $AppsToRemove = @(
            'Microsoft.Messaging',
            'Microsoft.Office.OneNote',
            'Microsoft.People',
            'Microsoft.SkypeApp',
            'Microsoft.windowscommunicationsapps'
        )

        #There is no better way to do this
        Foreach ($app in $appsToRemove) {
            $PackageName = Get-AppxProvisionedPackage -Online | Where-Object {$_.displayname -eq $app} | Select-Object -expandproperty PackageName
            if ($PackageName) {
                Write-Output -InputObject ('Removing AppxProvisionedPackage [{1}] with the appname [{0}].' -f $app, $PackageName)
                Remove-AppxProvisionedPackage -PackageName	$PackageName -Online -allusers
            }
            else {
                Write-Output -InputObject ('AppxProvisionedPackage [{0}] is not installed.' -f $app)
            }
        }
    }
    else {
        Write-Output -InputObject ('Timespan is outside the allowed range of one day. Timespan is [{0}].' -f $HumanTimespan)
    }
}
Catch {
    # Construct Message
    $ErrorMessage = 'Unable to uninstall all AppxProvisionedPackages.'
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
