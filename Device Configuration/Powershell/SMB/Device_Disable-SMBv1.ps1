<#

.SYNOPSIS
Disables SMBv1

.DESCRIPTION
Disables SMBv1 on the device. Requires a restart.

.NOTES
You need to run this script in the DEVICE context in Intune.

#>

$AppName = 'Device_Disable-SMBv1'
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
  $myWindowsID=[Security.Principal.WindowsIdentity]::GetCurrent()
  $myWindowsPrincipal=new-object -TypeName System.Security.Principal.WindowsPrincipal -ArgumentList ($myWindowsID)
 
  # Get the security principal for the Administrator role
  $adminRole=[Security.Principal.WindowsBuiltInRole]::Administrator
 
  # Check to see if we are currently running "as Administrator"
  if (!($myWindowsPrincipal.IsInRole($adminRole)))
  {
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
    }else{
        &"$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile -file ('{0}' -f $myInvocation.InvocationName) $args
    }
    exit $lastexitcode
  }
 
 
    #Remove bloatware
    Write-Output -InputObject 'Disabling [smb1protocol].'
    Disable-WindowsOptionalFeature -Online -FeatureName smb1protocol
    Write-Output -InputObject '[smb1protocol] is disabled.'
}
Catch {
  # Construct Message
  $ErrorMessage = 'Unable to disable smb1protocol.'
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
Finally
{
  Stop-Transcript
}
