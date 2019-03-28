# Test IronSync Office Templates Edition
    # Customer Name In Script
    $Customer = [string]$('MetierOEC'); $Customer


    # Check File Paths - Public
    ~Get-ChildItem -Path ('{0}\Users\Public' -f ($env:SystemDrive)) -Directory -Recurse:$false -Force


    # Check File Paths - Public\OfficeTemplates - View
    ~Get-ChildItem -Path ('{0}\Users\Public\OfficeTemplates' -f ($env:SystemDrive)) -File -Recurse:$false -Force
    cmd /c 'dir "C:\Users\Public\OfficeTemplates"'


    # Check File Paths - Public\OfficeTemplates - Count
    ~@(Get-ChildItem -Path ('{0}\Users\Public\OfficeTemplates' -f ($env:SystemDrive)) -File -Recurse:$false -Force).Count
    

    # Check Registry Entries - Word
    ~(Get-ItemProperty -Path ('Registry::HKEY_USERS\{0}\Software\Microsoft\Office\16.0\Word\Options' -f ([System.Security.Principal.NTAccount]::new(@(Get-Process -Name 'explorer' -IncludeUserName)[0].UserName).Translate([System.Security.Principal.SecurityIdentifier]).Value)) -Name 'PersonalTemplates' | Select-Object -ExpandProperty 'PersonalTemplates')


    # Check Registry Entries - PowerPoint
    ~(Get-ItemProperty -Path ('Registry::HKEY_USERS\{0}\Software\Microsoft\Office\16.0\PowerPoint\Options' -f ([System.Security.Principal.NTAccount]::new(@(Get-Process -Name 'explorer' -IncludeUserName)[0].UserName).Translate([System.Security.Principal.SecurityIdentifier]).Value)) -Name 'PersonalTemplates' | Select-Object -ExpandProperty 'PersonalTemplates')


    # Check Install Log
    ~(Get-Content -Path (Get-ChildItem -Path ('{0}\IronstoneIT\Intune\DeviceConfiguration' -f ($env:ProgramW6432)) -File | Where-Object {$_.Name -like ('Device_Install-IronSync*-64bit*')} | Sort-Object -Property 'LastWriteTime' | Select-Object -Last 1 -ExpandProperty 'FullName') -Raw)


    # Check Sync Error Logs - Any Present
    ~$Result = @(Get-ChildItem -Path ('{0}\IronstoneIT\IronSync(OfficeTemplates_MetierOEC)\Logs' -f ($env:ProgramW6432,$Customer)) -File); if((-not($?)) -or @($Result).Count -le 0){'None Where Found'}else{$Result}


    # Check Sync Error Logs - Last Log
    ~(Get-Content -Path (Get-ChildItem -Path ('{0}\IronstoneIT\IronSync(OfficeTemplates_{1})\Logs' -f ($env:ProgramW6432,$Customer)) -File | Sort-Object -Property 'LastWriteTime' | Select-Object -Last 1 -ExpandProperty 'FullName') -Raw)