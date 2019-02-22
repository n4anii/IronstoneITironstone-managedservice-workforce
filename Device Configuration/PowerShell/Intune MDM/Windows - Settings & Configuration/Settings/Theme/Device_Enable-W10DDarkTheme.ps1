#region    Set Registry Values from ANY context
function WriteTo-Registry {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject[]] $RegistryValues
    )


    #region    Make sure we have priveliges to perform these Registry Edits
        $Local:Paths    = [string[]]@($RegistryValues | Select-Object -ExpandProperty 'Path')
        $Local:IsAdmin  = [bool]([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        $Local:IsSystem = [bool](([string]([System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value)) -eq ([string]('S-1-5-18')))

        # HKLM = Need Admin Permissions
        if ((@($Local:Paths) | Where-Object {$_ -like 'HKLM:\*' -or $_ -like 'Registry::HKEY_LOCAL_MACHINE:\*'}).Count -ge 1 -and (-not($Local:IsAdmin))) {
            Throw 'ERROR: Can`t write to HKLM without Admin permissions.'
        }
    
        # HKCU & System Context = Need Admin Permissions
        if ((@($Local:Paths) | Where-Object {$_ -like 'HKCU:\*' -or $_ -like 'Registry::HKEY_CURRENT_USER\*'}).Count -ge 1) {
            if ($Local:IsSystem -and $Local:IsAdmin) {
                # HKCU from SYSTEM context, using 'Registry::HKEY_USERS'
                [string] $PathDirRootCU = ('Registry::HKEY_USERS\{0}' -f ([System.Security.Principal.NTAccount]::new(@(Get-Process -Name 'explorer' -IncludeUserName)[0].UserName).Translate([System.Security.Principal.SecurityIdentifier]).Value))
            }
            else {
                Throw 'ERROR: Can`t write to HKCU from System context without admin priveliges.'
            }
        }
    #endregion Make sure we have priveliges to perform these Registry Edits

           
    #region    Foreach Item in $RegValues
    foreach ($Item in $RegValues) {
        # Create $Path variable, switch HKCU: with HKU:
        [string] $Path = $Item.Path
        if ($Path -like 'HKCU:\*') {$Path = $Path.Replace('HKCU:\',('{0}{1}' -f ($PathDirRootCU,$(if(([string]$PathDirRootCU[-1]) -ne '\'){'\'}))))}
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
    #endregion Foreach Item in $RegValues
}
#endregion Set Registry Values from ANY context




$PathDirRegTitlebarColor = 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\DWM'
[PSCustomObject[]] $RegValues = @(
    # Black Titlebar when active, dark gray when inactive
    [PSCustomObject]@{Path=$PathDirRegTitlebarColor;Name='AccentColor';        Value='000d0d0d';Type='DWord'},
    [PSCustomObject]@{Path=$PathDirRegTitlebarColor;Name='AccentColorInactive';Value='00222222';Type='Dword'},
    # Office 365 Theme
    [PSCustomObject]@{Path='HKEY_CURRENT_USER\Software\Microsoft\Office\16.0\Common'; Name='UI Theme'; Value='4';Type='DWord'}
)


WriteTo-Registry -RegistryValues $RegValues -Verbose