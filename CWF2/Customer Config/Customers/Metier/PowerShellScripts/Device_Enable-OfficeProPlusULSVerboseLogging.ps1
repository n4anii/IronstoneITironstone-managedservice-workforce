#Requires -RunAsAdministrator

# Assets
$Path = [string]$('Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\ClickToRun\OverRide')
$RegistryItems = [PSCustomObject[]]$(
    [PSCustomObject]@{'Path'=$Path;'Name'='LogLevel';'Value'=3;'Type'='DWord'},
    [PSCustomObject]@{'Path'=$Path;'Name'='PipelineLogging';'Value'=1;'Type'='DWord'}
)

# Create folder if not exist
if (-not(Test-Path -Path $Path)) {
    $null = New-Item -Path $Path -ItemType 'Directory' -Force
}

# Set registry values
foreach ($Item in $RegistryItems) {
    $null = Set-ItemProperty -Path $Item.'Path' -Name $Item.'Name' -Value $Item.'Value' -Type $Item.'Type' -Force
}