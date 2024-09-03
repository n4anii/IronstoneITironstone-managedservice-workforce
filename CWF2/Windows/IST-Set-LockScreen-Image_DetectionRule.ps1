# Define the registry path and key name
$registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP"
$keyName = "LockScreenImagePath"
$imagePath = "C:\Windows\Logs\Software\lockscreen.png"

# Check if the registry key exists and has the correct value
if (Test-Path -Path "$registryPath\$keyName") {
    $keyValue = Get-ItemProperty -Path $registryPath -Name $keyName
    if ($keyValue.$keyName -eq $imagePath) {
        Write-Output "Detected"
        exit 0
    }
}

# If the key does not exist or the value is incorrect, return a non-zero exit code
Write-Output "Not Detected"
exit 1
