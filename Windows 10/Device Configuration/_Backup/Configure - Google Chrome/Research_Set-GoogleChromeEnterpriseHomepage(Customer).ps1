<#
    HomepageLocation
        * https://www.chromium.org/administrators/policy-list-3#HomepageLocation
        
    HomepageIsNewTabPage
        * https://www.chromium.org/administrators/policy-list-3#HomepageIsNewTabPage
#>


    # Assets
    $Homepage     = [string]$('')
    $CustomerName = [string]$('')
    
    $Paths = [string[]]@(
        ('Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Google\Chrome'),
        ('Registry::HKEY_USERS\{0}\Software\Policies\Google\Chrome' -f ($Script:StrIntuneUserSID))
    )

    $RegValues = [PSCustomObject[]]@(
        [PSCustomObject]@{Name=[string]'HomepageLocation';     Value=[string]$Homepage; Type=[string]'String'},               
        [PSCustomObject]@{Name=[string]'HomepageIsNewTabPage'; Value=[byte]0;           Type=[string]'DWord'}                
    )


    # Set HomePage
    foreach ($Path in $Paths) {
        if (-not(Test-Path -Path $Path)) {$null = New-Item -Path $Path -ItemType 'Directory' -Force -ErrorAction 'Stop'}
        foreach ($RegValue in $RegValues) {
            $null = Set-ItemProperty -Path $Path -Name $RegValue.Name -Value $RegValue.Value -Type $RegValue.Type -Force -ErrorAction 'SilentlyContinue'
        }
    }


    # Write Out Success
    Write-Output -InputObject ('Successfully configured Google Chrome Enterprise with "{0}" as homepage for customer "{1}".' -f ($Homepage,$CustomerName))