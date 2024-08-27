<#
.PARAMETER DeployMode
Interactive = Shows dialogs
Silent = No dialogs
NonInteractive = Very silent, i.e. no blocking apps.
NonInteractive mode is automatically set if it is detected that the process is not user interactive.

.PARAMETER AllowRebootPassThru
Allows the 3010 return code (requires restart) to be passed back to the parent process (e.g. SCCM) if detected from an installation. If 3010 is passed back to SCCM, a reboot prompt will be triggered.

.EXAMPLE
Deploy-Application.exe -DeploymentType "Install" -DeployMode "Silent"

.Make Application visible for enduser in Intune when running as System
%SystemRoot%\System32\WindowsPowerShell\v1.0\PowerShell.exe -ExecutionPolicy Bypass -NoProfile -File Invoke-ServiceUI.ps1 -DeploymentType Install -AllowRebootPassThru
#>

[CmdletBinding()]
Param (
    [Parameter(Mandatory = $false)]
    [ValidateSet('Install', 'Uninstall', 'Repair')]
    [String]$DeploymentType = 'Install',
    [Parameter(Mandatory = $false)]
    [ValidateSet('Interactive', 'Silent', 'NonInteractive')]
    [String]$DeployMode = 'Interactive',
    [Parameter(Mandatory = $false)]
    [switch]$AllowRebootPassThru = $false,
    [Parameter(Mandatory = $false)]
    [switch]$TerminalServerMode = $false,
    [Parameter(Mandatory = $false)]
    [switch]$DisableLogging = $false
)

