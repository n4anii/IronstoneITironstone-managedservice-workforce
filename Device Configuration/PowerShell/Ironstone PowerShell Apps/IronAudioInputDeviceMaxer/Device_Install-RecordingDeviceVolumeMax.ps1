<#

.SYNOPSIS


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
        @(Get-ChildItem -Path $PathDirScript -File -Recurse | Select-Object -ExpandProperty FullName) | ForEach-Object {Remove-Item -Path $_ -Force}


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
                Content =[string]('PCMKLlNZTk9QU0lTCiAgICBTZXQgbXZvbHVtZSBsZXZlbCB0byAxMDAlIGZvciBhbGwgUmVjb3JkaW5nIERldmljZXMgdXNpbmcgUG93ZXJTaGVsbCBNb2R1bGUgIkF1ZGlvRGV2aWNlQ21kbGV0cyIKCi5ERVNDUklQVElPTgogICAgR2V0IERlZmF1bHQgUmVjb3JkaW5nIERldmljZSAoVG8gcmVzZXQgdG8gdGhpcyBhZnRlcndhcmRzKQogICAgTG9vcCBldmVyeSBSZWNvcmRpbmcgRGV2aWNlCiAgICBTZXQgZWFjaCByZWNvcmRpbmcgdm9sdW1lIHRvIDEwMCUgYnkgZmlyc3Qgc2V0dGluZyBkZXZpY2UgYXMgZGVmYXVsdCwgdGhlbiBzZXQgdm9sdW1lCiAgICBSZXN0b3JlIGRlZmF1bHQgcmVjb3JkaW5nIGRldmljZSBhZnRlcndhcmRzCiM+CgoKCiNyZWdpb24gICAgU2V0dGluZ3MKICAgICMgU2V0dGluZ3MgLSBQb3dlclNoZWxsIC0gT3V0cHV0IFByZWZlcmVuY2VzCiAgICAkRGVidWdQcmVmZXJlbmNlICAgICAgID0gJ1NpbGVudGx5Q29udGludWUnCiAgICAkSW5mb3JtYXRpb25QcmVmZXJlbmNlID0gJ1NpbGVudGx5Q29udGludWUnCiAgICAkVmVyYm9zZVByZWZlcmVuY2UgICAgID0gJ1NpbGVudGx5Q29udGludWUnCiAgICAkV2FybmluZ1ByZWZlcmVuY2UgICAgID0gJ0NvbnRpbnVlJwoKICAgICMgU2V0dGluZ3MgLSBQb3dlclNoZWxsIC0gSW50ZXJhY3Rpb24KICAgICRDb25maXJtUHJlZmVyZW5jZSAgICAgPSAnTm9uZScKICAgICRQcm9ncmVzc1ByZWZlcmVuY2UgICAgPSAnU2lsZW50bHlDb250aW51ZScKCiAgICAjIFNldHRpbmdzIC0gUG93ZXJTaGVsbCAtIEJlaGF2aW91cgogICAgJEVycm9yQWN0aW9uUHJlZmVyZW5jZSA9ICdDb250aW51ZScKI2VuZHJlZ2lvbiBTZXR0aW5ncwoKCgoKI3JlZ2lvbiAgICBMb2dnaW5nCiAgICAjIFZhcmlhYmxlcyAtIFN0YXRpYwogICAgW2Jvb2xdICAgJFNjcmlwdDpTdWNjZXNzICAgID0gJHRydWUKICAgIFtzdHJpbmddICROYW1lU2NyaXB0ICAgICAgICA9ICgnU2V0LVJlY29yZGluZ0RldmljZVZvbHVtZU1heCcpCgogICAgIyBWYXJpYWJsZXMgLSBFbnZpcm9ubWVudCBJbmZvCiAgICBbc3RyaW5nXSAkU3RyVXNlck5hbWUgPSBbU3lzdGVtLlNlY3VyaXR5LlByaW5jaXBhbC5XaW5kb3dzSWRlbnRpdHldOjpHZXRDdXJyZW50KCkuTmFtZQogICAgW3N0cmluZ10gJFN0cklzQWRtaW4gID0gKFtTZWN1cml0eS5QcmluY2lwYWwuV2luZG93c1ByaW5jaXBhbF1bU2VjdXJpdHkuUHJpbmNpcGFsLldpbmRvd3NJZGVudGl0eV06OkdldEN1cnJlbnQoKSkuSXNJblJvbGUoW1NlY3VyaXR5LlByaW5jaXBhbC5XaW5kb3dzQnVpbHRJblJvbGVdOjpBZG1pbmlzdHJhdG9yKQogICAgW3N0cmluZ10gJFByb2Nlc3NBcmNoaXRlY3R1cmUgPSAkKGlmKFtTeXN0ZW0uRW52aXJvbm1lbnRdOjpJczY0Qml0UHJvY2Vzcyl7JzY0J31FbHNleyczMid9KQogICAgW3N0cmluZ10gJE9TQXJjaGl0ZWN0dXJlICAgICAgPSAkKGlmKFtTeXN0ZW0uRW52aXJvbm1lbnRdOjpJczY0Qml0T3BlcmF0aW5nU3lzdGVtKXsnNjQnfUVsc2V7JzMyJ30pCgogICAgIyBWYXJpYWJsZXMgLSBMb2dnaW5nCiAgICBbc3RyaW5nXSAkTmFtZVNjcmlwdE5vdW4gICAgPSAkTmFtZVNjcmlwdC5TcGxpdCgnLScpWy0xXQogICAgW3N0cmluZ10gJE5hbWVTY3JpcHRGaWxlICAgID0gKCdTZXQtezB9LnBzMScgLWYgKCROYW1lU2NyaXB0Tm91bikpCiAgICBbc3RyaW5nXSAkTmFtZVNjaGVkdWxlZFRhc2sgPSAoJ1J1bi17MH0nIC1mICgkTmFtZVNjcmlwdE5vdW4pKQogICAgW3N0cmluZ10gJFBhdGhEaXJMb2cgICAgICAgID0gKCd7MH1cSXJvbnN0b25lSVRcezF9XExvZ3NcJyAtZiAoJChpZigkU3RySXNBZG1pbiAtZXEgJ1RydWUnKXskZW52OlByb2dyYW1XNjQzMn1lbHNleyRlbnY6QVBQREFUQX0pLCROYW1lU2NyaXB0Tm91bikpCiAgICBbc3RyaW5nXSAkUGF0aEZpbGVMb2cgICAgICAgPSAoJ3swfXsxfS17Mn0udHh0JyAtZiAoJFBhdGhEaXJMb2csJE5hbWVTY3JpcHROb3VuLChbRGF0ZVRpbWVdOjpOb3cuVG9TdHJpbmcoJ3l5TU1kZC1ISG1tc3NmZmZmJykpKSkKICAgIAogICAgIyBTdGFydCB0cmFuc2NyaXB0CiAgICBpZiAoLW5vdChUZXN0LVBhdGggLVBhdGggJFBhdGhEaXJMb2cpKXtOZXctSXRlbSAtUGF0aCAkUGF0aERpckxvZyAtSXRlbVR5cGUgJ0RpcmVjdG9yeScgLUZvcmNlfQogICAgU3RhcnQtVHJhbnNjcmlwdCAtUGF0aCAkUGF0aEZpbGVMb2cKI2VuZHJlZ2lvbiBMb2dnaW5nCgoKCgojcmVnaW9uICAgIERlYnVnCiAgICBXcml0ZS1PdXRwdXQgLUlucHV0T2JqZWN0ICgnKioqKioqKioqKioqKioqKioqKioqKicpCiAgICBXcml0ZS1PdXRwdXQgLUlucHV0T2JqZWN0ICgnUG93ZXJTaGVsbCBpcyBydW5uaW5nIGFzIGEgezB9IGJpdCBwcm9jZXNzIG9uIGEgezF9IGJpdCBPUy4nIC1mICgkUHJvY2Vzc0FyY2hpdGVjdHVyZSwkT1NBcmNoaXRlY3R1cmUpKQogICAgV3JpdGUtT3V0cHV0IC1JbnB1dE9iamVjdCAoJ1J1bm5pbmcgYXMgdXNlciAiezB9Ii4gSGFzIGFkbWluIHByaXZpbGVnZXM/IHsxfScgLWYgKCRTdHJVc2VyTmFtZSwkU3RySXNBZG1pbikpCiAgICBXcml0ZS1PdXRwdXQgLUlucHV0T2JqZWN0ICgnKioqKioqKioqKioqKioqKioqKioqKicpCiNlbmRyZWdpb24gRGVidWcKCgoKCiNyZWdpb24gICAgTWFpbgogICAgVHJ5IHsKICAgICAgICAjIEltcG9ydCBtb2R1bGVzIG1hbnVhbGx5CiAgICAgICAgR2V0LUNoaWxkSXRlbSAtUGF0aCAoJ3swfVxXaW5kb3dzUG93ZXJTaGVsbFxNb2R1bGVzXEF1ZGlvRGV2aWNlQ21kbGV0c1wnIC1mICgkZW52OlByb2dyYW1XNjQzMikpIC1GaWxlIC1SZWN1cnNlIHwgU2VsZWN0LU9iamVjdCAtRXhwYW5kUHJvcGVydHkgRnVsbE5hbWUgfCBGb3JFYWNoLU9iamVjdCB7SW1wb3J0LU1vZHVsZSAtTmFtZSAkX30KICAgICAgICAKICAgICAgICAKICAgICAgICAjIElmIG1vZHVsZXMgaW1wb3J0IGZhaWxlZAogICAgICAgIGlmIChAKEdldC1Nb2R1bGUgfCBXaGVyZS1PYmplY3QgeyRfLk5hbWUgLWVxICdBdWRpb0RldmljZUNtZGxldHMnfSkuQ291bnQgLWx0IDIpIHsKICAgICAgICAgICAgV3JpdGUtT3V0cHV0IC1JbnB1dE9iamVjdCAoJ0ZhaWxlZCB0byBpbXBvcnQgUG93ZXJTaGVsbCBNb2R1bGUgIkF1ZGlvRGV2aWNlQ21kbGV0cyInKQogICAgICAgIH0KCgogICAgICAgICMgSWYgbW9kdWxlcyBpbXBvcnQgc3VjY2VlZGVkIC0gTG9vcCB0aHJvdWdoIHJlY29yZGluZyBkZXZpY2VzLCBzZXQgUmVjb3JkaW5nIFZvbHVtZSB0byAxMDAlCiAgICAgICAgZWxzZSB7ICAgIAogICAgICAgICAgICAkUmVjb3JkaW5nRGV2aWNlRGVmYXVsdCA9IEdldC1BdWRpb0RldmljZSAtUmVjb3JkaW5nIHwgU2VsZWN0LU9iamVjdCAtUHJvcGVydHkgJ05hbWUnLCdJRCcKICAgICAgICAgICAgJFJlY29yZGluZ0RldmljZUFsbCAgICAgPSBAKChHZXQtQXVkaW9EZXZpY2UgLUxpc3QgfCBXaGVyZS1PYmplY3QgeyRfLlR5cGUgLWVxICdSZWNvcmRpbmcnfSkgfCBTZWxlY3QtT2JqZWN0IC1Qcm9wZXJ0eSAnTmFtZScsJ0lEJykKICAgICAgICAgICAgaWYgKCRSZWNvcmRpbmdEZXZpY2VBbGwuQ291bnQgLWVxIDApIHsKICAgICAgICAgICAgICAgIFdyaXRlLU91dHB1dCAtSW5wdXRPYmplY3QgKCdGb3VuZCBubyByZWNvcmRpbmcgZGV2aWNlcy4nKQogICAgICAgICAgICAgICAgJFNjcmlwdDpTdWNjZXNzID0gJGZhbHNlCiAgICAgICAgICAgIH0KICAgICAgICAgICAgZWxzZSB7CiAgICAgICAgICAgICAgICBmb3JlYWNoICgkRGV2aWNlIGluICRSZWNvcmRpbmdEZXZpY2VBbGwpIHsKICAgICAgICAgICAgICAgICAgICAjIFNldCBEZWZhdWx0IFJlY29yZGluZyBEZXZpY2UKICAgICAgICAgICAgICAgICAgICAkbnVsbCA9IFNldC1BdWRpb0RldmljZSAkRGV2aWNlLklECiAgICAgICAgICAgICAgICAgICAgW2Jvb2xdICRMb2NhbDpTdWNjZXNzX1NldERlZmF1bHREZXZpY2UgPSAkPwogICAgICAgICAgICAgICAgICAgIFdyaXRlLU91dHB1dCAtSW5wdXRPYmplY3QgKCdTZXR0aW5nICJ7MH0iIGFzIGRlZmF1bHQgcmVjb3JkaW5nIGRldmljZS4gU3VjY2Vzcz8gezF9LicgLWYgKCREZXZpY2UuTmFtZSwkTG9jYWw6U3VjY2Vzc19TZXREZWZhdWx0RGV2aWNlKSkKICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAjIFNldCBWb2x1bWUgdG8gMTAwJQogICAgICAgICAgICAgICAgICAgICRudWxsID0gU2V0LUF1ZGlvRGV2aWNlIC1SZWNvcmRpbmdWb2x1bWUgMTAwCiAgICAgICAgICAgICAgICAgICAgW2Jvb2xdICRMb2NhbDpTdWNjZXNzX1NldFZvbHVtZSA9ICQ/CiAgICAgICAgICAgICAgICAgICAgV3JpdGUtT3V0cHV0IC1JbnB1dE9iamVjdCAoJ1NldHRpbmcgdm9sdW1lIHRvIDEwMCUuIFN1Y2Nlc3M/ICJ7MH0iLicgLWYgKCRMb2NhbDpTdWNjZXNzX1NldFZvbHVtZSkpCiAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgIyBTdGF0cwogICAgICAgICAgICAgICAgICAgIGlmICgtbm90KCRMb2NhbDpTdWNjZXNzX1NldERlZmF1bHREZXZpY2UgLW9yICRMb2NhbDpTdWNjZXNzX1NldFZvbHVtZSkpeyRTY3JpcHQ6U3VjY2VzcyA9ICRmYWxzZX0KICAgICAgICAgICAgICAgIH0KICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgIyBTZXQgRGVmYXVsdCBSZWNvcmRpbmcgRGV2aWNlIGJhY2sgdG8gd2hhdCBpdCB3YXMKICAgICAgICAgICAgICAgICRudWxsID0gU2V0LUF1ZGlvRGV2aWNlICRSZWNvcmRpbmdEZXZpY2VEZWZhdWx0LklECiAgICAgICAgICAgICAgICAkTG9jYWw6U3VjY2Vzc19SZXZlcnREZWZhdWx0ID0gJD8KICAgICAgICAgICAgICAgIFdyaXRlLU91dHB1dCAtSW5wdXRPYmplY3QgKCdSZXZlcnRpbmcgInswfSIgYmFjayBhcyBkZWZhdWx0IHJlY29yZGluZyBkZXZpY2UuIFN1Y2Nlc3M/IHsxfS4nIC1mICgkUmVjb3JkaW5nRGV2aWNlRGVmYXVsdC5OYW1lLCRMb2NhbDpTdWNjZXNzX1JldmVydERlZmF1bHQpKQogICAgICAgICAgICAgICAgaWYoLW5vdCgkTG9jYWw6U3VjY2Vzc19SZXZlcnREZWZhdWx0KSl7JFNjcmlwdDpTdWNjZXNzID0gJExvY2FsOlN1Y2Nlc3NfUmV2ZXJ0RGVmYXVsdH0KICAgICAgICAgICAgfQogICAgICAgIH0KICAgIH0KI2VuZHJlZ2lvbiBNYWluCgoKCgojcmVnaW9uICAgIENhdGNoIGFuZCBGaW5hbGx5CiAgICBDYXRjaCB7CiAgICAgICAgJFN1Y2Nlc3MgPSAkZmFsc2UKICAgICAgICAjIENvbnN0cnVjdCBNZXNzYWdlCiAgICAgICAgJEVycm9yTWVzc2FnZSA9ICgnezB9IGZpbmlzaGVkIHdpdGggZXJyb3JzOicgLWYgKCROYW1lU2NyaXB0KSkKICAgICAgICAkRXJyb3JNZXNzYWdlICs9ICIgYG4iCiAgICAgICAgJEVycm9yTWVzc2FnZSArPSAnRXhjZXB0aW9uOiAnCiAgICAgICAgJEVycm9yTWVzc2FnZSArPSAkXy5FeGNlcHRpb24KICAgICAgICAkRXJyb3JNZXNzYWdlICs9ICIgYG4iCiAgICAgICAgJEVycm9yTWVzc2FnZSArPSAnQWN0aXZpdHk6ICcKICAgICAgICAkRXJyb3JNZXNzYWdlICs9ICRfLkNhdGVnb3J5SW5mby5BY3Rpdml0eQogICAgICAgICRFcnJvck1lc3NhZ2UgKz0gIiBgbiIKICAgICAgICAkRXJyb3JNZXNzYWdlICs9ICdFcnJvciBDYXRlZ29yeTogJwogICAgICAgICRFcnJvck1lc3NhZ2UgKz0gJF8uQ2F0ZWdvcnlJbmZvLkNhdGVnb3J5CiAgICAgICAgJEVycm9yTWVzc2FnZSArPSAiIGBuIgogICAgICAgICRFcnJvck1lc3NhZ2UgKz0gJ0Vycm9yIFJlYXNvbjogJwogICAgICAgICRFcnJvck1lc3NhZ2UgKz0gJF8uQ2F0ZWdvcnlJbmZvLlJlYXNvbgogICAgICAgIFdyaXRlLUVycm9yIC1NZXNzYWdlICRFcnJvck1lc3NhZ2UKICAgIH0KICAgIEZpbmFsbHkgewogICAgICAgIFN0b3AtVHJhbnNjcmlwdAogICAgICAgIGlmICgkU2NyaXB0OlN1Y2Nlc3MgLWFuZCAkVmVyYm9zZVByZWZlcmVuY2UgLW5lICdDb250aW51ZScpIHtSZW1vdmUtSXRlbSAtUGF0aCAkUGF0aEZpbGVMb2cgLUZvcmNlfQogICAgfQojZW5kcmVnaW9uIENhdGNoIGFuZCBGaW5hbGx5');
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