#Requires -RunAsAdministrator

<#
    
Research_Configure-LenovoVantage.ps1

.SYNOPSIS

.RESOURCES
    Lenovo Think Deploy Blog - Configuring Lenovo Vantage with an MDM 
    http://thinkdeploy.blogspot.no/2018/01/configuring-lenovo-vantage-with-mdm.html

#>




#region    Action & Variables
    # Settings
        # 0 = Reset All | 10 = Set All
        [byte] $Action = 0

    # Variables HKLM
        [string] $PathDirRegVantage        = 'HKLM:\SOFTWARE\Policies\Lenovo\E046963F.LenovoCompanion_k1h2ywk1493x8'
        [string] $PathDirRegSystemUpdate   = 'HKLM:\SOFTWARE\WOW6432Node\Policies\Lenovo\ImController\Plugins\LenovoSystemUpdatePlugin'
    # Variables HKCU from System Context
        [string] $PathDirRootCU            = ('HKU:\{0}\' -f ([System.Security.Principal.NTAccount]::new((Get-Process -Name 'Explorer' -IncludeUserName).UserName).Translate([System.Security.Principal.SecurityIdentifier]).Value))
        if ((Get-PSDrive -Name 'HKU' -ErrorAction 'SilentlyContinue') -eq $null) {$null = New-PSDrive -PSProvider 'Registry' -Name 'HKU' -Root 'HKEY_USERS'}
        [string] $PathDirRegVantageCU      = $PathDirRegVantage.Replace('HKLM:\',$PathDirRootCU)
        [string] $PathDirRegSystemUpdateCU = $PathDirRegSystemUpdate.Replace('HKLM:\',$PathDirRootCU) 
#endregion Action & Variables




#region    Reset Settings   
    # Remove all settings
    if ($Action -eq 0) {
        foreach ($Path in @($PathDirRegVantage,$PathDirRegVantageCU,$PathDirRegSystemUpdate,$PathDirRegSystemUpdateCU)) {
            if (Test-Path -Path $Path) {
                $null = Remove-Item -Path $Path -Recurse -Force
                Write-Verbose -Message ('Removing "{0}". Success? {1}.' -f ($Path,$?.ToString()))
                #$null = New-Item -Path $Path -Type 'Directry' -Force
            }
        }
    }
#endregion Reset Settings




#region     Set All Settings
    if ($Action -eq 10) {        
        # Create Reg Path for Lenovo Vantage -> Messaging (Recurse, no need checking $PathDirRegVantageDirRegVantage alone)
            if (-not(Test-Path -Path ('{0}\Messaging' -f ($PathDirRegVantage)))){$null = New-Item -Path ('{0}\Messaging' -f ($PathDirRegVantage)) -ItemType 'Directory' -Force}


        # System Health and Support Section
            Write-Output -InputObject ('Configuring System Health and Support Section')
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name '6674459E-60E2-49DE-A791-510247897877' -Value 0 -Type 'DWord' -Force                        # Knowledge Base
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name 'CCCD4009-AAE7-4014-8F5D-5AEC2585F503' -Value 0 -Type 'DWord' -Force                        # Hardware Scan
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name 'D65D67BF-8916-4928-9B07-35E3A9A0EDC3' -Value 0 -Type 'DWord' -Force                        # Discussion Forum
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name 'bc690b89-77aa-4cc9-b217-73573202b94e' -Value 0 -Type 'DWord' -Force                        # Tips & Tricks


        # Apps and Offers Section
            Write-Output -InputObject ('Configuring Apps and Offers Section')
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name '08EC2D60-1A14-4B27-AF71-FB62D301D236' -Value 0 -Type 'DWord' -Force                        # Accessories
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name '0E101F47-9A6F-4915-8C5F-E577D3184E5D' -Value 0 -Type 'DWord' -Force                        # Offers & Deals
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name '8A6263C0-490C-4AE6-9456-8BBD81379787' -Value 0 -Type 'DWord' -Force                        # Rewards
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name 'CD120116-1DE7-4BA2-905B-1149BB7A12E7' -Value 0 -Type 'DWord' -Force                        # Apps For You (Entire Feature)
            #$null = Set-ItemProperty -Path $PathDirRegVantage -Name 'CD120116-1DE7-4BA2-905B-1149BB7A12E7_UserDefaultPreference' -Value 0 -Type 'DWord' -Force  # Apps For You (User Default Preference)
            #$null = Set-ItemProperty -Path $PathDirRegVantage -Name '41A76A93-E02F-4703-862F-5187D84E7D90' -Value 0 -Type 'DWord' -Force                        # Apps For You (Drop Box)
            #$null = Set-ItemProperty -Path $PathDirRegVantage -Name 'ECD16265-0AE8-429E-BC0A-E62BADFE3708' -Value 0 -Type 'DWord' -Force                        # Apps For You (Connect2)


        # Hardware Settings Section
            Write-Output -InputObject ('Configuring Hardware Settings Section')
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name '10DF05AE-BA16-4808-A436-A40A925F6EF6' -Value 0 -Type 'DWord' -Force                        # HubPage/ Recommended Settings


        # Messaging Preferences
            Write-Output -InputObject ('Configuring Messaging Preferences')
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name '6BBE64B3-0E60-4C88-B901-4EF86BC01031' -Value 0 -Type 'DWord' -Force                        # App Features
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name 'B187E8D5-D2AB-4A8B-B27E-2AF878017008' -Value 0 -Type 'DWord' -Force                        # Marketing
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name 'EB3D3705-FA1F-4833-A88D-2F49A2968A1A' -Value 0 -Type 'DWord' -Force                        # Action Triggered
            $null = Set-ItemProperty -Path ('{0}\Messaging' -f ($PathDirRegVantage)) -Name 'Marketing' -Value 1 -Type 'DWord' -Force                            # Marketing


        # Launch page and Preferences
            Write-Output -InputObject ('Setting Launch Page and Preferences')
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name '2210FAAF-933B-4985-BC86-7E5C47EB2465' -Value 0 -Type 'DWord' -Force                        # Lenovo ID Welcome Page
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name '2885591F-F5A8-477A-9744-D1B9F30B5B79' -Value 0 -Type 'DWord' -Force                        # Preferences & WiFi Security
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name '349B8C6E-6AE4-4FF3-B8A0-25D398E75AAE' -Value 0 -Type 'DWord' -Force                        # Device Refresh
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name '369C3066-08A0-415A-838C-9C56C5FBF5C4' -Value 0 -Type 'DWord' -Force                        # Welcome Page
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name '41A76A93-E02F-4703-862F-5187D84E7D90_Help' -Value 0 -Type 'DWord' -Force                   # Location Tracking
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name '422FDE50-51D5-4A5B-9A44-7B19BCD03A29' -Value 0 -Type 'DWord' -Force                        # Anonymous Usage Statistics (Entire Feature)
            #$null = Set-ItemProperty -Path $PathDirRegVantage -Name '422FDE50-51D5-4A5B-9A44-7B19BCD03A29_UserConfigurable' -Value 0 -Type 'DWord' -Force       # Anonymous Usage Statistics (Allow User Configuration)
            #$null = Set-ItemProperty -Path $PathDirRegVantage -Name '422FDE50-51D5-4A5B-9A44-7B19BCD03A29_UserDefaultPreference' -Value 0 -Type 'DWord' -Force  # Anonymous Usage Statistics (User Default Preference)
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name '9023E851-DE40-42C4-8175-1AE5953DE624' -Value 0 -Type 'DWord' -Force                        # User Feedback
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name 'AE37F328-7A7B-4E2F-BE67-A5BBBC0F444A' -Value 0 -Type 'DWord' -Force                        # Vantage Toolbar
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name 'AE37F328-7A7B-4E2F-BE67-A5BBBC0F444A_UserDefaultPreference' -Value 0 -Type 'DWord' -Force  # Vantage Toolbar Default Preferences
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name 'E0DF659E-02A6-417C-8B39-DB116529BFDD' -Value 0 -Type 'DWord' -Force                        # Lenovo ID


        # Lenovo System Update
            Write-Output -InputObject ('Disabling System Update Plugin')
            if (-not(Test-Path -Path $PathDirRegSystemUpdate)) {$null = New-Item -Path $PathDirRegSystemUpdate  -ItemType 'Directory' -Force}
            $null = Set-ItemProperty -Path $PathDirRegSystemUpdate -Name 'Imc-Block' -Value 1 -Type 'DWord' -Force                                              # System Update Plugin
            $null = Set-ItemProperty -Path $PathDirRegVantage -Name 'E40B12CE-C5DD-4571-BBC6-7EA5879A8472' -Value 0 -Type 'DWord' -Force                        # System Update GUI
    }
#endregion Set All Settings