Try {
    ## Set the script execution policy for this process
    Try {
        Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -Scope 'Process' -Force -ErrorAction 'Stop'
    } Catch {
    }

    ##*===============================================
    ##* VARIABLE DECLARATION
    ##*===============================================
    ## Variables: Application
    [String]$appVendor = ''
    [String]$appName = ''
    [String]$appVersion = ''
    [String]$appArch = ''
    [String]$appLang = 'EN'
    [String]$appRevision = '01'
    [String]$appScriptVersion = '1.0.0'
    [String]$appScriptDate = 'XX/XX/2024'
    [String]$appScriptAuthor = 'Ironstone'
    ##*===============================================
    ## Variables: Install Titles (Only set here to override defaults set by the toolkit)
    [String]$installName = ''
    [String]$installTitle = ''

    ##* Do not modify section below
    #region DoNotModify

    ## Variables: Exit Code
    [Int32]$mainExitCode = 0

    ## Variables: Script
    [String]$deployAppScriptFriendlyName = 'Deploy Application'
    [Version]$deployAppScriptVersion = [Version]'3.10.2'
    [String]$deployAppScriptDate = '08/13/2024'
    [Hashtable]$deployAppScriptParameters = $PsBoundParameters

    ## Variables: Environment
    If (Test-Path -LiteralPath 'variable:HostInvocation') {
        $InvocationInfo = $HostInvocation
    }
    Else {
        $InvocationInfo = $MyInvocation
    }
    [String]$scriptDirectory = Split-Path -Path $InvocationInfo.MyCommand.Definition -Parent

    ## Dot source the required App Deploy Toolkit Functions
    Try {
        [String]$moduleAppDeployToolkitMain = "$scriptDirectory\AppDeployToolkit\AppDeployToolkitMain.ps1"
        If (-not (Test-Path -LiteralPath $moduleAppDeployToolkitMain -PathType 'Leaf')) {
            Throw "Module does not exist at the specified location [$moduleAppDeployToolkitMain]."
        }
        If ($DisableLogging) {
            . $moduleAppDeployToolkitMain -DisableLogging
        }
        Else {
            . $moduleAppDeployToolkitMain
        }
    }
    Catch {
        If ($mainExitCode -eq 0) {
            [Int32]$mainExitCode = 60008
        }
        Write-Error -Message "Module [$moduleAppDeployToolkitMain] failed to load: `n$($_.Exception.Message)`n `n$($_.InvocationInfo.PositionMessage)" -ErrorAction 'Continue'
        ## Exit the script, returning the exit code to SCCM
        If (Test-Path -LiteralPath 'variable:HostInvocation') {
            $script:ExitCode = $mainExitCode; Exit
        }
        Else {
            Exit $mainExitCode
        }
    }

    #endregion
    ##* Do not modify section above
    ##*===============================================
    ##* END VARIABLE DECLARATION
    ##*===============================================

    Write-Log -Message "=============================================== Ironstone code starts here ===============================================" -Severity "2"

    $CloseApps = "CloseMe,CloseMeToo" #Apps that must be closed before installing application. 
    $AppsToRemove = @(
        @{
            Name = "Example_*7-Zip*" #Check Appwiz.cpl for correct name. Wildcards are supporterd.
            Type = "msi"
        },
        @{
            Path = "Example_C:\Program Files\7-Zip\Uninstall.exe" #Supports wildcards
            Parameters = "/S"
            Type = "exe"
            IgnoreExitCodes = "$false" # Add ExitCodes to ignore when uninstalling. IgnoreExitCodes = "1,2,3"
        },
        @{
            Name = "Example_E046963F.LenovoSettingsforEnterprise" # Run Get-AppxPackage | Select-Object Name, version
            Type = "AppX"
        },
        @{
            Name = "Example_Notepad++ (64-bit x64)" # Run Winget list on target machine to get ID and Name
            ID = "Example_Notepad++.Notepad++"
            Scope = "User" # User/Machine
            Type = "Winget"
        }
    )

    $Cleanups = @(
        "Example_C:\Programdata\AdobeR",
        "Example_HKLM:\Software\Adobe\AcrobatR",
        "Example_C:\Users\*\AppData\Local\AcrobatR"
    )

    If ($deploymentType -ine 'Uninstall' -and $deploymentType -ine 'Repair') {

        ## Show Welcome Message, close apps if required, allow up to 3 deferrals, verify there is enough disk space to complete the install, and persist the prompt
        Show-InstallationWelcome -CloseApps $CloseApps -AllowDefer -DeferTimes 3 -CheckDiskSpace -PersistPrompt

        ## Comment out Uninstall-Apps/Remove-Leftovers function if uninstalling is required before installation of new version
        # Uninstall-Apps -AppsToRemove $AppsToRemove
        # Remove-Leftovers -Cleanups $Cleanups

        ## Show Progress Message (with the default message)
        Show-InstallationProgress

        ## <Perform Installation tasks here>

        ## Display a message at the end of the install
        Show-InstallationPrompt -Message "Installation of $appName was successful!." -ButtonRightText 'OK' -Icon Information -NoWait
    }
    ElseIf ($deploymentType -ieq 'Uninstall') {

        ## Show Welcome Message, close apps with a 60 second countdown before automatically closing
        Show-InstallationWelcome -CloseApps $CloseApps -CloseAppsCountdown 60

        ## <Perform Uninstal tasks here>
        # Uninstall-Apps -AppsToRemove $AppsToRemove
        # Remove-Leftovers -Cleanups $Cleanups
    }
    ElseIf ($deploymentType -ieq 'Repair') {

        ## Show Welcome Message, close apps with a 60 second countdown before automatically closing
        Show-InstallationWelcome -CloseApps $CloseApps -CloseAppsCountdown 60

        ## Show Progress Message (with the default message)
        Show-InstallationProgress

        ## <Perform Repair tasks here>

    }
    Exit-Script -ExitCode $mainExitCode
}
Catch {
    [Int32]$mainExitCode = 60001
    [String]$mainErrorMessage = "$(Resolve-Error)"
    Write-Log -Message $mainErrorMessage -Severity 3 -Source $deployAppScriptFriendlyName
    Show-DialogBox -Text $mainErrorMessage -Icon 'Stop'
    Exit-Script -ExitCode $mainExitCode
}
