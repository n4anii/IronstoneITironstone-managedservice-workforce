$Path = [string]$('Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Templafy')
if(-not(Test-Path -Path $Path)){$null=New-Item -Path $Path -ItemType 'Directory' -Force}
Set-ItemProperty -Path $Path -Name 'AuthenticationMethod' -Value 'rpsgroupmetieroec' -Type 'String' -Force