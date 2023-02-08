[String]$LogfileName = "OneDriveDetection"

[String]$Logfile = "$env:SystemRoot\logs\$LogfileName.log"

Function Write-Log

{

Param ([string]$logstring)

If (Test-Path $Logfile)

{

If ((Get-Item $Logfile).Length -gt 2MB)

{

Rename-Item $Logfile $Logfile".bak" -Force

}

}

$WriteLine = (Get-Date).ToString() + " " + $logstring

Add-content $Logfile -value $WriteLine

}

$User = gwmi win32_computersystem -Property Username

$UserName = $User.UserName

$UserSplit = $User.UserName.Split("\")

$OneDrive = "$env:SystemDrive\users\" + $UserSplit[1] +"\appdata\local\microsoft\onedrive\onedrive.exe"

# Parameter to Log

Write-Log "Start Script Execution"

Write-Log "Logged on User: $UserName"

Write-Log "Detection-String: $OneDrive"

If(Test-Path $OneDrive)

{

Write-Log "Found DetectionFile"

$OneDriveFile = Get-Item $OneDrive

Write-Log "Get File Details"

Write-Log "Version found:$OneDriveFile.VersionInfo.FileVersion"

Write-Log "Script Exectuion End!"

Write-Log ""

Return $true

}

Else

{

Write-Log "Warning: OneDrive.exe not found – need to install App!"

}