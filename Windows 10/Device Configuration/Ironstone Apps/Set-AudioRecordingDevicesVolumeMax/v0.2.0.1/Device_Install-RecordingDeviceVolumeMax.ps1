﻿<#

.SYNOPSIS
    Installs a PowerShell script which is scheduled to run once a day at 9am (or earliest time available after that) to make sure volume on Audio Recording Devices is 100%.


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

# Dynamic Variables - Process & Environment
[string] $NameScriptFull      = ('{0}_{1}' -f ($(if($DeviceContext){'Device'}else{'User'}),$NameScript))
[string] $NameScriptVerb      = $NameScript.Split('-')[0]
[string] $NameScriptNoun      = $NameScript.Split('-')[-1]
[string] $ProcessArchitecture = $(if([System.Environment]::Is64BitProcess){'64'}else{'32'})
[string] $OSArchitecture      = $(if([System.Environment]::Is64BitOperatingSystem){'64'}else{'32'})

# Dynamic Variables - User
[bool] $BoolIsAdmin        = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
[string] $StrIsAdmin       = $BoolIsAdmin.ToString()
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
    if ([System.Environment]::Is64BitOperatingSystem -and -not [System.Environment]::Is64BitProcess) {
        write-Output -InputObject (' * Will restart this PowerShell session as x64.')
        if ($myInvocation.Line) {& ('{0}\sysnative\WindowsPowerShell\v1.0\powershell.exe' -f ($env:windir)) -NonInteractive -NoProfile $myInvocation.Line}
        else {& ('{0}\sysnative\WindowsPowerShell\v1.0\powershell.exe' -f ($env:windir)) -NonInteractive -NoProfile -File ('{0}' -f ($myInvocation.InvocationName)) $args}
        exit $LASTEXITCODE
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

        # Access the main module page, and add a random number to trick proxies
        $Url = ('https://www.powershellgallery.com/packages/{0}/?dummy={1}' -f ($Name,[System.Random]::New().Next(9999)))
        $Request = [System.Net.WebRequest]::Create($Url)
        # Do not allow to redirect. The result is a "MovedPermanently"
        $Request.AllowAutoRedirect=$false
        Try {
            # Send the request
            $Response = $Request.GetResponse()
            # Get back the URL of the true destination page, and split off the version
            $Response.GetResponseHeader('Location').Split('/')[-1] -as [System.Version]
            # Make sure to clean up
            $Response.Close()
            $Response.Dispose()
        }
        Catch {
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
            [string] $PathDirOut,
            
            [Parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [string] $NameFileOut,
            
            [Parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [string] $ContentFileOut, 
            
            [Parameter(Mandatory=$true)]
            [ValidateSet('utf8','default')]
            [string] $EncodingFileOut,

            [Parameter(Mandatory=$false)]
            [Switch] $Force
        )

        # Output Debug Info
        [byte] $SubstringLength = $(if($ContentFileOut.Length -lt 10){$ContentFileOut.Length}else{10})
        Write-Debug -Message ('FileOut-FromBase64 -PathDirOut "{0}" -NameFileOut "{1}" -ContentFileOut "{2}" -EncodingFileOut "{3}"' -f ($PathDirOut,$NameFileOut,($ContentFileOut.Substring(0,$SubstringLength)+'...'),$EncodingFileOut))
        

        # If writing to Program Files, and not admin
        if ($PathDirOut -like '*Program Files\*' -and (-not([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {
            Throw ('Cannot write to "{0}" without admin rights!' -f ($PathDirOut))
        }
        else {
            # Create Install Dir if not exist
            if(-not(Test-Path -Path $PathDirOut)){$null = New-Item -Path $PathDirOut -ItemType 'Directory' -Force}
                
            # Continue only if Install Dir exist    
            if (Test-Path -Path $PathDirOut) {
                [string] $Local:PathFileOut = ('{0}{1}{2}' -f ($PathDirOut,($(if($PathDirOut[-1] -ne '\'){'\'})) + $NameFileOut)).Replace('\\','\')
                Write-Verbose -Message ('   Path exists, trying to write the file (File alrady exists? {0}).' -f (Test-Path -Path $Local:PathFileOut))
                if (-not($ReadOnly)) {
                    Out-File -FilePath $Local:PathFileOut -Encoding $EncodingFileOut -InputObject ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($ContentFileOut))) -Force:$Force
                    Write-Verbose -Message ('      Success? {0}.' -f ($?))
                    Write-Verbose -Message ('         Does file actually exist? {0}.' -f (Test-Path -Path $Local:PathFileOut -ErrorAction 'SilentlyContinue'))
                }
            }
            else {
                Throw ('ERROR: Install Path does not exist.')
            }
        }
    }
    #endregion FileOut-FromBase64
#endregion Functions




#region    Install required Modules and PackageProvider
    # NuGet
    [System.Version] $VersionNuGetMinimum   = [System.Version](Find-PackageProvider -Name 'NuGet' -Force -Verbose:$false -Debug:$false | Select-Object -ExpandProperty 'Version')
    [System.Version] $VersionNuGetInstalled = [System.Version]([System.Version[]]@(Get-PackageProvider -ListAvailable -Name 'NuGet' -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'Version') | Sort-Object)[-1]
    Write-Output -InputObject ('NuGet')
    if ( (-not($VersionNuGetInstalled)) -or $VersionNuGetInstalled -lt $VersionNuGetMinimum) {        
        Install-PackageProvider 'NuGet' –Force -Verbose:$false -Debug:$false -ErrorAction Stop
        Write-Output -InputObject ('Not installed, or newer version available. Installing... Success? {0}' -f ($?))
    }


    # Wanted Module
    [string[]] $NameWantedModules = @('PowerShellGet','AudioDeviceCmdlets')
    foreach ($Module in $NameWantedModules) {
        Write-Output -InputObject ('{0}' -f ($Module))
        [System.Version] $VersionModuleAvailable = [System.Version](Get-PublishedModuleVersion -Name $Module)
        [System.Version] $VersionModuleInstalled = [System.Version](Get-InstalledModule -Name $Module -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'Version')
        if ( (-not($VersionModuleInstalled)) -or $VersionModuleInstalled -lt $VersionModuleAvailable) {           
            Install-Module -Name $Module -Repository 'PSGallery' -Scope 'AllUsers' -Verbose:$false -Debug:$false -Confirm:$false -Force -ErrorAction Stop
            Write-Output -InputObject ('Not installed, or newer version available. Installing... Success? {0}' -f ($?))
        }
    }
#endregion Install required Modules and PackageProvider




#region    Install Set-RecordingDeviceVolumeMax.ps1

    # Check that required modules exist
    if ( @(Get-ChildItem -Path ('{0}\WindowsPowerShell\Modules\AudioDeviceCmdlets\' -f ($env:ProgramW6432)) -File -Recurse | Select-Object -ExpandProperty FullName).Count -lt 2) {
        Write-Output -InputObject ('Required module "AudioDeviceCmdlets" failed to install. Scheduled script cannot function without it. Will skip install of {0}.' -f ($NameScript))
        Break
    }


    #region    Export Set-RecordingDeviceVolumeMax.ps1 & Create Scheduled Task
        # Variables
        [string] $PathDirLog     = ('{0}\Logs' -f ($PathDirScript))
        [string] $PathDirScript  = ('{0}\IronstoneIT\{1}' -f ($env:ProgramW6432,$NameScriptNoun))
        [string] $NameFileScript = ('Set-{0}.ps1' -f ($NameScriptNoun))
        [string] $PathFileScript = ('{0}\{1}' -f ($PathDirScript,$NameFileScript))


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
                Content =[string]('PCMKLlNZTk9QU0lTCiAgICBTZXQgdm9sdW1lIGxldmVsIHRvIDEwMCUgZm9yIGFsbCBSZWNvcmRpbmcgRGV2aWNlcyB1c2luZyBQb3dlclNoZWxsIE1vZHVsZSAiQXVkaW9EZXZpY2VDbWRsZXRzIgoKLkRFU0NSSVBUSU9OCiAgICBHZXQgRGVmYXVsdCBSZWNvcmRpbmcgRGV2aWNlIChUbyByZXNldCB0byB0aGlzIGFmdGVyd2FyZHMpCiAgICBMb29wIGV2ZXJ5IFJlY29yZGluZyBEZXZpY2UKICAgIFNldCBlYWNoIHJlY29yZGluZyB2b2x1bWUgdG8gMTAwJSBieSBmaXJzdCBzZXR0aW5nIGRldmljZSBhcyBkZWZhdWx0LCB0aGVuIHNldCB2b2x1bWUKICAgIFJlc3RvcmUgZGVmYXVsdCByZWNvcmRpbmcgZGV2aWNlIGFmdGVyd2FyZHMKIz4KCgoKI3JlZ2lvbiAgICBTZXR0aW5ncwogICAgIyBTZXR0aW5ncyAtIFBvd2VyU2hlbGwgLSBPdXRwdXQgUHJlZmVyZW5jZXMKICAgICREZWJ1Z1ByZWZlcmVuY2UgICAgICAgPSAnU2lsZW50bHlDb250aW51ZScKICAgICRJbmZvcm1hdGlvblByZWZlcmVuY2UgPSAnU2lsZW50bHlDb250aW51ZScKICAgICRWZXJib3NlUHJlZmVyZW5jZSAgICAgPSAnU2lsZW50bHlDb250aW51ZScKICAgICRXYXJuaW5nUHJlZmVyZW5jZSAgICAgPSAnQ29udGludWUnCgogICAgIyBTZXR0aW5ncyAtIFBvd2VyU2hlbGwgLSBJbnRlcmFjdGlvbgogICAgJENvbmZpcm1QcmVmZXJlbmNlICAgICA9ICdOb25lJwogICAgJFByb2dyZXNzUHJlZmVyZW5jZSAgICA9ICdTaWxlbnRseUNvbnRpbnVlJwoKICAgICMgU2V0dGluZ3MgLSBQb3dlclNoZWxsIC0gQmVoYXZpb3VyCiAgICAkRXJyb3JBY3Rpb25QcmVmZXJlbmNlID0gJ0NvbnRpbnVlJwoKICAgICMgU2V0dGluZ3MgLSBTY3JpcHQKICAgIFtib29sXSAkU2NyaXB0OlVubXV0ZSAgPSAkdHJ1ZQojZW5kcmVnaW9uIFNldHRpbmdzCgoKCgojcmVnaW9uICAgIExvZ2dpbmcKICAgICMgVmFyaWFibGVzIC0gU3RhdGljCiAgICBbYm9vbF0gICAkU2NyaXB0OlN1Y2Nlc3MgICAgPSAkdHJ1ZQogICAgW3N0cmluZ10gJE5hbWVTY3JpcHQgICAgICAgID0gKCdTZXQtUmVjb3JkaW5nRGV2aWNlVm9sdW1lTWF4JykKCiAgICAjIFZhcmlhYmxlcyAtIEVudmlyb25tZW50IEluZm8KICAgIFtzdHJpbmddICRTdHJVc2VyTmFtZSA9IFtTeXN0ZW0uU2VjdXJpdHkuUHJpbmNpcGFsLldpbmRvd3NJZGVudGl0eV06OkdldEN1cnJlbnQoKS5OYW1lCiAgICBbc3RyaW5nXSAkU3RySXNBZG1pbiAgPSAoW1NlY3VyaXR5LlByaW5jaXBhbC5XaW5kb3dzUHJpbmNpcGFsXVtTZWN1cml0eS5QcmluY2lwYWwuV2luZG93c0lkZW50aXR5XTo6R2V0Q3VycmVudCgpKS5Jc0luUm9sZShbU2VjdXJpdHkuUHJpbmNpcGFsLldpbmRvd3NCdWlsdEluUm9sZV06OkFkbWluaXN0cmF0b3IpCiAgICBbc3RyaW5nXSAkUHJvY2Vzc0FyY2hpdGVjdHVyZSA9ICQoaWYoW1N5c3RlbS5FbnZpcm9ubWVudF06OklzNjRCaXRQcm9jZXNzKXsnNjQnfUVsc2V7JzMyJ30pCiAgICBbc3RyaW5nXSAkT1NBcmNoaXRlY3R1cmUgICAgICA9ICQoaWYoW1N5c3RlbS5FbnZpcm9ubWVudF06OklzNjRCaXRPcGVyYXRpbmdTeXN0ZW0peyc2NCd9RWxzZXsnMzInfSkKCiAgICAjIFZhcmlhYmxlcyAtIExvZ2dpbmcKICAgIFtzdHJpbmddICROYW1lU2NyaXB0Tm91biAgICA9ICROYW1lU2NyaXB0LlNwbGl0KCctJylbLTFdCiAgICBbc3RyaW5nXSAkTmFtZVNjcmlwdEZpbGUgICAgPSAoJ1NldC17MH0ucHMxJyAtZiAoJE5hbWVTY3JpcHROb3VuKSkKICAgIFtzdHJpbmddICROYW1lU2NoZWR1bGVkVGFzayA9ICgnUnVuLXswfScgLWYgKCROYW1lU2NyaXB0Tm91bikpCiAgICBbc3RyaW5nXSAkUGF0aERpckxvZyAgICAgICAgPSAoJ3swfVxJcm9uc3RvbmVJVFx7MX1cTG9nc1wnIC1mICgkKGlmKCRTdHJJc0FkbWluIC1lcSAnVHJ1ZScpeyRlbnY6UHJvZ3JhbVc2NDMyfWVsc2V7JGVudjpBUFBEQVRBfSksJE5hbWVTY3JpcHROb3VuKSkKICAgIFtzdHJpbmddICRQYXRoRmlsZUxvZyAgICAgICA9ICgnezB9ezF9LXsyfS50eHQnIC1mICgkUGF0aERpckxvZywkTmFtZVNjcmlwdE5vdW4sKFtEYXRlVGltZV06Ok5vdy5Ub1N0cmluZygneXlNTWRkLUhIbW1zc2ZmZmYnKSkpKQogICAgCiAgICAjIFN0YXJ0IHRyYW5zY3JpcHQKICAgIGlmICgtbm90KFRlc3QtUGF0aCAtUGF0aCAkUGF0aERpckxvZykpe05ldy1JdGVtIC1QYXRoICRQYXRoRGlyTG9nIC1JdGVtVHlwZSAnRGlyZWN0b3J5JyAtRm9yY2V9CiAgICBTdGFydC1UcmFuc2NyaXB0IC1QYXRoICRQYXRoRmlsZUxvZwojZW5kcmVnaW9uIExvZ2dpbmcKCgoKCiNyZWdpb24gICAgRGVidWcKICAgIFdyaXRlLU91dHB1dCAtSW5wdXRPYmplY3QgKCcqKioqKioqKioqKioqKioqKioqKioqJykKICAgIFdyaXRlLU91dHB1dCAtSW5wdXRPYmplY3QgKCdQb3dlclNoZWxsIGlzIHJ1bm5pbmcgYXMgYSB7MH0gYml0IHByb2Nlc3Mgb24gYSB7MX0gYml0IE9TLicgLWYgKCRQcm9jZXNzQXJjaGl0ZWN0dXJlLCRPU0FyY2hpdGVjdHVyZSkpCiAgICBXcml0ZS1PdXRwdXQgLUlucHV0T2JqZWN0ICgnUnVubmluZyBhcyB1c2VyICJ7MH0iLiBIYXMgYWRtaW4gcHJpdmlsZWdlcz8gezF9JyAtZiAoJFN0clVzZXJOYW1lLCRTdHJJc0FkbWluKSkKICAgIFdyaXRlLU91dHB1dCAtSW5wdXRPYmplY3QgKCcqKioqKioqKioqKioqKioqKioqKioqJykKI2VuZHJlZ2lvbiBEZWJ1ZwoKCgoKI3JlZ2lvbiAgICBNYWluCiAgICBUcnkgewogICAgICAgICMgSW1wb3J0IEF1ZGlvRGV2aWNlQ21kbGV0cyBtb2R1bGUgbWFudWFsbHkgKExhdGVzdCBWZXJzaW9uKQogICAgICAgIFtzdHJpbmddICRQYXRoRGlyTW9kdWxlICAgICAgID0gKCd7MH1cV2luZG93c1Bvd2VyU2hlbGxcTW9kdWxlc1xBdWRpb0RldmljZUNtZGxldHMnIC1mICgkZW52OlByb2dyYW1XNjQzMikpCiAgICAgICAgW3N0cmluZ10gJFZlcnNpb25Nb2R1bGVMYXRlc3QgPSAoW1N5c3RlbS5WZXJzaW9uW11dKEAoR2V0LUNoaWxkSXRlbSAtUGF0aCAkUGF0aERpck1vZHVsZSAtRGlyZWN0b3J5IHwgU2VsZWN0LU9iamVjdCAtRXhwYW5kUHJvcGVydHkgTmFtZSkpIHwgU29ydC1PYmplY3QpWy0xXS5Ub1N0cmluZygpCiAgICAgICAgW3N0cmluZ10gJFBhdGhNb2R1bGVMYXRlc3QgICAgPSAoJ3swfVx7MX0nIC1mICgkUGF0aERpck1vZHVsZSwkVmVyc2lvbk1vZHVsZUxhdGVzdCkpCiAgICAgICAgR2V0LUNoaWxkSXRlbSAtUGF0aCAkUGF0aE1vZHVsZUxhdGVzdCAtRmlsZSB8IFNlbGVjdC1PYmplY3QgLUV4cGFuZFByb3BlcnR5IEZ1bGxOYW1lIHwgRm9yRWFjaC1PYmplY3Qge0ltcG9ydC1Nb2R1bGUgLU5hbWUgJF99CiAgICAgICAgCiAgICAgICAgCiAgICAgICAgIyBJZiBtb2R1bGVzIGltcG9ydCBmYWlsZWQKICAgICAgICBpZiAoQChHZXQtTW9kdWxlIHwgV2hlcmUtT2JqZWN0IC1Qcm9wZXJ0eSAnTmFtZScgLUVRICdBdWRpb0RldmljZUNtZGxldHMnKS5Db3VudCAtbHQgMSkgewogICAgICAgICAgICBXcml0ZS1PdXRwdXQgLUlucHV0T2JqZWN0ICgnRmFpbGVkIHRvIGltcG9ydCBQb3dlclNoZWxsIE1vZHVsZSAiQXVkaW9EZXZpY2VDbWRsZXRzIicpCiAgICAgICAgICAgICRTY3JpcHQ6U3VjY2VzcyA9ICRmYWxzZQogICAgICAgIH0KCgogICAgICAgICMgSWYgbW9kdWxlcyBpbXBvcnQgc3VjY2VlZGVkIC0gTG9vcCB0aHJvdWdoIHJlY29yZGluZyBkZXZpY2VzLCBzZXQgUmVjb3JkaW5nIFZvbHVtZSB0byAxMDAlCiAgICAgICAgZWxzZSB7ICAgIAogICAgICAgICAgICAkUmVjb3JkaW5nRGV2aWNlRGVmYXVsdCA9IEdldC1BdWRpb0RldmljZSAtUmVjb3JkaW5nIHwgU2VsZWN0LU9iamVjdCAtUHJvcGVydHkgJ05hbWUnLCdJRCcKICAgICAgICAgICAgJFJlY29yZGluZ0RldmljZUFsbCAgICAgPSBAKChHZXQtQXVkaW9EZXZpY2UgLUxpc3QgfCBXaGVyZS1PYmplY3QgLVByb3BlcnR5ICdUeXBlJyAtRVEgJ1JlY29yZGluZycpIHwgU2VsZWN0LU9iamVjdCAtUHJvcGVydHkgJ05hbWUnLCdJRCcpCiAgICAgICAgICAgIGlmICgkUmVjb3JkaW5nRGV2aWNlQWxsLkNvdW50IC1lcSAwKSB7CiAgICAgICAgICAgICAgICBXcml0ZS1PdXRwdXQgLUlucHV0T2JqZWN0ICgnRm91bmQgbm8gcmVjb3JkaW5nIGRldmljZXMuJykKICAgICAgICAgICAgICAgICRTY3JpcHQ6U3VjY2VzcyA9ICRmYWxzZQogICAgICAgICAgICB9CiAgICAgICAgICAgIGVsc2UgewogICAgICAgICAgICAgICAgZm9yZWFjaCAoJERldmljZSBpbiAkUmVjb3JkaW5nRGV2aWNlQWxsKSB7CiAgICAgICAgICAgICAgICAgICAgIyBTZXQgRGVmYXVsdCBSZWNvcmRpbmcgRGV2aWNlCiAgICAgICAgICAgICAgICAgICAgJG51bGwgPSBTZXQtQXVkaW9EZXZpY2UgJERldmljZS5JRAogICAgICAgICAgICAgICAgICAgIFtib29sXSAkTG9jYWw6U3VjY2Vzc19TZXREZWZhdWx0RGV2aWNlID0gJD8KICAgICAgICAgICAgICAgICAgICBXcml0ZS1PdXRwdXQgLUlucHV0T2JqZWN0ICgnU2V0dGluZyAiezB9IiBhcyBkZWZhdWx0IHJlY29yZGluZyBkZXZpY2UuIFN1Y2Nlc3M/IHsxfS4nIC1mICgkRGV2aWNlLk5hbWUsJExvY2FsOlN1Y2Nlc3NfU2V0RGVmYXVsdERldmljZS5Ub1N0cmluZygpKSkKICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAjIFNldCBWb2x1bWUgdG8gMTAwJQogICAgICAgICAgICAgICAgICAgICRudWxsID0gU2V0LUF1ZGlvRGV2aWNlIC1SZWNvcmRpbmdWb2x1bWUgMTAwCiAgICAgICAgICAgICAgICAgICAgW2Jvb2xdICRMb2NhbDpTdWNjZXNzX1NldFZvbHVtZSA9ICQ/CiAgICAgICAgICAgICAgICAgICAgV3JpdGUtT3V0cHV0IC1JbnB1dE9iamVjdCAoJ1NldHRpbmcgdm9sdW1lIHRvIDEwMCUuIFN1Y2Nlc3M/ICJ7MH0iLicgLWYgKCRMb2NhbDpTdWNjZXNzX1NldFZvbHVtZS5Ub1N0cmluZygpKSkKCiAgICAgICAgICAgICAgICAgICAgIyBDaGVjayBpZiBtdXRlZCwgdW5tdXRlIGlmIGl0IGlzCiAgICAgICAgICAgICAgICAgICAgaWYgKFtib29sXShHZXQtQXVkaW9EZXZpY2UgLVJlY29yZGluZ011dGUpIC1hbmQgJFNjcmlwdDpVbm11dGUpewogICAgICAgICAgICAgICAgICAgICAgICAkbnVsbCA9IFNldC1BdWRpb0RldmljZSAtUmVjb3JkaW5nTXV0ZSAkZmFsc2UKICAgICAgICAgICAgICAgICAgICAgICAgW2Jvb2xdICRMb2NhbDpTdWNjZXNzX1VubXV0ZSA9ICQ/CiAgICAgICAgICAgICAgICAgICAgICAgIFdyaXRlLU91dHB1dCAtSW5wdXRPYmplY3QgKCdVbm11dGluZyBjdXJyZW50IHJlY29yZGluZyBkZXZpY2UuIFN1Y2Nlc3M/ICJ7MH0iLicgLWYgKCRMb2NhbDpTdWNjZXNzX1VubXV0ZS5Ub1N0cmluZygpKSkKICAgICAgICAgICAgICAgICAgICB9CiAgICAgICAgICAgICAgICAgICAgZWxzZSB7W2Jvb2xdICRMb2NhbDpTdWNjZXNzX1VubXV0ZSA9ICR0cnVlfQogICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICMgU3RhdHMKICAgICAgICAgICAgICAgICAgICBpZiAoLW5vdCgkTG9jYWw6U3VjY2Vzc19TZXREZWZhdWx0RGV2aWNlIC1vciAkTG9jYWw6U3VjY2Vzc19TZXRWb2x1bWUgLW9yICRMb2NhbDpTdWNjZXNzX1VubXV0ZSkpeyRTY3JpcHQ6U3VjY2VzcyA9ICRmYWxzZX0KICAgICAgICAgICAgICAgIH0KICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgIyBTZXQgRGVmYXVsdCBSZWNvcmRpbmcgRGV2aWNlIGJhY2sgdG8gd2hhdCBpdCB3YXMKICAgICAgICAgICAgICAgICRudWxsID0gU2V0LUF1ZGlvRGV2aWNlICRSZWNvcmRpbmdEZXZpY2VEZWZhdWx0LklECiAgICAgICAgICAgICAgICAkTG9jYWw6U3VjY2Vzc19SZXZlcnREZWZhdWx0ID0gJD8KICAgICAgICAgICAgICAgIFdyaXRlLU91dHB1dCAtSW5wdXRPYmplY3QgKCdSZXZlcnRpbmcgInswfSIgYmFjayBhcyBkZWZhdWx0IHJlY29yZGluZyBkZXZpY2UuIFN1Y2Nlc3M/IHsxfS4nIC1mICgkUmVjb3JkaW5nRGV2aWNlRGVmYXVsdC5OYW1lLCRMb2NhbDpTdWNjZXNzX1JldmVydERlZmF1bHQuVG9TdHJpbmcoKSkpCiAgICAgICAgICAgICAgICBpZigtbm90KCRMb2NhbDpTdWNjZXNzX1JldmVydERlZmF1bHQpKXskU2NyaXB0OlN1Y2Nlc3MgPSAkTG9jYWw6U3VjY2Vzc19SZXZlcnREZWZhdWx0fQogICAgICAgICAgICB9CiAgICAgICAgfQogICAgfQojZW5kcmVnaW9uIE1haW4KCgoKCiNyZWdpb24gICAgQ2F0Y2ggYW5kIEZpbmFsbHkKICAgIENhdGNoIHsKICAgICAgICAkU2NyaXB0OlN1Y2Nlc3MgPSAkZmFsc2UKICAgICAgICAjIENvbnN0cnVjdCBNZXNzYWdlCiAgICAgICAgW3N0cmluZ10gJEVycm9yTWVzc2FnZSA9ICgnezB9IGZpbmlzaGVkIHdpdGggZXJyb3JzOicgLWYgKCROYW1lU2NyaXB0KSkKICAgICAgICAkRXJyb3JNZXNzYWdlICs9ICgnezB9ezB9RXhjZXB0aW9uOnswfScgLWYgKCJgcmBuIikpCiAgICAgICAgJEVycm9yTWVzc2FnZSArPSAkXy5FeGNlcHRpb24KICAgICAgICAkRXJyb3JNZXNzYWdlICs9ICgnezB9ezB9QWN0aXZpdHk6ezB9JyAtZiAoImByYG4iKSkKICAgICAgICAkRXJyb3JNZXNzYWdlICs9ICRfLkNhdGVnb3J5SW5mby5BY3Rpdml0eQogICAgICAgICRFcnJvck1lc3NhZ2UgKz0gKCd7MH17MH1FcnJvciBDYXRlZ29yeTp7MH0nIC1mICgiYHJgbiIpKQogICAgICAgICRFcnJvck1lc3NhZ2UgKz0gJF8uQ2F0ZWdvcnlJbmZvLkNhdGVnb3J5CiAgICAgICAgJEVycm9yTWVzc2FnZSArPSAoJ3swfXswfUVycm9yIFJlYXNvbjp7MH0nIC1mICgiYHJgbiIpKQogICAgICAgICRFcnJvck1lc3NhZ2UgKz0gJF8uQ2F0ZWdvcnlJbmZvLlJlYXNvbgogICAgICAgICMgV3JpdGUgRXJyb3IgTWVzc2FnZQogICAgICAgIFdyaXRlLUVycm9yIC1NZXNzYWdlICRFcnJvck1lc3NhZ2UKICAgIH0KICAgIEZpbmFsbHkgewogICAgICAgIFN0b3AtVHJhbnNjcmlwdAogICAgICAgIGlmICgkU2NyaXB0OlN1Y2Nlc3MgLWFuZCAkVmVyYm9zZVByZWZlcmVuY2UgLW5lICdDb250aW51ZScpIHtSZW1vdmUtSXRlbSAtUGF0aCAkUGF0aEZpbGVMb2cgLUZvcmNlfQogICAgfQojZW5kcmVnaW9uIENhdGNoIGFuZCBGaW5hbGx5');
            }
            FileOut-FromBase64 -PathDirOut $PathDirScript -NameFileOut $InstallFile.Name -ContentFileOut $InstallFile.Content -EncodingFileOut $InstallFile.Encoding -Force
        #endregion Export Set-RecordingDeviceVolumeMax.ps1




        #region    Create Scheduled Task
            # Variables - Scheduled Task
            [string] $NameScheduledTask  = ('Run-{0}' -f ($NameScriptNoun))
            [string] $PathFilePowerShell = '%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe' # Works regardless of 64bit vs 32bit
            

            # Exit if $PathFileScript does not exist
            foreach ($Path in @($PathFileScript)) {
                Write-Output -InputObject ('Test-Path -Path "{0}" = {1}' -f ($Path,([bool] $Exist = Test-Path -Path $Path).ToString()))
                if (-not($Exist)) {Throw 'Cannot create scheduled task without this file.';Break}
            }


            #region    Create Scheduled Task running PS1 using PowerShell.exe - Every Day at 9
                $ScheduledTask = New-ScheduledTask                                                    `
                    -Action    (New-ScheduledTaskAction -Execute ('"{0}"' -f ($PathFilePowerShell)) -Argument ('-ExecutionPolicy Bypass -NoLogo -NonInteractive -NoProfile -WindowStyle Hidden -File "{0}"' -f ($PathFileScript))) `
                    -Principal (New-ScheduledTaskPrincipal -UserId 'NT AUTHORITY\SYSTEM' -RunLevel 'Highest')                                                                                                                      `
                    -Trigger   (New-ScheduledTaskTrigger -Daily -At ([DateTime]::Today.AddHours(9)))                                                                                                                              `
                    -Settings  (New-ScheduledTaskSettingsSet -Hidden -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit ([TimeSpan]::FromMinutes(10)) -Compatibility 4 -StartWhenAvailable)
                $ScheduledTask.Author      = 'Ironstone'
                $ScheduledTask.Description = ('{0}Runs a PowerShell script. {1}Execute: "{2}". {1}Arguments: "{3}".' -f (
                    $(if([string]::IsNullOrEmpty($DescriptionScheduledTask)){''}else{('{0} {1}' -f ($DescriptionScheduledTask,"`r`n"))}),"`r`n",
                    [string]($ScheduledTask | Select-Object -ExpandProperty Actions | Select-Object -ExpandProperty Execute),
                    [string]($ScheduledTask | Select-Object -ExpandProperty Actions | Select-Object -ExpandProperty Arguments)
                ))
                $null = Register-ScheduledTask -TaskName $NameScheduledTask -InputObject $ScheduledTask -Force -Verbose:$false -Debug:$false
                if ($?) {$null = Start-ScheduledTask -TaskName $NameScheduledTask}
            #endregion Create Scheduled Task running PS1 using PowerShell.exe - Every Day at 9
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
    [string] $ErrorMessage = ('{0} finished with errors:' -f ($NameScriptFull))
    $ErrorMessage += ('{0}{0}Exception:{0}' -f ("`r`n"))
    $ErrorMessage += $_.Exception
    $ErrorMessage += ('{0}{0}Activity:{0}' -f ("`r`n"))
    $ErrorMessage += $_.CategoryInfo.Activity
    $ErrorMessage += ('{0}{0}Error Category:{0}' -f ("`r`n"))
    $ErrorMessage += $_.CategoryInfo.Category
    $ErrorMessage += ('{0}{0}Error Reason:{0}' -f ("`r`n"))
    $ErrorMessage += $_.CategoryInfo.Reason
    # Write Error Message
    Write-Error -Message $ErrorMessage
}
Finally {
    Stop-Transcript
}
#endregion Don't touch this