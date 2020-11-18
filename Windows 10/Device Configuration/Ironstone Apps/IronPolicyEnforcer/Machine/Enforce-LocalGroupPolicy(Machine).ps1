#Requires -RunAsAdministrator
<#
    Run from Intune
        WScript and VBS
            "%windir%\System32\wscript.exe" //B //NoLogo //T:60 "Run-PS1.vbs" "Enforce-LocalGroupPolicy(Machine).ps1"
        PowerShell directly (does not work with Intune Win32)
            "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy Bypass -WindowStyle Hidden -NonInteractive -NoProfile -File ".\Enforce-LocalGroupPolicy(Machine).ps1"
        CMD
            "%windir%\System32\cmd.exe"
#>


# Logging
$Success     = [string]$($true)
$PathDirLog  = [string]$('{0}\IronstoneIT\Intune\ClientApps\IronPolicyEnforcer Install' -f ($env:ProgramW6432))
$PathFileLog = [string]$('{0}\Log-{2}-x{1}.txt' -f ($PathDirLog,[string]$(if([System.Environment]::Is64BitProcess){'64'}else{'86'}),[datetime]::Now.ToString('yyyyMMdd-HHmmssffff')))
if (-not(Test-Path -Path $PathDirLog -ErrorAction 'Stop')) {$null = New-Item -Path $PathDirLog -ItemType 'Directory' -ErrorAction 'Stop'}
Start-Transcript -Path $PathFileLog -Force -ErrorAction 'Stop'


#region    Main
Try {
    # Assets
    $PathWorkingDirectory = [string]$([string]$($MyInvocation.'InvocationName').Replace(('\{0}' -f ($MyInvocation.'MyCommand')),''))
    $PathGPOFileIncluded  = [string]$('{0}\registry.pol' -f ($PathWorkingDirectory))
    $PathGPOFileInstalled = [string]$('{0}\System32\GroupPolicy\Machine\registry.pol' -f ($env:windir))
    

    # Troubleshooting info
    Write-Output -InputObject ('# Troubleshooting info')
    Write-Output -InputObject ('{0}Working directory:   "{1}"' -f ("`t",$PathWorkingDirectory))
    Write-Output -InputObject ('{0}Running as Username: "{1}"' -f ("`t",[System.Security.Principal.WindowsIdentity]::GetCurrent().'Name'))
    Write-Output -InputObject ('{0}Running as SID:      "{1}"' -f ("`t",[System.Security.Principal.WindowsIdentity]::GetCurrent().'User'.'Value'))
    Write-Output -InputObject ('{0}Is 64 bit OS?        "{1}"' -f ("`t",[System.Environment]::Is64BitOperatingSystem.ToString()))
    Write-Output -InputObject ('{0}Is 64 bit process?   "{1}"' -f ("`t",[System.Environment]::Is64BitProcess.ToString()))
    

    # If OS is 64 bit, and PowerShell got launched as x86, relaunch as x64
    if ([System.Environment]::Is64BitOperatingSystem -and -not [System.Environment]::Is64BitProcess) {
        write-Output -InputObject ('{0} * Will restart this PowerShell session as x64.' -f ("`t"))        
        $null = & ('{0}\sysnative\WindowsPowerShell\v1.0\powershell.exe' -f ($env:windir)) -NonInteractive -NoProfile -File ('{0}' -f ($MyInvocation.'InvocationName'))
        $Success = [bool]$(if($? -and ([string]::IsNullOrEmpty($LASTEXITCODE) -or $LASTEXITCODE -eq 0)){$true}else{$false})
    }
    else {
        # Only continue if paths can be found
        foreach ($Path in [string[]]$($PathGPOFileIncluded,$PathGPOFileInstalled)) {
            if(-not([bool]$(Test-Path -Path $Path -ErrorAction 'Stop'))) {
                Throw ('ERROR, path "{0}" does not exist.' -f ($Path))
            }
        }


        # Calculate SHA256 Checksums
        Write-Output -InputObject ('# Calculate SHA256 Checksums')
        $HashGPOIncluded  = Get-FileHash -Path $PathGPOFileIncluded -Algorithm 'SHA256' | Select-Object -ExpandProperty 'Hash' -ErrorAction 'Stop'
        Write-Output -InputObject ('{0}"{1}"{2}SHA256:{3}' -f ("`t",$PathGPOFileIncluded,"`r`n`t`t",$HashGPOIncluded))
        $HashGPOInstalled = Get-FileHash -Path $PathGPOFileInstalled -Algorithm 'SHA256' | Select-Object -ExpandProperty 'Hash' -ErrorAction 'Stop'
        Write-Output -InputObject ('{0}"{1}"{2}SHA256:{3}' -f ("`t",$PathGPOFileInstalled,"`r`n`t`t",$HashGPOInstalled))


        # Replace installed GPO if hash mismatch
        Write-Output -InputObject ('# Replace installed GPO if hash mismatch')
        if ($HashGPOIncluded -ne $HashGPOInstalled) {
            # Install new GPO
            Write-Output -InputObject ('{0}Different SHA256 checksum on installed vs. included file. Will replace.' -f ("`t"))
            $null = Copy-Item -Path $PathGPOFileIncluded -Destination $PathGPOFileInstalled -Force -ErrorAction 'Stop'
            # Force GPO Refresh
            Write-Output -InputObject ('{0}Running a GPO Update.' -f ("`t"))
            Start-Process -FilePath ('{0}\System32\GPUpdate.exe' -f ($env:windir)) -ArgumentList '/force' -WindowStyle 'Hidden' -Wait    
        }
        else {
            # Do not install GPO
            Write-Output -InputObject ('{0}Same SHA256 checksum on installed vs. included GPO. Will not replace.' -f ("`t"))
        }
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