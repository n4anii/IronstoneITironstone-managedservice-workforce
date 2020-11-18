<#
    HomepageLocation
        * https://www.chromium.org/administrators/policy-list-3#HomepageLocation
        
    HomepageIsNewTabPage
        * https://www.chromium.org/administrators/policy-list-3#HomepageIsNewTabPage
#>

    # Assets
    $Paths = [string[]]@(
        ('Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Google\Chrome'),
        ('Registry::HKEY_USERS\{0}\Software\Policies\Google\Chrome' -f ($Script:StrIntuneUserSID))
    )

    $RegValues = [PSCustomObject[]]@(
        [PSCustomObject]@{Name=[string]'HomepageLocation';     Value=[string]$Homepage; Type=[string]'String'},               
        [PSCustomObject]@{Name=[string]'HomepageIsNewTabPage'; Value=[byte]0;           Type=[string]'DWord'}                
    )

    # Remove
    foreach ($Path in $Paths) {
        foreach ($Name in [string[]]@($RegValues | Select-Object -ExpandProperty 'Name')) {
            if ([bool]$(Get-ItemProperty -Path $Path -Name $Name -ErrorAction 'SilentlyContinue')) {
                $null = Remove-ItemProperty -Path $Path -Name $Name -Force -ErrorAction 'Stop'
            }
        }
    }