#Requires -RunAsAdministrator
<#
.NAME
Research_Configure-CitrixWorkspace.ps1

.SYNAPSIS
Generic script which configures app shortcuts for apps available through Citrix Workspace.

.DESCRIPTION
Generic script which configures app shortcuts for apps available through Citrix Workspace.
Must be run with admin privileges! Device Context in Intune.


.RESOURCES
App Shortcuts with Receiver for Windows
https://support.citrix.com/article/CTX230318
#>



#region    Settings
    # PowerShell Session Settings
    $DebugPreference                 = 'Continue'
    $VerbosePreference               = 'Continue'
    
    # Script Settings
    [bool] $UseRegistryWow6432Node   = $false
    
    # Assets
    [string] $NamePathCitrixShorcuts = 'Citrix Apps' 
#endregion Settings



#region    HKCU from SYSTEM context, using 'Registry::HKEY_USERS'
    [string] $Script:FullNameUserCurrent = @(Get-Process -Name 'Explorer' -IncludeUserName)[0].UserName
    [string] $Script:NameUserCurrent     = $Script:FullNameUserCurrent.Split('\')[-1]
    [string] $Script:PathDirRootCU       = ('Registry::HKEY_USERS\{0}' -f ([System.Security.Principal.NTAccount]::new($Script:FullNameUserCurrent).Translate([System.Security.Principal.SecurityIdentifier]).Value))
#endregion HKCU from SYSTEM context, using 'Registry::HKEY_USERS'



#region    Variables - Registry Values
    # Variables - HKEY_LOCAL_MACHINE
    [string] $PathDirRegCitrixConfigHKLM = ('HKLM:\SOFTWARE\{0}Citrix\Dazzle' -f ($(if($UseRegistryWow6432Node -and [System.Environment]::Is64BitOperatingSystem){'Wow6432Node\'})))
    [PSCustomObject[]] $RegValuesHKLM = @(
        [PSCustomObject[]]@{Path=$PathDirRegCitrixConfigHKLM;Name=[string]'DesktopDir';                             Value=$NamePathCitrixShorcuts;Type=[string]'String'},
        [PSCustomObject[]]@{Path=$PathDirRegCitrixConfigHKLM;Name=[string]'PutShortcutsOnDesktop';                  Value=[string]'true';         Type=[string]'String'},
        [PSCustomObject[]]@{Path=$PathDirRegCitrixConfigHKLM;Name=[string]'PutShortcutsInStartMenu';                Value=[string]'true';         Type=[string]'String'},
        [PSCustomObject[]]@{Path=$PathDirRegCitrixConfigHKLM;Name=[string]'StartMenuDir';                           Value=$NamePathCitrixShorcuts;Type=[string]'String'},
        [PSCustomObject[]]@{Path=$PathDirRegCitrixConfigHKLM;Name=[string]'SelfServiceMode';                        Value=[string]'true';         Type=[string]'String'},
        [PSCustomObject[]]@{Path=$PathDirRegCitrixConfigHKLM;Name=[string]'UseCategoryAsDesktopPath';               Value=[string]'true';         Type=[string]'String'},
        [PSCustomObject[]]@{Path=$PathDirRegCitrixConfigHKLM;Name=[string]'UseCategoryAsStartMenuPath';             Value=[string]'true';         Type=[string]'String'},
        [PSCustomObject[]]@{Path=$PathDirRegCitrixConfigHKLM;Name=[string]'UseDifferentPathsforStartmenuAndDesktop';Value=[string]'true';         Type=[string]'String'}
    )

    # Variables - HKEY_CURRENT_USER
    [string] $PathDirRegCitrixConfigHKCU  = ('{0}\Software\{1}Citrix\Dazzle' -f ($Script:PathDirRootCU,$(if($UseRegistryWow6432Node -and [System.Environment]::Is64BitOperatingSystem){'Wow6432Node\'})))    
    [PSCustomObject[]] $RegValuesHKCU = @(
        [PSCustomObject[]]@{Path=$PathDirRegCitrixConfigHKCU;Name=[string]'DesktopDir';                             Value=$NamePathCitrixShorcuts;Type=[string]'String'},
        [PSCustomObject[]]@{Path=$PathDirRegCitrixConfigHKCU;Name=[string]'PutShortcutsOnDesktop';                  Value=[string]'true';         Type=[string]'String'},
        [PSCustomObject[]]@{Path=$PathDirRegCitrixConfigHKCU;Name=[string]'PutShortcutsInStartMenu';                Value=[string]'true';         Type=[string]'String'},
        [PSCustomObject[]]@{Path=$PathDirRegCitrixConfigHKCU;Name=[string]'StartMenuDir';                           Value=$NamePathCitrixShorcuts;Type=[string]'String'},
        [PSCustomObject[]]@{Path=$PathDirRegCitrixConfigHKCU;Name=[string]'SelfServiceMode';                        Value=[string]'true';         Type=[string]'String'},
        [PSCustomObject[]]@{Path=$PathDirRegCitrixConfigHKCU;Name=[string]'UseCategoryAsDesktopPath';               Value=[string]'true';         Type=[string]'String'},
        [PSCustomObject[]]@{Path=$PathDirRegCitrixConfigHKCU;Name=[string]'UseCategoryAsStartMenuPath';             Value=[string]'true';         Type=[string]'String'},
        [PSCustomObject[]]@{Path=$PathDirRegCitrixConfigHKCU;Name=[string]'UseDifferentPathsforStartmenuAndDesktop';Value=[string]'true';         Type=[string]'String'}
    )
#endregion Variables - Registry Values



#region    Reg Values to Apply
    [PSCustomObject[]] $RegValues = [PSCustomObject[]]@($RegValuesHKLM + $RegValuesHKCU)
#endregion Reg Valyes to Apply



#region    Stop all running Citrix Processes
    # Stop all running Citrix Processes
    $CitrixProcesses = Get-Process | Where-Object -Property 'Description' -Like 'Citrix*'
    if (-not([string]::IsNullOrEmpty(@($CitrixProcesses)[0].Name))) {
        foreach ($Process in $CitrixProcesses) {
            Stop-Process -InputObject $Process
        }
    }
#endregion Stop all running Citrix Processes



#region    Reg Values Clean Up
    # Assets - Registry Paths and Keys
    [string[]] $Names = @('DesktopDir','PutShortcutsOnDesktop','StartMenuDir','SelfServiceMode','UseCategoryAsDesktopPath','UseCategoryAsStartMenuPath','UseDifferentPathsforStartmenuAndDesktop') 
    [string[]] $Paths = @(
        'HKLM:\SOFTWARE\Citrix\Dazzle',
        'HKLM:\SOFTWARE\WOW6432Node\Citrix\Dazzle',
        ('{0}\Software\Citrix\Dazzle' -f ($Script:PathDirRootCU)),
        ('{0}\Software\Wow6432Node\Citrix\Dazzle' -f ($Script:PathDirRootCU))
    )
    
    # Remove all settings related to shortcuts
    foreach ($Path in $Paths) {
        foreach ($Name in $Names) {
            Write-Debug -Message ('Remove-ItemProperty -Path "{0}" -Name "{1}" -Force -ErrorAction "SilentlyContinue"' -f ($Path,$Name))
            Remove-ItemProperty -Path $Path -Name $Name -Force -ErrorAction 'SilentlyContinue'
        }
    }
#endregion Reg Values Clean Up



#region    Set Registry Values from SYSTEM / DEVICE context
    foreach ($Item in $RegValues) {
        # Create $Path variable, switch HKCU: with HKU:
        [string] $Path = $Item.Path
        if ($Path -like 'HKCU:\*') {$Path = $Path.Replace('HKCU:\',('{0}{1}' -f ($Script:PathDirRootCU,$(if(([string]$Script:PathDirRootCU[-1]) -ne '\'){'\'}))))}
        $Path = $Path.Replace('\\','\')
        Write-Verbose -Message ('Path: "{0}".' -f ($Path))

        # Check if $Path is valid
        [bool] $SuccessValidPath = $true
        if ($Path -like 'HKCU:\*') {$SuccessValidPath = $false}
        elseif ($Path -like 'HKLM:\*' -or $Path -like 'HKU:\') {
            $SuccessValidPath = -not ($Path -notlike 'HK*:\*' -or $Path -like '*:*:*' -or $Path -like '*\\*' -or $Path.Split(':')[0].Length -gt 4)       
        }
        elseif ($Path -like 'Registry::HKEY_USERS\*') {
            $SuccessValidPath = [bool]($Path -notlike '*\\*')
        }
        else {$SuccessValidPath = $false}
        if (-not($SuccessValidPath)){Throw 'Not a valid path! Will not continue.'}


        # Check if $Path exist, create it if not
        if (-not(Test-Path -Path $Path)){
            $null = New-Item -Path $Path -ItemType 'Directory' -Force
            Write-Verbose -Message ('   Path did not exist. Successfully created it? {0}.' -f (([bool] $Local:SuccessCreatePath = $?).ToString()))
            if (-not($Local:SuccessCreatePath)){Continue}
        }
        
        # Set Value / ItemPropery
        Set-ItemProperty -Path $Path -Name $Item.Name -Value $Item.Value -Type $Item.Type -Force
        Write-Verbose -Message ('   Name: {0} | Value: {1} | Type: {2} | Success? {3}' -f ($Item.Name,$Item.Value,$Item.Type,$?.ToString()))
    }
#endregion Set Registry Values from SYSTEM / DEVICE context