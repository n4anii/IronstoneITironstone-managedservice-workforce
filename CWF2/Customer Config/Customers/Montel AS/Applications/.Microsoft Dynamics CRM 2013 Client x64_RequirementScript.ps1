<#
    .SYNOPSIS
        Checks if Microsoft Visual C++ 2010 x64 is not installed, or installed versjon is a specific version.
#>


# Input parameters
[OutputType([bool])]
Param ()


# PowerShell preferences
$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'


# Assets
$WantedVersionReg  = [string] 'v10.0.30319.01'
$WantedVersionFile = [string] '10.00.30319.01'


# Get versions
$InstalledVersionReg  = [string](Get-ItemPropertyValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\VisualStudio\10.0\VC\VCRedist\x64' -Name 'Version' -ErrorAction 'SilentlyContinue')
$InstalledVersionFile = [string](Get-Item -Path ('{0}\Common Files\microsoft shared\VC\msdia100.dll'-f$env:ProgramW6432) -ErrorAction 'SilentlyContinue').'VersionInfo'.'ProductVersion'
Write-Information -MessageData ('Installed version registry: {0}. Installed version file: {1}.' -f $WantedVersionReg, $InstalledVersionFile)


# Check if not installed
if ([string]::IsNullOrEmpty($InstalledVersionReg) -and [string]::IsNullOrEmpty($InstalledVersionFile)) {
    Write-Information -MessageData 'Success, not installed.'
    Write-Output -InputObject $true
}
else {
    if ($InstalledVersionReg -eq $WantedVersionReg -and $InstalledVersionFile -eq $WantedVersionFile) {
        Write-Information -MessageData 'Success, correct version installed.'
        Write-Output -InputObject $true
    }
    else {
        Write-Error -Exception 'Wrong version installed.' -Message 'Wrong version installed.' -ErrorAction 'Continue'
        Write-Output -InputObject $false
    }
}
