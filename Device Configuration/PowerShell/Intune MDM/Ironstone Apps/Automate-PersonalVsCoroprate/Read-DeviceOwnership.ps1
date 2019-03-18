# Assets
$Path  = [string]$('Registry::HKEY_LOCAL_MACHINE\SOFTWARE\IronstoneIT\Intune\DeviceInfo')
$Name  = [string]$('DeviceOwnership')

# Read
[string]$($Val=Get-ItemProperty -Path $Path -Name $Name -ErrorAction 'SilentlyContinue';if($?){$Val}else{''})

# Oneliner
[string]$($Val=Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\IronstoneIT\Intune\DeviceInfo' -Name 'DeviceOwnership' -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'DeviceOwnership';if($?){$Val}else{''})
