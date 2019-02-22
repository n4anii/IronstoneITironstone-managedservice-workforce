#region    Chocolatey - Install & Update
    # Chocolatey installed?
    $null = Get-Command -Name choco -ErrorAction SilentlyContinue

    if ($?) {
        [System.Version] $ChocoVersionInstalled = choco -v
        # Upgrade Chocolatey
        choco upgrade chocolatey
        [System.Version] $ChocoVersionUpdated = choco -v
    }
    else {
        # Install Chocolatey
        Invoke-Expression -Command ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    }
#endregion Chocolatey - Install & Update


#region    Install Software
    # Install C++ Redistributable 2017
    choco install vcredist140 -y
#endregion Install Software