<#

.SYNOPSIS
Removes all specified pre-installed applications from the users profile.

.DESCRIPTION
Removes all specified pre-installed applications from the users profile. This script MUST be deployed together with Device_Uninstall-Bloatware.ps1, else the apps will come back.

.NOTES
You need to run this script in the USER context in Intune.

#>
$AppName = 'User_Uninstall-Bloatware'
$Timestamp = Get-Date -Format 'HHmmssffff'
$LogDirectory = ('{0}\IronstoneIT\Intune\DeviceConfiguration' -f $env:APPData)
$Transcriptname = ('{2}\{0}_{1}.txt' -f $AppName, $Timestamp, $LogDirectory)
$RegistryPath = 'HKCU:\SOFTWARE\IronstoneIT\Intune\DeviceConfiguration'
$RegistryKey = 'UserUninstallBloatware'
$ErrorActionPreference = 'Continue'

if (-not(Test-Path -Path $LogDirectory)) {
    New-Item -ItemType Directory -Path $LogDirectory -ErrorAction Stop
}

Start-Transcript -Path $Transcriptname
#Wrap in a try/catch, so we can always end the transcript
Try {
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

    if (-not(Test-Path -Path ('{0}\{1}' -f $RegistryPath, $RegistryKey))) {
        $BloatWares = @(# Microsoft
                        '*BingFinance*',
                        '*BingNews*',
                        '*BingSports*',
                        '*BingWeather*',                       
                        '*LinkedInforWindows*',
                        '*MicrosoftSolitaireCollection*',
                        '*MinecraftUWP*',
                        '*OneNote*',
                        '*SkypeApp*',
                        '*windowsphone*',
                        '*ZuneMusic*',
                        '*ZuneVideo*',
                        # Other
                        '*ActiproSoftwareLLC*',
                        '*AdobePhotoshopExpress*',
                        '*Asphalt8Airborne*',
                        '*AutodeskSketchBook*',
                        '*CandyCrushSodaSaga*',                       
                        '*DrawboardPDF*',
                        '*Duolingo-LearnLanguagesforFree*',                 
                        '*EclipseManager*',                                             
                        '*Facebook*',                        
                        '*FarmVille2CountryEscape*',
                        '*KeeperSecurityInc.Keeper*',
                        '*king.com.BubbleWitch3Sag*',
                        '*MarchofEmpires*',
                        '*Netflix*',                       
                        '*PandoraMediaInc*',
                        '*Plex*',
                        '*RoyalRevolt2*',
                        '*Twitter*'
                    )
        
        Foreach ($BloatWare in $BloatWares) {
            Write-Output -InputObject ('Removing AppxPackage [{0}].' -f $BloatWare)
            Get-AppxPackage -Name $bloatware | Remove-AppxPackage
        }

        Write-Output -InputObject ('Creating registry path {0} key {1}' -f $RegistryPath, $RegistryKey)
        $null = New-Item -Path ('{0}\{1}' -f $RegistryPath, $RegistryKey) -force
    }
    else {
        Write-Output -InputObject ('Registry {0} already set' -f $RegistryKey)
    }
}
Catch {
    # Construct Message
    $ErrorMessage = 'Unable to uninstall all AppxPackages.'
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