#Requires -RunAsAdministrator



#region    Settings
    [bool] $UninstallUWPApp = $false
    [bool] $ForceRemoveExe  = $true
#endregion Settings



#region    HKCU from SYSTEM context, using 'Registry::HKEY_USERS'
    [string] $Script:FullNameUserCurrent = @(Get-Process -Name 'Explorer' -IncludeUserName)[0].UserName
    [string] $Script:NameUserCurrent     = $Script:FullNameUserCurrent.Split('\')[-1]
    [string] $Script:PathDirRootCU       = ('Registry::HKEY_USERS\{0}' -f ([System.Security.Principal.NTAccount]::new($Script:FullNameUserCurrent).Translate([System.Security.Principal.SecurityIdentifier]).Value))
#endregion HKCU from SYSTEM context, using 'Registry::HKEY_USERS'



#region    Variables
    [string] $NameUserCurrent             = (Get-Process -Name 'Explorer' -IncludeUserName).UserName.Split('\')[-1]
    # Variables - ProgramData
    [string] $PathDirCitrixProgramData    = ('{0}\Citrix' -f ($env:ProgramData))
    [string] $PathDirCitrixAppDataLocal   = ('{0}\Users\{1}\AppData\Local\Citrix' -f ($env:SystemDrive,$NameUserCurrent))
    # Variables - Shortcut Folders
    [string] $PathDirCitrixDesktopHKCU    = ('{0}\Users\{1}\Desktop\Citrix Apps' -f ($env:SystemDrive,$NameUserCurrent))
    [string] $PathDirCitrixStartMenuHKCU  = ('{0}\Users\{1}\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Citrix Apps' -f ($env:SystemDrive,$NameUserCurrent))
    [string] $PathDirCitrixStartMenuHKLM  = ('{0}\Microsoft\Windows\Start Menu\Programs\Citrix Apps' -f ($env:ProgramData))
    # Variables - KKEY_CLASSES_ROOT
    [string] $PathHCR                     = 'Registry::HKEY_CLASSES_ROOT'
    [string[]] $PathsCitrixHCR            = @( ('{0}\.ica' -f ($PathHCR)) + (Get-ChildItem -Path $PathHCR | Where-Object -Property 'Name' -Contains 'citrix')
    # Variables - HKEY_LOCAL_MACHINE
    [string] $PathDirRegCitrixConfigHKLM1 = ('HKLM:\SOFTWARE\Citrix')
    [string] $PathDirRegCitrixConfigHKLM2 = ('HKLM:\SOFTWARE\{0}Citrix' -f ($(if([System.Environment]::Is64BitOperatingSystem){'Wow6432Node\'})))
    # Variables - HKEY_CURRENT_USER    
    [string] $PathDirRegCitrixConfigHKCU1 = ('{0}\Software\Citrix' -f ($Script:PathDirRootCU))
    [string] $PathDirRegCitrixConfigHKCU2 = ('{0}\Software\{1}Citrix' -f ($Script:PathDirRootCU,$(if([System.Environment]::Is64BitOperatingSystem){'Wow6432Node\'})))
#endregion Variables



#region    Clean up Citrix
    # Uninstall UWP App
    if ($UninstallUWPApp) {
        $null = Get-AppxPackage -Name '*.Citrix*' -User $NameUserCurrent | Remove-AppxPackage
    }

    # Force remove EXE
    if ($ForceRemoveExe) {
        [string[]] $FileSystemPaths = @(
            ('{0}\Citrix' -f (${env:ProgramFiles(x86)})),
            ('{0}\Citrix' -f ($env:APPDATA)),
            ('{0}\ICAClient' -f ($env:APPDATA))
        )
        foreach ($Path in $FileSystemPaths) {
            $null = Remove-Item -Path $Path -Recurse -Force
        }
    }
    
    # Remove remaining directories and registry entries
    foreach ($Path in @(
        # ProgramData
        $PathDirCitrixProgramData,$PathDirCitrixAppDataLocal,
        # Shortcut Directories
        $PathDirCitrixDesktopHKCU,$PathDirCitrixStartMenuHKCU,$PathDirCitrixStartMenuHKLM,
        # Registry Directories
        $PathDirRegCitrixConfigHKLM1,$PathDirRegCitrixConfigHKLM2,$PathDirRegCitrixConfigHKCU1,$PathDirRegCitrixConfigHKCU2)
    ) {if (Test-Path -Path $Path$null){$null = Remove-Item -Path $Path -Recurse -Force}}
#endregion Clean Up Citrix