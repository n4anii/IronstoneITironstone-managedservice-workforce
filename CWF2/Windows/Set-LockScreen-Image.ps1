# Define the URL of the image in Azure Blob Storage
$blobUrl = "URL OF HE BLOB STORAGE HERE"

# Define the path where the image will be saved locally
$localImagePath = "$env:USERPROFILE\Pictures\lockscreen.png"

# Ensure the directory exists
$directory = [System.IO.Path]::GetDirectoryName($localImagePath)
if (-not (Test-Path -Path $directory)) {
    New-Item -ItemType Directory -Path $directory
}

# Download the image from Blob Storage
Invoke-WebRequest -Uri $blobUrl -OutFile $localImagePath

# Set the lock screen image
$registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Lock Screen"
if (-not (Test-Path -Path $registryPath)) {
    New-Item -Path $registryPath -ItemType Directory
}
Set-ItemProperty -Path $registryPath -Name "CreativeId" -Value $localImagePath
Set-ItemProperty -Path $registryPath -Name "LandscapeAssetPath" -Value $localImagePath
Set-ItemProperty -Path $registryPath -Name "PortraitAssetPath" -Value $localImagePath

# Refresh the lock screen image
RUNDLL32.EXE user32.dll,UpdatePerUserSystemParameters