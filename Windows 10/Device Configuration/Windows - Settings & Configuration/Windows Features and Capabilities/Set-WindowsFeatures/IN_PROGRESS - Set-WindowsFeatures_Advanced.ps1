#Requires -RunAsAdministrator

# Variables - Change these according to your preference
[string[]] $WindowsOptionalFeatures_Add = @()
[string[]] $WindowsOptionalFeatures_Rem = @('*smb1*')
[string[]] $WindowsCapabilities_Add     = @('NetFx3~~~~')
[string[]] $WindowsCapabilities_Rem     = @()


#region    Main
    #region     Windows Optional Features
        # All available Windows Optional Features
        $WindowsOptionalFeatures_All = @(Get-WindowsOptionalFeature -Online | Select-Object *)
    
        # Add Windows Optional Features
        if ($WindowsOptionalFeatures_Add.Count -gt 0) {
            foreach ($Feature in $WindowsOptionalFeatures_Add) {
                $ExactFeature = $WindowsOptionalFeatures_All | Where-Object {$_.Name -like $Feature}
                if ($ExactFeature -and $ExactFeature.State -eq 'Disabled') {
                    $null = Enable-WindowsOptionalFEature -Online -FeatureName $ExactFeature.Name -Norestart -LogLevel 1 2>&1
                }
            }
        }

        # Remove Windows Optional Features
        if ($WindowsOptionalFeatures_Rem.Count -gt 0) {
            foreach ($Feature in $WindowsOptionalFeatures_Rem) {
                $ExactFeature = $WindowsOptionalFeatures_All | Where-Object {$_.Name -like $Feature}
                if ($ExactFeature -and $ExactFeature.State -eq 'Enabled') {
                    $null = Disable-WindowsOptionalFeature -Online -FeatureName $ExactFeature.Name -Norestart -LogLevel 1 2>&1
                }
            }
        }
    #endregion Windows Optional Feature



    #region    Windows Capabilities
        # All available Windows Capabilities
        $WindowsCapabilities_All     = @(Get-WindowsCapability -Online | Select-Object *) 
        if ($WindowsCapabilities_Add.Count -gt 0) {
        }

        if ($WindowsCapabilities_Rem.Count -gt 0) {
        }
    #endregion Windows Capabilities
#endregion Main












# Disable features if enabled
Get-WindowsOptionalFeature -Online -FeatureName * | Where-Object State -eq 'Enabled'

# Add features if not enabled
Get-WindowsCapability -Online -Name 'NetFx3~~~~' | ForEach-Object {If($_.State -ne 'Installed'){Add-WindowsCapability –Online -Name $_.Name}}