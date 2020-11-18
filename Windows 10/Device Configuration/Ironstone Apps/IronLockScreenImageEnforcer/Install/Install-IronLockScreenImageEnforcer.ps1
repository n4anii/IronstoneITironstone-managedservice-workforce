#Requires -RunAsAdministrator
<#
    Run from Intune
        Install        
            "%windir%\System32\wscript.exe" //B //NoLogo //T:60 "Run-PS1.vbs" "Install-IronLockScreenImageEnforcer.ps1"
        Uninstall
            "%windir%\System32\wscript.exe" //B //NoLogo //T:60 "Run-PS1.vbs" "Uninstall-IronLockScreenImageEnforcer.ps1"
#>


# Logging
$Success     = [bool]$($true)
$PathDirLog  = [string]$('{0}\IronstoneIT\Intune\ClientApps\IronLockScreenImageEnforcer Install' -f ($env:ProgramW6432))
$PathFileLog = [string]$('{0}\Log-{2}-x{1}.txt' -f ($PathDirLog,[string]$(if([System.Environment]::Is64BitProcess){'64'}else{'86'}),[datetime]::Now.ToString('yyyyMMdd-HHmmssffff')))
if (-not(Test-Path -Path $PathDirLog -ErrorAction 'Stop')) {$null = New-Item -Path $PathDirLog -ItemType 'Directory' -ErrorAction 'Stop'}
Start-Transcript -Path $PathFileLog -Force -ErrorAction 'Stop'


#region    Main
Try {
    # Assets - Installer
    $PathWorkingDirectory    = [string]$([string]$($MyInvocation.'InvocationName').Replace(('\{0}' -f ($MyInvocation.'MyCommand')),''))
    $PathFileLockScreenImage = [string]$(Get-ChildItem -Path $PathWorkingDirectory -File -Filter '*.jpg' -Recurse:$false -ErrorAction 'Stop' | Select-Object -First 1 -ExpandProperty 'FullName' -ErrorAction 'Stop')
    

    # Troubleshooting info
    Write-Output -InputObject ('# Troubleshooting info')
    Write-Output -InputObject ('{0}Working directory:   "{1}"' -f ("`t",$PathWorkingDirectory))
    Write-Output -InputObject ('{0}Running as Username: "{1}"' -f ("`t",[System.Security.Principal.WindowsIdentity]::GetCurrent().'Name'))
    Write-Output -InputObject ('{0}Running as SID:      "{1}"' -f ("`t",[System.Security.Principal.WindowsIdentity]::GetCurrent().'User'.'Value'))
    Write-Output -InputObject ('{0}Is 64 bit OS?        "{1}"' -f ("`t",[System.Environment]::Is64BitOperatingSystem.ToString()))
    Write-Output -InputObject ('{0}Is 64 bit process?   "{1}"' -f ("`t",[System.Environment]::Is64BitProcess.ToString()))
    

    # Assets - Destinations
    $LockScreenImageDirectoryPath = [string]$('{0}\IronstoneIT\IronLockScreenImageEnforcer' -f ($env:ProgramW6432))
    $LockScreenImageFilePath      = [string]$('{0}\LockScreenImage.jpg' -f ($LockScreenImageDirectoryPath))
    $RegistryPath  = [string]$('Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Personalization')
    $RegistryKeys  = [PSCustomObject[]]$(
        [PSCustomObject]@{'Name'='NoLockScreenSlideshow';'Type'='DWord'; 'Value'='1'}
        [PSCustomObject]@{'Name'='LockScreenImage';     ;'Type'='String';'Value'=$LockScreenImageFilePath.Replace($env:ProgramW6432,'%ProgramW6432%')}
    )


    # Install Lock Screen Image
    if (Test-Path -Path $LockScreenImageDirectoryPath) {$null = Remove-Item -Path $LockScreenImageDirectoryPath -Recurse:$true -Force -ErrorAction 'Stop'}
    if (-not(Test-Path -Path $LockScreenImageDirectoryPath)) {$null = New-Item -Path $LockScreenImageDirectoryPath -ItemType 'Directory' -Force -ErrorAction 'Stop'}
    $null = Copy-Item -Path $PathFileLockScreenImage -Destination $LockScreenImageFilePath -Force -ErrorAction 'Stop'
    


    # Set LockScreen Image Registry Values
    foreach ($RegistryKey in $RegistryKeys) {
        $null = Set-ItemProperty -Path $RegistryPath -Name $RegistryKey.'Name' -Value $RegistryKey.'Value' -Type $RegistryKey.'Type' -Force -ErrorAction 'Stop'
    }
}
Catch {
    # Set $Success to false
    $Success = [bool]$($false)
    # Construct Message
    $ErrorMessage = [string]('Finished with errors:')
    $ErrorMessage += ('{0}{0}Exception:{0}{1}'             -f ("`r`n",$_.'Exception'))
    $ErrorMessage += ('{0}{0}CategoryInfo\Activity:{0}{1}' -f ("`r`n",$_.'CategoryInfo'.'Activity'))
    $ErrorMessage += ('{0}{0}CategoryInfo\Category:{0}{1}' -f ("`r`n",$_.'CategoryInfo'.'Category'))
    $ErrorMessage += ('{0}{0}CategoryInfo\Reason:{0}{1}'   -f ("`r`n",$_.'CategoryInfo'.'Reason'))
    # Write Error Message
    Write-Error -Message $ErrorMessage   
}
Finally {
    Stop-Transcript
}
#endregion Main



# Return Exit Code
if ($Success) {
    exit 0
} 
else {
    exit 1
}