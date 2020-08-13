#region    Default Applications
    # Windows 10 - Default Applications - All
    ~(Dism.exe /Online /Get-DefaultAppAssociations)

    # Windows 10 - Default Applications - ".pdf"
    ~(Dism.exe /online /Get-DefaultAppAssociations).Split("`r`n") | Where-Object {$_ -like '*".pdf"*'}
    assoc .pdf
    
    # Export current list as SYSTEM user
    ~(Start-Process -NoNewWindow -FilePath ('{0}\Dism.exe' -f ([System.Environment]::SystemDirectory)) -ArgumentList ('/online /Export-DefaultAppAssociations:"{0}"' -f (('{0}\Temp\DefaultApps.txt' -f ($env:windir)))))

    # Get default app for ".pdf"   (HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.pdf\UserChoice)
    ~(Get-ItemProperty -Path ('Registry::HKEY_USERS\{0}\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.pdf\UserChoice' -f ([System.Security.Principal.NTAccount]::new(@(Get-Process -Name 'explorer' -IncludeUserName)[0].UserName).Translate([System.Security.Principal.SecurityIdentifier]).Value)) -Name 'ProgId' | Select-Object -ExpandProperty 'ProgId')

    # Get default app for "mailto" (HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\mailto\UserChoice)
    ~(Get-ItemProperty -Path ('Registry::HKEY_USERS\{0}\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\mailto\UserChoice' -f ([System.Security.Principal.NTAccount]::new(@(Get-Process -Name 'explorer' -IncludeUserName)[0].UserName).Translate([System.Security.Principal.SecurityIdentifier]).Value)) -Name 'ProgId' | Select-Object -ExpandProperty 'ProgId')

    # Look at the exported list
    ~(Get-Content -Path ('{0}\Temp\DefaultApps.txt' -f ($env:windir)))

    # Re-register all apps
    ~(Get-AppxPackage -User @(Get-Process -Name 'explorer' -IncludeUserName)[0].UserName | ForEach-Object {Add-AppxPackage -DisableDevelopmentmode -Register ('{0}\Appxmanifest.xml' -f ($_.InstallLocation))})
#endregion Default Applications