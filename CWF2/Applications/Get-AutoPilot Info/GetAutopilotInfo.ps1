# Ensure TLS 1.2 is used
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-PackageProvider -Name NuGet -Force


# Create a directory for HWID if it doesn't exist
New-Item -Type Directory -Path "C:\HWID" -Force

# Set the location to the script's directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location -Path $scriptDir

# Update the PATH environment variable
$env:Path += ";C:\Program Files\WindowsPowerShell\Scripts"

# Set the execution policy for the current process
Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned

# Install the NuGet provider if not already installed
if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
    Install-PackageProvider -Name NuGet -RequiredVersion 2.8.5.208 -Force
}

# Install the Get-WindowsAutopilotInfo script and force acceptance of any prompts
Install-Script -Name Get-WindowsAutopilotInfo -Force

# Ensure the script is available in the session
$scriptPath = (Get-InstalledScript -Name Get-WindowsAutopilotInfo).InstalledLocation
& "$scriptPath\Get-WindowsAutopilotInfo.ps1" -OutputFile "$scriptDir\AutopilotHWID.csv"
