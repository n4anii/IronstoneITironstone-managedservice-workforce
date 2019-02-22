<#

.SYNOPSIS


.DESCRIPTION


.NOTES
You need to run this script in the DEVICE context in Intune.

#>


#Change the app name
$AppName   = 'Device_Install-IronSync(Metier)'
# Settings - Logging
$Timestamp = Get-Date -Format 'HHmmssffff'
$LogDirectory = ('{0}\Program Files\IronstoneIT\Intune\DeviceConfiguration' -f ($env:SystemDrive))
$Transcriptname = ('{2}\{0}_{1}.txt' -f ($AppName,$Timestamp,$LogDirectory))
# Settings - PowerShell
$ErrorActionPreference = 'Continue'
$VerbosePreference = 'Continue'
$WarningPreference = 'Continue'


if (-not(Test-Path -Path $LogDirectory)) {
    New-Item -ItemType Directory -Path $LogDirectory -ErrorAction Stop
}

Start-Transcript -Path $Transcriptname
#Wrap in a try/catch, so we can always end the transcript
Try {
    # Get the ID and security principal of the current user account
    $myWindowsID = [Security.Principal.WindowsIdentity]::GetCurrent()
    $myWindowsPrincipal = New-Object -TypeName System.Security.Principal.WindowsPrincipal -ArgumentList ($myWindowsID)
 
    # Get the security principal for the Administrator role
    $adminRole = [Security.Principal.WindowsBuiltInRole]::Administrator
 
    # Check to see if we are currently running "as Administrator"
    if (-not($myWindowsPrincipal.IsInRole($adminRole))) {
        # We are not running "as Administrator" - so relaunch as administrator
   
        # Create a new process object that starts PowerShell
        $newProcess = New-Object -TypeName System.Diagnostics.ProcessStartInfo -ArgumentList 'PowerShell'
   
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
 
 

    #region    Code Goes Here
    ##############################

        #region    Initialize - Settings and Variables
            #region    Variables - Generic
                # Variables - Script
                [string] $NameScript           = 'IronSync'
                [string] $NameFileScript       = ('Install-{0}' -f ($NameScript))
                [bool] $ReadOnly               = $false
                [bool] $BoolScriptSuccess      = $true
                # Variables - Paths - IronSync
                [string] $PathDirIronSync      = ('{0}\Program Files\IronstoneIT\{1}\' -f ($env:SystemDrive,$NameScript))
                [string] $PathDirIronSyncLog   = ('{0}Logs\' -f ($PathDirIronSync))
                [string] $PathDirAzCopyJournal = ('{0}AzCopyJournal\' -f ($PathDirIronSync))
   
                # Settings - PowerShell
                $ConfirmPreference     = 'None' 
                $DebugPreference       = 'SilentlyContinue'
                $ErrorActionPreference = 'Stop'
                $InformationPreference = 'SilentlyContinue'
                $ProgressPreference    = 'SilentlyContinue'
                $VerbosePreference     = 'Continue'
                $WarningPreference     = 'Continue' 
            #endregion Variables - Generic      
            


            #region    Varbiable - Office Templates Edition           
                [string[]]$PathsDirOfficeReg = @('HKCU:\Software\Microsoft\Office\16.0\Excel\Options','HKCU:\Software\Microsoft\Office\16.0\Word\Options','HKCU:\Software\Microsoft\Office\16.0\PowerPoint\Options')
            #endregion Variables - Office Templates Edition
            


            #region    Variables - Case Specific              
                # Sync Folder
                [string] $PathDirSync = ('{0}\Users\Public\OfficeTemplates\' -f ($env:SystemDrive))               
                #region     Install Files
                    [PSCustomObject[]] $InstallFiles = @(
                        [PSCustomObject[]]@{Name=[string]('Schedule-{0}.ps1' -f ($NameScript));
                                            Encoding=[string]'utf8';
                                            Content=[string]'I1JlcXVpcmVzIC1SdW5Bc0FkbWluaXN0cmF0b3IKCjwjCiAgICAuREVTQ1JJUFRJT04KICAgICAgICBUaGlzIHNjcmlwdCB3aWxsIHN5bmMgZG93biBhIEF6dXJlIFN0b3JhZ2UgQWNjb3VudCBCbG9iIENvbnRhaW5lciB0byBzcGVjaWZpZWQgZm9sZGVyCgogICAgLlVTQUdFCiAgICAgICAgKiBZb3Ugc2hvdWxkIG9ubHkgbmVlZCB0byBlZGl0IHRoZSB2YXJpYWJsZXMgaW5zaWRlICIjcmVnaW9uIFZhcmlhYmxlcyAtIEVESVQgVEhFU0UgT05MWSIKICAgICAgICAqIFJlbWVtYmVyIHRvIGVtYmVkIGl0IGludG8gdGhlIGluc3RhbGwgc2NyaXB0IGFzIEJBU0U2NCEKICAgICAgICAqIFJlbWVtYmVyIHRvIHVzZSB0aGUgc2FtZSBmb2xkZXJzIGluIGJvdGggaW5zdGFsbGVyIGFuZCBzY2hlZHVsZSBzY3JpcHQhCiAgICAgICAgICAgICogUGF0aERpclN5bmMgICAgICAgICAgPSBGb2xkZXIgdG8gc3luYyB0aGUgQXp1cmUgQmxvYiBmaWxlcwogICAgICAgICAgICAqIFBhdGhEaXJBekNvcHlKb3VybmFsID0gQXpDb3B5IEpvdXJuYWwgRmlsZXMuIEF6Q29weSB3b24ndCBmdW5jdGlvbiB3aXRob3V0IGl0CiM+CgoKI3JlZ2lvbiAgICBJbml0aWFsaXplIC0gU2V0dGluZ3MgYW5kIFZhcmlhYmxlcwogICAgIyBWYXJpYWJsZXMgLSBTY3JpcHQKICAgIFtzdHJpbmddICROYW1lU2NyaXB0ICAgICAgPSAnSXJvblN5bmMnCiAgICBbc3RyaW5nXSAkTmFtZUZpbGVTY3JpcHQgID0gKCdTY2hlZHVsZS17MH0nIC1mICgkTmFtZVNjcmlwdCkpCiAgICBbYm9vbF0gJEJvb2xTY3JpcHRTdWNjZXNzID0gJHRydWUKICAgICMgVmFyaWFibGVzIC0gTG9nCiAgICBbc3RyaW5nXSAkUGF0aERpckxvZyAgID0gKCd7MH1cUHJvZ3JhbSBGaWxlc1xJcm9uc3RvbmVJVFx7MX1cTG9nc1wnIC1mICgkZW52OlN5c3RlbURyaXZlLCROYW1lU2NyaXB0KSkKICAgIFtzdHJpbmddICROYW1lRmlsZUxvZyAgPSAoJ3swfS1ydW5sb2ctezF9LmxvZycgLWYgKCROYW1lU2NyaXB0LChHZXQtRGF0ZSAtRm9ybWF0ICd5eU1NZGRoaG1tc3MnKSkpCiAgICBbc3RyaW5nXSAkUGF0aEZpbGVMb2cgID0gKCd7MH17MX0nIC1mICgkUGF0aERpckxvZywkTmFtZUZpbGVMb2cpKQogICAgIyBTZXR0aW5ncyAtIFBvd2VyU2hlbGwKICAgICREZWJ1Z1ByZWZlcmVuY2UgICAgICAgPSAnU2lsZW50bHlDb250aW51ZScKICAgICRFcnJvckFjdGlvblByZWZlcmVuY2UgPSAnU3RvcCcKICAgICRJbmZvcm1hdGlvblByZWZlcmVuY2UgPSAnU2lsZW50bHlDb250aW51ZScKICAgICRQcm9ncmVzc1ByZWZlcmVuY2UgICAgPSAnU2lsZW50bHlDb250aW51ZScKICAgICRWZXJib3NlUHJlZmVyZW5jZSAgICAgPSAnQ29udGludWUnCiAgICAkV2FybmluZ1ByZWZlcmVuY2UgICAgID0gJ0NvbnRpbnVlJwoKICAgICNyZWdpb24gICAgVmFyaWFibGVzIC0gRURJVCBUSEVTRSBPTkxZCiAgICAgICAgIyBWYXJpYWJsZXMgLSBFbnZpcm9ubWVudAogICAgICAgIFtzdHJpbmddICRQYXRoRGlyU3luYyAgPSAoJ3swfVxVc2Vyc1xQdWJsaWNcT2ZmaWNlVGVtcGxhdGVzXCcgLWYgKCRlbnY6U3lzdGVtRHJpdmUpKQogICAgICAgICMgVmFyaWFibGVkIC0gQ29ubmVjdGlvbiBJbmZvCiAgICAgICAgW3N0cmluZ10gJFN0b3JhZ2VBY2NvdW50TmFtZSAgICAgPSAnbWV0aWVyY2xpZW50c3RvcmFnZScKICAgICAgICBbc3RyaW5nXSAkU3RvcmFnZUFjY291bnRTQVNUb2tlbiA9ICc/c3Y9MjAxNy0wNy0yOSZzcz1iJnNydD1jbyZzcD1ybCZzZT0yMDE5LTAxLTAxVDIxOjA1OjI5WiZzdD0yMDE4LTA0LTExVDEyOjA1OjI5WiZzcHI9aHR0cHMmc2lnPUs3N0lLTXdpTVM3STE1REwlMkZ3dGJiUEVERElHQVJ0aVdjZEpvM1UxWUdGNCUzRCcgICAgICAgICAgICAgICAgICAgICAKICAgICNlbmRyZWdpb24gVmFyaWFibGVzIC0gRURJVCBUSEVTRSBPTkxZCiNlbmRyZWdpb24gSW5pdGlhbGl6ZSAtIFNldHRpbmdzIGFuZCBWYXJpYWJsZXMKCgp0cnkgewojcmVnaW9uICAgICBNYWluCiAgICAjcmVnaW9uICAgIExvZ2dpbmcKICAgICAgICBpZiAoLW5vdChUZXN0LVBhdGggLVBhdGggJFBhdGhEaXJMb2cpKSB7TmV3LUl0ZW0gLVBhdGggJFBhdGhEaXJMb2cgLUl0ZW1UeXBlICdEaXJlY3RvcnknIC1Gb3JjZX0KICAgICAgICBTdGFydC1UcmFuc2NyaXB0IC1QYXRoICRQYXRoRmlsZUxvZwogICAgI2VuZHJlZ2lvbiBMb2dnaW5nCiAgICAKCgogICAgI3JlZ2lvbiAgICBBekNvcHkgLSBWYXJpYWJsZXMKICAgICAgICA8IyBTd2l0Y2hlcwogICAgICAgICAgICAvWiAgICAgICAgPSBKb3VybmFsIGZpbGUgZm9sZGVyLCBmb3IgQXpDb3B5IHRvIHJlc3VtZSBvcGVyYXRpb24KICAgICAgICAgICAgL1kgICAgICAgID0gU3VycHJlc3MgYWxsIGNvbmZpcm1hdGlvbnMKICAgICAgICAgICAgL1MgICAgICAgID0gU3BlY2lmaWVzIHJlY3Vyc2l2ZSBtb2RlIGZvciBjb3B5IG9wZXJhdGlvbnMuIEluIHJlY3Vyc2l2ZSBtb2RlLCBBekNvcHkgd2lsbCBjb3B5IGFsbCBibG9icyBvciBmaWxlcyB0aGF0IG1hdGNoIHRoZSBzcGVjaWZpZWQgZmlsZSBwYXR0ZXJuLCBpbmNsdWRpbmcgdGhvc2UgaW4gc3ViZm9sZGVycy4KICAgICAgICAgICAgL0NoZWNrTUQ1ID0gU2VlIGlmIGRlc3RpbmF0aW9uIG1hdGNoZXMgc291cmNlIE1ENQogICAgICAgICAgICAvTCAgICAgICAgPSBTcGVjaWZpZXMgYSBsaXN0aW5nIG9wZXJhdGlvbiBvbmx5OyBubyBkYXRhIGlzIGNvcGllZC4KICAgICAgICAgICAgL01UICAgICAgID0gU2V0cyB0aGUgZG93bmxvYWRlZCBmaWxlJ3MgbGFzdC1tb2RpZmllZCB0aW1lIHRvIGJlIHRoZSBzYW1lIGFzIHRoZSBzb3VyY2UgYmxvYiBvciBmaWxlJ3MuCiAgICAgICAgICAgIC9YTiAgICAgICA9IEV4Y2x1ZGVzIGEgbmV3ZXIgc291cmNlIHJlc291cmNlLiBUaGUgcmVzb3VyY2Ugd2lsbCBub3QgYmUgY29waWVkIGlmIHRoZSBzb3VyY2UgaXMgdGhlIHNhbWUgb3IgbmV3ZXIgdGhhbiBkZXN0aW5hdGlvbi4KICAgICAgICAgICAgL1hPICAgICAgID0gRXhjbHVkZXMgYW4gb2xkZXIgc291cmNlIHJlc291cmNlLiBUaGUgcmVzb3VyY2Ugd2lsbCBub3QgYmUgY29waWVkIGlmIHRoZSBzb3VyY2UgcmVzb3VyY2UgaXMgdGhlIHNhbWUgb3Igb2xkZXIgdGhhbiBkZXN0aW5hdGlvbi4KICAgICAgICAjPgogICAgICAgIFtzdHJpbmddICRTdG9yYWdlQWNjb3VudFVSTCAgICA9ICgnaHR0cHM6Ly97MH0uYmxvYi5jb3JlLndpbmRvd3MubmV0JyAtZiAoJFN0b3JhZ2VBY2NvdW50TmFtZSkpCiAgICAgICAgW3N0cmluZ10gJFN0b3JhZ2VBY2NvdW50QmxvYlVSTD0gKCd7MH0vb2ZmaWNlMzY1LXRlbXBsYXRlcycgLWYgKCRTdG9yYWdlQWNjb3VudFVSTCkpCiAgICAgICAgW3N0cmluZ10gJFBhdGhGaWxlQXpDb3B5ICAgICAgID0gKCd7MH1cUHJvZ3JhbSBGaWxlcyAoeDg2KVxNaWNyb3NvZnQgU0RLc1xBenVyZVxBekNvcHlcQXpDb3B5LmV4ZScgLWYgKCRlbnY6U3lzdGVtRHJpdmUpKQogICAgICAgIFtzdHJpbmddICRQYXRoRGlyQXpDb3B5Sm91cm5hbCA9ICgnezB9XFByb2dyYW0gRmlsZXNcSXJvbnN0b25lSVRcezF9XEF6Q29weUpvdXJuYWxcJyAtZiAoJGVudjpTeXN0ZW1Ecml2ZSwkTmFtZVNjcmlwdCkpCiAgICAjZW5kcmVnaW9uIEF6Q29weSAtIFZhcmlhYmxlcwoKCgogICAgI3JlZ2lvbiAgICBDaGVjayBpZiBuZWNjZXNzYXJ5IHBhdGhzIGV4aXN0CiAgICAgICAgV3JpdGUtT3V0cHV0IC1JbnB1dE9iamVjdCAoJyMgQ2hlY2tpbmcgZm9yIG5lY2Nlc3NhcnkgcGF0aHMgYW5kIGZpbGVzJykKICAgICAgICBbc3RyaW5nW11dICRQYXRoc1RvQ2hlY2sgPSBAKCRQYXRoRGlyU3luYywkUGF0aEZpbGVBekNvcHksJFBhdGhEaXJBekNvcHlKb3VybmFsKQogICAgICAgIGZvcmVhY2ggKCRQYXRoIGluICRQYXRoc1RvQ2hlY2spIHsKICAgICAgICAgICAgaWYgKFRlc3QtUGF0aCAtUGF0aCAkUGF0aCkgewogICAgICAgICAgICAgICAgV3JpdGUtT3V0cHV0IC1JbnB1dE9iamVjdCAoJyAgIFN1Y2Nlc3MgLSB7MH0gZG9lcyBleGlzdC4nIC1mICgkUGF0aCkpCiAgICAgICAgICAgIH0KICAgICAgICAgICAgZWxzZSB7CiAgICAgICAgICAgICAgICBXcml0ZS1PdXRwdXQgLUlucHV0T2JqZWN0ICgnICAgRXJyb3IgLSB7MH0gZG9lcyBOT1QgZXhpc3RzLiBDYW4gbm90IGNvbnRpbnVlIHdpdGhvdXQgaXQnIC1mICgkUGF0aCkpCiAgICAgICAgICAgICAgICAkQm9vbFNjcmlwdFN1Y2Nlc3MgPSAkZmFsc2UKICAgICAgICAgICAgfQogICAgICAgIH0KICAgICAgICBJZiAoLW5vdCgkQm9vbFNjcmlwdFN1Y2Nlc3MpKSB7QnJlYWt9CiAgICAjZW5kcmVnaW9uIENoZWNrIGlmIG5lY2Nlc3NhcnkgcGF0aHMgZXhpc3QKICAgICAgICAKCgoKICAgICNyZWdpb24gICAgQXpDb3B5IC0gU3luYyBkb3duIHVzaW5nIFNBUyBUb2tlbiAgICAgICAKICAgICAgICAjIERvd25sb2FkCiAgICAgICAgJG51bGwgPSBTdGFydC1Qcm9jZXNzIC1GaWxlUGF0aCAkUGF0aEZpbGVBekNvcHkgLVdpbmRvd1N0eWxlICdIaWRkZW4nIC1Bcmd1bWVudExpc3QgKCcvU291cmNlOnswfSAvRGVzdDp7MX0gL1NvdXJjZVNBUzp7Mn0gL1o6InszfSIgL1kgL1MgL01UIC9YTycgLWYgKCRTdG9yYWdlQWNjb3VudEJsb2JVUkwsJFBhdGhEaXJTeW5jLCRTdG9yYWdlQWNjb3VudFNBU1Rva2VuLCRQYXRoRGlyQXpDb3B5Sm91cm5hbCkpIC1XYWl0CiAgICAgICAgaWYgKCAoLW5vdCgkPykpIC1vciAoKEdldC1DaGlsZEl0ZW0gLVBhdGggJFBhdGhEaXJTeW5jIC1GaWxlIC1Gb3JjZSkuTGVuZ3RoIC1sZSAwKSApIHsKICAgICAgICAgICAgV3JpdGUtT3V0cHV0IC1JbnB1dE9iamVjdCAoJ0VSUk9SIC0gTm8gZmlsZXMgZm91bmQgaW4gZGlyZWN0b3J5ICJ7MH0iIGFmdGVyIEF6Q29weSBmaW5pc2hlZC4nIC1mICgkUGF0aERpclN5bmMpKQogICAgICAgICAgICAkQm9vbFNjcmlwdFN1Y2Nlc3MgPSAkZmFsc2UKICAgICAgICB9CiAgICAjZW5kcmVnaW9uIEF6Q29weSAtIFN5bmMgZG93biB1c2luZyBTQVMgVG9rZW4KI2VuZHJlZ2lvbiBNYWluCn0KCgoKZmluYWxseSB7CiAgICAjIFN0b3AgVHJhbnNjcmlwdAogICAgU3RvcC1UcmFuc2NyaXB0CiAgICAjIERvbid0IGtlZXAgdGhlIGxvZyBmaWxlIGlmIHN1Y2Nlc3MKICAgIGlmICgkQm9vbFNjcmlwdFN1Y2Nlc3MpIHtSZW1vdmUtSXRlbSAtUGF0aCAkUGF0aEZpbGVMb2cgLUZvcmNlfQp9';}
                        [PSCustomObject[]]@{Name=([string]'Run-{0}.vbs' -f ($NameScript));
                                            Encoding=[string]'default';
                                            Content=[string]'U2V0IG9ialNoZWxsID0gQ3JlYXRlT2JqZWN0KCJXc2NyaXB0LlNoZWxsIikgIApTZXQgYXJncyA9IFdzY3JpcHQuQXJndW1lbnRzICAKRm9yIEVhY2ggYXJnIEluIGFyZ3MgIAogICAgRGltIFBTUnVuCiAgICBQU1J1biA9ICJwb3dlcnNoZWxsLmV4ZSAtV2luZG93U3R5bGUgaGlkZGVuIC1FeGVjdXRpb25Qb2xpY3kgYnlwYXNzIC1Ob25JbnRlcmFjdGl2ZSAtRmlsZSAiIiIgJiBhcmcgJiAiIiIiCiAgICBvYmpTaGVsbC5SdW4oUFNSdW4pLDAKTmV4dA==';}
                    )
                #endregion Install Files                
            #endregion Variables - Case Specific
            


            #region    Variables - Dynamically Created
                # Paths to create if does not exist
                [string[]] $PathsToCreate = @($PathDirIronSync,$PathDirIronSyncLog,$PathDirAzCopyJournal,$PathDirSync)
                # Paths to remove if exist
                [string[]] $PathsToRemove = @(('{0}\Users\Public\OfficeTemplateMO\' -f ($env:SystemDrive)))
            #endregion Variables - Dynamically Created
        #endregion Initialize - Settings and Variables




        #region    Functions
            #region    FileOut-FromBase64
            Function FileOut-FromBase64 {
                Param(
                    [Parameter(Mandatory=$true)]
                    [string] $InstallDir, $FileName, $File, $Encoding
                )
                [byte] $SubstringLength = $(If($File.Count -lt 10){$File.Count}Else{10})
                Write-Verbose -Message ('FileOut-FromBase64 -FilePath ' + $InstallDir + ' -FileName ' + $FileName + ' -File ' + ($File.Substring(0,$SubstringLength) + '...'))
                $Local:FilePath = $InstallDir + $FileName

                If (Test-Path -Path $InstallDir) {
                    Write-Verbose -Message ('   Path exists, trying to write the file (File alrady exists? {0})' -f (Test-Path -Path $Local:FilePath))
                    If (-not($ReadOnly)) {
                        Out-File -FilePath $Local:FilePath -Encoding $Encoding -InputObject ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($File))) -Force
                        Write-Verbose -Message ('      Success? {0}' -f ($?))
                        Write-Verbose -Message ('         Does file actually exist? {0}' -f (Test-Path $Local:FilePath -ErrorAction SilentlyContinue))
                    }
                }
                Else {
                    Write-Verbose -Message ('   ERROR: Path does not exist')
                }
            }
            #endregion FileOut-FromBase64



            #region    Write-ReadOnly
            function Write-ReadOnly {Write-Verbose -Message ('ReadOnly = {0}, will not write any changes.' -f ($ReadOnly))}
            #endregion Write-ReadOnly
        #endregion Functions




        #region    Cleanup Previous Install
            # Install folder
            if (Test-Path -Path $PathDirIronSync) {Remove-Item -Path $PathDirIronSync -Recurse -Force}
            # Previous versions leftovers
            foreach ($Path in $PathsToRemove) {If (Test-Path -Path $Path) {Remove-Item -Path $Path -Recurse -Force}}
        #endregion Cleanup Previous Install




        #region    Create Template folder & IronSync Folder - For Schedule and log files      
            foreach ($Dir in $PathsToCreate) {
                If (Test-Path -Path $Dir) {
                    Write-Verbose -Message ('Path "{0}" already exist.' -f ($Dir))
                }
                Else {
                    Write-Verbose -Message ('Path "{0}" does not already exist.' -f ($Dir))
                    If ($ReadOnly) {Write-ReadOnly}
                    Else {
                        $null = New-Item -Path $Dir -ItemType 'Directory' -Force
                        Write-Verbose -Message ('Creating.. Success? {0}' -f ($?))
                    }
                }
            }
        #endregion Create Template folder & IronSync Folder - For Schedule and log files




        #region    Set hidden folder
        Write-Verbose -Message ('Setting folder "{0}" to be ReadOnly and Hidden' -f ($PathDirSync))
        If ($ReadOnly) {Write-ReadOnly}
        Else {
            (Get-Item $PathDirSync -Force).Attributes = 'Hidden, ReadOnly, Directory'
            Write-Verbose -Message ('Success? {0}' -f ($?))
        }
        #endregion Set hidden folder




        #region    Set template folder for O365 application
            #region    Get Current User + New PS Drive for HKU
                # Get current user
                [string] $CurrentUser         = (Get-Process -Name 'explorer' -IncludeUserName).UserName
                [string] $CurrentUserName     = $CurrentUser.Split('\')[-1]
                [string] $CurrentUserRegValue = (New-Object -TypeName System.Security.Principal.NTAccount($CurrentUser)).Translate([System.Security.Principal.SecurityIdentifier]).Value
                [string] $PathDirReg          = ('HKU:\{0}\' -f ($CurrentUserRegValue))

                # Set PS Drive
                If ((Get-PSDrive -Name 'HKU' -ErrorAction SilentlyContinue) -eq $null) {
                    New-PSDrive -PSProvider Registry -Name 'HKU' -Root HKEY_USERS
                }
            #endregion Get Current User + New PS Drive for HKU


            #region    Write reg values
            # Add template folder to O365 Templates
            foreach ($RegistryPathOffice in $PathsDirOfficeReg) {
                [string] $TempPath = $RegistryPathOffice
                if ($TempPath -like 'HKCU:\*') {
                    $TempPath = $TempPath.Replace('HKCU:\',$PathDirReg)
                }
        
                # Registry Dir 
                If (-not(Test-path -Path $TempPath)) {
                    Write-Verbose -Message ('Registry path "{0}" does not exist.' -f ($TempPath))
                    If ($ReadOnly) {Write-ReadOnly}
                    Else {
                        $null = New-Item -Path $TempPath -ItemType 'Directory' -Force
                        Write-Verbose -Message ('Registry path "{0}" does not exist. Creating it.. Success? {0}.' -f ($?))
                    }
                }
        
                # Registry value
                Write-Verbose -Message ('Setting registry key "{0}" item property "PersonalTemplates" = "{1}" .' -f ($TempPath,$PathDirSync))
                If ($ReadOnly) {Write-ReadOnly}
                Else {
                    $null = New-ItemProperty -Path $TempPath -Name 'PersonalTemplates' -Value $PathDirSync -PropertyType 'ExpandString' -Force
                    Write-Verbose -Message ('Success? {0}' -f ($?))
                }        
            }
            #endregion Write reg values
        #endregion Set template folder for O365 application




        #region    Install IronSync
            foreach ($File in $InstallFiles) {
                Write-Verbose -Message ('Installing IronSync file "{0}"' -f ($File.Name))
                If ($ReadOnly) {Write-ReadOnly}
                Else { 
                    FileOut-FromBase64 -InstallDir $PathDirIronSync -FileName $File.Name -File $File.Content -Encoding $File.Encoding
                }
            }
        #endregion Install IronSync



        #region    Create Scheduled Task
            [string] $PathFileWScript = ('{0}\System32\wscript.exe' -f ($env:windir))
            [string] $PathFilePS1 = ('{0}{1}' -f ($PathDirIronSync,$InstallFiles[0].Name))
            [string] $PathFileVBS = ('{0}{1}' -f ($PathDirIronSync,$InstallFiles[1].Name))

            $ScheduledTask = New-ScheduledTask                                                    `
                -Action    (New-ScheduledTaskAction -Execute $PathFileWScript -Argument ('"{0}" "{1}"' -f ($PathFileVBS,$PathFilePS1))) `
                -Principal (New-ScheduledTaskPrincipal 'NT AUTHORITY\SYSTEM')                     `
                -Trigger   (New-ScheduledTaskTrigger -Daily -At '1pm')                            `
                -Settings  (New-ScheduledTaskSettingsSet -Hidden)
            $ScheduledTask.Author = 'Ironstone'
            $ScheduledTask.Description = 'Runs IronSync, which syncs down files from Azure Blob Storage using AzCopy'
            $null = Register-ScheduledTask -TaskName $NameScript -Force -InputObject $ScheduledTask
            if ($?) {Start-ScheduledTask -TaskName $NameScript}
        #endregion Create Scheduled Task

    ##############################
    #endregion Code Goes Here
 
 
    
}
Catch {
    # Construct Message
    $ErrorMessage = ('Unable to {0}.' -f ($AppName))
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