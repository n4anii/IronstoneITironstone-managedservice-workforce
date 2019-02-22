<# 
    RestoreOnStartup Option
    https://www.chromium.org/administrators/policy-list-3#RestoreOnStartup
#>

    # Assets
    $Path  = [string]$('Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Google\Chrome')
    $Name  = [string]$('RestoreOnStartup')

    # Remove
    if ([bool]$(Get-ItemProperty -Path $Path -Name $Name -ErrorAction 'SilentlyContinue')) {
        $null = Remove-ItemProperty -Path $Path -Name $Name -Force -ErrorAction 'Stop'
    }



<# 
    Startup URLs
    https://www.chromium.org/administrators/policy-list-3#RestoreOnStartupURLs
#>

    # Assets
    $Path = [string]$('Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Google\Chrome\RestoreOnStartupURLs')

    # Remove
    if (Test-Path -Path $Path) {
        $null = Remove-Item -Path $Path -Recurse -Force -ErrorAction 'Stop'
    }