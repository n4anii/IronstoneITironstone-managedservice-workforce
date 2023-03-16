<#

.SYNOPSIS
    Installs a PowerShell script that runs every three hour to make sure Lenovo Software is properly configured, and that Lenovo Auto Updates are enabled.


.DESCRIPTION
    Installs a PowerShell script that runs every three hour to make sure Lenovo Software is properly configured, and that Lenovo Auto Updates are enabled.
    * Will do this ONLY if computer manufacturer -eq Lenovo


.NOTES
    * In Intune, remember to set "Run this script using the logged in credentials"  according to the $DeviceContext variable.
        * Intune -> Device Configuration -> PowerShell Scripts -> $NameScriptFull -> Properties -> "Run this script using the logged in credentials"
        * DEVICE (Local System) or USER (Logged in user).
    * Only edit $NameScript and add your code in the #region Your Code Here.
    * You might want to touch "Settings - PowerShell - Output Preferences" for testing / development. 
        * $VerbosePreference, eventually $DebugPreference, to 'Continue' will print much more details.

#>


# Script Variables
[bool]   $DeviceContext = $true
[string] $NameScript    = 'Install-LenovoConfig(EnableUpdates)'

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
[string] $StrIsAdmin       = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
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


# Only continue if a Lenovo Computer
[string] $NameManufacturerTarget = 'Lenovo'
if ((Get-ItemProperty -Path 'HKLM:\HARDWARE\DESCRIPTION\System\BIOS' -Name 'SystemManufacturer' | Select-Object -ExpandProperty 'SystemManufacturer') -notlike $NameManufacturerTarget) {
    Write-Output -InputObject ('This is not a {0} computer. Skipping.' -f ($NameManufacturerTarget))
}
else {
    Write-Output -InputObject ('This is a {0} computer. Will continue.' -f ($NameManufacturerTarget))



#region    Script File to Install
[string] $PathDirPS1ToInstall  = ('{0}\IronstoneIT\{1}' -f ($env:ProgramW6432,$NameScriptNoun))
[string] $NameFilePS1ToInstall = 'Configure-Lenovo&EnableAutoUpdates.ps1'
[string] $PathFilePS1ToInstall = ('{0}\{1}' -f ($PathDirPS1ToInstall,$NameFilePS1ToInstall))
[System.Management.Automation.ScriptBlock] $ContentFilePS1ToInstall = {
#region    Generic Initialization
    #region    Settings
        [bool] $ResetCurrentSettings = $false
    #endregion Settings



    # Only continue if Computer Manufacturer is LENOVO
    if ((Get-ItemProperty -Path 'HKLM:\HARDWARE\DESCRIPTION\System\BIOS' -Name 'SystemManufacturer' | Select-Object -ExpandProperty 'SystemManufacturer') -notlike 'lenovo') {
        Write-Output -InputObject ('This is not a Lenovo Computer. Skipping.')
    }
    else {
        Write-Output -InputObject ('This is a Lenovo Computer. Will continue.')


        #region    Action & Variables
            # Variables HKLM
                # Lenovo ImController
                [string] $PathDirRegImController                      = ('HKLM:\SOFTWARE\{0}Policies\Lenovo\ImController' -f ($(if([System.Environment]::Is64BitOperatingSystem){'Wow6432Node\'})))
                [string] $PathDirRegImControllerAccount               = ('{0}\Plugins\LenovoAccountPlugin' -f ($PathDirRegImController))
                [string] $PathDirRegImControllerSystemUpdate          = ('{0}\Plugins\LenovoSystemUpdatePlugin' -f ($PathDirRegImController))
                [string] $PathDirRegImControllerWiFi                  = ('{0}\Plugins\LenovoWiFiSecurityPlugin' -f ($PathDirRegImController))
                # Lenovo System Update
                [string] $PathDirRegSystemUpdate                      = ('HKLM:\SOFTWARE\{0}Lenovo\System Update' -f ($(if([System.Environment]::Is64BitOperatingSystem){'Wow6432Node\'})))
                [string] $PathDirRegSystemUpdateUserSettings          = ('{0}\Preferences\UserSettings' -f ($PathDirRegSystemUpdate))
                [string] $PathDirRegSystemUpdateUserSettingsGeneral   = ('{0}\General' -f ($PathDirRegSystemUpdateUserSettings))
                [string] $PathDirRegSystemUpdateUserSettingsScheduler = ('{0}\Scheduler' -f ($PathDirRegSystemUpdateUserSettings))
                # Lenovo Vantage
                [string] $PathDirRegVantage                           = ('HKLM:\SOFTWARE\{0}Policies\Lenovo\E046963F.LenovoCompanion_k1h2ywk1493x8' -f ($(if([System.Environment]::Is64BitOperatingSystem){'Wow6432Node\'})))
                [string] $PathDirRegVantageMsg                        = ('{0}\Messaging' -f ($PathDirRegVantage))
                # Lenovo WiFi Security
                [string] $PathDirRegWiFiSec                           = ('HKLM:\SOFTWARE\{0}Policies\Lenovo\LenovoWiFiSecurityPlugin' -f ($(if([System.Environment]::Is64BitOperatingSystem){'Wow6432Node\'})))
        #endregion Action & Variables



        #region    Create Paths if not exist, Reset current settings if $ResetCurrentSettings -eq $true      
            foreach ($Path in @(Get-Variable -Name 'PathDirReg*' | Select-Object -ExpandProperty 'Name' | Sort-Object)){
                if ($ResetCurrentSettings -and (Test-Path -Path $Path)) {
                    # Remove
                    $null = Remove-Item -Path $Path -Recurse -Force
                }
                # Create empty dir
                if (-not(Test-Path -Path $Path)) {
                    $null = New-Item -Path $Path -ItemType 'Directory' -Force
                }
            }
        #endregion Create Paths if not exist, Reset current settings if $ResetCurrentSettings -eq $true
#endregion Generic Initialization




#region    Generic Settings
    #region    ImController and Vantage Settings - Generic
        # Lenovo - Vantage - GUI - Section - System Health and Support
            Write-Output -InputObject ('Lenovo - Vantage - GUI - Section - System Health and Support')
            #$null = Set-ItemProperty -Path $PathDirRegVantage -Name 'A191BF9F-60BE-4843-B4BA-441DD0AEB12E' -Value 0 -Type 'DWord' -Force                                       # Warrenty & Services 
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name 'D65D67BF-8916-4928-9B07-35E3A9A0EDC3' -Value 0 -Type 'DWord' -Force                                       # Discussion Forum
            #$null = Set-ItemProperty -Path $PathDirRegVantage -Name 'CCCD4009-AAE7-4014-8F5D-5AEC2585F503' -Value 0 -Type 'DWord' -Force                                       # Hardware Scan
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name '6674459E-60E2-49DE-A791-510247897877' -Value 0 -Type 'DWord' -Force                                       # Knowledge Base
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name 'bc690b89-77aa-4cc9-b217-73573202b94e' -Value 0 -Type 'DWord' -Force                                       # Tips & Tricks                 
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name '18E12FC0-EACB-43CB-8231-87D9C09EE0DF' -Value 0 -Type 'DWord' -Force                                       # User Guide



        # Lenovo - Vantage - GUI - Section - Apps and Offers
            Write-Output -InputObject ('Lenovo - Vantage - GUI - Section - Apps and Offers')
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name '08EC2D60-1A14-4B27-AF71-FB62D301D236' -Value 0 -Type 'DWord' -Force                                       # Accessories
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name '0E101F47-9A6F-4915-8C5F-E577D3184E5D' -Value 0 -Type 'DWord' -Force                                       # Offers & Deals
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name '8A6263C0-490C-4AE6-9456-8BBD81379787' -Value 0 -Type 'DWord' -Force                                       # Rewards
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name 'CD120116-1DE7-4BA2-905B-1149BB7A12E7' -Value 0 -Type 'DWord' -Force                                       # Apps For You (Entire Feature)
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name 'CD120116-1DE7-4BA2-905B-1149BB7A12E7_UserDefaultPreference' -Value 0 -Type 'DWord' -Force                 # Apps For You (User Default Preference)
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name '41A76A93-E02F-4703-862F-5187D84E7D90' -Value 0 -Type 'DWord' -Force                                       # Apps For You (Drop Box)
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name 'ECD16265-0AE8-429E-BC0A-E62BADFE3708' -Value 0 -Type 'DWord' -Force                                       # Apps For You (Connect2)



        # Lenovo - Vantage - GUI - Section - Hardware Settings
            Write-Output -InputObject ('Lenovo - Vantage - GUI - Section - Hardware Settings')
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name '10DF05AE-BA16-4808-A436-A40A925F6EF6' -Value 0 -Type 'DWord' -Force                                       # HubPage/ Recommended Settings



        # Lenovo - Vantage - Messaging Settings
            Write-Output -InputObject ('Lenovo - Vantage - Messaging Settings')
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name '6BBE64B3-0E60-4C88-B901-4EF86BC01031' -Value 0 -Type 'DWord' -Force                                       # Vantage - App Features
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name 'B187E8D5-D2AB-4A8B-B27E-2AF878017008' -Value 0 -Type 'DWord' -Force                                       # Vantage - Marketing
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name 'EB3D3705-FA1F-4833-A88D-2F49A2968A1A' -Value 0 -Type 'DWord' -Force                                       # Vantage - Action Triggered
            $null = Set-ItemProperty -Path $PathDirRegVantageMsg -Name 'Marketing' -Value 1 -Type 'DWord' -Force                                                               # Vantage - Messaging - Marketing
            $null = Set-ItemProperty -Path $PathDirRegVantageMsg -Name 'AppFeatures' -Value 1 -Type 'DWord' -Force                                                             # Vantage - Messaging - App Features



        # Lenovo - Vantage - Launch Page and Preferences
            Write-Output -InputObject ('Lenovo - Vantage - Launch Page and Preferences')
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name '2210FAAF-933B-4985-BC86-7E5C47EB2465' -Value 0 -Type 'DWord' -Force                                       # Lenovo ID Welcome Page
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name '2885591F-F5A8-477A-9744-D1B9F30B5B79' -Value 0 -Type 'DWord' -Force                                       # Preferences & WiFi Security | Hide Vantage preferences GUI
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name '349B8C6E-6AE4-4FF3-B8A0-25D398E75AAE' -Value 0 -Type 'DWord' -Force                                       # Device Refresh
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name '369C3066-08A0-415A-838C-9C56C5FBF5C4' -Value 0 -Type 'DWord' -Force                                       # Welcome Page at first run   | Disable Vantage "Welcome" screen at first run
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name '9023E851-DE40-42C4-8175-1AE5953DE624' -Value 0 -Type 'DWord' -Force                                       # User Feedback               | Hide Vantage feedback GUI
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name 'AE37F328-7A7B-4E2F-BE67-A5BBBC0F444A' -Value 0 -Type 'DWord' -Force                                       # Vantage Toolbar
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name 'AE37F328-7A7B-4E2F-BE67-A5BBBC0F444A_UserDefaultPreference' -Value 0 -Type 'DWord' -Force                 # Vantage Toolbar Default Preferences
            
            

        # Lenovo - ImController and Vantage - Account Plugin / ID - Disable
            Write-Output -InputObject ('ImController and Vantage - Account Plugin / ID - Disable')
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name 'E0DF659E-02A6-417C-8B39-DB116529BFDD' -Value 0 -Type 'DWord' -Force                                       # Hide Vantage GUI features related to Lenovo ID
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name '2210FAAF-933B-4985-BC86-7E5C47EB2465' -Value 0 -Type 'DWord' -Force                                       # Hide Vantage GUI features related to Lenovo ID
            $null = Set-ItemProperty -Path $PathDirRegImControllerAccount -Name 'Imc-Block' -Value 1 -Type 'DWord' -Force                                                      # Disable the Lenovo ID plugin of LSIF (Lenovo System Interface Foundation)



        # Lenovo - ImController and Vantage - Data Collection / Privacy - Disable
            Write-Output -InputObject ('ImController and Vantage - Data Collection / Privacy - Disable')
            $null = Set-ItemProperty -Path $PathDirRegImController -Name 'DisableSystemInterfaceUsageStats' -Value 1 -Type 'DWord' -Force                                      # Disable collecting anonymous usage data in LSIF (Lenovo System Interface Foundation)
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name '41A76A93-E02F-4703-862F-5187D84E7D90_Help' -Value 0 -Type 'DWord' -Force                                  # Location Tracking
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name '422FDE50-51D5-4A5B-9A44-7B19BCD03A29' -Value 0 -Type 'DWord' -Force                                       # Anonymous Usage Statistics (Entire Feature)
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name '422FDE50-51D5-4A5B-9A44-7B19BCD03A29_UserConfigurable' -Value 0 -Type 'DWord' -Force                      # Anonymous Usage Statistics (Allow User Configuration)
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name '422FDE50-51D5-4A5B-9A44-7B19BCD03A29_UserDefaultPreference' -Value 0 -Type 'DWord' -Force                 # Anonymous Usage Statistics (User Default Preference)



        # Lenovo - ImController and Vantage - WiFi Security Plugin - Disable
            Write-Output -InputObject ('ImController and Vantage - WiFi Security Plugin - Disable')
            $null = Set-ItemProperty -Path $PathDirRegWiFiSec -Name 'DisableAll' -Value 1 -Type 'DWord' -Force                                                                 # Disable Lenovo WiFi Security Plugin
            $null = Set-ItemProperty -Path $PathDirRegImControllerWiFi -Name 'Imc-Block' -Value 1 -Type 'DWord' -Force                                                         # Disable Lenovo WiFi Security Plugin in ImController
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name '2885591F-F5A8-477A-9744-D1B9F30B5B79' -Value 0 -Type 'DWord' -Force                                       # Disable Lenovo WiFi Security Plugin in Vantage
    #endregion ImController and Vantage Settings - Generic

    
    #region    Lenovo System Update Settings - Generic
        # Lenovo - System Update - General Settings
            Write-Output -InputObject ('Lenovo - System Update - General Settings')
            $null = Set-ItemProperty -Path $PathDirRegSystemUpdate -Name 'DefaultLanguage' -Value 'EN' -Type 'String' -Force                                                   # Default Language
            $null = Set-ItemProperty -Path $PathDirRegSystemUpdate -Name 'LanguageOverride' -Value 'EN' -Type 'String' -Force                                                  # Override Language
            $null = Set-ItemProperty -Path $PathDirRegSystemUpdateUserSettingsGeneral -Name 'AskBeforeClosing' -Value 'NO' -Type 'String' -Force                               # Ask when closing System Update            YES or NO
            $null = Set-ItemProperty -Path $PathDirRegSystemUpdateUserSettingsGeneral -Name 'EULAAccepted' -Value 'true' -Type 'String' -Force                                 # Hide EULA?                                true or false
            $null = Set-ItemProperty -Path $PathDirRegSystemUpdateUserSettingsGeneral -Name 'DisplayLicenseNotice' -Value 'NO' -Type 'String' -Force                           # Display License Notice?                   YES or NO
            $null = Set-ItemProperty -Path $PathDirRegSystemUpdateUserSettingsGeneral -Name 'DisplayLicenseNoticeSU' -Value 'NO' -Type 'String' -Force                         # Display License Notice SU?                YES or NO
            $null = Set-ItemProperty -Path $PathDirRegSystemUpdateUserSettingsGeneral -Name 'IgnoreLocalLicense' -Value 'YES' -Type 'String' -Force                            # Ignore Local License?                     YES or NO
            $null = Set-ItemProperty -Path $PathDirRegSystemUpdateUserSettingsGeneral -Name 'IgnoreRMLicCRCSize' -Value 'YES' -Type 'String' -Force                            # Ignore RMLicebse CRC Size?                YES or NO
    #endregion Lenovo System Update Settings - Generic
#endregion Generic Settings




#region    Special Settings
    #region    Lenovo System Update Settings - Enable
        # Lenovo - System Update - Enable Auto Updates
            Write-Output -InputObject ('Lenovo - System Update - Enable Auto Updates')
            $null = Set-ItemProperty -Path $PathDirRegSystemUpdateUserSettingsScheduler -Name 'Frequency' -Value 'WEEKLY' -Type 'String' -Force                                # How often to check for updates.           WEEKLY or MONTHLY
            $null = Set-ItemProperty -Path $PathDirRegSystemUpdateUserSettingsScheduler -Name 'NotifyOptions' -Value 'DOWNLOADANDINSTALL -INCLUDEREBOOT' -Type 'String' -Force # How to notify the user.                   DOWNLOADANDINSTALL, DOWNLOAD, NOTIFY or DOWNLOADANDINSTALL -INCLUDEREBOOT
            $null = Set-ItemProperty -Path $PathDirRegSystemUpdateUserSettingsScheduler -Name 'RunAt' -Value '14' -Type 'String' -Force                                        # What time of day to run.                  Any number from 0 to 23. You can also format the time as HH:MM:SS
            $null = Set-ItemProperty -Path $PathDirRegSystemUpdateUserSettingsScheduler -Name 'RunOn' -Value 'MONDAY' -Type 'String' -Force                                    # When to run it.                           If you chose MONTHLY, the values are 1 to 28. For WEEKLY use SUNDAY, MONDAY, etc.
            $null = Set-ItemProperty -Path $PathDirRegSystemUpdateUserSettingsScheduler -Name 'SchedulerAbility' -Value 'YES' -Type 'String' -Force                            # Enable scheduled check for System Updates YES or NO
            $null = Set-ItemProperty -Path $PathDirRegSystemUpdateUserSettingsScheduler -Name 'SchedulerLock' -Value 'LOCK' -Type 'String' -Force                              # Show/ hide/ disable/ lock GUI settings    SHOW, HIDE, DISABLE or LOCK
            $null = Set-ItemProperty -Path $PathDirRegSystemUpdateUserSettingsScheduler -Name 'SchedulerSettingChangedByUser' -Value 'NO' -Type 'String' -Force                # Did user change these settings?           YES or NO             
            $null = Set-ItemProperty -Path $PathDirRegSystemUpdateUserSettingsScheduler -Name 'SearchMode' -Value 'ALL' -Type 'String' -Force                                  # What types of updates to look for         CRITICAL, RECOMMENDED or ALL
            $null = Set-ItemProperty -Path $PathDirRegSystemUpdateUserSettingsGeneral -Name 'AdminCommandLine' -Value '/CM -search A -action INSTALL -includerebootpackages 1,3,4 -noicon -noreboot -nolicense -defaultupdate'
            $null = Set-ItemProperty -Path $PathDirRegSystemUpdateUserSettingsGeneral -Name 'LaunchMode' -Value 'auto' -Type 'String' -Force                                   # How to launch LSU                         manual or auto
            $null = Set-ItemProperty -Path $PathDirRegImControllerSystemUpdate -Name 'Imc-Block' -Value 0 -Type 'DWord' -Force                                                 # Enable the System Update plugin of LSIF (Lenovo System Interface Foundation)
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name 'E40B12CE-C5DD-4571-BBC6-7EA5879A8472' -Value 1 -Type 'DWord' -Force                                       # Show the System Update feature in the Vantage GUI


        # Lenovo - ImController and Vantage - System Update Plugin - Enable
            Write-Output -InputObject ('Lenovo - ImController and Vantage - System Update Plugin - Enable')
            $null = Set-ItemProperty -Path $PathDirRegImControllerSystemUpdate -Name 'Imc-Block' -Value 0 -Type 'DWord' -Force                                                 # Disable (1) or Enable (0) the System Update plugin of LSIF (Lenovo System Interface Foundation)
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name 'E40B12CE-C5DD-4571-BBC6-7EA5879A8472' -Value 1 -Type 'DWord' -Force                                       # Hide (0) or Show (1) the System Update feature in the Vantage GUI
    #endregion Lenovo System Update Settings - Enable
#endregion Special Settings
}
}
#endregion Script File to Install



#region    Clean up previous installs
    # Install Directory
    Get-ChildItem -Path ('{0}\IronstoneIT' -f ($env:ProgramW6432)) -Directory | Select-Object -ExpandProperty 'FullName' | Where-Object {$_ -like '*LenovoConfig*'} | ForEach-Object{Remove-Item -Path $_ -Recurse -Force}
    # Scheduled Task
    Get-ScheduledTask | Where-Object {$_.TaskName -like '*LenovoConfig*' -and $_.Author -eq 'Ironstone'} | Unregister-ScheduledTask -Confirm:$false
#endregion Clean up previous installs



#region    Install Script File
if(-not(Test-Path -Path $PathDirPS1ToInstall)){$null = New-Item -Path $PathDirPS1ToInstall -ItemType 'Directory' -Force}
Out-File -FilePath $PathFilePS1ToInstall -InputObject $ContentFilePS1ToInstall.ToString() -Encoding 'utf8' -Force
#endregion Install Script File



#region    Scheduled Task  
    # Create Scheduled Task, run it if success
    [string] $NameScheduledTask  = ('Run-{0}' -f ($NameScriptNoun))
    [string] $PathFilePowerShell = '%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe' # Works regardless of 64bit vs 32bit
    [string] $PathFilePS1        = $PathFilePS1ToInstall

    #region    Create Scheduled Task running PS1 using PowerShell.exe     
        # If PowerShell.exe and the PS1 file exist
        $ScheduledTask = New-ScheduledTask                                                    `
            -Action    (New-ScheduledTaskAction -Execute ('"{0}"' -f ($PathFilePowerShell)) -Argument ('-ExecutionPolicy Bypass -NoLogo -NonInteractive -NoProfile -WindowStyle Hidden -File "{0}"' -f ($PathFilePS1))) `
            -Principal (New-ScheduledTaskPrincipal 'NT AUTHORITY\SYSTEM' -RunLevel 'Highest')                                                                                                                           `
            -Trigger   (New-ScheduledTaskTrigger -Once -At ([DateTime]::Today.AddHours(12)) -RepetitionInterval ([TimeSpan]::FromHours(3)))                                                                             `
            -Settings  (New-ScheduledTaskSettingsSet -Hidden -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit ([TimeSpan]::FromMinutes(10)) -Compatibility 4 -StartWhenAvailable)
        $ScheduledTask.Author      = 'Ironstone'
        $ScheduledTask.Description = ('Runs a PowerShell script.{0} "{1}" -ExecutionPolicy Bypass -NoLogo -NonInteractive -NoProfile -WindowStyle Hidden -File "{2}".' -f ("`r`n",$PathFilePowerShell,$PathFilePS1))
        $null = Register-ScheduledTask -TaskName $NameScheduledTask -InputObject $ScheduledTask -Force -Verbose:$false -Debug:$false
        if ($?) {$null = Start-ScheduledTask -TaskName $NameScheduledTask}
    #endregion Create Scheduled Task running PS1 using PowerShell.exe
#endregion Scheduled Task
}


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