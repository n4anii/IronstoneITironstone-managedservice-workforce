<#
    .NAME
        IronTelemetryEnforcer-Enhanced-InstallScript.ps1

    .NOTES
        Run from Intune
            "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy Bypass -WindowStyle Hidden -NonInteractive -NoProfile -File ".\IronTelemetryEnforcer-Enhanced-InstallScript.ps1"
#>

# Script Settings
$TelemetryLevel  = [byte]$(2)

# Logging
$Success     = [string]$($true)
$PathDirLog  = [string]$('{0}\IronstoneIT\Intune\ClientApps\IronLockScreenImageEnforcer Install' -f ($env:ProgramW6432))
$PathFileLog = [string]$('{0}\Log-{2}-x{1}.txt' -f ($PathDirLog,[string]$(if([System.Environment]::Is64BitProcess){'64'}else{'86'}),[datetime]::Now.ToString('yyyyMMdd-HHmmssffff')))
if (-not(Test-Path -Path $PathDirLog -ErrorAction 'Stop')) {$null = New-Item -Path $PathDirLog -ItemType 'Directory' -ErrorAction 'Stop'}
Start-Transcript -Path $PathFileLog -Force -ErrorAction 'Stop'


#region    Main
Try {





# Assets
$Paths = [string[]]$(
    'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\DataCollection',
    'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection'
)
$RegistryValues = [PSCustomObject[]]$(
    [PSCustomObject]@{'Name'='AllowTelemetry';                             'Value'=[byte]$($TelemetryLevel);                       'Type'='DWord'},
    [PSCustomObject]@{'Name'='AllowTelemetry_PolicyManager';               'Value'=[byte]$($TelemetryLevel);                       'Type'='DWord'},
    [PSCustomObject]@{'Name'='AllowDeviceNameInTelemetry';                 'Value'=[byte]$(1);                                     'Type'='DWord'},
    [PSCustomObject]@{'Name'='DisableDeviceDelete';                        'Value'=[byte]$(1);                                     'Type'='DWord'},
    [PSCustomObject]@{'Name'='DisableTelemetryOptInSettingsUx';            'Value'=[byte]$(1);                                     'Type'='DWord'},
    [PSCustomObject]@{'Name'='DisableTelemetryOptInChangeNotification';    'Value'=[byte]$(1);                                     'Type'='DWord'},
    [PSCustomObject]@{'Name'='DoNotShowFeedbackNotifications';             'Value'=[byte]$(1);                                     'Type'='DWord'},
    [PSCustomObject]@{'Name'='LimitEnhancedDiagnosticDataWindowsAnalytics';'Value'=[byte]$($(if($TelemetryLevel -le 2){1}else{0}));'Type'='DWord'}
)
    

# Remove Values - Location 1
foreach ($Name in [string[]]$(Get-Item -Path $Paths[0] | Select-Object -ExpandProperty 'Property')) {
    $null = Remove-ItemProperty -Path $Paths[0] -Name $Name -Force -ErrorAction 'Stop'
}


# Remove Values - Location 2
foreach ($Name in [string[]]$(Get-Item -Path $Paths[1] | Select-Object -ExpandProperty 'Property')) {
    # Don't remove CommercialID at this location, is set using Intune MDM Policies (OMA-URI)
    if ($Name -ne 'CommercialID') {
        $null = Remove-ItemProperty -Path $Paths[1] -Name $Name -Force -ErrorAction 'Stop'
    }
}


# Set Values - Both Locations
foreach ($Path in $Paths) {
    foreach ($Item in $RegistryValues) {
        Write-Output -InputObject ('Set-ItemProperty -Path "{0}" -Name "{1}" -Value "{2}" -Type "{3}" -Force' -f ($Path,$Item.'Name',$Item.'Value',$Item.'Type'))
        Set-ItemProperty -Path $Path -Name $Item.'Name' -Value $Item.'Value' -Type $Item.'Type' -Force -ErrorAction 'Stop'
        Write-Output -InputObject ('{0}Success? {1}.' -f ("`t",$?.ToString()))
    }
}


# Make sure Registry Values matches $RegistryValues
foreach ($Path in $Paths) {
    foreach ($RegistryValue in $RegistryValues) {
        $Value = Get-ItemProperty -Path $Path -Name $RegistryValue.'Name' -ErrorAction 'Stop' | Select-Object -ExpandProperty $RegistryValue.'Name' -ErrorAction 'Stop'
        if ([string]$($Value) -ne [string]$($RegistryValue.'Value')) {exit 1}
    }
}


# Exit with Success exit code if we got this far
exit 0