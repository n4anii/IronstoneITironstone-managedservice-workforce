<#
    HKCU From Current Logged In User to My Documents - No Need for Admin Permissions
#>
    
    # Get all paths for "My Documents"
    $PathDirDocuments = [string[]]@([string]$('{0}\Documents' -f ($env:USERPROFILE)),[string]$([System.Environment]::GetFolderPath('Documents'))) | Select-Object -Unique

    # Get OneDrive for Business folder location
    $PathDirOD4B = [string]$(Get-ItemProperty -Path 'Registry::HKEY_CURRENT_USER\Environment' -Name 'OneDriveCommercial' | Select-Object -ExpandProperty 'OneDriveCommercial')

    # Add Shortcut from "My Documents" to OneDrive
    foreach ($Path in $PathDirDocuments) {
        $null = Start-Process -FilePath ('{0}\cmd.exe' -f ([System.Environment]::SystemDirectory)) -ArgumentList ('mklink /h "{0}\OneDrive" "{1}"' -f ($Path,$PathDirOD4B)) -WindowStyle 'Hidden' -Wait
    }





<#
    System From HKCU Perspective to Root (C:) - No Need for Admin Permissions

    From Intune
#>

$PathDirOD4B = [string]$(Get-ItemProperty -Path ([string]$('Registry::HKEY_USERS\{0}\Environment' -f ($Script:StrIntuneUserSID))) -Name 'OneDriveCommercial' -ErrorAction 'Stop' | Select-Object -ExpandProperty 'OneDriveCommercial' -ErrorAction 'Stop')




<#
    System From HKCU Perspective to Root (C:) - No Need for Admin Permissions

    Test Locally as Admin
#>

    # Settings    $VerbosePreference = 'Continue'    # Assets    $PathDirOD4B  = [string]$(Get-ItemProperty -Path 'Registry::HKEY_CURRENT_USER\Environment' -Name 'OneDriveCommercial' -ErrorAction 'Stop' | Select-Object -ExpandProperty 'OneDriveCommercial' -ErrorAction 'Stop')    $NameDirOD4b  = [string]$([string[]]$($PathDirOD4B.Split('\')) | Select-Object -Last 1)    $PathDirFrom  = [string]$('{0}\{1}' -f ($env:HOMEDRIVE,$NameDirOD4b))    $PathDirTo    = [string]$('%HOMEDRIVE%\Users\{0}' -f ([string]$(([string[]]$($PathDirOD4B.Split('\')) | Select-Object -Last 2) -join '\')))    $FilePath     = [string]$('{0}\cmd.exe' -f ([System.Environment]::SystemDirectory))    $ArgumentList = [string]$('mklink /d "{0}" "{1}"' -f ($PathDirFrom,$PathDirTo))    # Create Link    if (Test-Path -Path $PathDirFrom) {        Write-Verbose -Message 'Path already exist.'    }    else {        # CMD /C        Write-Verbose -Message ('$null = cmd /c {0}' -f ($ArgumentList))        $null = cmd /c $ArgumentList 2>&1            # Success?        Write-Output -InputObject ('Created symbolic link from "{0}" to "{1}". Success? {2}.' -f ($PathDirFrom,$PathDirTo,[string]$(Test-Path -Path $PathDirFrom)))    }<#     Does not work#>        # &    Write-Verbose -Message ('$null = & "{0}" {1}"' -f ($FilePath,$ArgumentList))    $null = & $FilePath $ArgumentList    # Start-Process    Write-Verbose -Message ('$null = Start-Process -FilePath {0} -ArgumentList {1} -WindowStyle `Hidden` -Wait' -f ($FilePath,$ArgumentList))    $null = Start-Process -FilePath $FilePath  -ArgumentList $ArgumentList -WindowStyle 'Hidden' -Wait