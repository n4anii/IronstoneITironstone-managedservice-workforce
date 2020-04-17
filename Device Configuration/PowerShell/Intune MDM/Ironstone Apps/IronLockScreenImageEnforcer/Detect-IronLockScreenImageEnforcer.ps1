# Settings
$ErrorActionPreference = 'Stop'


# Assets
$LockScreenImageFilePath = [string]$('{0}\IronstoneIT\IronLockScreenImageEnforcer\LockScreenImage.jpg' -f ($env:ProgramW6432))
$RegistryPath  = [string]$('Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Personalization')
$RegistryPath  = [string]$('Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Personalization')
$RegistryKeys  = [PSCustomObject[]]$(
    [PSCustomObject]@{'Name'='NoLockScreenSlideshow';'Type'='DWord'; 'Value'='1'}
    [PSCustomObject]@{'Name'='LockScreenImage';     ;'Type'='String';'Value'=$LockScreenImageFilePath.Replace($env:ProgramW6432,'%ProgramW6432%')}
)


# Check that Image file exist
if (-not(Test-Path -Path $LockScreenImageFilePath)) {
    Write-Output -InputObject ('Image "{0}" does not exist.' -f ($LockScreenImageFilePath))
    exit 1
}


# Check that registry keys are correct
foreach ($RegistryKey in $RegistryKeys) {
    if ([string]$(Get-ItemProperty -Path $RegistryPath -Name $RegistryKey.'Name' | Select-Object -ExpandProperty $RegistryKey.'Name') -ne [string]$($RegistryKey.'Value')) {
        Write-Output -InputObject ('Registry key "{0}\{1}" is not "{2}"' -f ($RegistryPath,$RegistryKey.'Name',$RegistryKey.'Value'))
        exit 1
    }
}


# Return success if no problems
exit 0