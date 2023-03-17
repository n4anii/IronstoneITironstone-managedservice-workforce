# Input parameters
[OutputType($null)]
Param ()


# PowerShell Preferences
$ErrorActionPreference = 'Stop'


# Assets
$Path = [string] '{0}\IronstoneIT\Binaries\AzCopy\azcopy.exe' -f $env:ProgramData
$RequiredVersion = [System.Version] '10.7.0'


# Check if installed
if (-not [System.IO.File]::Exists($Path)) {
    Write-Error -Message 'Fail - Not installed.' -ErrorAction 'Continue'
    Exit 1
}


# Get version
$VersionInfo = [string[]](& $Path '--version')
$InstalledVersion = [System.Version]($VersionInfo[0].Split(' ')[-1])


# Check version
if ($InstalledVersion -ge $RequiredVersion) {
    Write-Output -InputObject ('Success - Installed version "{0}" is newer than or equal to required version "{1}".' -f ($InstalledVersion,$RequiredVersion))
    Exit 0
}
else {
    Write-Error -Message ('Fail - Installed version "{0}" is not newer than or equal to required version "{1}".' -f ($InstalledVersion,$RequiredVersion)) -ErrorAction 'Continue'
    Exit 1
}
