#Requires -RunAsAdministrator



#region    Settings
    $VerbosePreference = 'Continue'
#endregion Settings



#region    Registry Values
    [string[]] $Paths = @(
        'HKLM:\SOFTWARE\Policies\Microsoft\Communicator',            # Microsoft Lync 2010 & Office Communicator 2007 R2 
        'HKLM:\SOFTWARE\Policies\Microsoft\Office\15.0\Lync',        # Skype for Business 2013 & 2015
        'HKLM:\SOFTWARE\Policies\Microsoft\Office\16.0\Lync'         # Skype for Business 2016
    )
    [string[]] $Names = @(
        'EnableAppearOffline',                                       # Enable to set status "Appear Offline". 0 = Disable | 1 = Enable
        'DisableServerCheck'                                         # Disables check server for settings.    0 = Enable  | 1 = Disable
    )
    [byte]     $Value = 0
    [string]   $Type  = 'DWord'
#endregion Registry Values



#region    Set Registry Values
    foreach ($Path in $Paths) {
        foreach ($Name in $Names) {
            Write-Output -InputObject ('Path: "{0}".' -f ($Path))
        
            # Check that $Path is valid
            if($Path -notlike 'HK*:\*' -or $Path -like '*:*:*' -or $Path -like '*\\*'){
                Throw 'Not a valid path! Will not continue'
            }

            # Check if $Path exist, create it if not
            if (-not(Test-Path -Path $Path)){
                Write-Verbose -Message ('Path does not exist. Creating it.')
                $null = New-Item -Path $Path -ItemType 'Directory' -Force
                if ($? -and (Test-Path -Path $Paths)) {Write-Verbose -Message ('Successfully created the path.')}
                else {Throw ('Could not create path. Cannot continue.')}
            }
        
            # Set Value / ItemPropery
            Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force
            Write-Output -InputObject ('   Name: "{0}" | Value: "{1}" | Type: {2} | Success? {3}' -f ($Name,$Value,$Type,$?.ToString()))
        }
    }
#endregion Set Registry Values
