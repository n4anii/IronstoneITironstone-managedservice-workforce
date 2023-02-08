# Edit the URL to your blob storage path
$PSurl= "https://satsintuneintegration.blob.core.windows.net/drivemapping/MapDrives.ps1"

# Don't change anything below this line

# Location where we will add the script to run on logon
$regKeyLocation="HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"

# Command for the registry
$psCommand= "PowerShell.exe -ExecutionPolicy Bypass -Windowstyle hidden -command $([char]34)& {(Invoke-RestMethod '$PSurl').Replace('ï','').Replace('»','').Replace('¿','') | Invoke-Expression}$([char]34)"


# Check if the registry location exist, if not create it.
if (-not(Test-Path -Path $regKeyLocation)){

    New-ItemProperty -Path $regKeyLocation -Force

}

# Create / Update the registry to reflect the powershell command.
Set-ItemProperty -Path $regKeyLocation -Name "PowerShellDriveMapping" -Value $psCommand -Force

# Invoke PowerShell script immediately
Invoke-Expression $psCommand -ErrorAction SilentlyContinue