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
            # Variables - Script
            [string] $NameScript           = 'IronSync'
            [string] $NameFileScript       = ('Install-{0}' -f ($NameScript))
            [bool] $ReadOnly               = $false
            [bool] $BoolScriptSuccess      = $true
            # Variables - Paths - IronSync
            [string] $PathDirIronSync      = ('{0}\Program Files\IronstoneIT\{1}\' -f ($env:SystemDrive,$NameScript))
            [string] $PathDirIronSyncLog   = ('{0}Logs\' -f ($PathDirIronSync))
            [string] $PathDirAzCopyJournal = ('{0}AzCopyJournal\' -f ($PathDirIronSync))            
            # Variables - Paths - TemplateFolder
            [string] $PathDirSync          = ('{0}\Users\Public\OfficeTemplateMO\' -f ($env:SystemDrive))
            # Variables - Paths - All
            [string[]] $PathsToCreate      = @($PathDirIronSync,$PathDirIronSyncLog,$PathDirAzCopyJournal,$PathDirSync)
            # Variables - Install
            
            
            [string[]]$PathsDirOfficeReg = @('HKCU:\Software\Microsoft\Office\16.0\Excel\Options','HKCU:\Software\Microsoft\Office\16.0\Word\Options','HKCU:\Software\Microsoft\Office\16.0\PowerPoint\Options')
            #region     Install Files
                [PSCustomObject[]] $InstallFiles = @(
                    [PSCustomObject[]]@{Name=[string]('Schedule-{0}.ps1' -f ($NameScript));
                                        Encoding=[string]'utf8';
                                        Content=[string]'I1JlcXVpcmVzIC1SdW5Bc0FkbWluaXN0cmF0b3IKCiNyZWdpb24gICAgSW5pdGlhbGl6ZSAtIFNldHRpbmdzIGFuZCBWYXJpYWJsZXMKICAgICMgVmFyaWFibGVzIC0gU2NyaXB0CiAgICBbc3RyaW5nXSAkTmFtZVNjcmlwdCAgICAgID0gJ0lyb25TeW5jJwogICAgW3N0cmluZ10gJE5hbWVGaWxlU2NyaXB0ICA9ICgnU2NoZWR1bGUtezB9JyAtZiAoJE5hbWVTY3JpcHQpKQogICAgW2Jvb2xdICRCb29sU2NyaXB0U3VjY2VzcyA9ICR0cnVlCiAgICAjIFZhcmlhYmxlcyAtIExvZwogICAgW3N0cmluZ10gJFBhdGhEaXJMb2cgICA9ICgnezB9XFByb2dyYW0gRmlsZXNcSXJvbnN0b25lSVRcezF9XExvZ3NcJyAtZiAoJGVudjpTeXN0ZW1Ecml2ZSwkTmFtZVNjcmlwdCkpCiAgICBbc3RyaW5nXSAkTmFtZUZpbGVMb2cgID0gKCd7MH0tcnVubG9nLXsxfS5sb2cnIC1mICgkTmFtZVNjcmlwdCwoR2V0LURhdGUgLUZvcm1hdCAneXlNTWRkaGhtbXNzJykpKQogICAgW3N0cmluZ10gJFBhdGhGaWxlTG9nICA9ICgnezB9ezF9JyAtZiAoJFBhdGhEaXJMb2csJE5hbWVGaWxlTG9nKSkKICAgICMgVmFyaWFibGVzIC0gRW52aXJvbm1lbnQKICAgIFtzdHJpbmddICRQYXRoRGlyU3luYyAgPSAoJ3swfVxVc2Vyc1xQdWJsaWNcT2ZmaWNlVGVtcGxhdGVNTycgLWYgKCRlbnY6U3lzdGVtRHJpdmUpKQogICAgIyBTZXR0aW5ncyAtIFBvd2VyU2hlbGwKICAgICREZWJ1Z1ByZWZlcmVuY2UgICAgICAgPSAnU2lsZW50bHlDb250aW51ZScKICAgICRFcnJvckFjdGlvblByZWZlcmVuY2UgPSAnU3RvcCcKICAgICRJbmZvcm1hdGlvblByZWZlcmVuY2UgPSAnU2lsZW50bHlDb250aW51ZScKICAgICRQcm9ncmVzc1ByZWZlcmVuY2UgICAgPSAnU2lsZW50bHlDb250aW51ZScKICAgICRWZXJib3NlUHJlZmVyZW5jZSAgICAgPSAnQ29udGludWUnCiAgICAkV2FybmluZ1ByZWZlcmVuY2UgICAgID0gJ0NvbnRpbnVlJwojZW5kcmVnaW9uIEluaXRpYWxpemUgLSBTZXR0aW5ncyBhbmQgVmFyaWFibGVzCgoKdHJ5IHsKI3JlZ2lvbiAgICAgTWFpbgogICAgI3JlZ2lvbiAgICBMb2dnaW5nCiAgICBpZiAoLW5vdChUZXN0LVBhdGggLVBhdGggJFBhdGhEaXJMb2cpKSB7TmV3LUl0ZW0gLVBhdGggJFBhdGhEaXJMb2cgLUl0ZW1UeXBlICdEaXJlY3RvcnknIC1Gb3JjZX0KICAgIFN0YXJ0LVRyYW5zY3JpcHQgLVBhdGggJFBhdGhGaWxlTG9nCiAgICAjZW5kcmVnaW9uIExvZ2dpbmcKICAgIAoKICAgICNyZWdpb24gICAgQXpDb3B5CiAgICAgICAgPCMgU3dpdGNoZXMKICAgICAgICAgICAgL1ogICAgICAgID0gSm91cm5hbCBmaWxlIGZvbGRlciwgZm9yIEF6Q29weSB0byByZXN1bWUgb3BlcmF0aW9uCiAgICAgICAgICAgIC9ZICAgICAgICA9IFN1cnByZXNzIGFsbCBjb25maXJtYXRpb25zCiAgICAgICAgICAgIC9TICAgICAgICA9IFNwZWNpZmllcyByZWN1cnNpdmUgbW9kZSBmb3IgY29weSBvcGVyYXRpb25zLiBJbiByZWN1cnNpdmUgbW9kZSwgQXpDb3B5IHdpbGwgY29weSBhbGwgYmxvYnMgb3IgZmlsZXMgdGhhdCBtYXRjaCB0aGUgc3BlY2lmaWVkIGZpbGUgcGF0dGVybiwgaW5jbHVkaW5nIHRob3NlIGluIHN1YmZvbGRlcnMuCiAgICAgICAgICAgIC9DaGVja01ENSA9IFNlZSBpZiBkZXN0aW5hdGlvbiBtYXRjaGVzIHNvdXJjZSBNRDUKICAgICAgICAgICAgL0wgICAgICAgID0gU3BlY2lmaWVzIGEgbGlzdGluZyBvcGVyYXRpb24gb25seTsgbm8gZGF0YSBpcyBjb3BpZWQuCiAgICAgICAgICAgIC9NVCAgICAgICA9IFNldHMgdGhlIGRvd25sb2FkZWQgZmlsZSdzIGxhc3QtbW9kaWZpZWQgdGltZSB0byBiZSB0aGUgc2FtZSBhcyB0aGUgc291cmNlIGJsb2Igb3IgZmlsZSdzLgogICAgICAgICAgICAvWE4gICAgICAgPSBFeGNsdWRlcyBhIG5ld2VyIHNvdXJjZSByZXNvdXJjZS4gVGhlIHJlc291cmNlIHdpbGwgbm90IGJlIGNvcGllZCBpZiB0aGUgc291cmNlIGlzIHRoZSBzYW1lIG9yIG5ld2VyIHRoYW4gZGVzdGluYXRpb24uCiAgICAgICAgICAgIC9YTyAgICAgICA9IEV4Y2x1ZGVzIGFuIG9sZGVyIHNvdXJjZSByZXNvdXJjZS4gVGhlIHJlc291cmNlIHdpbGwgbm90IGJlIGNvcGllZCBpZiB0aGUgc291cmNlIHJlc291cmNlIGlzIHRoZSBzYW1lIG9yIG9sZGVyIHRoYW4gZGVzdGluYXRpb24uCiAgICAgICAgIz4KICAgICAgICBbc3RyaW5nXSAkUGF0aEZpbGVBekNvcHkgPSAoJ3swfVxQcm9ncmFtIEZpbGVzICh4ODYpXE1pY3Jvc29mdCBTREtzXEF6dXJlXEF6Q29weVxBekNvcHkuZXhlJyAtZiAoJGVudjpTeXN0ZW1Ecml2ZSkpCiAgICAgICAgW3N0cmluZ10gJFBhdGhEaXJBekNvcHlKb3VybmFsID0gKCd7MH1cUHJvZ3JhbSBGaWxlc1xJcm9uc3RvbmVJVFx7MX1cQXpDb3B5Sm91cm5hbFwnIC1mICgkZW52OlN5c3RlbURyaXZlLCROYW1lU2NyaXB0KSkKICAgICNlbmRyZWdpb24gQXpDb3B5CgoKICAgICNyZWdpb24gICAgVXNpbmcgU0FTIFRva2VuCiAgICAgICAgIyBDb25uZWN0aW9uIEluZm8KICAgICAgICBbc3RyaW5nXSAkQmxvYkFjY291bnROYW1lICAgID0gJ21ldGllcmNsaWVudHN0b3JhZ2UnCiAgICAgICAgW3N0cmluZ10gJEJsb2JBY2NvdW50VVJMICAgICA9ICgnaHR0cHM6Ly97MH0uYmxvYi5jb3JlLndpbmRvd3MubmV0JyAtZiAoJEJsb2JBY2NvdW50TmFtZSkpCiAgICAgICAgW3N0cmluZ10gJEJsb2JBY2NvdW50QmxvYlVSTCA9ICgnezB9L29mZmljZTM2NS10ZW1wbGF0ZXMnIC1mICgkQmxvYkFjY291bnRVUkwpKQogICAgICAgIFtzdHJpbmddICRTQVNUb2tlbiAgICAgICAgICAgPSAnP3N2PTIwMTctMDctMjkmc3M9YiZzcnQ9Y28mc3A9cmwmc2U9MjAxOS0wMS0wMVQyMTowNToyOVomc3Q9MjAxOC0wNC0xMVQxMjowNToyOVomc3ByPWh0dHBzJnNpZz1LNzdJS013aU1TN0kxNURMJTJGd3RiYlBFRERJR0FSdGlXY2RKbzNVMVlHRjQlM0QnCiAgICAgICAgIyBEb3dubG9hZAogICAgICAgICRudWxsID0gU3RhcnQtUHJvY2VzcyAtRmlsZVBhdGggJFBhdGhGaWxlQXpDb3B5IC1XaW5kb3dTdHlsZSAnSGlkZGVuJyAtQXJndW1lbnRMaXN0ICgnL1NvdXJjZTp7MH0gL0Rlc3Q6ezF9IC9Tb3VyY2VTQVM6ezJ9IC9aOiJ7M30iIC9ZIC9TIC9NVCAvWE8nIC1mICgkQmxvYkFjY291bnRCbG9iVVJMLCRQYXRoRGlyU3luYywkU0FTVG9rZW4sJFBhdGhEaXJBekNvcHlKb3VybmFsKSkgLVdhaXQKICAgICAgICBpZiAoICgtbm90KCQ/KSkgLW9yICgoR2V0LUNoaWxkSXRlbSAtUGF0aCAkUGF0aERpclN5bmMgLUZvcmNlKS5MZW5ndGggLWxlIDApICkgewogICAgICAgICAgICAkQm9vbFNjcmlwdFN1Y2Nlc3MgPSAkZmFsc2UKICAgICAgICB9CiAgICAjZW5kcmVnaW9uIFVzaW5nIFNBUyBUb2tlbgojZW5kcmVnaW9uIE1haW4KfQoKCmZpbmFsbHkgewogICAgIyBEb24ndCBrZWVwIHRoZSBsb2cgZmlsZSBpZiBzdWNjZXNzCiAgICBTdG9wLVRyYW5zY3JpcHQKICAgIGlmICgkQm9vbFNjcmlwdFN1Y2Nlc3MpIHsKICAgICAgICBSZW1vdmUtSXRlbSAtUGF0aCAkUGF0aEZpbGVMb2cgLUZvcmNlCiAgICB9Cn0=';}
                    [PSCustomObject[]]@{Name=([string]'Run-{0}.vbs' -f ($NameScript));
                                        Encoding=[string]'default';
                                        Content=[string]'U2V0IG9ialNoZWxsID0gQ3JlYXRlT2JqZWN0KCJXc2NyaXB0LlNoZWxsIikgIApTZXQgYXJncyA9IFdzY3JpcHQuQXJndW1lbnRzICAKRm9yIEVhY2ggYXJnIEluIGFyZ3MgIAogICAgRGltIFBTUnVuCiAgICBQU1J1biA9ICJwb3dlcnNoZWxsLmV4ZSAtV2luZG93U3R5bGUgaGlkZGVuIC1FeGVjdXRpb25Qb2xpY3kgYnlwYXNzIC1Ob25JbnRlcmFjdGl2ZSAtRmlsZSAiIiIgJiBhcmcgJiAiIiIiCiAgICBvYmpTaGVsbC5SdW4oUFNSdW4pLDAKTmV4dA==';}
                )
            #endregion Install Files
            # Settings - PowerShell
            $ConfirmPreference     = 'None' 
            $DebugPreference       = 'SilentlyContinue'
            $ErrorActionPreference = 'Stop'
            $InformationPreference = 'SilentlyContinue'
            $ProgressPreference    = 'SilentlyContinue'
            $VerbosePreference     = 'Continue'
            $WarningPreference     = 'Continue'
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
            function Write-ReadOnly {Write-Verbose -Message ('ReadOnly = {0} on, will not write any changes.' -f ($ReadOnly))}
            #endregion Write-ReadOnly
        #endregion Functions




        #region    Cleanup Previous Install
            if (Test-Path -Path $PathDirIronSync) {Remove-Item -Path $PathDirIronSync -Recurse -Force}
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