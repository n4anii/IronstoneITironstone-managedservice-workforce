# Get the path to the current user's local AppData folder
$localAppDataPath = "$env:LOCALAPPDATA"

# Specify the path to the file to look for
$filePath = Join-Path $localAppDataPath "Programs\IHCStarter\IHCStarter.exe"

# Check if the file exists for the current user
if (Test-Path $filePath) {
    Write-Host "The file 'example.txt' was found at '$filePath'."

} else {
    # If the file was not found, check if the script is running as SYSTEM
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
    $isSystem = $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::System)

    if ($isSystem) {
        # If the script is running as SYSTEM, try to access the file as the current user
        $userName = $env:USERNAME
        $userPath = "C:\Users\$userName\AppData\Local\Programs\IHCStarter\example.txt"

        if (Test-Path $userPath) {
            Write-Host "The file 'example.txt' was found for user '$userName' at '$userPath'."
	
        } else {
            Write-Host "The file 'example.txt' was not found for the current user or SYSTEM account."
	
        }
    } else {
        Write-Host "The file 'example.txt' was not found for the current user or SYSTEM account."
	
    }
}
