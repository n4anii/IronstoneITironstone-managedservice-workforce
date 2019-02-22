<#

Configure-Lenovo&DisableAutoUpdates

.SYNOPSIS
    Disables most features in Lenovo Vantage, but also

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
[bool]   $DeviceContext = $true
[string] $NameScript    = 'Configure-Lenovo&DisableAutoUpdates'

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
[string] $NameScriptFull      = ('{0}_{1}' -f ($(if($DeviceContext){'Device'}Else{'User'}),$NameScript))
[string] $NameScriptVerb      = $NameScript.Split('-')[0]
[string] $NameScriptNoun      = $NameScript.Split('-')[-1]
[string] $ProcessArchitecture = $(if([System.Environment]::Is64BitProcess){'64'}Else{'32'})
[string] $OSArchitecture      = $(if([System.Environment]::Is64BitOperatingSystem){'64'}Else{'32'})

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


# Only continue if Computer Manufacturer is LENOVO
if ((Get-ItemProperty -Path 'HKLM:\HARDWARE\DESCRIPTION\System\BIOS' -Name 'SystemManufacturer' | Select-Object -ExpandProperty 'SystemManufacturer') -notlike 'lenovo') {
    Write-Output -InputObject ('This is not a Lenovo Computer. Skipping.')
}
else {
    Write-Output -InputObject ('This is a Lenovo Computer. Will continue.')

    #region    Action & Variables
        # Variables HKLM      
            [string] $PathDirRegImController             = 'HKLM:\SOFTWARE\Policies\Lenovo\ImController' 
            [string] $PathDirRegImControllerAccount      = ('{0}\Plugins\LenovoAccountPlugin' -f ($PathDirRegImController))
            [string] $PathDirRegImControllerSystemUpdate = ('{0}\Plugins\LenovoSystemUpdatePlugin' -f ($PathDirRegImController))
            [string] $PathDirRegImControllerWiFi         = ('{0}\Plugins\LenovoWiFiSecurityPlugin' -f ($PathDirRegImController))
            [string] $PathDirRegVantage                  = 'HKLM:\SOFTWARE\Policies\Lenovo\E046963F.LenovoCompanion_k1h2ywk1493x8'
            [string] $PathDirRegVantageMsg               = ('{0}\Messaging' -f ($PathDirRegVantage))
            [string] $PathDirRegWiFiSec                  = 'HKLM:\SOFTWARE\Policies\Lenovo\LenovoWiFiSecurityPlugin'
    #endregion Action & Variables




    #region    Reset current settings
        foreach ($Path in @($PathDirRegImController,$PathDirRegImControllerAccount,$PathDirRegImControllerSystemUpdate,$PathDirRegImControllerWiFi,$PathDirRegVantage,$PathDirRegVantageMsg,$PathDirRegWiFiSec)){
            if (Test-Path -Path $Path) {
                # Remove
                $null = Remove-Item -Path $Path -Recurse -Force
            }
            # Create empty dir
            $null = New-Item -Path $Path -ItemType 'Directory' -Force
        }
    #endregion Reset current settings




    #region    Set All Settings    
        # Lenovo - Vantage - GUI - Section - System Health and Support
            Write-Output -InputObject ('Lenovo - Vantage - GUI - Section - System Health and Support')
            #$null = Set-ItemProperty -Path $PathDirRegVantage -Name 'A191BF9F-60BE-4843-B4BA-441DD0AEB12E' -Value 0 -Type 'DWord' -Force                        # Warrenty & Services 
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name 'D65D67BF-8916-4928-9B07-35E3A9A0EDC3' -Value 0 -Type 'DWord' -Force                        # Discussion Forum
            #$null = Set-ItemProperty -Path $PathDirRegVantage -Name 'CCCD4009-AAE7-4014-8F5D-5AEC2585F503' -Value 0 -Type 'DWord' -Force                        # Hardware Scan
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name '6674459E-60E2-49DE-A791-510247897877' -Value 0 -Type 'DWord' -Force                        # Knowledge Base
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name 'bc690b89-77aa-4cc9-b217-73573202b94e' -Value 0 -Type 'DWord' -Force                        # Tips & Tricks                 
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name '18E12FC0-EACB-43CB-8231-87D9C09EE0DF' -Value 0 -Type 'DWord' -Force                        # User Guide



        # Lenovo - Vantage - GUI - Section - Apps and Offers
            Write-Output -InputObject ('Lenovo - Vantage - GUI - Section - Apps and Offers')
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name '08EC2D60-1A14-4B27-AF71-FB62D301D236' -Value 0 -Type 'DWord' -Force                        # Accessories
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name '0E101F47-9A6F-4915-8C5F-E577D3184E5D' -Value 0 -Type 'DWord' -Force                        # Offers & Deals
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name '8A6263C0-490C-4AE6-9456-8BBD81379787' -Value 0 -Type 'DWord' -Force                        # Rewards
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name 'CD120116-1DE7-4BA2-905B-1149BB7A12E7' -Value 0 -Type 'DWord' -Force                        # Apps For You (Entire Feature)
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name 'CD120116-1DE7-4BA2-905B-1149BB7A12E7_UserDefaultPreference' -Value 0 -Type 'DWord' -Force  # Apps For You (User Default Preference)
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name '41A76A93-E02F-4703-862F-5187D84E7D90' -Value 0 -Type 'DWord' -Force                        # Apps For You (Drop Box)
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name 'ECD16265-0AE8-429E-BC0A-E62BADFE3708' -Value 0 -Type 'DWord' -Force                        # Apps For You (Connect2)



        # Lenovo - Vantage - GUI - Section - Hardware Settings
            Write-Output -InputObject ('Lenovo - Vantage - GUI - Section - Hardware Settings')
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name '10DF05AE-BA16-4808-A436-A40A925F6EF6' -Value 0 -Type 'DWord' -Force                        # HubPage/ Recommended Settings



        # Lenovo - Vantage - Preferences - Messaging
            Write-Output -InputObject ('Lenovo - Vantage - Messaging Preferences')
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name '6BBE64B3-0E60-4C88-B901-4EF86BC01031' -Value 0 -Type 'DWord' -Force                        # Vantage - App Features
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name 'B187E8D5-D2AB-4A8B-B27E-2AF878017008' -Value 0 -Type 'DWord' -Force                        # Vantage - Marketing
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name 'EB3D3705-FA1F-4833-A88D-2F49A2968A1A' -Value 0 -Type 'DWord' -Force                        # Vantage - Action Triggered
            $null = Set-ItemProperty -Path $PathDirRegVantageMsg -Name 'Marketing' -Value 1 -Type 'DWord' -Force                                                # Vantage - Messaging - Marketing
            $null = Set-ItemProperty -Path $PathDirRegVantageMsg -Name 'AppFeatures' -Value 1 -Type 'DWord' -Force                                              # Vantage - Messaging - App Features



        # Lenovo - Vantage - Launch Page and Preferences
            Write-Output -InputObject ('Lenovo - Vantage - Launch Page and Preferences')
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name '2210FAAF-933B-4985-BC86-7E5C47EB2465' -Value 0 -Type 'DWord' -Force                        # Lenovo ID Welcome Page
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name '2885591F-F5A8-477A-9744-D1B9F30B5B79' -Value 0 -Type 'DWord' -Force                        # Preferences & WiFi Security
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name '349B8C6E-6AE4-4FF3-B8A0-25D398E75AAE' -Value 0 -Type 'DWord' -Force                        # Device Refresh
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name '369C3066-08A0-415A-838C-9C56C5FBF5C4' -Value 0 -Type 'DWord' -Force                        # Welcome Page at first run
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name '9023E851-DE40-42C4-8175-1AE5953DE624' -Value 0 -Type 'DWord' -Force                        # User Feedback
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name 'AE37F328-7A7B-4E2F-BE67-A5BBBC0F444A' -Value 0 -Type 'DWord' -Force                        # Vantage Toolbar
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name 'AE37F328-7A7B-4E2F-BE67-A5BBBC0F444A_UserDefaultPreference' -Value 0 -Type 'DWord' -Force  # Vantage Toolbar Default Preferences
            
            

        # Lenovo - Account Plugin / ID - Disable
            Write-Output -InputObject ('Lenovo - Account Plugin / ID - Disable')
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name 'E0DF659E-02A6-417C-8B39-DB116529BFDD' -Value 0 -Type 'DWord' -Force                        # Hide Vantage GUI features related to Lenovo ID
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name '2210FAAF-933B-4985-BC86-7E5C47EB2465' -Value 0 -Type 'DWord' -Force                        # Hide Vantage GUI features related to Lenovo ID
            $null = Set-ItemProperty -Path $PathDirRegImControllerAccount -Name 'Imc-Block' -Value 1 -Type 'DWord' -Force                                       # Disable the Lenovo ID plugin of LSIF (Lenovo System Interface Foundation)



        # Lenovo - Data Collection / Privacy
            Write-Output -InputObject ('Lenovo - Data Collection / Privacy')
            $null = Set-ItemProperty -Path $PathDirRegImController -Name 'DisableSystemInterfaceUsageStats' -Value 1 -Type 'DWord' -Force                       # Disable collecting anonymous usage data in LSIF (Lenovo System Interface Foundation)
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name '41A76A93-E02F-4703-862F-5187D84E7D90_Help' -Value 0 -Type 'DWord' -Force                   # Location Tracking
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name '422FDE50-51D5-4A5B-9A44-7B19BCD03A29' -Value 0 -Type 'DWord' -Force                        # Anonymous Usage Statistics (Entire Feature)
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name '422FDE50-51D5-4A5B-9A44-7B19BCD03A29_UserConfigurable' -Value 0 -Type 'DWord' -Force       # Anonymous Usage Statistics (Allow User Configuration)
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name '422FDE50-51D5-4A5B-9A44-7B19BCD03A29_UserDefaultPreference' -Value 0 -Type 'DWord' -Force  # Anonymous Usage Statistics (User Default Preference)



        # Lenovo - WiFi Security Plugin - Disable
            Write-Output -InputObject ('Lenovo - WiFi Security Plugin - Disable')
            $null = Set-ItemProperty -Path $PathDirRegWiFiSec -Name 'DisableAll' -Value 1 -Type 'DWord' -Force                                                  # Disable Lenovo WiFi Security Plugin
            $null = Set-ItemProperty -Path $PathDirRegImControllerWiFi -Name 'Imc-Block' -Value 1 -Type 'DWord' -Force                                          # Disable Lenovo WiFi Security Plugin in ImController
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name '2885591F-F5A8-477A-9744-D1B9F30B5B79' -Value 0 -Type 'DWord' -Force                        # Disable Lenovo WiFi Security Plugin in Vantage



        # Lenovo - System Update - Disable
            Write-Output -InputObject ('Lenovo - System Update - Disable')
            $null = Set-ItemProperty -Path $PathDirRegImControllerSystemUpdate -Name 'Imc-Block' -Value 1 -Type 'DWord' -Force                                   # Disable the System Update plugin of LSIF (Lenovo System Interface Foundation)
            #$null = Set-ItemProperty -Path $PathDirRegVantage -Name 'E40B12CE-C5DD-4571-BBC6-7EA5879A8472' -Value 0 -Type 'DWord' -Force                         # Hide the System Update feature in the Vantage GUI
    #endregion Set All Settings
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