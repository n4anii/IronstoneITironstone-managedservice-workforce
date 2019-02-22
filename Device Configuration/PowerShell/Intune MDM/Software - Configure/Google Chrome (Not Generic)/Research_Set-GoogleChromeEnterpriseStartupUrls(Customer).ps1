<# 
    RestoreOnStartup Option
    https://www.chromium.org/administrators/policy-list-3#RestoreOnStartup
        1 = Restore the last session
        4 = Open a list of URLs
        5 = Open New Tab Page
#>
    # Assets
    $Path  = [string]$('Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Google\Chrome')
    $Name  = [string]$('RestoreOnStartup')
    $Value = [byte]$(4)

    # Create Folder if not exist
    if (-not(Test-Path -Path $Path)){$null = New-Item -Path $Path -ItemType 'Directory' -Force -ErrorAction 'Stop'}

    # Set RestoreOnStartup
    $null = Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type 'Dword' -Force -ErrorAction 'Stop'



<# 
    Startup URLs
    https://www.chromium.org/administrators/policy-list-3#RestoreOnStartupURLs
#>
    # Assets
    $Path = [string]$('Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Google\Chrome\RestoreOnStartupURLs')
    $URLs = [string[]]@(
        'micromaticnorge.sharepoint.com/sites/intranett/sitepages/hjemmeside.aspx',
        'micromatic.no',
        'micromaticnorge.crm4.dynamics.com',
        'micro-matic-no.facebook.com'
    )

    # Create Folder if not exist
    if (-not(Test-Path -Path $Path)){$null = New-Item -Path $Path -ItemType 'Directory' -Force -ErrorAction 'Stop'}


    # Set Startup URLs
    $C = [byte]$(0)
    foreach ($URL in $URLs) {
        $null = Set-ItemProperty -Path $Path -Name $C -Value $URL -Type 'String' -Force -ErrorAction 'Stop'
        $C++
    }