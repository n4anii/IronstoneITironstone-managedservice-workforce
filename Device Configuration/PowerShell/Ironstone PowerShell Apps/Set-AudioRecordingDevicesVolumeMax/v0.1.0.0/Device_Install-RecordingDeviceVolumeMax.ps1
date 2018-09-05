<#

.SYNOPSIS
    Installs a PowerShell script which runs once a day at 9am (or earliest time available after that) to make sure volume on Audio Recording Devices is 100%.


.DESCRIPTION


.NOTES
    * In Intune, remember to set "Run this script using the logged in credentials"  according to the $DeviceContext variable.
        * Intune -> Device Configuration -> PowerShell Scripts -> $NameScriptFull -> Properties -> "Run this script using the logged in credentials"
        * DEVICE (Local System) or USER (Logged in user).
    * Only edit $NameScript and add your code in the #region Your Code Here.
    * You might want to touch "Settings - PowerShell - Output Preferences" for testing / development. 
        * $VerbosePreference, eventually $DebugPreference, to 'Continue' will print much more details.

#>


# Script Variables
[bool]   $DeviceContext  = $true
[string] $NameScript     = ('Install-RecordingDeviceVolumeMax')


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

# Dynamic Process Variables
[string] $NameScriptFull      = ('{0}_{1}' -f ($(if($DeviceContext){'Device'}Else{'User'}),$NameScript))
[string] $NameScriptVerb      = $NameScript.Split('-')[0]
[string] $NameScriptNoun      = $NameScript.Split('-')[-1]
[string] $ProcessArchitecture = $(if([System.Environment]::Is64BitProcess){'64'}Else{'32'})
[string] $OSArchitecture      = $(if([System.Environment]::Is64BitOperatingSystem){'64'}Else{'32'})

