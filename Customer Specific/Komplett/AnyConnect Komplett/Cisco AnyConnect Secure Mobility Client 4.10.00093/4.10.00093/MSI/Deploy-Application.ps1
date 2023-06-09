<#
.SYNOPSIS
	This script performs the installation or uninstallation of an application(s).
	# LICENSE #
	PowerShell App Deployment Toolkit - Provides a set of functions to perform common application deployment tasks on Windows. 
	Copyright (C) 2017 - Sean Lillis, Dan Cunningham, Muhammad Mashwani, Aman Motazedian.
	This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. 
	You should have received a copy of the GNU Lesser General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
.DESCRIPTION
	The script is provided as a template to perform an install or uninstall of an application(s).
	The script either performs an "Install" deployment type or an "Uninstall" deployment type.
	The install deployment type is broken down into 3 main sections/phases: Pre-Install, Install, and Post-Install.
	The script dot-sources the AppDeployToolkitMain.ps1 script which contains the logic and functions required to install or uninstall an application.
.PARAMETER DeploymentType
	The type of deployment to perform. Default is: Install.
.PARAMETER DeployMode
	Specifies whether the installation should be run in Interactive, Silent, or NonInteractive mode. Default is: Interactive. Options: Interactive = Shows dialogs, Silent = No dialogs, NonInteractive = Very silent, i.e. no blocking apps. NonInteractive mode is automatically set if it is detected that the process is not user interactive.
.PARAMETER AllowRebootPassThru
	Allows the 3010 return code (requires restart) to be passed back to the parent process (e.g. SCCM) if detected from an installation. If 3010 is passed back to SCCM, a reboot prompt will be triggered.
.PARAMETER TerminalServerMode
	Changes to "user install mode" and back to "user execute mode" for installing/uninstalling applications for Remote Destkop Session Hosts/Citrix servers.
.PARAMETER DisableLogging
	Disables logging to file for the script. Default is: $false.
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeployMode 'Silent'; Exit $LastExitCode }"
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -AllowRebootPassThru; Exit $LastExitCode }"
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeploymentType 'Uninstall'; Exit $LastExitCode }"
.EXAMPLE
    Deploy-Application.exe -DeploymentType "Install" -DeployMode "Silent"
.NOTES
	Toolkit Exit Code Ranges:
	60000 - 68999: Reserved for built-in exit codes in Deploy-Application.ps1, Deploy-Application.exe, and AppDeployToolkitMain.ps1
	69000 - 69999: Recommended for user customized exit codes in Deploy-Application.ps1
	70000 - 79999: Recommended for user customized exit codes in AppDeployToolkitExtensions.ps1
.LINK 
	http://psappdeploytoolkit.com
#>
[CmdletBinding()]
Param (
	[Parameter(Mandatory=$false)]
	[ValidateSet('Install','Uninstall')]
	[string]$DeploymentType = 'Install',
	[Parameter(Mandatory=$false)]
	[ValidateSet('Interactive','Silent','NonInteractive')]
	[string]$DeployMode = 'Interactive',
	[Parameter(Mandatory=$false)]
	[switch]$AllowRebootPassThru = $false,
	[Parameter(Mandatory=$false)]
	[switch]$TerminalServerMode = $false,
	[Parameter(Mandatory=$false)]
	[switch]$DisableLogging = $false,
	[Parameter(Mandatory=$false)]
	[switch]$Install_StartBefore = $false,		
	#Allow Cancel
	[Parameter(Mandatory=$false)]
	[ValidateSet('Yes','No')]
	[string]$AllowCancel = 'Yes',
	#Force Close
	[Parameter(Mandatory=$false)]
	[ValidateSet('Yes','No')]
	[string]$ForceClose = 'Yes',
	#Completion Notice
	[Parameter(Mandatory=$false)]
	[ValidateSet('Yes','No')]
	[string]$EndDialog = 'No',
	#Disable Interaction
	[Parameter(Mandatory=$false)]
	[switch]$DisableInteraction = $false,
	#MSI Arguments
	[Parameter(Mandatory=$false)]
	[string]$MSIArgs = '',
	#Script Timeout
	[Parameter(Mandatory=$false)]
	[ValidateRange(0,5400)]
	[int32]$ScriptTimeout = 5400,
	#Show Progress
	[Parameter(Mandatory=$false)]
	[ValidateSet('Yes','No')]
	[string]$ShowProgress = 'No'
)

