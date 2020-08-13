# Get all items on Desktop for current user
## Explorer.exe
Get-ChildItem -File -Depth 2 -Path ('{0}\Users\{1}\Desktop' -f ($env:SystemDrive,[string]$(Get-Process -Name 'explorer' -IncludeUserName | Select-Object -ExpandProperty 'UserName' -First 1).Split('\')[-1])) | Select-Object -Property 'Name','LastWriteTime','Length','FullName' | Sort-Object -Property 'Name'
## File system
Get-ChildItem -File -Depth 2 -Path ('{0}\Desktop' -f ([string]$([string[]]$(Get-ChildItem -Path ('{0}\Users' -f ($env:SystemDrive)) -Depth 0 -Directory | Select-Object -ExpandProperty 'FullName').Where{$_ -notlike '*\Public'}[0])))


# Get items in start menu
## Explorer.exe
Get-ChildItem -File -Depth 2 -Path ('{0}\Users\{1}\AppData\Roaming\Microsoft\Windows\Start Menu\Programs' -f ($env:SystemDrive,[string]$(Get-Process -Name 'explorer' -IncludeUserName | Select-Object -ExpandProperty 'UserName' -First 1).Split('\')[-1])) | Select-Object -Property 'Name','LastWriteTime','Length','FullName' | Sort-Object -Property 'Name'
### Filter out system user
Get-ChildItem -File -Depth 2 -Path ('{0}\Users\{1}\AppData\Roaming\Microsoft\Windows\Start Menu\Programs' -f ($env:SystemDrive,[string]$(Get-Process -Name 'explorer' -IncludeUserName | Select-Object -ExpandProperty 'UserName' -Unique | Where-Object -FilterScript {$_ -notlike '*System*'} | Select-Object -First 1).Split('\')[-1])) | Select-Object -Property 'Name','LastWriteTime','Length','FullName' | Sort-Object -Property 'Name'

# Get paths to home folders (Desktop, My Documents etc.)
## Explorer.exe
### All
Get-ItemProperty -Path ('Registry::HKEY_USERS\{0}\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' -f ([string]$([System.Security.Principal.NTAccount]::new([string]$(Get-Process -Name 'explorer' -IncludeUserName | Select-Object -ExpandProperty 'UserName' -First 1)).Translate([System.Security.Principal.SecurityIdentifier]).'Value')))
### Desktop and Start Menu only
Get-ItemProperty -Name 'Desktop','Start Menu' -Path ('Registry::HKEY_USERS\{0}\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' -f ([string]$([System.Security.Principal.NTAccount]::new([string]$(Get-Process -Name 'explorer' -IncludeUserName | Select-Object -ExpandProperty 'UserName' -First 1)).Translate([System.Security.Principal.SecurityIdentifier]).'Value'))) | Select-Object -Property 'Desktop','Start Menu' | Format-List
## Registry
### All
Get-ItemProperty -Path ('Registry::{0}\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' -f ([string]$(Get-ChildITem -Path 'Registry::HKEY_USERS' | Select-Object -ExpandProperty 'Name' | Where-Object -FilterScript {$_ -like '*S-1-12*' -and $_ -notlike '*_Classes'})))
### Desktop and Start Menu only
Get-ItemProperty -Name 'Desktop','Start Menu' -Path ('Registry::{0}\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' -f ([string]$(Get-ChildITem -Path 'Registry::HKEY_USERS' | Select-Object -ExpandProperty 'Name' | Where-Object -FilterScript {$_ -like '*S-1-12*' -and $_ -notlike '*_Classes'}))) | Select-Object -Property 'Desktop','Start Menu' | Format-List
### In case of multiple users
[array]$(Get-ChildITem -Path 'Registry::HKEY_USERS' | Select-Object -ExpandProperty 'Name' | Where-Object -FilterScript {$_ -like '*S-1-12*' -and $_ -notlike '*_Classes'}).ForEach{Get-ItemProperty -Name 'Desktop','Start Menu' -Path ('Registry::{0}\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' -f ($_)) | Select-Object -Property 'Desktop','Start Menu'} | Format-List