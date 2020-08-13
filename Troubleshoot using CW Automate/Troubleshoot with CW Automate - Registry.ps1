#Requires -RunAsAdministrator

# Get current logged on user SID
## Explorer.exe
[string]$([System.Security.Principal.NTAccount]::new([string]$(Get-Process -Name 'explorer' -IncludeUserName | Select-Object -First 1 -ExpandProperty 'UserName')).Translate([System.Security.Principal.SecurityIdentifier]).'Value')

# Skype for Business - Current User - All
Get-Item -Path ('Registry::HKEY_USERS\{0}\Software\Microsoft\Office\16.0\Lync' -f ([string]$([System.Security.Principal.NTAccount]::new([string]$(Get-Process -Name 'explorer' -IncludeUserName | Select-Object -First 1 -ExpandProperty 'UserName')).Translate([System.Security.Principal.SecurityIdentifier]).'Value')))

# Skype for Business - Current User - "ServerAddress*" and "ConfigurationMode"
Get-ItemProperty -Path ('Registry::HKEY_USERS\{0}\Software\Microsoft\Office\16.0\Lync' -f ([string]$([System.Security.Principal.NTAccount]::new([string]$(Get-Process -Name 'explorer' -IncludeUserName | Select-Object -First 1 -ExpandProperty 'UserName')).Translate([System.Security.Principal.SecurityIdentifier]).'Value'))) -Name 'ServerAddress*','ConfigurationMode'

# Skype for Business - Current User - "ConfigurationMode"
Get-ItemProperty -Path ('Registry::HKEY_USERS\{0}\Software\Microsoft\Office\16.0\Lync' -f ([string]$([System.Security.Principal.NTAccount]::new([string]$(Get-Process -Name 'explorer' -IncludeUserName | Select-Object -First 1 -ExpandProperty 'UserName')).Translate([System.Security.Principal.SecurityIdentifier]).'Value'))) -Name 'ConfigurationMode' | Select-Object -ExpandProperty 'ConfigurationMode'

# Skype for Business - Local Machine
Get-Item -Path ('Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Office\16.0\Lync')