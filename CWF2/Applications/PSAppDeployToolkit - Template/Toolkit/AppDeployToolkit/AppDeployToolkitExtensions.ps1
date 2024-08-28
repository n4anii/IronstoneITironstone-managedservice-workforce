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

    # Determine the context in which the script is running
    $isSystemContext = $env:USERNAME -like "$env:COMPUTERNAME*"
    Write-Log -Message "Script is running in $(if ($isSystemContext) {'system'} else {'user'}) context."

    $Global:WingetLogFilePath = "$Env:TEMP\Winget"
    if (-Not (Test-Path -Path $Global:WingetLogFilePath)) {
        New-Item -ItemType Directory -Path $Global:WingetLogFilePath -Force
    }
    
    # If running in system context, resolve the path where winget.exe is found
    # ((Get-ChildItem -Path "$PSScriptRoot\Files\LenovoCommercialVantage_*.zip").Name | Select-String -Pattern "\d+\.\d+\.\d+\.0").Matches.Value; if (-not $appVersion) { $appVersion = '0.0.0.0' }
    if ($isSystemContext) {
        $WingetPath = Resolve-Path -Path "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_*__8wekyb3d8bbwe" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Path 
        [version]$WingetVersion = ($WingetPath | Select-String -Pattern "\d+\.\d+\.\d+\.0").Matches.Value
        [Version]$MinimumVersion = "1.23.1911.0"
        if ((-not($WingetPath)) -or (-not($WingetVersion -ge $MinimumVersion))) {
            Write-Log -Message "[ERROR] Winget not installed or Winget version $WingetVersion is not acceptable"
            return $null
        } else {
            Write-Log -Message "Winget is running an acceptable version $($WingetVersion)"
            Write-Log -Message "Logs can be found $env:TEMP\Winget"
            Write-Log -Message "Found path to winget directory $($WingetPath)"
            return $WingetPath
        }
    } else {
        # If running in user context, winget can be called directly
        $WingetPath = Resolve-Path -Path "$env:LOCALAPPDATA\Microsoft\WindowsApps\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Path
        Write-Log -Message "Logs can be found $env:TEMP\Winget"
        return $WingetPath
    }
}
Function Uninstall-Apps {
    <#
    .SYNOPSIS
        Removes apps from a computer in a standardized way

    .Example
        Call from Deploy-Application.ps1 like this Uninstall-Apps -AppsToRemove $AppsToRemove
 
    .NOTES
        Version: 1.2.2.0
        Author: Herman Bergsløkken / IronstoneIT
        Creation Date: 2024.06.04
        Edited Date: 2024.08.20
        Purpose/Change: Added custom parameters for MSI.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [array]$AppsToRemove
    )
    Show-InstallationProgress "Uninstalling apps. Please wait"
    
    foreach ($App in $AppsToRemove) {
            Write-Log -Message "Application is type $($App.Type). Uninstalling $(if ($App.Name) {"application name $($App.Name)"} else {"application path $($App.Path)"})"
            if ($App.Type -eq "msi") {
                if ($App.Parameters) {
                    Write-Log -Message "Uninstalling MSI with custom parameters"
                    Remove-MSIApplications -Name $App.Name -WildCard -AddParameters $App.Parameters
                } else {
                    Remove-MSIApplications -Name $App.Name -WildCard
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
                $WingetPath = Get-WingetPath
                if ($WingetPath) {
                    if (($env:USERNAME -like "$env:COMPUTERNAME*") -and ($App.Scope -eq "Machine")) {
                        Write-Log -Message "Uninstalling $($App.Name) with Winget as System"
                        Push-Location -Path $WingetPath
                        .\Winget.exe uninstall --id $App.ID --scope Machine --silent --force
                        Pop-Location
                    } elseif (($env:USERNAME -ne "$env:COMPUTERNAME*") -and ($App.Scope -eq "User")) {
                        Push-Location -Path $WingetPath
                        Write-Log -Message "Uninstalling $($App.Name) with Winget as User"
                        .\Winget.exe uninstall --id $App.ID --scope User --silent --force
                        Pop-Location
                    }
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
        Version: 1.0.0.0
        Author: Herman Bergsløkken / IronstoneIT
        Creation Date: 2024.06.04
        Purpose/Change: Initial script development
    #>
    param(
        [Parameter(Mandatory=$true)]
        [array]$Cleanups
    )
    
    foreach ($Cleanup in $Cleanups) {
        if (Test-Path -Path $Cleanup) {
            Write-Log -Message "Removing $Cleanup"
            Remove-Item -Path $Cleanup -Recurse -Force -ErrorAction SilentlyContinue
        } else {
            Write-Log -Message "$Cleanup does not exist on the target computer"
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
