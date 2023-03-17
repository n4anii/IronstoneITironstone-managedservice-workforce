#Requires -RunAsAdministrator
<#
    .SYNAPSIS
        Sets Windows 10 Telemetry settings in registry.
#>


# Script Settings
$TelemetryLevel  = [byte]$(3)


# Assets
$Paths = [string[]]$(
    'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\DataCollection',
    'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection'
)
$RegistryValues = [PSCustomObject[]]$(
    [PSCustomObject]@{'Name'='AllowTelemetry';                             'Value'=[byte]$($TelemetryLevel);                    'Type'='DWord'},
    [PSCustomObject]@{'Name'='AllowTelemetry_PolicyManager';               'Value'=[byte]$($TelemetryLevel);                    'Type'='DWord'},
    [PSCustomObject]@{'Name'='AllowDeviceNameInTelemetry';                 'Value'=[byte]$(1);                                  'Type'='DWord'},
    [PSCustomObject]@{'Name'='DisableDeviceDelete';                        'Value'=[byte]$(1);                                  'Type'='DWord'},
    [PSCustomObject]@{'Name'='DisableTelemetryOptInSettingsUx';            'Value'=[byte]$(1);                                  'Type'='DWord'},
    [PSCustomObject]@{'Name'='DisableTelemetryOptInChangeNotification';    'Value'=[byte]$(1);                                  'Type'='DWord'},
    [PSCustomObject]@{'Name'='DoNotShowFeedbackNotifications';             'Value'=[byte]$(1);                                  'Type'='DWord'},
    [PSCustomObject]@{'Name'='LimitEnhancedDiagnosticDataWindowsAnalytics';'Value'=[byte]$(if($TelemetryLevel -le 2){1}else{0});'Type'='DWord'}
)
    

# Remove Values - Location 1
[string[]]$(Get-Item -Path $Paths[0] | Select-Object -ExpandProperty 'Property').ForEach{
    $null = Remove-ItemProperty -Path $Paths[0] -Name $_ -Force -ErrorAction 'Stop'
}


# Remove Values - Location 2
[string[]]$(Get-Item -Path $Paths[1] | Select-Object -ExpandProperty 'Property').ForEach{
    # Don't remove CommercialID at this location, is set using Intune MDM Policies (OMA-URI)
    if ($_ -ne 'CommercialID') {
        $null = Remove-ItemProperty -Path $Paths[1] -Name $_ -Force -ErrorAction 'Stop'
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