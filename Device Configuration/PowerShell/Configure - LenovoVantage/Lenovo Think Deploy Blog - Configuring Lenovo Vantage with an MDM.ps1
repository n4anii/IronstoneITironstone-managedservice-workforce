# Transcript for logging
        $stampDate = Get-Date
        $vantageTempDir = "C:\Vantage\Config"
        $transcriptName = $vantageTempDir + "\VantageConfig_" + $stampDate.ToFileTimeUtc() + ".txt"
        Start-Transcript -Path $transcriptName -NoClobber

If ($ENV:PROCESSOR_ARCHITEW6432 -eq “AMD64”) {
     Try {
         &”$ENV:WINDIR\SysNative\WindowsPowershell\v1.0\PowerShell.exe” -File $PSCOMMANDPATH
     }
     Catch {
         Throw “Failed to start $PSCOMMANDPATH”
     }
     Exit
}

$path = "HKLM:\SOFTWARE\Policies\Lenovo\E046963F.LenovoCompanion_k1h2ywk1493x8"

IF(!(Test-Path $path\Messaging))

    {

        New-Item -Path $path\Messaging -Force | Out-Null

    }

# System Health and Support Section

                Write-Host "--------------------------------------------------------------------------------------"
                Write-Host "Configuring System Health and Support Section"
                Write-Host "--------------------------------------------------------------------------------------"

        New-ItemProperty -Path $path -Name 6674459E-60E2-49DE-A791-510247897877 -Value 0 -Force | Out-Null # Knowledge Base
        New-ItemProperty -Path $path -Name CCCD4009-AAE7-4014-8F5D-5AEC2585F503 -Value 0 -Force | Out-Null # Hardware Scan
        New-ItemProperty -Path $path -Name D65D67BF-8916-4928-9B07-35E3A9A0EDC3 -Value 0 -Force | Out-Null # Discussion Forum
        New-ItemProperty -Path $path -Name bc690b89-77aa-4cc9-b217-73573202b94e -Value 0 -Force | Out-Null # Tips & Tricks

# Apps and Offers Section

                Write-Host "--------------------------------------------------------------------------------------"
                Write-Host "Configuring Apps and Offers Section"
                Write-Host "--------------------------------------------------------------------------------------"

        New-ItemProperty -Path $path -Name 08EC2D60-1A14-4B27-AF71-FB62D301D236 -Value 0 -Force | Out-Null # Accessories
        New-ItemProperty -Path $path -Name 0E101F47-9A6F-4915-8C5F-E577D3184E5D -Value 0 -Force | Out-Null # Offers & Deals
        New-ItemProperty -Path $path -Name 8A6263C0-490C-4AE6-9456-8BBD81379787 -Value 0 -Force | Out-Null # Rewards
        New-ItemProperty -Path $path -Name CD120116-1DE7-4BA2-905B-1149BB7A12E7 -Value 0 -Force | Out-Null # Apps For You (Entire Feature)
        New-ItemProperty -Path $path -Name CD120116-1DE7-4BA2-905B-1149BB7A12E7_UserDefaultPreference -Value 0 -Force | Out-Null # Apps For You (User Default Preference)
        New-ItemProperty -Path $path -Name 41A76A93-E02F-4703-862F-5187D84E7D90 -Value 0 -Force | Out-Null # Apps For You/Drop Box
        New-ItemProperty -Path $path -Name ECD16265-0AE8-429E-BC0A-E62BADFE3708 -Value 0 -Force | Out-Null # Apps For You/Connect2

# Hardware Settings Section

                Write-Host "--------------------------------------------------------------------------------------"
                Write-Host "Configuring Hardware Settings Section"
                Write-Host "--------------------------------------------------------------------------------------"

        New-ItemProperty -Path $path -Name 10DF05AE-BA16-4808-A436-A40A925F6EF6 -Value 0 -Force | Out-Null # HubPage/Recommended Settings

