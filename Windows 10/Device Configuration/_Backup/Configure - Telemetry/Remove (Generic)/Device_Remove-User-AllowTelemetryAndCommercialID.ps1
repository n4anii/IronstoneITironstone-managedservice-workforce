<#
.SYNAPSIS
    Deletes registry keys

.DESCRIPTION
    Deletes registry keys, if they exists and $WriteChanges = $true
    Script to completely remove CommercialID and AllowTelemetry from all known locations in registry.

.NOTES
    You need to run this script in the DEVICE context in Intune.
    This script is generic, no custom per customer values needed.
#>


#Change the app name
$AppName = 'Device_Remove-User-AllowTelemetryAndCommercialID'
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
 
 
 
    ##########################################################
    #region    Settings
        $VerbosePreference     = 'Continue'
        $WarningPreference     = 'Continue'
        $ErrorActionPreference = 'Continue'
        [bool] $WriteChanges   = $true
    #endregion Settings




    #region Variables
        Write-Verbose -Message '### Building variables'
        #region    Static Paths
            # Static paths and items to check
            [string[]] $Paths = @()
            [string[]] $Items = @('CommercialID','AllowTelemetry','AllowTelemetry_PolicyManager')
        #endregion Static Paths



        #region    Dynamic Paths
            # Add user paths to $Paths
            Write-Verbose -Message '# Checking for dynamic paths.'
            [string] $UserDir = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection\Users'
            $ChildItems = Get-ChildItem -Path $UserDir
            if ($ChildItems -eq $null) {
                Write-Verbose -Message 'Found none.'
            }
            else {
                foreach ($ChildItem in $ChildItems) {
                    [string] $Local:TempPath = [string]($ChildItem.Name.Replace('HKEY_LOCAL_MACHINE','HKLM:'))
                    Write-Verbose -Message ('Found path: {0}' -f ($Local:TempPath))
                    $Paths += @($Local:TempPath)
                }
            }
        #endregion Dynamic Paths

        Write-Verbose -Message '# Paths to check:'
        $Paths | ForEach-Object {Write-Verbose -Message ('{0}' -f ($_)) }
        Write-Verbose -Message '# Items to check in each path:'
        $Items | ForEach-Object {Write-Verbose -Message ('{0}' -f ($_)) }
    #endregion Variables




    #region    Remove Registry Items
        # Loop through all items
        Write-Verbose -Message '### Deleting items in paths if found.'
        foreach ($Path in $Paths) {
            foreach ($Item in $Items) {
                [string] $Local:PathRegItem = ('"{0}\{1}"' -f ($Path,$Item))
                Write-Verbose -Message ('Item: {0}' -f ($Local:PathRegItem))
                if ((Get-ItemProperty -Path $Path -Name $Item -ErrorAction SilentlyContinue) -ne $null) {
                #if (Test-Path -Path $Local:Item) {
                    Write-Verbose -Message ('   Remove-ItemProperty -Path "{0}" -Name "{1}"'-f ($Path,$Item))
                    if ($WriteChanges) {
                        $null = Remove-ItemProperty -Path $Path -Name $Item
                        if ($?) {
                            Write-Verbose -Message ('      Success')
                            Write-Output -InputObject ('Removed {0}' -f ($Local:PathRegItem))
                        }
                        else {
                            Write-Warning -Message ('      Fail')
                        }
                    }
                }
                else {
                    Write-Verbose -Message ('   Item does not exist')
                }
            }
        }
    #endregion Remove Registry Items



    Write-Output -InputObject 'Done.'
    ##########################################################
 
 
    
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