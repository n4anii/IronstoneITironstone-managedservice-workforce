<#
    .SYNAPSIS
    Enables OneDrive for Business Known Folder Move. Generic by getting TenantId (GUID) from registry, or specify TenantId manually.

    .DESCRIPTION
    Enables OneDrive for Business Known Folder Move. Generic by getting TenantId (GUID) from registry, or specify TenantId manually.
      * TenantId is fetched from "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo\<somefolderwithlongname>\TenantId"
          * Must be AzureAD Joined


    .NOTES
    Resources
      * Microsoft Docs - Redirect and move Windows known folders to OneDrive
        https://docs.microsoft.com/en-us/onedrive/redirect-known-folders
      * Microsoft Docs - Use Group Policy to control OneDrive sync client settings - Prompt users to move Windows known folders to OneDrive
        https://docs.microsoft.com/en-us/onedrive/use-group-policy#prompt-users-to-move-windows-known-folders-to-onedrive
      * Microsoft Docs - Use Group Policy to control OneDrive sync client settings - Silently redirect Windows known folders to OneDrive
        https://docs.microsoft.com/en-us/onedrive/use-group-policy#silently-redirect-windows-known-folders-to-onedrive
      * Microsoft Docs - Find your Office 365 tenant ID
        https://docs.microsoft.com/en-us/onedrive/find-your-office-365-tenant-id

#>


#region    Research
    $ErrorActionPreference = 'Stop'
    $DebugPreference   = 'Continue'
    $VerbosePreference = 'Continue'
    $WarningPreference = 'Continue'
#endregion Research


#region    Variables
    # Non-generic
    <#[Hashtable] $TenantIds = @{
        # Ironstone
        'Ironstone'='3eaaf1d3-6f9e-40fd-b7e9-60b45e55e125'
        'Irontest' ='9c34b0e4-6072-4013-be77-4e42d35f317d'
        # Customers
        'Holta'    ='42caec1d-ecbe-4c9f-8735-4354eefb7fe3'
        'Metier'   ='4413f8ec-be2f-43c0-83de-dab13f6ea059'
    }
    [string] $TenantId       = $TenantIds.Ironstone#>
    
    
    # Generic
    [string] $TenantId   = Get-ItemProperty -Path ('Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo\{0}' -f ((Get-ChildItem -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo\' -ErrorAction 'SilentlyContinue' | Select-Object -First 1 -ExpandProperty Name).Split('\')[-1])) -Name 'TenantId' -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'TenantId'
    [string] $PathDirReg = 'HKLM:\SOFTWARE\Policies\Microsoft\OneDrive'
    
    # Registry Values - Wizard
    [array] $RegValuesWizard = @(
        [hashtable]@{Path=[string]$PathDirReg;Name=[string]'KFMOptInWithWizard';            Value=[string]$TenantId;Type=[string]'String'}     
    )
    
    # Registry Values - Silent with Notification
    [array] $RegValuesSilent = @(
        [hashtable]@{Path=[string]$PathDirReg;Name=[string]'KFMSilentOptIn';                Value=[string]$TenantId;Type=[string]'String'},
        [hashtable]@{Path=[string]$PathDirReg;Name=[string]'KFMSilentOptInWithNotification';Value=[byte]1;          Type=[string]'DWord'}
    )

    # Registry Values - Silent without Notification
    [array] $RegValuesSilent = @(
        [hashtable]@{Path=[string]$PathDirReg;Name=[string]'KFMSilentOptIn';                Value=[string]$TenantId;Type=[string]'String'},
        [hashtable]@{Path=[string]$PathDirReg;Name=[string]'KFMSilentOptInWithNotification';Value=[byte]0;          Type=[string]'DWord'}
    )

    # Registry Values - Block Opting Out
    [array] $RegValuesBlockOptOut = @(
        [hashtable]@{Path=[string]$PathDirReg;Name=[string]'KFMBlockOptOut';                Value=[byte]1;          Type=[string]'DWord'}
    )

    # Registry Values - Block Opting In
    [array] $RegValuesBlockOptOut = @(
        [hashtable]@{Path=[string]$PathDirReg;Name=[string]'KFMBlockOptIn';                 Value=[byte]1;          Type=[string]'DWord'}
    )


#endregion Variables



if ($false) {
    #region    Set Registry Values from SYSTEM / DEVICE context
        foreach ($Item in $RegValuesWizard) {
            # Create $Path variable, switch HKCU: with HKU:
            [string] $Path = $Item.Path
            if ($Path -like 'HKCU:\*') {$Path = $Path.Replace('HKCU:\',$Script:PathDirRootCU)}
            $Path = $Path.Replace('\\','\')
            Write-Verbose -Message ('Path: "{0}".' -f ($Path))

            # Check if $Path is valid
            [bool] $SuccessValidPath = $true
            if ($Path -like 'HKCU:\*') {$SuccessValidPath = $false}
            elseif ($Path -like 'HKLM:\*' -or $Path -like 'HKU:\') {
                $SuccessValidPath = -not ($Path -notlike 'HK*:\*' -or $Path -like '*:*:*' -or $Path -like '*\\*' -or $Path.Split(':')[0].Length -gt 4)       
            }
            elseif ($Path -like 'Registry::HKU\*') {
                $SuccessValidPath = -not ($Path -like '*\\*')
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


    #region    Remove KFM Wizard
    foreach ($Item in $RegValuesWizard){$null = Remove-ItemProperty -Path $Item.Path -Name $Item.Name -Force}
    #endregion Remove KFM Wizard

    #region    Remove KFM Silent
    foreach ($Item in $RegValuesSilent){$null = Remove-ItemProperty -Path $Item.Path -Name $Item.Name -Force}
    #endregion Remove KFM Silent
}