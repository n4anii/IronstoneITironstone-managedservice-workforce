if ($PSVersionTable.PSVersion.Major -ge 6) {
    Write-Output "PowerShell Core (6.x or 7.x) supports TLS 1.3"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls13
} else {
    Write-Output "Windows PowerShell (5.1 or earlier) supports up to TLS 1.2"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "You need to run this script as an Administrator."
    PAUSE
}

if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
}

$hwidPath = "C:\HWID"
if (-not (Test-Path -Path $hwidPath)) {
    Write-Output "Create a directory for HWID"
    New-Item -Type Directory -Path $hwidPath -Force
}

Write-Output "Set the location to the script's directory"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location -Path $scriptDir

Write-Output "Update the PATH environment variable"
$env:Path += ";C:\Program Files\WindowsPowerShell\Scripts"

Write-Output "Set the execution policy for the current process"
Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned -Force

if (-not (Get-InstalledScript -Name Get-WindowsAutopilotInfo -ErrorAction SilentlyContinue)) {
    Write-Output "Installing Get-WindowsAutopilotInfo script if not already installed"
    Install-Script -Name Get-WindowsAutopilotInfo -Force -Confirm:$false
}

Write-Output "Ensure the script is available in the session"
$scriptPath = (Get-InstalledScript -Name Get-WindowsAutopilotInfo).InstalledLocation
& "$scriptPath\Get-WindowsAutopilotInfo.ps1" -OutputFile "$hwidPath\AutopilotHWID.csv"