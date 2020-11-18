# Assets
$Path  = [string]$('Registry::HKEY_LOCAL_MACHINE\SOFTWARE\IronstoneIT\Intune\DeviceInfo')
$Name  = [string]$('DeviceOwnership')
$Value = [string]$('Corporate')
$Type  = [string]$('String')

# Create Path If Not Exist
if (-not(Test-Path -Path $Path)){$null = New-Item -Path $Path -ItemType 'Directory' -Force -ErrorAction 'Stop'}

# Set Registry Value
$null = Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force -ErrorAction 'Stop'