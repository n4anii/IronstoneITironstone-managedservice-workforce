#Requires -RunAsAdministrator


# Settings
$ErrorActionPreference = 'SilentlyContinue'


# Assets
$IronLockScreenEnforcerDirectoryPath = [string]$('{0}\IronstoneIT\IronLockScreenImageEnforcer' -f ($env:ProgramW6432))
$RegistryPath = [string]$('Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Personalization')


# Install Path
if (Test-Path -Path $IronLockScreenEnforcerDirectoryPath) {
    $null = Remove-Item -Path $IronLockScreenEnforcerDirectoryPath -Force -Recurse:$true -Confirm:$false
    if (-not($?)){exit 1}
}


# Registry Keys \ Remove "LockScreenImage"
if ([bool]$($null = Get-ItemProperty -Path $RegistryPath -Name 'LockScreenImage' -ErrorAction 'SilentlyContinue';$?)) {
    $null = Remove-ItemProperty -Path $RegistryPath -Name 'LockScreenImage' -Force
    if (-not($?)){exit 1}
}


# Registry Keys \ Reset "NoLockScreenSlideShow" to default
$null = Set-ItemProperty -Path $RegistryPath -Name 'NoLockScreenSlideshow' -Value 1 -Type 'DWord' -Force
if (-not($?)){exit 1}


# Return success if we got this far
exit 0