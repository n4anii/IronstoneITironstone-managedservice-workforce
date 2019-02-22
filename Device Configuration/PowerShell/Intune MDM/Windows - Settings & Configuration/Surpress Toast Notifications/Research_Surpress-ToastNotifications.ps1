#region    Toast Notifications
    #region    Assets
        $PathRoot = [string]'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings'
        $Paths    = [string[]]@(
            # UWP Apps
            [string]('{0}\E046963F.LenovoCompanion_k1h2ywk1493x8!App' -f ($PathRoot)),                                             # 00 Lenovo Vantage
            [string]('{0}\Microsoft.Windows.Cortana_cw5n1h2txyewy!CortanaUI' -f ($PathRoot)),                                      # 01 Microsoft Cortana
            [string]('{0}\Microsoft.MicrosoftEdge_8wekyb3d8bbwe!MicrosoftEdge' -f ($PathRoot)),                                    # 02 Microsoft Edge
            [string]('{0}\microsoft.windowscommunicationsapps_8wekyb3d8bbwe!microsoft.windowslive.calendar' -f ($PathRoot)),       # 03 Microsoft Mail And Calendar \ Calendar
            [string]('{0}\Microsoft.microsoft.windowscommunicationsapps_8wekyb3d' -f ($PathRoot)),                                 # 04 Microsoft Mail And Calendar \ Mail
            [string]('{0}\Microsoft.BingNews_8wekyb3d8bbwe!AppexNews' -f ($PathRoot)),                                             # 05 Microsoft News
            [string]('{0}\Microsoft.Windows.Photos_8wekyb3d8bbwe!App' -f ($PathRoot)),                                             # 06 Microsoft Photos
            [string]('{0}\Microsoft.WindowsStore_8wekyb3d8bbwe!App' -f ($PathRoot)),                                               # 07 Microsoft Store        
            # Applications
            [string]('{0}\Logitech.LogiOptions' -f ($PathRoot)),                                                                   # 08 Logitech Options
            [string]('{0}\Microsoft.SkyDrive.Desktop' -f ($PathRoot)),                                                             # 09 Microsoft OneDrive
            [string]('{0}\Microsoft.Office.lync.exe.15' -f ($PathRoot)),                                                           # 10 Microsoft Skype for Business
            # Windows System
            [string]('{0}\Windows.System.AppInitiatedDownload' -f ($PathRoot)),                                                    # 11 App Initiaded Download (OneDrive Files On Demand)
            [string]('{0}\Windows.SystemToast.BackgroundAccess' -f ($PathRoot)),                                                   # 12 Battery Saver
            [string]('{0}\Windows.SystemToast.BdeUnlock' -f ($PathRoot)),                                                          # 13 BitLocker
            [string]('{0}\Windows.SystemToast.BitLockerPolicyRefresh' -f ($PathRoot)),                                             # 14 BitLocker
            [string]('{0}\Windows.SystemToast.SecurityAndMaintenance' -f ($PathRoot)),                                             # 15 Security & Maintenance
            [string]('{0}\windows.immersivecontrolpanel_cw5n1h2txyewy!microsoft.windows.immersivecontrolpanel' -f ($PathRoot)),    # 16 Settings (aka Windows Immersive Control Panel)
            [string]('{0}\Windows.SystemToast.DisplaySettings' -f ($PathRoot)),                                                    # 17 Settings \ Display Settings
            [string]('{0}\Windows.SystemToast.MobilityExperience' -f ($PathRoot)),                                                 # 18 Settings \ Mobility Experience
            [string]('{0}\Windows.SystemToast.Suggested' -f ($PathRoot)),                                                          # 19 Suggested
            [string]('{0}\Windows.SystemToast.WiFiNetworkManager' -f ($PathRoot))                                                  # 20 Wireless Notifications
        )
    #endregion Assets




    #region    Surpress a single Toast Notification
        # Using $Paths variable
        if (-not(Test-Path -Path $Paths[15])){$null = New-Item -Path $Paths[15] -ItemType 'Directory' -Force -ErrorAction 'Stop'}
        $null = Set-ItemProperty -Path $Paths[15] -Name 'Enabled' -Value 0 -Type 'DWord'
    
    
        # Full Path
        if (-not(Test-Path -Path 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.SecurityAndMaintenance')){$null = New-Item -Path 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.SecurityAndMaintenance' -ItemType 'Directory' -Force -ErrorAction 'Stop'} 
        $null = Set-ItemProperty -Path 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.SecurityAndMaintenance' -Name 'Enabled' -Value 0 -Type 'DWord' -Force
    #endregion Surpress a single Toast Notification




    #region    Surpress All Toast Notifications in $Paths
        foreach ($Path in $Paths) {
            if (-not(Test-Path -Path $Path)) {$null = New-Item -Path $Path -ItemType 'Directory' -Force}
            $null = Set-ItemProperty -Path $Path -Name 'Enabled' -Value 1 -Type 'DWord' -Force
            Write-Verbose -Message ('   Success? {0}' -f ($?))
        }
    #endregion Set Registry Values
#endregion Toast Notifications



#region    Other Notifications
    #region    Assets
        $Path  = [string]'HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
        $Names = [string[]]@(
            # Settings \ System \ Notifications & Settings
            [string]('SubscribedContent-310093Enabled'),  # 00 Show me the Windows welcome experience after updates and occasionally when I sign in, to highlight what's new and suggested
            [string]('SubscribedContent-338389Enabled'),  # 01 Get tips, tricks and suggestions as you use Windows
            # Settings \ Privacy \ General
            [string]('SubscribedContent-353696Enabled'),  # 02 Show me suggested content in the settings app
            # Others
            [string]('SubscribedContent-353693Enabled'),  # 03 Turn Off Suggested Content in Settings
            [string]('SubscribedContent-353694Enabled'),  # 04 Turn Off Suggested Content in Settings
            [string]('SubscribedContent-338388Enabled'),  # 05 Occational Suggestions
            [string]('SystemPaneSuggestionsEnabled')      # 06 Start Menu Suggestions \ Suggestions in system pane
            # [string]('{0}\' -f ($PathRoot)),
    )
    #endregion Assets


    #region    Set a single setting
        $null = Set-ItemProperty -Path $Path -Name $Names[3] -Value 0 -Type 'DWord' -Force
    #endregion Set a single setting
#endregion Other Notifications 