# Dynamic Logging Variables
$Timestamp    = [DateTime]::Now.ToString('yyMMdd-HHmmssffff')
$PathDirLog   = ('{0}\IronstoneIT\Intune\DeviceConfiguration\' -f ($(if($DeviceContext){$env:ProgramW6432}else{$env:APPDATA})))
$PathFileLog  = ('{0}{1}-{2}bit-{3}.txt' -f ($PathDirLog,$NameScriptFull,$ProcessArchitecture,$Timestamp))

# Start Transcript
if (-not(Test-Path -Path $PathDirLog)) {New-Item -ItemType 'Directory' -Path $PathDirLog -ErrorAction 'Stop'}
Start-Transcript -Path $PathFileLog


# Wrap in Try/Catch, so we can always end the transcript
Try {
    ### USER
    # Get variables
    [string] $StrUserName = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    [string] $StrIsAdmin  = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    # Output User Info
    Write-Output -InputObject ('Running as user "{0}". Has admin privileges? {1}. $DeviceContext = {2}' -f ($StrUserName,$StrIsAdmin,$DeviceContext.ToString()))

    # Check that you are running script correctly according to $DeviceContext and Intune Settings
    if     ($DeviceContext -and $StrUserName -ne 'NT AUTHORITY\SYSTEM')      {Write-Output -InputObject ('Not running as "NT AUTHORITY\SYSTEM". Exit.');Break}
    elseif (-not($DeviceContext) -and $StrUserName -eq 'NT AUTHORITY\SYSTEM'){Write-Output -InputObject ('Not running as logged in user. Exit.');Break}
    

    
    ### POWERSHELL
    # Output Process and OS Architecture Info
    Write-Output -InputObject ('PowerShell is running as a {0} bit process on a {1} bit OS.' -f ($ProcessArchitecture,$OSArchitecture))
    

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
    


#region    Functions
    #region    Get-PublishedModuleVersion
    function Get-PublishedModuleVersion {
        param(
            [Parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [string] $Name
        )

        # access the main module page, and add a random number to trick proxies
        $url = ('https://www.powershellgallery.com/packages/{0}/?dummy={1}' -f ($Name,[System.Random]::New().Next(9999)))
        $request = [System.Net.WebRequest]::Create($url)
        # do not allow to redirect. The result is a "MovedPermanently"
        $request.AllowAutoRedirect=$false
        try {
            # send the request
            $response = $request.GetResponse()
            # get back the URL of the true destination page, and split off the version
            $response.GetResponseHeader('Location').Split('/')[-1] -as [System.Version]
            # make sure to clean up
            $response.Close()
            $response.Dispose()
        }
        catch {
            Write-Warning -Message ($_.Exception.Message)
        }
    }
    #endregion Get-PublishedModuleVersion



    #region    FileOut-FromBase64
        Function FileOut-FromBase64 {
            [CmdLetBinding()]

            # Parameters
            Param(
                [Parameter(Mandatory=$true)]
                [ValidateNotNullOrEmpty()]
                [string] $InstallDir,
            
                [Parameter(Mandatory=$true)]
                [ValidateNotNullOrEmpty()]
                [string] $FileName,
            
                [Parameter(Mandatory=$true)]
                [ValidateNotNullOrEmpty()]
                [string] $FileContent, 
            
                [Parameter(Mandatory=$true)]
                [ValidateSet('utf8','default')]
                [string] $OutputEncoding,

                [Parameter(Mandatory=$false)]
                [Switch] $Force
            )

            # Do
            [byte] $SubstringLength = $(If($FileContent.Count -lt 10){$FileContent.Count}Else{10})
            Write-Verbose -Message ('FileOut-FromBase64 -FilePath ' + $InstallDir + ' -FileName ' + $FileName + ' -File ' + ($FileContent.Substring(0,$SubstringLength) + '...'))
            [string] $Local:FilePath = $InstallDir + $FileName

            If (Test-Path -Path $InstallDir) {
                Write-Verbose -Message ('   Path exists, trying to write the file (File alrady exists? {0})' -f (Test-Path -Path $Local:FilePath))
                If (-not($ReadOnly)) {
                    Out-File -FilePath $Local:FilePath -Encoding $OutputEncoding -InputObject ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($FileContent))) -Force:$Force
                    Write-Verbose -Message ('      Success? {0}' -f ($?))
                    Write-Verbose -Message ('         Does file actually exist? {0}' -f (Test-Path $Local:FilePath -ErrorAction SilentlyContinue))
                }
            }
            Else {
                Write-Verbose -Message ('   ERROR: Path does not exist')
            }
        }
    #endregion FileOut-FromBase64
#endregion Functions




#region    Install required modules and PackageProvider
    # NuGet
    [System.Version] $VersionNuGetMinimum   = [System.Version](Find-PackageProvider -Name 'NuGet' -Force -Verbose:$false -Debug:$false | Select-Object -ExpandProperty 'Version')
    [System.Version] $VersionNuGetInstalled = [System.Version]([System.Version[]]@(Get-PackageProvider -ListAvailable -Name 'NuGet' -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'Version') | Sort-Object)[-1]
    Write-Output -InputObject ('NuGet')
    if ( (-not($VersionNuGetInstalled)) -or $VersionNuGetInstalled -lt $VersionNuGetMinimum) {        
        Install-PackageProvider 'NuGet' –Force -Verbose:$false -Debug:$false
        Write-Output -InputObject ('Not installed, or newer version available. Installing... Success? {0}' -f ($?))
    }


    # Wanted Module
    [string[]] $NameWantedModules = @('PowerShellGet','AudioDeviceCmdlets')
    foreach ($Module in $NameWantedModules) {
        Write-Output -InputObject ('{0}' -f ($Module))
        [System.Version] $VersionModuleAvailable = [System.Version](Get-PublishedModuleVersion -Name $Module)
        [System.Version] $VersionModuleInstalled = [System.Version](Get-InstalledModule -Name $Module -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'Version')
        if ( (-not($VersionModuleInstalled)) -or $VersionModuleInstalled -lt $VersionModuleAvailable) {           
            Install-Module -Name $Module -Repository 'PSGallery' -Scope 'AllUsers' -Verbose:$false -Debug:$false -Confirm:$false -Force
            Write-Output -InputObject ('Not installed, or newer version available. Installing... Success? {0}' -f ($?))
        }
    }
#endregion Install required modules and PackageProvider




#region    Install Set-RecordingDeviceVolumeMax.ps1

    # Check that required modules exist
    if ( @(Get-ChildItem -Path ('{0}\WindowsPowerShell\Modules\AudioDeviceCmdlets\' -f ($env:ProgramW6432)) -File -Recurse | Select-Object -ExpandProperty FullName).Count -lt 2) {
        Write-Output -InputObject ('Required module "AudioDeviceCmdlets" failed to install. Scheduled script cannot function without it. Will skip install of {0}' -f ($NameScript))
        Break
    }


    #region    Export Set-RecordingDeviceVolumeMax.ps1 & Create Scheduled Task
        # Variables
        [string] $NameScriptNoun = $NameScript.Split('-')[-1]
        [string] $PathDirScript  = ('{0}\IronstoneIT\{1}\' -f ($env:ProgramW6432,$NameScriptNoun))
        [string] $PathDirLog     = ('{0}\Logs\' -f ($PathDirScript))
        [string] $NameFileScript = ('Set-{0}.ps1' -f ($NameScriptNoun))

        # Variables - Scheduled Task
        [string] $NameScheduledTask  = ('Run-{0}' -f ($NameScriptNoun))
        [string] $PathFilePowerShell = ('{0}\{1}\WindowsPowerShell\v1.0\powershell.exe' -f ($env:windir,$(if([System.Environment]::Is64BitOperatingSystem){'SysWOW64'}else{'System32'})))
        [string] $PathFilePS1        = ('{0}{1}' -f ($PathDirScript,$NameFileScript))


        # Remove eventual existing files
        @(Get-ChildItem -Path $PathDirScript -File -Recurse -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'FullName') | ForEach-Object {Remove-Item -Path $_ -Force}


        #region    Export Set-RecordingDeviceVolumeMax.ps1
            # Create DIR
            foreach ($Path in @($PathDirScript,$PathDirLog)) {
                if (Test-Path -Path $Path) {
                    Write-Verbose -Message ('Path "{0}" already exist.' -f ($Path))
                }
                else {
                    $null = New-Item -Path $Path -ItemType 'Directory' -Force
                    Write-Verbose -Message ('Path "{0}" does not exist. Creating... Success? {1}.' -f ($Path,$?.ToString()))
                }
            }
            
            # Export file from BASE64
            [PSCustomObject[]] $InstallFile = @{
                Name    =[string]('Set-{0}.ps1' -f ($NameScriptNoun));
                Encoding=[string]('utf8');
                Content =[string]('PCMKLlNZTk9QU0lTCiAgICBTZXQgdm9sdW1lIGxldmVsIHRvIDEwMCUgZm9yIGFsbCBSZWNvcmRpbmcgRGV2aWNlcyB1c2luZyBQb3dlclNoZWxsIE1vZHVsZSAiQXVkaW9EZXZpY2VDbWRsZXRzIgoKLkRFU0NSSVBUSU9OCiAgICBHZXQgRGVmYXVsdCBSZWNvcmRpbmcgRGV2aWNlIChUbyByZXNldCB0byB0aGlzIGFmdGVyd2FyZHMpCiAgICBMb29wIGV2ZXJ5IFJlY29yZGluZyBEZXZpY2UKICAgIFNldCBlYWNoIHJlY29yZGluZyB2b2x1bWUgdG8gMTAwJSBieSBmaXJzdCBzZXR0aW5nIGRldmljZSBhcyBkZWZhdWx0LCB0aGVuIHNldCB2b2x1bWUKICAgIFJlc3RvcmUgZGVmYXVsdCByZWNvcmRpbmcgZGV2aWNlIGFmdGVyd2FyZHMKIz4KCgoKI3JlZ2lvbiAgICBTZXR0aW5ncwogICAgIyBTZXR0aW5ncyAtIFBvd2VyU2hlbGwgLSBPdXRwdXQgUHJlZmVyZW5jZXMKICAgICREZWJ1Z1ByZWZlcmVuY2UgICAgICAgPSAnU2lsZW50bHlDb250aW51ZScKICAgICRJbmZvcm1hdGlvblByZWZlcmVuY2UgPSAnU2lsZW50bHlDb250aW51ZScKICAgICRWZXJib3NlUHJlZmVyZW5jZSAgICAgPSAnU2lsZW50bHlDb250aW51ZScKICAgICRXYXJuaW5nUHJlZmVyZW5jZSAgICAgPSAnQ29udGludWUnCgogICAgIyBTZXR0aW5ncyAtIFBvd2VyU2hlbGwgLSBJbnRlcmFjdGlvbgogICAgJENvbmZpcm1QcmVmZXJlbmNlICAgICA9ICdOb25lJwogICAgJFByb2dyZXNzUHJlZmVyZW5jZSAgICA9ICdTaWxlbnRseUNvbnRpbnVlJwoKICAgICMgU2V0dGluZ3MgLSBQb3dlclNoZWxsIC0gQmVoYXZpb3VyCiAgICAkRXJyb3JBY3Rpb25QcmVmZXJlbmNlID0gJ0NvbnRpbnVlJwojZW5kcmVnaW9uIFNldHRpbmdzCgoKCgojcmVnaW9uICAgIExvZ2dpbmcKICAgICMgVmFyaWFibGVzIC0gU3RhdGljCiAgICBbYm9vbF0gICAkU2NyaXB0OlN1Y2Nlc3MgICAgPSAkdHJ1ZQogICAgW3N0cmluZ10gJE5hbWVTY3JpcHQgICAgICAgID0gKCdTZXQtUmVjb3JkaW5nRGV2aWNlVm9sdW1lTWF4JykKCiAgICAjIFZhcmlhYmxlcyAtIEVudmlyb25tZW50IEluZm8KICAgIFtzdHJpbmddICRTdHJVc2VyTmFtZSA9IFtTeXN0ZW0uU2VjdXJpdHkuUHJpbmNpcGFsLldpbmRvd3NJZGVudGl0eV06OkdldEN1cnJlbnQoKS5OYW1lCiAgICBbc3RyaW5nXSAkU3RySXNBZG1pbiAgPSAoW1NlY3VyaXR5LlByaW5jaXBhbC5XaW5kb3dzUHJpbmNpcGFsXVtTZWN1cml0eS5QcmluY2lwYWwuV2luZG93c0lkZW50aXR5XTo6R2V0Q3VycmVudCgpKS5Jc0luUm9sZShbU2VjdXJpdHkuUHJpbmNpcGFsLldpbmRvd3NCdWlsdEluUm9sZV06OkFkbWluaXN0cmF0b3IpCiAgICBbc3RyaW5nXSAkUHJvY2Vzc0FyY2hpdGVjdHVyZSA9ICQoaWYoW1N5c3RlbS5FbnZpcm9ubWVudF06OklzNjRCaXRQcm9jZXNzKXsnNjQnfUVsc2V7JzMyJ30pCiAgICBbc3RyaW5nXSAkT1NBcmNoaXRlY3R1cmUgICAgICA9ICQoaWYoW1N5c3RlbS5FbnZpcm9ubWVudF06OklzNjRCaXRPcGVyYXRpbmdTeXN0ZW0peyc2NCd9RWxzZXsnMzInfSkKCiAgICAjIFZhcmlhYmxlcyAtIExvZ2dpbmcKICAgIFtzdHJpbmddICROYW1lU2NyaXB0Tm91biAgICA9ICROYW1lU2NyaXB0LlNwbGl0KCctJylbLTFdCiAgICBbc3RyaW5nXSAkTmFtZVNjcmlwdEZpbGUgICAgPSAoJ1NldC17MH0ucHMxJyAtZiAoJE5hbWVTY3JpcHROb3VuKSkKICAgIFtzdHJpbmddICROYW1lU2NoZWR1bGVkVGFzayA9ICgnUnVuLXswfScgLWYgKCROYW1lU2NyaXB0Tm91bikpCiAgICBbc3RyaW5nXSAkUGF0aERpckxvZyAgICAgICAgPSAoJ3swfVxJcm9uc3RvbmVJVFx7MX1cTG9nc1wnIC1mICgkKGlmKCRTdHJJc0FkbWluIC1lcSAnVHJ1ZScpeyRlbnY6UHJvZ3JhbVc2NDMyfWVsc2V7JGVudjpBUFBEQVRBfSksJE5hbWVTY3JpcHROb3VuKSkKICAgIFtzdHJpbmddICRQYXRoRmlsZUxvZyAgICAgICA9ICgnezB9ezF9LXsyfS50eHQnIC1mICgkUGF0aERpckxvZywkTmFtZVNjcmlwdE5vdW4sKFtEYXRlVGltZV06Ok5vdy5Ub1N0cmluZygneXlNTWRkLUhIbW1zc2ZmZmYnKSkpKQogICAgCiAgICAjIFN0YXJ0IHRyYW5zY3JpcHQKICAgIGlmICgtbm90KFRlc3QtUGF0aCAtUGF0aCAkUGF0aERpckxvZykpe05ldy1JdGVtIC1QYXRoICRQYXRoRGlyTG9nIC1JdGVtVHlwZSAnRGlyZWN0b3J5JyAtRm9yY2V9CiAgICBTdGFydC1UcmFuc2NyaXB0IC1QYXRoICRQYXRoRmlsZUxvZwojZW5kcmVnaW9uIExvZ2dpbmcKCgoKCiNyZWdpb24gICAgRGVidWcKICAgIFdyaXRlLU91dHB1dCAtSW5wdXRPYmplY3QgKCcqKioqKioqKioqKioqKioqKioqKioqJykKICAgIFdyaXRlLU91dHB1dCAtSW5wdXRPYmplY3QgKCdQb3dlclNoZWxsIGlzIHJ1bm5pbmcgYXMgYSB7MH0gYml0IHByb2Nlc3Mgb24gYSB7MX0gYml0IE9TLicgLWYgKCRQcm9jZXNzQXJjaGl0ZWN0dXJlLCRPU0FyY2hpdGVjdHVyZSkpCiAgICBXcml0ZS1PdXRwdXQgLUlucHV0T2JqZWN0ICgnUnVubmluZyBhcyB1c2VyICJ7MH0iLiBIYXMgYWRtaW4gcHJpdmlsZWdlcz8gezF9JyAtZiAoJFN0clVzZXJOYW1lLCRTdHJJc0FkbWluKSkKICAgIFdyaXRlLU91dHB1dCAtSW5wdXRPYmplY3QgKCcqKioqKioqKioqKioqKioqKioqKioqJykKI2VuZHJlZ2lvbiBEZWJ1ZwoKCgoKI3JlZ2lvbiAgICBNYWluCiAgICBUcnkgewogICAgICAgICMgSW1wb3J0IG1vZHVsZXMgbWFudWFsbHkKICAgICAgICBHZXQtQ2hpbGRJdGVtIC1QYXRoICgnezB9XFdpbmRvd3NQb3dlclNoZWxsXE1vZHVsZXNcQXVkaW9EZXZpY2VDbWRsZXRzXCcgLWYgKCRlbnY6UHJvZ3JhbVc2NDMyKSkgLUZpbGUgLVJlY3Vyc2UgfCBTZWxlY3QtT2JqZWN0IC1FeHBhbmRQcm9wZXJ0eSBGdWxsTmFtZSB8IEZvckVhY2gtT2JqZWN0IHtJbXBvcnQtTW9kdWxlIC1OYW1lICRffQogICAgICAgIAogICAgICAgIAogICAgICAgICMgSWYgbW9kdWxlcyBpbXBvcnQgZmFpbGVkCiAgICAgICAgaWYgKEAoR2V0LU1vZHVsZSB8IFdoZXJlLU9iamVjdCB7JF8uTmFtZSAtZXEgJ0F1ZGlvRGV2aWNlQ21kbGV0cyd9KS5Db3VudCAtbHQgMikgewogICAgICAgICAgICBXcml0ZS1PdXRwdXQgLUlucHV0T2JqZWN0ICgnRmFpbGVkIHRvIGltcG9ydCBQb3dlclNoZWxsIE1vZHVsZSAiQXVkaW9EZXZpY2VDbWRsZXRzIicpCiAgICAgICAgfQoKCiAgICAgICAgIyBJZiBtb2R1bGVzIGltcG9ydCBzdWNjZWVkZWQgLSBMb29wIHRocm91Z2ggcmVjb3JkaW5nIGRldmljZXMsIHNldCBSZWNvcmRpbmcgVm9sdW1lIHRvIDEwMCUKICAgICAgICBlbHNlIHsgICAgCiAgICAgICAgICAgICRSZWNvcmRpbmdEZXZpY2VEZWZhdWx0ID0gR2V0LUF1ZGlvRGV2aWNlIC1SZWNvcmRpbmcgfCBTZWxlY3QtT2JqZWN0IC1Qcm9wZXJ0eSAnTmFtZScsJ0lEJwogICAgICAgICAgICAkUmVjb3JkaW5nRGV2aWNlQWxsICAgICA9IEAoKEdldC1BdWRpb0RldmljZSAtTGlzdCB8IFdoZXJlLU9iamVjdCB7JF8uVHlwZSAtZXEgJ1JlY29yZGluZyd9KSB8IFNlbGVjdC1PYmplY3QgLVByb3BlcnR5ICdOYW1lJywnSUQnKQogICAgICAgICAgICBpZiAoJFJlY29yZGluZ0RldmljZUFsbC5Db3VudCAtZXEgMCkgewogICAgICAgICAgICAgICAgV3JpdGUtT3V0cHV0IC1JbnB1dE9iamVjdCAoJ0ZvdW5kIG5vIHJlY29yZGluZyBkZXZpY2VzLicpCiAgICAgICAgICAgICAgICAkU2NyaXB0OlN1Y2Nlc3MgPSAkZmFsc2UKICAgICAgICAgICAgfQogICAgICAgICAgICBlbHNlIHsKICAgICAgICAgICAgICAgIGZvcmVhY2ggKCREZXZpY2UgaW4gJFJlY29yZGluZ0RldmljZUFsbCkgewogICAgICAgICAgICAgICAgICAgICMgU2V0IERlZmF1bHQgUmVjb3JkaW5nIERldmljZQogICAgICAgICAgICAgICAgICAgICRudWxsID0gU2V0LUF1ZGlvRGV2aWNlICREZXZpY2UuSUQKICAgICAgICAgICAgICAgICAgICBbYm9vbF0gJExvY2FsOlN1Y2Nlc3NfU2V0RGVmYXVsdERldmljZSA9ICQ/CiAgICAgICAgICAgICAgICAgICAgV3JpdGUtT3V0cHV0IC1JbnB1dE9iamVjdCAoJ1NldHRpbmcgInswfSIgYXMgZGVmYXVsdCByZWNvcmRpbmcgZGV2aWNlLiBTdWNjZXNzPyB7MX0uJyAtZiAoJERldmljZS5OYW1lLCRMb2NhbDpTdWNjZXNzX1NldERlZmF1bHREZXZpY2UpKQogICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICMgU2V0IFZvbHVtZSB0byAxMDAlCiAgICAgICAgICAgICAgICAgICAgJG51bGwgPSBTZXQtQXVkaW9EZXZpY2UgLVJlY29yZGluZ1ZvbHVtZSAxMDAKICAgICAgICAgICAgICAgICAgICBbYm9vbF0gJExvY2FsOlN1Y2Nlc3NfU2V0Vm9sdW1lID0gJD8KICAgICAgICAgICAgICAgICAgICBXcml0ZS1PdXRwdXQgLUlucHV0T2JqZWN0ICgnU2V0dGluZyB2b2x1bWUgdG8gMTAwJS4gU3VjY2Vzcz8gInswfSIuJyAtZiAoJExvY2FsOlN1Y2Nlc3NfU2V0Vm9sdW1lKSkKICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAjIFN0YXRzCiAgICAgICAgICAgICAgICAgICAgaWYgKC1ub3QoJExvY2FsOlN1Y2Nlc3NfU2V0RGVmYXVsdERldmljZSAtb3IgJExvY2FsOlN1Y2Nlc3NfU2V0Vm9sdW1lKSl7JFNjcmlwdDpTdWNjZXNzID0gJGZhbHNlfQogICAgICAgICAgICAgICAgfQogICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAjIFNldCBEZWZhdWx0IFJlY29yZGluZyBEZXZpY2UgYmFjayB0byB3aGF0IGl0IHdhcwogICAgICAgICAgICAgICAgJG51bGwgPSBTZXQtQXVkaW9EZXZpY2UgJFJlY29yZGluZ0RldmljZURlZmF1bHQuSUQKICAgICAgICAgICAgICAgICRMb2NhbDpTdWNjZXNzX1JldmVydERlZmF1bHQgPSAkPwogICAgICAgICAgICAgICAgV3JpdGUtT3V0cHV0IC1JbnB1dE9iamVjdCAoJ1JldmVydGluZyAiezB9IiBiYWNrIGFzIGRlZmF1bHQgcmVjb3JkaW5nIGRldmljZS4gU3VjY2Vzcz8gezF9LicgLWYgKCRSZWNvcmRpbmdEZXZpY2VEZWZhdWx0Lk5hbWUsJExvY2FsOlN1Y2Nlc3NfUmV2ZXJ0RGVmYXVsdCkpCiAgICAgICAgICAgICAgICBpZigtbm90KCRMb2NhbDpTdWNjZXNzX1JldmVydERlZmF1bHQpKXskU2NyaXB0OlN1Y2Nlc3MgPSAkTG9jYWw6U3VjY2Vzc19SZXZlcnREZWZhdWx0fQogICAgICAgICAgICB9CiAgICAgICAgfQogICAgfQojZW5kcmVnaW9uIE1haW4KCgoKCiNyZWdpb24gICAgQ2F0Y2ggYW5kIEZpbmFsbHkKICAgIENhdGNoIHsKICAgICAgICAkU3VjY2VzcyA9ICRmYWxzZQogICAgICAgICMgQ29uc3RydWN0IE1lc3NhZ2UKICAgICAgICAkRXJyb3JNZXNzYWdlID0gKCd7MH0gZmluaXNoZWQgd2l0aCBlcnJvcnM6JyAtZiAoJE5hbWVTY3JpcHQpKQogICAgICAgICRFcnJvck1lc3NhZ2UgKz0gIiBgbiIKICAgICAgICAkRXJyb3JNZXNzYWdlICs9ICdFeGNlcHRpb246ICcKICAgICAgICAkRXJyb3JNZXNzYWdlICs9ICRfLkV4Y2VwdGlvbgogICAgICAgICRFcnJvck1lc3NhZ2UgKz0gIiBgbiIKICAgICAgICAkRXJyb3JNZXNzYWdlICs9ICdBY3Rpdml0eTogJwogICAgICAgICRFcnJvck1lc3NhZ2UgKz0gJF8uQ2F0ZWdvcnlJbmZvLkFjdGl2aXR5CiAgICAgICAgJEVycm9yTWVzc2FnZSArPSAiIGBuIgogICAgICAgICRFcnJvck1lc3NhZ2UgKz0gJ0Vycm9yIENhdGVnb3J5OiAnCiAgICAgICAgJEVycm9yTWVzc2FnZSArPSAkXy5DYXRlZ29yeUluZm8uQ2F0ZWdvcnkKICAgICAgICAkRXJyb3JNZXNzYWdlICs9ICIgYG4iCiAgICAgICAgJEVycm9yTWVzc2FnZSArPSAnRXJyb3IgUmVhc29uOiAnCiAgICAgICAgJEVycm9yTWVzc2FnZSArPSAkXy5DYXRlZ29yeUluZm8uUmVhc29uCiAgICAgICAgV3JpdGUtRXJyb3IgLU1lc3NhZ2UgJEVycm9yTWVzc2FnZQogICAgfQogICAgRmluYWxseSB7CiAgICAgICAgU3RvcC1UcmFuc2NyaXB0CiAgICAgICAgaWYgKCRTY3JpcHQ6U3VjY2VzcyAtYW5kICRWZXJib3NlUHJlZmVyZW5jZSAtbmUgJ0NvbnRpbnVlJykge1JlbW92ZS1JdGVtIC1QYXRoICRQYXRoRmlsZUxvZyAtRm9yY2V9CiAgICB9CiNlbmRyZWdpb24gQ2F0Y2ggYW5kIEZpbmFsbHk=');
            }
            FileOut-FromBase64 -InstallDir $PathDirScript -FileName $InstallFile.Name -FileContent $InstallFile.Content -OutputEncoding $InstallFile.Encoding -Force
        #endregion Export Set-RecordingDeviceVolumeMax.ps1




        #region    Create Scheduled Task
            # If PowerShell.exe and the PS1 file does NOT exist
            foreach ($Path in @($PathFilePowerShell,$PathFilePS1)) {
                Write-Output -InputObject ('Test-Path -Path "{0}" = {1}' -f ($Path,([bool] $Exist = Test-Path -Path $Path).ToString()))
                if (-not($Exist)) {Throw 'Cannot create scheduled task without this file.';Break}
            }

            # If PowerShell.exe and the PS1 file exist
            $ScheduledTask = New-ScheduledTask                                                    `
                -Action    (New-ScheduledTaskAction -Execute ('"{0}"' -f ($PathFilePowerShell)) -Argument ('-ExecutionPolicy ByPass -NonInteractive -NoProfile -File "{0}"' -f ($PathFilePS1))) `
                -Principal (New-ScheduledTaskPrincipal ($(if($DeviceContext){'NT AUTHORITY\SYSTEM'}else{[System.Security.Principal.WindowsIdentity]::GetCurrent().Name})))                      `
                -Trigger   (New-ScheduledTaskTrigger -Daily -At '9:00am')                                                                                                                       `
                -Settings  (New-ScheduledTaskSettingsSet -Hidden -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit ([TimeSpan]::FromMinutes(10)) -Compatibility 4 -StartWhenAvailable)
            $ScheduledTask.Author      = 'Ironstone'
            $ScheduledTask.Description = ('Runs a PowerShell script.{0} "{1}" -NonInteractive -NoProfile -File "{2}".' -f ("`r`n",$PathFilePowerShell,$PathFilePS1))
            $null = Register-ScheduledTask -TaskName $NameScheduledTask -Force -InputObject $ScheduledTask
            if ($?) {Start-ScheduledTask -TaskName $NameScheduledTask}
        #endregion Create Scheduled Task
    #endregion Export Set-RecordingDeviceVolumeMax.ps1 & Create Scheduled Task
#endregion Install Set-RecordingDeviceVolumeMax.ps1    

    
    
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