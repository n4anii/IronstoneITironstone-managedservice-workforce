# Script Settings
$TelemetryLevel  = [byte]$(3)


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


# Make sure Registry Values matches $RegistryValues
foreach ($Path in $Paths) {
    foreach ($RegistryValue in $RegistryValues) {
        $Value = Get-ItemProperty -Path $Path -Name $RegistryValue.'Name' -ErrorAction 'Stop' | Select-Object -ExpandProperty $RegistryValue.'Name' -ErrorAction 'Stop'
        if ([string]$($Value) -ne [string]$($RegistryValue.'Value')) {Exit 1}
    }
}