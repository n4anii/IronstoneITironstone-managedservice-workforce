# Assets
$Path  = 'Registry::HKEY_CURRENT_USER\SOFTWARE\Palo Alto Networks\GlobalProtect\Settings'
$Name  = 'LastUrl'
$Value = 'vpn.montelnews.com'
$Type  = 'String'

# Create path if not exist
if (-not (Test-Path -Path $Path)) {
    $null = New-Item -Path $Path -ItemType 'Directory' -Force
}

# Set registry key
$null = Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force

# Add to path
$Path += '\vpn.montelnews.com'

# Create path if not exist
if (-not (Test-Path -Path $Path)) {
    $null = New-Item -Path $Path -ItemType 'Directory' -Force
}
