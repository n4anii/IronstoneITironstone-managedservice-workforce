<#
    .EXAMPLE ConnectWise Automate Control Center
        & '.\Install-EXEorMSI.ps1' -ProductName 'ConnectWise Automate Control Center' -Uri 'https://ironstoneit.hostedrmm.com/LabTech/Updates/ControlCenterInstaller.exe' -InstallerType 'EXE' -InstallVerifyPath ('{0}\LabTech Client\LTClient.exe' -f (${env:ProgramFiles(x86)})) -ArgumentList ('/install /quiet /norestart /log "{0}\IronstoneIT\Intune\ClientApps\ConnectWise Automate Control Center -  Install Log {1}.txt"' -f ($env:ProgramData,[datetime]::Now.ToString('yyyyMMdd-HHmmss')))

     .EXAMPLE Google Chrome
        & '.\Install-EXEorMSI.ps1' -ProductName 'Google Chrome' -Uri 'https://dl.google.com/chrome/install/latest/chrome_installer.exe' -InstallerType 'EXE' -InstallVerifyPath ('{0}\Google\Chrome\Application\chrome.exe' -f (${env:ProgramFiles(x86)})) -ArgumentList '/silent /install'

    .EXAMPLE LastPass for Windows Desktop
        # Verify install path
        & '.\Install-EXEorMSI.ps1' -ProductName 'LastPass for Windows Desktop' -Uri 'https://download.cloud.lastpass.com/windows_installer/LastPassInstaller.msi' -InstallerType 'msi' -InstallVerifyPath ('{0}\LastPass\pwimport.exe' -f (${env:ProgramFiles(x86)})) -ArgumentList ('/l*v "{0}\IronstoneIT\Logs\ClientApps\Install-LastPass-{1}.txt" ADDLOCAL=GenericShortcuts,BinaryComponent,PasswordImporter,Updater TRYENABLESIDELOADING=0 TRYENABLESIDELOADINGFORINSTALL=0' -f ($env:ProgramData,[datetime]::Now.ToString('yyyyMMdd-HHmmss')))
        # Do not verify install path
        & '.\Install-EXEorMSI.ps1' -ProductName 'LastPass for Windows Desktop' -Uri 'https://download.cloud.lastpass.com/windows_installer/LastPassInstaller.msi' -InstallerType 'msi' -ArgumentList ('/l*v "{0}\IronstoneIT\Logs\ClientApps\Install-LastPass-{1}.txt" ADDLOCAL=GenericShortcuts,BinaryComponent,PasswordImporter,Updater TRYENABLESIDELOADING=0 TRYENABLESIDELOADINGFORINSTALL=0' -f ($env:ProgramData,[datetime]::Now.ToString('yyyyMMdd-HHmmss')))


    .EXAMPLE Lenovo System Interface Foundation
        & '.\Install-EXEorMSI.ps1' -ProductName 'Lenovo System Interface Foundation' -Uri 'https://filedownload.lenovo.com/enm/sift/core/SystemInterfaceFoundation.exe' -InstallerType 'EXE' -InstallVerifyPath ('{0}\ImController.InfInstaller.exe' -f ([System.Environment]::GetFolderPath('System'))) -ArgumentList '/SP- /VERYSILENT /NORESTART /SUPPRESSMSGBOXES /TYPE=installpackageswithreboot'
    

    .EXAMPLE Mozilla Firefox en-US
        & '.\Install-EXEorMSI.ps1' -ProductName 'Mozilla Firefox' -Uri 'https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=en-US' -InstallerType 'EXE' -InstallVerifyPath ('{0}\Mozilla Firefox\firefox.exe' -f ($env:ProgramW6432)) -ArgumentList '-ms'


    .EXAMPLE Microsoft Visual Studio Code
        & '.\Install-EXEorMSI.ps1' -ProductName 'Visual Studio Code' -Uri 'https://go.microsoft.com/fwlink/?Linkid=852157' -InstallerType 'EXE' -InstallVerifyPath ('{0}\Microsoft VS Code\Code.exe' -f ($env:ProgramW6432)) -ArgumentList '/VERYSILENT /NORESTART /NOCLOSEAPPLICATIONS /NORESTARTAPPLICATIONS /MERGETASKS=!runcode'

    
    .EXAMPLE Microsoft Visual Studio Code Insiders
        & '.\Install-EXEorMSI.ps1' -ProductName 'Visual Studio Code Insiders' -Uri 'https://go.microsoft.com/fwlink/?Linkid=852155' -InstallerType 'EXE' -InstallVerifyPath ('{0}\Microsoft VS Code Insiders\Code.exe' -f ($env:ProgramW6432)) -ArgumentList '/VERYSILENT /NORESTART /NOCLOSEAPPLICATIONS /NORESTARTAPPLICATIONS /MERGETASKS=!runcode'


    .EXAMPLE Microsoft Yammer (SYSTEM)
        & '.\Install-EXEorMSI.ps1' -ProductName 'Yammer' -Uri 'https://aka.ms/yammer_desktop_msi_x64' -InstallerType 'MSI' -InstallVerifyPath ('{0}\Yammer Installer\yammerdesktop.exe' -f (${env:ProgramFiles(x86)}))


    .EXAMPLE Microsoft Yammer (USER)
        & '.\Install-EXEorMSI.ps1' -ProductName 'Yammer' -Uri 'https://aka.ms/yammer_desktop_x64' -InstallerType 'EXE' -InstallVerifyPath ('{0}\yammerdesktop\Yammer.exe' -f ($env:LOCALAPPDATA)) -UserContext -ArgumentList '-s'
#>