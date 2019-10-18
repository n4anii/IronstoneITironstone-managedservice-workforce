#Requires -RunAsAdministrator
<#
    .SYNAPSIS
        Uninstalls all versions of Google Chrome.

    .NOTES
        Author:   Olav Rønnestad Birkeland
        Version:  1.0.0.0
        Created:  191011
        Modified: 191011

        Run from Intune
            "%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy "Bypass" -NoLogo -NonInteractive -NoProfile -WindowStyle "Hidden" -Command "& '.\Device_Uninstall-GoogleChromeBrowser.ps1'; exit $LASTEXITCODE"

        Exit codes
            0 = Success. Either chrome was not found, not installed, or uninstalled successfully.
            1 = Must run PowerShell as 64 bit process on a 64 bit OS.
            2 = Failed to uninstall system wide MSI installer.
            3 = Failed to uninstall system wide EXE installer.
#>



# Close process if not running as 64 bit on 64 bit OS
if ([System.Environment]::Is64BitOperatingSystem -and -not [System.Environment]::Is64BitProcess) {
    Exit 1
}



# Close Chrome if running
$null = Get-Process -Name 'chrome' -ErrorAction 'SilentlyContinue' | Stop-Process



# MSI
## Assets
$MSIExecPath  = [string]$('{0}\System32\msiexec.exe' -f ($env:SystemRoot))
$RegexGUIDMSI = [string]$('^[\{][a-fA-F0-9]{8}[-][a-fA-F0-9]{4}[-][a-fA-F0-9]{4}[-][a-fA-F0-9]{4}[-][a-fA-F0-9]{12}[\}]$')

## Get registry path to all installed MSIs
$ChromeMsiRegistryPaths = [string[]]$(
    [string[]]$(Get-ChildItem -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall' -Depth 0 | Select-Object -ExpandProperty 'Name') +
    [string[]]$(Get-ChildItem -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall' -Depth 0 -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'Name')
).Where{$_.Split('\')[-1] -match $RegexGUIDMSI}.ForEach{'Registry::{0}' -f $_}.Where{
    [string]$(Get-ItemProperty -Path $_ -Name 'DisplayName' -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'DisplayName') -eq 'Google Chrome'
}

## Uninstall
:ForEachMSI foreach ($Path in $ChromeMsiRegistryPaths) {
    # Get MSI GUID
    $MSIGUID = $Path.Split('\')[-1]
    # Uninstall it
    $null = Start-Process -FilePath $MSIExecPath -ArgumentList ('/x "{0}" /qn /norestart' -f ($MSIGUID)) -WindowStyle 'Hidden' -Verb 'RunAs' -Wait -ErrorAction 'SilentlyContinue'
    # Success?
    if ($? -and -not [bool]$(Test-Path -Path $Path)) {
        Continue :ForEachMSI
    }
    else {
        Exit 2
    }
}



# EXE
## Assets
$ChromeInstallPathBase   = [string]$('{0}\Google\Chrome\Application' -f (${env:ProgramFiles(x86)}))

## Get installed version(s)
$ChromeInstalledVersions = [System.Version[]]$([string[]]$(Get-ChildItem -Path $ChromeInstallPathBase -Depth 0 -Directory -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'Name').Where{Try{[System.Version]$($_);$?}Catch{$false}})

## Uninstall all installed versions
:ForEachVersion foreach ($Version in $ChromeInstalledVersions) {
    $ChromeUninstallPath = [string]$('{0}\{1}\installer\setup.exe' -f ($ChromeInstallPathBase,$Version.ToString()))
    if (Test-Path -Path $ChromeUninstallPath) {
        $null = Start-Process -FilePath $ChromeUninstallPath -ArgumentList '--uninstall --multi-install --chrome --system-level --force-uninstall'  -WindowStyle 'Hidden' -Verb 'RunAs' -Wait -ErrorAction 'SilentlyContinue'
        if ($? -and -not [bool]$(Test-Path -Path $ChromeUninstallPath)) {
            Continue :ForEachVersion
        }
        else {
            Exit 3
        }
    }
}



# Exit with success if we got this far
Exit 0