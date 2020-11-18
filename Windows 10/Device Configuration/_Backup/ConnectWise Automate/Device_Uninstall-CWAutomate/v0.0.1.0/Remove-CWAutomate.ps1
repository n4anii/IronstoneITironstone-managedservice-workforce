[string] $PathDirRegAutomate = 'HKLM:\SOFTWARE\LabTech'
[string] $PathDirRegAutomateUninstaller = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{58A3001D-B675-4D67-A5A1-0FA9F08CF7CA}'

if (Test-Path -Path $PathDirRegAutomate) {
    # Removes all items, but some folders remain
    Remove-Item -Path $PathDirRegAutomate -Recurse -Force
}

if (Test-Path -Path $PathDirRegAutomate) {
    # Removes everything
    $null = reg delete $PathDirAutomate /f
}

# Run MSI Uninstall
if (Test-Path -Path $PathDirRegAutomateUninstaller) {
    [string[]] $UninstallString = @(((Get-ItemProperty $PathDirRegAutomateUninstaller).UninstallString).Split(' '))
    If (-not([string]::IsNullOrEmpty($UninstallString))) {
        Start-Process -FilePath $UninstallString[0] -ArgumentList ('{0} /qn' -f ($UninstallString[1])) -Wait
    }
}