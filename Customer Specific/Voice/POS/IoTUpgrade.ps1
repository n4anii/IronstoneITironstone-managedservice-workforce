$isoLocalPath = "C:\temp\iot2021ltsc.iso"
$unzipDirectory = "C:\Temp"

$TLS12Protocol = [System.Net.SecurityProtocolType] 'Ssl3 , Tls12'
[System.Net.ServicePointManager]::SecurityProtocol = $TLS12Protocol

# Create temporary folder
if (!(Test-Path -Path $unzipDirectory)) {
    New-Item -ItemType Directory -Path $unzipDirectory -Force
    Write-Output -InputObject ("Created temporary folder: $unzipDirectory")
}

# Download ISO File
Invoke-WebRequest -Uri "https://deviceyouremployees.blob.core.windows.net/iot2021/en-us_windows_10_iot_enterprise_version_22h2_x64_dvd_51cc370f.iso" -OutFile C:\temp\Win10Enterprise22H2.iso

# Extract ISO file
Write-Output -InputObject ('# Extract ISO file')
if (Test-Path -Path $isoLocalPath) {
    Write-Output -InputObject ('{0}SUCCESS - ISO file downloaded successfully.' -f ("`t"))
    Write-Output -InputObject ('# Extracting ISO file...')
    Mount-DiskImage -ImagePath $isoLocalPath
    $isoDrive = (Get-DiskImage -ImagePath $isoLocalPath | Get-Volume).DriveLetter
    
    Get-ChildItem -Path "$($isoDrive):\*" -Recurse | ForEach-Object {
        $destination = $unzipDirectory + $_.FullName.Substring(2)
        if ($_.PSIsContainer) {
            if (!(Test-Path $destination)) {
                New-Item -ItemType Directory -Path $destination -Force
            }
        } else {
            Copy-Item -Path $_.FullName -Destination $destination -Force
        }
    }
    
    Dismount-DiskImage -ImagePath $isoLocalPath
} else {
    Write-Output -InputObject ('{0}ERROR   - ISO file not found. Download failed.' -f ("`t"))
    $BoolScriptSuccess = $false
}

# Run Setup.exe for Inplace upgrade
C:\temp\setup.exe /auto upgrade /dynamicupdate disable /quiet /eula accept