# Messaging Preferences

                Write-Host "--------------------------------------------------------------------------------------"
                Write-Host "Configuring Messaging Preferences"
                Write-Host "--------------------------------------------------------------------------------------"

        New-ItemProperty -Path $path -Name 6BBE64B3-0E60-4C88-B901-4EF86BC01031 -Value 0 -Force | Out-Null # App Features
        New-ItemProperty -Path $path -Name B187E8D5-D2AB-4A8B-B27E-2AF878017008 -Value 0 -Force | Out-Null # Marketing
        New-ItemProperty -Path $path -Name EB3D3705-FA1F-4833-A88D-2F49A2968A1A -Value 0 -Force | Out-Null # Action Triggered
        New-ItemProperty -Path $path\Messaging -Name Marketing -Value 1 -Force | Out-Null

# Launch page and Preferences

                Write-Host "--------------------------------------------------------------------------------------"
                Write-Host "Setting Launch Page and Preferences"
                Write-Host "--------------------------------------------------------------------------------------"

        New-ItemProperty -Path $path -Name 2210FAAF-933B-4985-BC86-7E5C47EB2465 -Value 0 -Force | Out-Null # Lenovo ID Welcome Page
        New-ItemProperty -Path $path -Name 2885591F-F5A8-477A-9744-D1B9F30B5B79 -Value 0 -Force | Out-Null # Preferences & WiFi Security
        New-ItemProperty -Path $path -Name 349B8C6E-6AE4-4FF3-B8A0-25D398E75AAE -Value 0 -Force | Out-Null # Device Refresh
        New-ItemProperty -Path $path -Name 369C3066-08A0-415A-838C-9C56C5FBF5C4 -Value 0 -Force | Out-Null # Welcome Page
        New-ItemProperty -Path $path -Name 41A76A93-E02F-4703-862F-5187D84E7D90_Help -Value 0 -Force | Out-Null # Location Tracking
        New-ItemProperty -Path $path -Name 422FDE50-51D5-4A5B-9A44-7B19BCD03A29 -Value 0 -Force | Out-Null # Anonymous Usage Statistics (Entire Feature)
        New-ItemProperty -Path $path -Name 422FDE50-51D5-4A5B-9A44-7B19BCD03A29_UserConfigurable -Value 0 -Force | Out-Null # Anonymous Usage Statistics (Allow User Configuration)
        New-ItemProperty -Path $path -Name 422FDE50-51D5-4A5B-9A44-7B19BCD03A29_UserDefaultPreference -Value 0 -Force | Out-Null # Anonymous Usage Statistics (User Default Preference)
        New-ItemProperty -Path $path -Name 9023E851-DE40-42C4-8175-1AE5953DE624 -Value 0 -Force | Out-Null # User Feedback
        New-ItemProperty -Path $path -Name AE37F328-7A7B-4E2F-BE67-A5BBBC0F444A -Value 0 -Force | Out-Null # Vantage Toolbar
        New-ItemProperty -Path $path -Name AE37F328-7A7B-4E2F-BE67-A5BBBC0F444A_UserDefaultPreference -Value 0 -Force | Out-Null # Vantage Toolbar Default Preferences
        New-ItemProperty -Path $path -Name E0DF659E-02A6-417C-8B39-DB116529BFDD -Value 0 -Force | Out-Null # Lenovo ID

# System Update

                Write-Host "--------------------------------------------------------------------------------------"
                Write-Host "Disabling System Update Plugin"
                Write-Host "--------------------------------------------------------------------------------------"

$SUplugin = "HKLM:\SOFTWARE\WOW6432Node\Policies\Lenovo\ImController\Plugins\LenovoSystemUpdatePlugin"

IF(!(Test-Path $SUplugin))

    {

        New-Item -Path $SUplugin -Force | Out-Null

    }

        New-ItemProperty -Path $SUplugin -Name Imc-Block -Value 1 -Force | Out-Null # System Update Plugin
        New-ItemProperty -Path $path -Name E40B12CE-C5DD-4571-BBC6-7EA5879A8472 -Value 0 -Force | Out-Null # System Update GUI