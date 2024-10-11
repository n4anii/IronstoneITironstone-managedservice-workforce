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

function Get-WingetPath {
    <#
    .SYNOPSIS
        Resolves the location of Winget.exe, so that winget can run in both user and System-context

    .Example
        Call from Deploy-Application.ps1 like this $WingetPath = Get-WingetPath
 
    .NOTES
        Version: 1.2.0.0
        Author: Herman Bergsløkken / IronstoneIT
        Creation Date: 2024.08.28
        Purpose/Change: Returns Path (directory) and not fullpath to winget.exe
                        Added version check of Winget
    #>

    Write-Log -Message "Starting Get-WingetPath function."
    # Determine the context in which the script is running
    $isSystemContext = $env:USERNAME -like "$env:COMPUTERNAME*"
    Write-Log -Message "Script is running in $(if ($isSystemContext) {'system'} else {'user'}) context."

    # If running in system context, resolve the path where winget.exe is found
    if ($isSystemContext) {
        $WingetPath = Resolve-Path -Path "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_*__8wekyb3d8bbwe" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Path 
        [version]$WingetVersion = ($WingetPath | Select-String -Pattern "\d+\.\d+\.\d+\.0").Matches.Value
        [Version]$MinimumVersion = "1.23.1911.0"
        if ((-not($WingetPath)) -or (-not($WingetVersion -ge $MinimumVersion))) {
            Write-Log -Message "[ERROR] Winget not installed or Winget version $WingetVersion is not acceptable" -Severity 3
            return $null
        } else {
            Write-Log -Message "Winget is running an acceptable version $($WingetVersion)"
            Write-Log -Message "Logs can be found $WingetLogFilePath"
            Write-Log -Message "Found path to winget directory $($WingetPath)"
            return $WingetPath | Where-Object {$_ -like "*Microsoft.DesktopAppInstaller*"}
        }
    } else {
        # If running in user context, winget can be called directly
        $WingetPath = Resolve-Path -Path "$env:LOCALAPPDATA\Microsoft\WindowsApps\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Path
        Write-Log -Message "Logs can be found $WingetLogFilePath"
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
        Invoke-Winget -Action Install -AppWizName "7-Zip" -ID "7zip.7zip"
        Invoke-Winget -Action Uninstall -AppWizName "7-Zip" -ID "7zip.7zip"
        Invoke-Winget -Action Install -AppWizName "Draw.io" -ID "JGraph.Draw" -Scope User

    .NOTES
        Version: 1.2.0.0
        Author: Herman Bergsløkken / IronstoneIT
        Creation Date: 2024-09-12
        Purpose Change: First implementation of Winget as user
    #>
    [CmdletBinding()]
    param (

        [Parameter(Mandatory=$true)]
        [ValidateSet("Install", "Uninstall")]
        [string]$Action,

        # Friendly Name (Make it identical to the appwiz entry)
        [Parameter(Mandatory=$true)]
        [string]$AppWizName,

        #  The ID used by Winget to identify the application
        [Parameter(Mandatory=$true)]
        [string]$ID,

        # The specific version of the application to install, should only be used if absolutely necessary. If not set will install newest
        [Parameter(Mandatory=$false)]
        [string]$Version,

        # Some applications must be installed as user. This might required administrative rights
        [Parameter(Mandatory=$false)]
        [ValidateSet("user", "machine")]
        [string]$Scope = $(if ($env:USERNAME -like "$env:COMPUTERNAME*") {"machine"} else {"user"})
    )

    Begin {

        # Is required to run Winget in System-Context
        $RequiredPrereqs = [PSCustomObject]@{
            "Microsoft Visual C++ 2015-2022 Redistributable (x64)" = @{
            Version = "14.40.33810.0"
            InstallationFile = "vc_redist.x64.exe"
            Parameters = "/install /passive /norestart"
            URL = "https://aka.ms/vs/17/release/vc_redist.x64.exe"
            }
        }
        Test-InstallPrereqs -RequiredPrereqs $RequiredPrereqs
        Write-Log -Message "Starting Invoke-Winget function."
        [string]$WingetDirectory = Get-WingetPath
    }

    Process {
        
        $wingetParams = "--id $ID --exact --scope $Scope --accept-source-agreements --accept-package-agreements --silent --disable-interactivity --log $env:TEMP\Winget.log"
        $logMessage = "Executing: $((Get-Location).Path) .\Winget.exe $Action $wingetParams"
        
        if (-not [string]::IsNullOrEmpty($WingetDirectory)) {
            Write-Log -Message "Setting $WingetDirectory as working directory!"
            Set-Location -Path $WingetDirectory
            if ($Action -like "Install" -or $Action -like "Uninstall") {
                Write-Log -Message $logMessage
                if ($Scope -eq "user") {
                    Execute-ProcessAsUser -Path "$WingetDirectory\winget.exe" -Parameters $wingetParams
                } else {
                    .\Winget.exe $wingetParams
                }
            }
            Start-Sleep -Seconds 3
            Write-Log -Message "Reverting working directory!"
            Pop-Location
        } else {
            Write-Log -Message "No Winget directory was found. Unable to continue." -Severity 3
        }
    }
    End {
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
                    Invoke-Winget -Action Uninstall -AppWizName "$($App.Name)" -ID "$App.ID" -Scope Machine
                } elseif (($env:USERNAME -ne "$env:COMPUTERNAME*") -and ($App.Scope -eq "User")) {
                    Write-Log -Message "Uninstalling $($App.Name) with Winget as User"
                    Invoke-Winget -Action Uninstall -AppWizName "$($App.Name)" -ID "$App.ID" -Scope User
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
        }

        Test-InstallPrereqs -RequiredPrereqs $RequiredPrereqs

    .NOTES
        Author: Herman Bergsløkken / IronstoneIT
        Date: 2024-09-12
        Winget as prereqs is WIP. But should work
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
    $InstalledPackages = Get-Package

    # Check if the Prereqs is installed and if the version is up-to-date
    foreach ($Software in $RequiredPrereqs.PSObject.Properties) {
        $Name = $Software.Name
        $RequiredVersion = $Software.Value.Version

        $InstalledPackage = $InstalledPackages | Where-Object { $_.Name -like "*$Name*" }

        if ($InstalledPackage) {
            $InstalledVersion = $InstalledPackage.Version | Sort-Object | Select-Object -First 1 # Some products might be both MSI and EXE with multiple versions. Example: Vstor_2010
            if (Compare-Version -InstalledVersion $InstalledVersion -RequiredVersion $RequiredVersion) {
                Write-Log -Message "$Name is installed and up-to-date (Version: $InstalledVersion)"
            } else {
                Write-Log -Message "$Name is installed but not up-to-date (Installed Version: $InstalledVersion, Required Version: $RequiredVersion)"
            }
        } else {
            Write-Log -Message "$Name is not installed"

            if ($Software.Value.URL) {
                Show-InstallationProgress "Downloading $Name"
                $DownloadFolder = "$dirFiles\PreRequisites"
                if (-not (Test-Path -Path $DownloadFolder)) {
                    Write-Log -Message "Creating $DownloadFolder"
                    New-Item -Path $DownloadFolder -ItemType Directory -Force | Out-Null
                }
                try {
                    [string]$PathFileOut = "$DownloadFolder\$($Software.Value.InstallationFile)"
                    Start-BitsTransfer -Source $($Software.Value.URL) -Destination $PathFileOut -ErrorAction Stop
                    Write-Log -Message "All files downloaded successfully to $PathFileOut"
                } catch {
                    Write-Log -Message "An error occurred while downloading $Name : $_"
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
                Invoke-Winget -Action Install -AppWizName "$($Name)" -ID "$($InstallationFile.WingetID)"
            } else {
                Write-Log -Message "Installation file for $Name not found." -Severity 3
            }
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