Try {
	## Set the script execution policy for this process
	Try { Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -Scope 'Process' -Force -ErrorAction 'Stop' } Catch {}
	
	##*===============================================
	##* VARIABLE DECLARATION
	##*===============================================
	
    $appVendor = "Cisco"
	$appName = "AnyConnect Secure Mobility Client"
	$appVersion = "4.10.00093"
	$appArch = "x86"
	$appLang = ""
	$appFamily = "Cisco AnyConnect Secure Mobility Client"		
	$appRevision = "01"
	$appScriptVersion = "1.0.0"
	$appScriptAuthor = "Peteris Beltins"
    $ScriptGuid = "{506e2c29-a8ce-4a26-b2f9-8743faea79d7}"
    
	[string]$installTitle = $DeploymentType + ": $appName $appVersion"
	[string]$appList = "vpnui"
	[switch]$isAppUpdate = $true
	$PkgName = $appName
	$PkgVersion = $appVersion
	$PkgVendor = $appVendor
	
	$SB_Install={
		Execute-MSI -Action Install -Path "anyconnect-win-4.10.00093-core-vpn-predeploy-k9.msi" -Transform "Cisco AnyConnect Secure Mobility Client 4.10.mst" -Parameters "/qn $MSIArgs"
		If ($Install_StartBefore) {
		Execute-MSI -Action Install -Path "anyconnect-win-4.10.00093-gina-predeploy-k9.msi" -Transform "Cisco AnyConnect Start Before Login Module 4.10.mst" -Parameters "/qn $MSIArgs"
		}	
		
        Foreach ($DRK In Get-ChildItem -Path 'HKLM:\SOFTWARE\Atea\Applications\') {
            If ((Test-RegistryValue -Key $DRK -Value 'Family') -and (Test-RegistryValue -Key $DRK -Value 'AppUpdate')) {
                If (((Get-RegistryKey -Key $DRK -Value 'Family') -eq $appFamily) -and ((Get-RegistryKey -Key $DRK -Value 'AppUpdate') -eq 'True')) {
                    Remove-RegistryKey -Key $DRK
                }
            }
        }			


		Set-RegistryKey -Key "HKEY_LOCAL_MACHINE\SOFTWARE\Atea\Applications\$ScriptGuid" -Name "Architecture" -Value "$appArch"
		Set-RegistryKey -Key "HKEY_LOCAL_MACHINE\SOFTWARE\Atea\Applications\$ScriptGuid" -Name "DateTime" -Value "$currentDateTime"
		Set-RegistryKey -Key "HKEY_LOCAL_MACHINE\SOFTWARE\Atea\Applications\$ScriptGuid" -Name "Language" -Value "$appLang"
		Set-RegistryKey -Key "HKEY_LOCAL_MACHINE\SOFTWARE\Atea\Applications\$ScriptGuid" -Name "Manufacturer" -Value "$PkgVendor"
		Set-RegistryKey -Key "HKEY_LOCAL_MACHINE\SOFTWARE\Atea\Applications\$ScriptGuid" -Name "Name" -Value "$PkgName"
		Set-RegistryKey -Key "HKEY_LOCAL_MACHINE\SOFTWARE\Atea\Applications\$ScriptGuid" -Name "Revision" -Value "$appRevision"
		Set-RegistryKey -Key "HKEY_LOCAL_MACHINE\SOFTWARE\Atea\Applications\$ScriptGuid" -Name "Version" -Value "$PkgVersion"
		Set-RegistryKey -Key "HKEY_LOCAL_MACHINE\SOFTWARE\Atea\Applications\$ScriptGuid" -Name "AppUpdate" -Value "$isAppUpdate"
		Set-RegistryKey -Key "HKEY_LOCAL_MACHINE\SOFTWARE\Atea\Applications\$ScriptGuid" -Name "Family" -Value "$appFamily"		
		
		#Remove old GUIDs for upgrade
		Remove-RegistryKey -Key "HKEY_LOCAL_MACHINE\SOFTWARE\Atea\Applications\{506e2c29-a8ce-4a26-b2f9-8743faea79d1}"			
		Remove-RegistryKey -Key "HKEY_LOCAL_MACHINE\SOFTWARE\Atea\Applications\{16516d03-2dc6-4e56-a756-65bb0b4797b0}"			
		Remove-RegistryKey -Key "HKEY_LOCAL_MACHINE\SOFTWARE\Atea\Applications\{29C2FEE1-25AD-45FF-8A1A-86DF3DC6EEE4}"		
		Remove-RegistryKey -Key "HKEY_LOCAL_MACHINE\SOFTWARE\Atea\Applications\{A20F89F3-4323-4D94-9C34-186F031A26A4}"		
		Remove-RegistryKey -Key "HKEY_LOCAL_MACHINE\SOFTWARE\Atea\Applications\{D36E32FA-B68C-455E-A03F-CA806ECC50AA}"		
		Remove-RegistryKey -Key "HKEY_LOCAL_MACHINE\SOFTWARE\Atea\Applications\{5C26C4D7-BDDA-4625-AF6D-CC8C89D3C9B6}"			
		Remove-RegistryKey -Key "HKEY_LOCAL_MACHINE\SOFTWARE\Atea\Applications\{1352652A-E1CF-4EFB-9AEA-EFC85BEA763F}"			
		Remove-RegistryKey -Key "HKEY_LOCAL_MACHINE\SOFTWARE\Atea\Applications\{09A4C943-4876-48AE-8F9A-8C8EEB0E927A}"		
		Remove-RegistryKey -Key "HKEY_LOCAL_MACHINE\SOFTWARE\Atea\Applications\{8D158A8B-2FE1-4B20-B3B0-4F23C358AAF5}"			
		Remove-RegistryKey -Key "HKEY_LOCAL_MACHINE\SOFTWARE\Atea\Applications\{0C1067B1-CE6B-433B-8D04-3F5FBA83F5F7}"		
		Remove-RegistryKey -Key "HKEY_LOCAL_MACHINE\SOFTWARE\Atea\Applications\{DB3F1825-CFBA-43B4-A881-A35664BE43E8}"		
		Remove-RegistryKey -Key "HKEY_LOCAL_MACHINE\SOFTWARE\Atea\Applications\{C8782529-CEE9-4D1B-94B2-62742C5147B4}"			
		Remove-RegistryKey -Key "HKEY_LOCAL_MACHINE\SOFTWARE\Atea\Applications\{EB71184B-BDAC-4786-9DA1-9B93702E9B5D}"		
		Remove-RegistryKey -Key "HKEY_LOCAL_MACHINE\SOFTWARE\Atea\Applications\{1EE76014-DE8B-4262-8546-02042AB3BBE7}"
		Remove-RegistryKey -Key "HKEY_LOCAL_MACHINE\SOFTWARE\Atea\Applications\{D5946EFB-44D3-40EF-BC28-37F3C226AB34}"
		Remove-RegistryKey -Key "HKEY_LOCAL_MACHINE\SOFTWARE\Atea\Applications\{16D341A0-BBA8-48A6-9040-DB3018A378D4}"
		Remove-RegistryKey -Key "HKEY_LOCAL_MACHINE\SOFTWARE\Atea\Applications\{18A8B45C-2453-45F7-85EB-95190D9E44D4}"
		Remove-RegistryKey -Key "HKEY_LOCAL_MACHINE\SOFTWARE\Atea\Applications\{0B3E1D74-6900-441A-88C5-01FF264289A9}"
		Remove-RegistryKey -Key "HKEY_LOCAL_MACHINE\SOFTWARE\Atea\Applications\{8D2390A6-70A1-4118-BF86-E46E01802604}"
		Remove-RegistryKey -Key "HKEY_LOCAL_MACHINE\SOFTWARE\Atea\Applications\{262A1208-6EA7-4F4D-92F6-AD15EAE873F7}"
		Remove-RegistryKey -Key "HKEY_LOCAL_MACHINE\SOFTWARE\Atea\Applications\{DDB6F3F3-8733-4051-9822-0AB311DEBF12}"
	}
	
	$SB_Uninstall={

		#Cisco AnyConnect Start Before Login Module
		Execute-MSI -Action Uninstall -Path "{4612856C-1742-4F94-8DC4-1154258EEAF5}" -Parameters '/qn'
		#Cisco AnyConnect Secure Mobility Client
		Execute-MSI -Action Uninstall -Path "{6B15DEBB-2AB9-42DD-8ECF-82EF8F21CC69}" -Parameters '/qn'


		Remove-RegistryKey -Key "HKEY_LOCAL_MACHINE\SOFTWARE\Atea\Applications\$ScriptGuid"
	}
	
	## Variables: Exit Code
	[int32]$mainExitCode = 0
	
	## Variables: Script
	[string]$deployAppScriptFriendlyName = 'Deploy Application'
	[version]$deployAppScriptVersion = [version]'3.7.0'
	[string]$deployAppScriptDate = '02/13/2018'
	[hashtable]$deployAppScriptParameters = $psBoundParameters
	
	## Variables: Environment
	If (Test-Path -LiteralPath 'variable:HostInvocation') { $InvocationInfo = $HostInvocation } Else { $InvocationInfo = $MyInvocation }
	[string]$scriptDirectory = Split-Path -Path $InvocationInfo.MyCommand.Definition -Parent
	
	## Dot source the required App Deploy Toolkit Functions
	Try {
		[string]$moduleAppDeployToolkitMain = "$scriptDirectory\AppDeployToolkit\AppDeployToolkitMain.ps1"
		If (-not (Test-Path -LiteralPath $moduleAppDeployToolkitMain -PathType 'Leaf')) { Throw "Module does not exist at the specified location [$moduleAppDeployToolkitMain]." }
		If ($DisableLogging) { . $moduleAppDeployToolkitMain -DisableLogging } Else { . $moduleAppDeployToolkitMain }
	}
	Catch {
		If ($mainExitCode -eq 0){ [int32]$mainExitCode = 60008 }
		Write-Error -Message "Module [$moduleAppDeployToolkitMain] failed to load: `n$($_.Exception.Message)`n `n$($_.InvocationInfo.PositionMessage)" -ErrorAction 'Continue'
		## Exit the script, returning the exit code to SCCM
		If (Test-Path -LiteralPath 'variable:HostInvocation') { $script:ExitCode = $mainExitCode; Exit } Else { Exit $mainExitCode }
	}
	
	#endregion
	##* Do not modify section above
	##*===============================================
	##* END VARIABLE DECLARATION
	##*===============================================
		
	If ($deploymentType -ine 'Uninstall') {
		##*===============================================
		##* PRE-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Pre-Installation'
		
		If ($appList -ne [string]::Empty) {
			If (($DisableInteraction -eq $true) -or (-not $usersLoggedOn)) {
				Show-InstallationWelcome -CloseApps $appList -Silent
			}
			ElseIf ($DeployMode -eq 'Interactive') {
				If ($AllowCancel -ieq 'Yes' -and $ForceClose -ieq 'Yes') {
					Show-InstallationWelcome -CloseApps $appList -PersistPrompt -AllowDeferCloseApps -DeferTimes 3 -ForceCloseAppsCountdown $ScriptTimeout
				}
				ElseIf ($AllowCancel -ieq 'Yes' -and $ForceClose -ieq 'No') {
					Show-InstallationWelcome -CloseApps $appList -PersistPrompt -AllowDeferCloseApps -DeferTimes 3 -ForceCountdown $ScriptTimeout
				}
				ElseIf ($AllowCancel -ieq 'No' -and $ForceClose -ieq 'Yes') {
					Show-InstallationWelcome -CloseApps $appList -PersistPrompt -ForceCloseAppsCountdown $ScriptTimeout
				}
				ElseIf ($AllowCancel -ieq 'No' -and $ForceClose -ieq 'No') {
					Show-InstallationWelcome -CloseApps $appList -PersistPrompt -ForceCountdown $ScriptTimeout
				}
			}
			Else {
				try {
					Remove-Folder -Path "$envWinDir\PSADT"
					Copy-File -Path "$dirSupportFiles\User-Level" -Destination "$envWinDir\PSADT" -Recurse
					Copy-File -Path "$scriptRoot\Banner.png" -Destination "$envWinDir\PSADT\User-Level\AppDeployToolkit"
					Copy-File -Path "$scriptRoot\Icon.ico" -Destination "$envWinDir\PSADT\User-Level\AppDeployToolkit"
					$exitCode = Execute-ProcessAsUser -Path "$envWinDir\PSADT\User-Level\Deploy-Application.exe" -Parameters "-DeploymentType Install -DeployMode Interactive -Applist '$appList' -ScriptTimeout $ScriptTimeout -InstallTitle '$installTitle' -AllowCancel '$AllowCancel' -ForceClose '$ForceClose'" -Wait -PassThru  
					Remove-Folder -Path "$envWinDir\PSADT"
					If ($exitCode -ne 0) {
						Exit-Script -ExitCode $exitCode			
					}
				}
				catch {}
			}
		}
		
		## Show Progress Message (with the default message)
		If ($ShowProgress -ieq 'Yes') {
			Show-InstallationProgress
		}
		
		##*===============================================
		##* INSTALLATION 
		##*===============================================
		[string]$installPhase = 'Installation'
		
		& $SB_Install
		
		##*===============================================
		##* POST-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Installation'
		
		## Display a message at the end of the install
		If ($EndDialog -ieq 'Yes') {
			Show-InstallationPrompt -Message 'Installation has completed successfully.' -ButtonRightText 'OK' -Icon Information -NoWait
		}
		
	}
	ElseIf ($deploymentType -ieq 'Uninstall')
	{
		##*===============================================
		##* PRE-UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Pre-Uninstallation'
		
		If ($appList -ne [string]::Empty) {
			If (($DisableInteraction -eq $true) -or (-not $usersLoggedOn)) {
				Show-InstallationWelcome -CloseApps $appList -Silent
			}
			ElseIf ($DeployMode -eq 'Interactive') {
				If ($AllowCancel -ieq 'Yes' -and $ForceClose -ieq 'Yes') {
					Show-InstallationWelcome -CloseApps $appList -PersistPrompt -AllowDeferCloseApps -DeferTimes 3 -ForceCloseAppsCountdown $ScriptTimeout
				}
				ElseIf ($AllowCancel -ieq 'Yes' -and $ForceClose -ieq 'No') {
					Show-InstallationWelcome -CloseApps $appList -PersistPrompt -AllowDeferCloseApps -DeferTimes 3 -ForceCountdown $ScriptTimeout
				}
				ElseIf ($AllowCancel -ieq 'No' -and $ForceClose -ieq 'Yes') {
					Show-InstallationWelcome -CloseApps $appList -PersistPrompt -ForceCloseAppsCountdown $ScriptTimeout
				}
				ElseIf ($AllowCancel -ieq 'No' -and $ForceClose -ieq 'No') {
					Show-InstallationWelcome -CloseApps $appList -PersistPrompt -ForceCountdown $ScriptTimeout
				}
			}
			Else {
				try {
					Remove-Folder -Path "$envWinDir\PSADT"
					Copy-File -Path "$dirSupportFiles\User-Level" -Destination "$envWinDir\PSADT" -Recurse
					Copy-File -Path "$scriptRoot\Banner.png" -Destination "$envWinDir\PSADT\User-Level\AppDeployToolkit"
					Copy-File -Path "$scriptRoot\Icon.ico" -Destination "$envWinDir\PSADT\User-Level\AppDeployToolkit"
					$exitCode = Execute-ProcessAsUser -Path "$envWinDir\PSADT\User-Level\Deploy-Application.exe" -Parameters "-DeploymentType Uninstall -DeployMode Interactive -Applist '$appList' -ScriptTimeout $ScriptTimeout -InstallTitle '$installTitle' -AllowCancel '$AllowCancel' -ForceClose '$ForceClose'" -Wait -PassThru
					Remove-Folder -Path "$envWinDir\PSADT"
					If ($exitCode -ne 0) {
						Exit-Script -ExitCode $exitCode
					}
				}
				catch {}
			}
		}
		
		## Show Progress Message (with the default message)
		If ($ShowProgress -ieq 'Yes') {
			Show-InstallationProgress
		}
		
		##*===============================================
		##* UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Uninstallation'
		
		& $SB_Uninstall	
		
		##*===============================================
		##* POST-UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Uninstallation'
		
		## Display a message at the end of the uninstall
		If ($EndDialog -ieq 'Yes') {
			Show-InstallationPrompt -Message 'Uninstallation has completed successfully.' -ButtonRightText 'OK' -Icon Information -NoWait
		}
		
	}
	
	##*===============================================
	##* END SCRIPT BODY
	##*===============================================
	
	## Call the Exit-Script function to perform final cleanup operations
	Exit-Script -ExitCode $mainExitCode
}
Catch {
	[int32]$mainExitCode = 60001
	[string]$mainErrorMessage = "$(Resolve-Error)"
	Write-Log -Message $mainErrorMessage -Severity 3 -Source $deployAppScriptFriendlyName
	Show-DialogBox -Text $mainErrorMessage -Icon 'Stop'
	Exit-Script -ExitCode $mainExitCode
}
