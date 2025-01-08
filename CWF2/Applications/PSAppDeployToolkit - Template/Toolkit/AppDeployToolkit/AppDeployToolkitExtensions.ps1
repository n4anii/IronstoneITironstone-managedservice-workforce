<#
.SYNOPSIS

PSAppDeployToolkit - Provides the ability to extend and customise the toolkit by adding your own functions that can be re-used.

.DESCRIPTION

This script is a template that allows you to extend the toolkit with your own custom functions.

This script is dot-sourced by the AppDeployToolkitMain.ps1 script which contains the logic and functions required to install or uninstall an application.

PSApppDeployToolkit is licensed under the GNU LGPLv3 License - (C) 2024 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham and Muhammad Mashwani).

This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the
Free Software Foundation, either version 3 of the License, or any later version. This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details. You should have received a copy of the GNU Lesser General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.

.EXAMPLE

powershell.exe -File .\AppDeployToolkitHelp.ps1

.INPUTS

None

You cannot pipe objects to this script.

.OUTPUTS

None

This script does not generate any output.

.NOTES

.LINK

https://psappdeploytoolkit.com
#>


[CmdletBinding()]
Param (
)

##*===============================================
##* VARIABLE DECLARATION
##*===============================================

# Variables: Script
[string]$appDeployToolkitExtName = 'PSAppDeployToolkitExt'
[string]$appDeployExtScriptFriendlyName = 'App Deploy Toolkit Extensions'
[version]$appDeployExtScriptVersion = [version]'3.10.1'
[string]$appDeployExtScriptDate = '05/03/2024'
[hashtable]$appDeployExtScriptParameters = $PSBoundParameters

