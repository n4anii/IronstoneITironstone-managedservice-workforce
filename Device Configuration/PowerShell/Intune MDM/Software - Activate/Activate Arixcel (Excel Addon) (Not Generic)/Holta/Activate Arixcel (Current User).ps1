# Assets
[string] $Path  = 'HKCU:\Software\Arixcel\Explorer4'
[string] $Name  = 'License'
[string] $Value = 'Nlb552md3a39r1d7xqh8umsc990dhnu2'
[string] $Type  = 'String'

# Create Path if not exist
if (-not (Test-Path -Path $Path)) {
    $null = New-Item -Path $Path -ItemType 'Directory' -Force
}

# Set Registry Value
$null = Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force