##*===============================================
##* FUNCTION LISTINGS
##*===============================================
$Global:LoggedOnUser = Get-LoggedOnUser
function Get-WingetPath {
    <#
    .SYNOPSIS
        Resolves the location of Winget.exe, so that winget can run in both user and System-context

    .Example
        Call from Deploy-Application.ps1 like this $WingetPath = Get-WingetPath
 
    .NOTES
        Version: 1.3.5.0
        Author: Herman Bergsløkken / IronstoneIT
        Creation Date: 2024.10.21
        Edited Date: 2024.15.11
        Purpose/Change: Returns Path (directory) and not fullpath to winget.exe
                        Added version check of Winget
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [ValidateSet("User", "Machine")]
        [string]$OverrideContext
    )

    Write-Log -Message "Starting Get-WingetPath function."
    # Determine the context in which the script is running
    $isSystemContext = $env:USERNAME -like "$env:COMPUTERNAME*"
    Write-Log -Message "Script is running in $(if ($isSystemContext) {'system'} else {'user'}) context."
    if ($OverrideContext) {
        Write-Log -Message "Override context is set to $($OverrideContext)"
    }

    # If running in system context, resolve the path where winget.exe is found
    if ($isSystemContext) {
        if ($OverrideContext -notlike "User") {
            try {
                # Default version in case anything fails
                [Version]$WingetVersion = "0.0.0.0"
                [Version]$MinimumVersion = "1.23.1911.0"
            
                # Get Winget path
                $WingetPath = Resolve-Path -Path "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_*__8wekyb3d8bbwe" -ErrorAction SilentlyContinue | 
                    Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue
            
                if ($WingetPath) {
                    # Windows 11 24H2 started returning multiple versions of Winget installed. Picking the newest one.
                    $WingetPath = $WingetPath | Sort-Object { [version]($_ -split '_')[1]} -Descending | Select-Object -First 1
                    # Try to extract version using regex
                    if ($WingetPath -match "(\d+\.\d+\.\d+\.0)") {
                        $WingetVersion = [Version]$matches[1]
                    }
                }
            
                Write-Log -Message "Detected Winget Version: $WingetVersion"
                Write-Log -Message "Minimum Required Version: $MinimumVersion"
            }
            catch {
                Write-Log -Message "Unable to determine Winget version. Using default version 0.0.0.0"
                [Version]$WingetVersion = "0.0.0.0"
            }

            if ((-not($WingetPath)) -or (-not($WingetVersion -ge $MinimumVersion))) {
                Write-Log -Message "[ERROR] Winget not installed or Winget version $WingetVersion is not acceptable" -Severity 3
                return $null
            } else {
                Write-Log -Message "Winget is running an acceptable version $($WingetVersion)"
                Write-Log -Message "Found path to winget directory $($WingetPath)"
                return $WingetPath | Where-Object {$_ -like "*Microsoft.DesktopAppInstaller*"}
            }
        } else {
            Write-Log -Message "Resolving path to current logged on user's Winget"
            if (-not $LoggedOnUser) {
                Write-Log -Message "ERROR: LoggedOnUser variable not found" -Severity 3
                return $null
            }
            $WingetPath = Resolve-Path -Path "C:\Users\$($LoggedOnUser.Username)\AppData\Local\Microsoft\WindowsApps\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Path
            Write-Log -Message "Resolved Path is $($WingetPath)"
            return $WingetPath | Where-Object {$_ -like "*Microsoft.DesktopAppInstaller*"}
        }
    } else {
        # If running in user context, winget can be called directly
        $WingetPath = Resolve-Path -Path "$env:LOCALAPPDATA\Microsoft\WindowsApps\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Path
        Write-Log -Message "Resolved Path is $($WingetPath)"
        return $WingetPath | Where-Object {$_ -like "*Microsoft.DesktopAppInstaller*"}
    }
}
function Invoke-Winget {
    <#
    .SYNOPSIS
        This script installs or uninstalls an application using Winget.

    .DESCRIPTION
        This script uses Winget to install or uninstall an application based on the provided parameters. 
        It supports specifying the application AppWizName, Winget ID, version, scope, and log location.

    .EXAMPLE
        Invoke-Winget -Action Install -AppWizName "7-Zip" -ID "7zip.7zip" -Scope Machine
        Invoke-Winget -Action Uninstall -AppWizName "7-Zip" -ID "7zip.7zip" -Scope Machine

    .NOTES
        Version: 1.5.0.0
        Author: Herman Bergsløkken / IronstoneIT
        Creation Date: 2024-09-12
        Changed: 2025-07-01
        Purpose Change: Added support for Winget source error and removed --scope Machine when uninstalling + Sandbox
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet("Install", "Uninstall")]
        [string]$Action,

        [Parameter(Mandatory=$true)]
        [string]$AppWizName,

        [Parameter(Mandatory=$true)]
        [string]$ID,

        [Parameter(Mandatory=$false)]
        [string]$Version,

        [Parameter(Mandatory=$false)]
        [ValidateSet("user", "Machine")]
        [string]$Scope = $(if ($env:USERNAME -like "$env:COMPUTERNAME*") {"Machine"} else {"user"})
    )

    Begin {
        $RequiredPrereqs = [PSCustomObject]@{
            "Microsoft Visual C++ 2015-2022 Redistributable (x64)" = @{
                Version = "14.40.33810.0"
                InstallationFile = "vc_redist.x64.exe"
                Parameters = "/install /passive /norestart"
                URL = "https://aka.ms/vs/17/release/vc_redist.x64.exe"
            }
            "Microsoft.DesktopAppInstaller" = @{
                Version = "1.24.0.0"
                InstallationFile = "Microsoft.DesktopAppInstaller.msixbundle"
                URL = "https://aka.ms/getwinget"
            }
        }
        Test-InstallPrereqs -RequiredPrereqs $RequiredPrereqs
        
        [string]$WingetDirectory = Get-WingetPath -OverrideContext $Scope
        Write-Log -Message "Starting Invoke-Winget function."
    }

    Process {
        if ($Scope -eq "user") {
            if (-not $LoggedOnUser) {
                Write-Log -Message "ERROR: LoggedOnUser variable not found" -Severity 3
                return
            }
            $LogPath = Resolve-Path -Path "C:\Users\$($LoggedOnUser.Username)\AppData\Local\Temp"
            $LogPath = Join-Path $LogPath "Winget.log"
        } else {
            $LogPath = "$env:TEMP\Winget.log"
        }
        Write-Log -Message "LogPath is $LogPath"

        $wingetParams = @(
            $Action
            "--id"
            $ID
            "--exact"
            "--scope"
            $Scope
            "--accept-source-agreements"
            "--accept-package-agreements"
            "--silent"
            "--disable-interactivity"
            "--log"
            $LogPath
        )

        if ($Action -like "Uninstall") {
            Write-Log -Message "Removing --accept-package-agreements since action is Uninstall"
            $wingetParams = $wingetParams -creplace "--accept-package-agreements", ""
        }

        # Add version if specified
        if (-not [string]::IsNullOrEmpty($Version)) {
            Write-Log -Message "Adding --version"
            $wingetParams += @("--version", $Version)
        }

        Write-Log -Message "Remove whitespace and blank lines"
        $wingetParams = $wingetParams | Where-Object {$_ -ne ""}
        
        if (-not [string]::IsNullOrEmpty($WingetDirectory)) {
            if ($Scope -eq "user") {
                Write-Log -Message "Executing: $($WingetDirectory)\Winget.exe $($wingetParams -join ' ')"
                Execute-ProcessAsUser -Path "$WingetDirectory\winget.exe" -Parameters ($wingetParams -join ' ')
            } else {
                Write-Log -Message "Setting $WingetDirectory as working directory!"
                Set-Location -Path $WingetDirectory
                Write-Log -Message "Executing: $($WingetDirectory)\Winget.exe $($wingetParams -join ' ')"
                $InstallOutput = & .\Winget.exe @wingetParams
                if ($InstallOutput -match "No applicable installer found; see logs for more details.") {
                    Write-Log -Message "Specific error caught: $InstallOutput"
                    Write-Log -Message "Removing --scope Machine since this sometimes makes the difference"
                    $wingetParams = $wingetParams -creplace "--scope", "" -creplace "Machine", "" | Where-Object {$_ -ne ""}
                    Write-Log -Message "Executing: $($WingetDirectory)\Winget.exe $($wingetParams -join ' ')"
                    $InstallOutput = & .\Winget.exe @wingetParams
                    Write-Log -Message "Command output: $InstallOutput"
                } 
                elseif ($InstallOutput -match "0x8a15003b.") {
                    Write-Log -Message "Specific error caught: $InstallOutput"
                    Write-Log -Message "MS Store source error detected, retrying with winget source only"
                    $wingetParams += @("--source", "winget")
                    Write-Log -Message "Executing: $($WingetDirectory)\Winget.exe $($wingetParams -join ' ')"
                    $InstallOutput = & .\Winget.exe @wingetParams
                    Write-Log -Message "Command output: $InstallOutput"
                }
                else {
                    Write-Log -Message "Command output: $InstallOutput"
                }
            }
        } else {
            Write-Log -Message "No Winget directory was found. Unable to continue." -Severity 3
        }
    }
    
    End {
        Pop-Location
        Write-Log -Message "Ending Invoke-Winget function."
    }

}
Function Uninstall-Apps {
    <#
    .SYNOPSIS
        Removes apps from a computer in a standardized way

    .Example
        Call from Deploy-Application.ps1 like this Uninstall-Apps -AppsToRemove $AppsToRemove
 
    .NOTES
        Version: 1.4.0.0
        Author: Herman Bergsløkken / IronstoneIT
        Creation Date: 2024.06.04
        Edited Date: 2024.09.17
        Purpose/Change: Added MSI uninstall in user-context
    #>
    param(
        [Parameter(Mandatory=$true)]
        [array]$AppsToRemove
    )
    Write-Log -Message "Starting Uninstall-Apps function."
    Show-InstallationProgress "Uninstalling apps. Please wait"
    
    foreach ($App in $AppsToRemove) {
            Write-Log -Message "Application is type $($App.Type). Uninstalling $(if ($App.Name) {"application name $($App.Name)"} else {"application path $($App.Path)"})"
            if ($App.Type -eq "msi") {
                if ($App.Parameters) {
                    Write-Log -Message "Uninstalling MSI with custom parameters $($App.Parameters)"
                    Remove-MSIApplications -Name $App.Name -WildCard -AddParameters $App.Parameters
                    $ProductCodes = (Get-InstalledApplication -Name "$($AppsToRemove.Name)" -WildCard).ProductCode
                    if ($ProductCodes) {
                        foreach ($ProductCode in $ProductCodes) {
                            Write-Log -Message "Found $($AppsToRemove.Name) product in User-Context. Uninstalling $($ProductCode) with custom parameters $($App.Parameters)"
                            Execute-ProcessAsUser -Path "C:\Windows\System32\MsiExec.exe" -Parameters "/X $($ProductCode) $($App.Parameters)"
                        }
                    }
                } else {
                    Remove-MSIApplications -Name $App.Name -WildCard
                    $ProductCodes = (Get-InstalledApplication -Name "$($AppsToRemove.Name)" -WildCard).ProductCode
                    if ($ProductCodes) {
                        foreach ($ProductCode in $ProductCodes) {
                            Write-Log -Message "Found $($AppsToRemove.Name) product in User-Context. Uninstalling $($ProductCode)"
                            Execute-ProcessAsUser -Path "C:\Windows\System32\MsiExec.exe" -Parameters "/X $($ProductCode) /QN /NORESTART"
                        }
                    }
                }
            } elseif ($App.Type -eq "exe" -and (Test-Path -Path $App.Path)) {
                $ExeFullName = Get-ChildItem -Path "$($App.Path)" | Select-Object -ExpandProperty FUllName
                foreach ($EXEPath in $ExeFullName) {
                    if ($App.IgnoreExitCodes -eq "false") {
                        Write-Log -Message "Application is type $($App.Type) Uninstalling $EXEPath"
                        Execute-Process -Path $EXEPath -Parameters $App.Parameters
                    } else {
                        $ignoreExitCodesArray = [int]$($App.IgnoreExitCodes)
                        Write-Log -Message "Application is type $($App.Type) Uninstalling $EXEPath and ignoring exit codes $($App.IgnoreExitCodes)"
                        Execute-Process -Path $EXEPath -Parameters $App.Parameters -IgnoreExitCodes $ignoreExitCodesArray
                    }
                }
            } elseif ($App.Type -eq "Winget") {
                if (($env:USERNAME -like "$env:COMPUTERNAME*") -and ($App.Scope -eq "Machine")) {
                    Write-Log -Message "Uninstalling $($App.Name) with Winget as System"
                    Invoke-Winget -Action uninstall -AppWizName "$($App.Name)" -ID "$App.ID" -Scope Machine
                } elseif ($App.Scope -eq "User") {
                    Write-Log -Message "Uninstalling $($App.Name) with Winget as User"
                    Invoke-Winget -Action uninstall -AppWizName "$($App.Name)" -ID "$App.ID" -Scope User
                }
            } elseif ($App.Type -eq "AppX") {
                if ($env:USERNAME -like "$env:COMPUTERNAME*") { #If user is System you can uninstall for AllUsers and ProvisionedPackages
                    $PackageFullName = (Get-AppxPackage -AllUsers $App.Name).PackageFullName
                    $ProPackageFullName = (Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq $App.Name}).PackageName
                } else {
                    $PackageFullName = (Get-AppxPackage $App.Name).PackageFullName
                }
                ForEach ($Package in $PackageFullName) {
                    Write-Log -Message "Removing Package: $Package"
                    try {
                        Remove-AppxPackage -Package $Package -AllUsers
                    } catch {
                        $PackageBundleName = (Get-AppxPackage -PackageTypeFilter Bundle -AllUsers $App.Name).PackageFullName
                        ForEach ($BundlePackage in $PackageBundleName) {
                            Remove-AppxPackage -Package $BundlePackage -AllUsers
                        }
                    }
                }
                ForEach ($ProPackage in $ProPackageFullName) {
                    Write-Log -Message "Removing Provisioned Package: $ProPackage"
                    try {
                        Remove-AppxProvisionedPackage -Online -PackageName $ProPackage
                    } catch {
                        # Bundled/provisioned apps are already removed by "Remove-AppxPackage -AllUsers"
                    }
                }
            }
        }
}
Function Remove-Leftovers {
    <#
    .SYNOPSIS
        Removes folders, files and registry from a computer in a standardized way

    .Example
        Call from Deploy-Application.ps1 like this Remove-Leftovers -Cleanups $Cleanups
 
    .NOTES
        Version: 1.1.0.0
        Author: Herman Bergsløkken / IronstoneIT
        Creation Date: 2024.06.04
        Date Modified: 2024.09.30
        Purpose/Change: Updated to handle multiple resolved paths and added enhanced error handling
    #>
    param(
        [Parameter(Mandatory=$true)]
        [array]$Cleanups
    )

    Write-Log -Message "Starting Remove-Leftovers function."
    foreach ($Cleanup in $Cleanups) {
        $ResolvedPaths = Get-ChildItem -Path $Cleanup -ErrorAction SilentlyContinue
        foreach ($Path in $ResolvedPaths) {
            if (Test-Path -Path $Path.FullName) {
                Write-Log -Message "Removing $($Path.FullName)"
                Try {
                    Remove-Item -Path $Path.FullName -Recurse -Force -ErrorAction Stop
                } Catch {
                    Write-Log -Message "Error removing $($Path.FullName): $_"
                }
            } else {
                Write-Log -Message "$($Path.FullName) does not exist on the target computer"
            }
        }
    }
}
function Test-InstallPrereqs {
    <#
    .SYNOPSIS
        Checks and installs required prerequisites.

    .DESCRIPTION
        This function checks if the specified prerequisites are installed and up-to-date. If not, it downloads and installs them.

    .PARAMETER RequiredPrereqs
        A PSCustomObject containing the required prerequisites with their details.

    .EXAMPLE
        $RequiredPrereqs = [PSCustomObject]@{
            "Microsoft Visual C++ 2015-2022 Redistributable (x64)" = @{
                Version = "14.40.33810.0"
                InstallationFile = "vc_redist.x64.exe"
                Parameters = "/install /passive /norestart"
                URL = "https://aka.ms/vs/17/release/vc_redist.x64.exe"
            }
            "Microsoft Visual C++ 2015-2022 Redistributable (x86)" = @{
                Version = "14.40.33810.0"
                InstallationFile = "vc_redist.x86.exe"
                Parameters = "/install /passive /norestart"
            }
            "Microsoft.DesktopAppInstaller" = @{
                Version = "1.24.0.0"
                InstallationFile = "Microsoft.DesktopAppInstaller.msixbundle"
                URL = "https://aka.ms/getwinget"
            }
        }

        Test-InstallPrereqs -RequiredPrereqs $RequiredPrereqs

    .NOTES
        Author: Herman Bergsløkken / IronstoneIT
        Date: 2025-07-01
    #>
    param (
        [PSCustomObject]$RequiredPrereqs
    )

    # Declare supportive functions
    function Compare-Version {
        param (
            [string]$InstalledVersion,
            [string]$RequiredVersion
        )

        $installed = [version]$InstalledVersion
        $required = [version]$RequiredVersion

        if ($installed -ge $required) {
            return $true
        } else {
            return $false
        }
    }

    Write-Log -Message "Starting Test-InstallPrereqs function."
    $InstalledPackages = Get-Package -WarningAction SilentlyContinue
    $InstallAppXPackages = Get-AppxPackage -AllUsers -Name "*" -WarningAction SilentlyContinue
    $AllInstalledPackages = $InstalledPackages += $InstallAppXPackages

    # Check if the Prereqs is installed and if the version is up-to-date
    foreach ($Software in $RequiredPrereqs.PSObject.Properties) {
        
        $Name = $Software.Name
        $RequiredVersion = $Software.Value.Version
        $InstalledPackage = $AllInstalledPackages | Where-Object { $_.Name -like "*$Name*" }

        if ($InstalledPackage) {
            $InstalledVersion = $InstalledPackage.Version | Sort-Object | Select-Object -First 1 # Some products might be both MSI and EXE with multiple versions. Example: Vstor_2010
            if (Compare-Version -InstalledVersion $InstalledVersion -RequiredVersion $RequiredVersion) {
                Write-Log -Message "$Name is installed and up-to-date (Version: $InstalledVersion)"
                $Install = $false
            } else {
                Write-Log -Message "$Name is installed but not up-to-date (Installed Version: $InstalledVersion, Required Version: $RequiredVersion)"
                $Install = $true
            }
        } else {
            Write-Log -Message "$Name is not installed"
            $Install = $true
        }
        
        if ($Install) {
            if ($Software.Value.URL) {
                $InstallationFile = Get-ChildItem -Path "$dirFiles\PreRequisites\$($Software.Value.InstallationFile)"
                if (-not $InstallationFile) {
                    Write-Log -Message "Downloading $($Software.Value.InstallationFile) from $($Software.Value.URL)"
                    Get-DownloadFile -URL $Software.Value.URL -DestinationFolder "$dirFiles\PreRequisites" -FileName $Software.Value.InstallationFile
                }
            }

            # Determine the installation file type and install
            $InstallationFile = Get-ChildItem -Path "$dirFiles\PreRequisites\$($Software.Value.InstallationFile)"
            if ($InstallationFile -like "*.exe") {
                Show-InstallationProgress "Installing $Name"
                Execute-Process -Path $InstallationFile.FullName -Parameters $Software.Value.Parameters
            } elseif ($InstallationFile -like "*.msi") {
                Show-InstallationProgress "Installing $Name"
                Execute-MSI -Action Install -Path $InstallationFile.FullName -AddParameters $Software.Value.Parameters
            } elseif ($InstallationFile -like "Winget") {
                Show-InstallationProgress "Installing $Name"
                Invoke-Winget -Action Install -AppWizName "$($Name)" -ID "$($InstallationFile.WingetID)" -Scope "Machine"
            } elseif ($InstallationFile -like "*.msixbundle") {
                Show-InstallationProgress "Installing $Name"
                if ($Software.Value.Parameters) {
                    Add-AppxProvisionedPackage -Online -PackagePath "$($InstallationFile.FullName)" -SkipLicense "$($Software.Value.Parameters)"
                } else {
                    Add-AppxProvisionedPackage -Online -PackagePath "$($InstallationFile.FullName)" -SkipLicense
                }
            } else {
                Write-Log -Message "Installation file for $Name not found." -Severity 3
            }
        }
    }
}
function Get-DownloadFile {
    <#
    .SYNOPSIS
        Downloads files using BITS transfer with WebClient fallback.

    .DESCRIPTION
        This function downloads files using Background Intelligent Transfer Service (BITS) with a WebClient fallback mechanism.
        It supports custom headers, ensures destination folders exist, and uses a Windows-specific user agent for compatibility.
        The function attempts BITS transfer first, and if that fails, falls back to WebClient.

    .PARAMETER URL
        The source URL of the file to download.

    .PARAMETER DestinationFolder
        The folder where the downloaded file will be saved. The folder will be created if it doesn't exist.

    .PARAMETER FileName
        The name to save the downloaded file as.

    .PARAMETER AdditionalHeaders
        Optional hashtable of additional headers to include in the request.

    .EXAMPLE
        Get-DownloadFile -URL "https://example.com/file.zip" -DestinationFolder "C:\Downloads" -FileName "file.zip"

        Downloads a file using default settings and BITS transfer.

    .EXAMPLE
        $headers = @{
            "X-FORMS_BASED_AUTH_ACCEPTED" = "f"
            "Authorization" = "Bearer token123"
        }
        Get-DownloadFile -URL "https://example.com/file.zip" -DestinationFolder "C:\Downloads" -FileName "custom-name.zip" -AdditionalHeaders $headers

        Downloads a file using WebClient with custom headers.

    .NOTES
        Author: Herman Bergsløkken / IronstoneIT
        Date: 2024-01-06
        
        The function uses a Windows Update Agent user-agent string for better compatibility with Windows/Microsoft servers.
        BITS transfer is attempted first for better reliability with large files, falling back to WebClient if BITS fails.
        Returns the full path to the downloaded file on success, $false on failure.
#>
    param (
        [Parameter(Mandatory = $true)]
        [string]$URL,
        
        [Parameter(Mandatory = $true)]
        [string]$DestinationFolder,
        
        [Parameter(Mandatory = $true)]
        [string]$FileName,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$AdditionalHeaders = @{}
    )

    Write-Log -Message "Starting Get-DownloadFile function."
    if (-not (Test-Path $DestinationFolder)) {
        Write-Log -Message "Creating folder $DestinationFolder"
        New-Item -ItemType Directory -Path $DestinationFolder -Force | Out-Null
    }

    $DestinationPath = Join-Path $DestinationFolder $FileName
    Write-Log -Message "Destination path is $DestinationPath"

    try {
            Write-Log -Message "Attempting download using BITS..."
            $request = [System.Net.WebRequest]::Create($URL)
            $request.AllowAutoRedirect = $true
            $response = $request.GetResponse()
            $resolvedUrl = $response.ResponseUri.AbsoluteUri
            $response.Dispose()

            Start-BitsTransfer -Source $resolvedUrl -Destination $DestinationPath -DisplayName "File Download" -Priority High
            Write-Log -Message "Download completed successfully using BITS."
            return $DestinationPath
        }
        catch {
            Write-Log -Message "BITS transfer failed: $($_.Exception.Message)"
            Write-Log -Message "Falling back to WebClient..."
        }
    
    try {
        # Use WebClient as primary or fallback method
        $webClient = New-Object System.Net.WebClient
        $webClient.UseDefaultCredentials = $true
        $webClient.Headers.Add("user-agent", "Windows-Update-Agent/10.0.10011.16384 Client-Protocol/1.40")

        # Add any additional headers
        foreach ($header in $AdditionalHeaders.GetEnumerator()) {
            $webClient.Headers.Add($header.Key, $header.Value)
        }

        $webClient.DownloadFile($URL, $DestinationPath)
        Write-Log -Message "Download completed successfully using WebClient."
        return $DestinationPath
    }
    catch {
        Write-Log -Message "Download failed. Error: $($_.Exception.Message)"
        return $false
    }
    finally {
        if ($webClient) {
            $webClient.Dispose()
        }
    }
}
##*===============================================
##* END FUNCTION LISTINGS
##*===============================================

##*===============================================
##* SCRIPT BODY
##*===============================================

If ($scriptParentPath) {
    Write-Log -Message "Script [$($MyInvocation.MyCommand.Definition)] dot-source invoked by [$(((Get-Variable -Name MyInvocation).Value).ScriptName)]" -Source $appDeployToolkitExtName
}
Else {
    Write-Log -Message "Script [$($MyInvocation.MyCommand.Definition)] invoked directly" -Source $appDeployToolkitExtName
}

##*===============================================
##* END SCRIPT BODY
##*===============================================
