#Requires -RunAsAdministrator
# PowerShell preferences
$ErrorActionPreference = 'Stop'
# Registry
$R=(Get-Item -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts')
$R.'Property'.Where{$_ -like 'Meta *'}.ForEach{
    $null=Remove-ItemProperty -Path ('Registry::{0}'-f$R.'Name') -Name $_ -Force
}
# Files
(Get-ChildItem -Path ('{0}\Fonts' -f ($env:windir)) -File).Where{$_.'Name' -like 'Meta*.ttf'}.ForEach{
    $null = cmd /c 'takeown' '/f' $_.'FullName'
    $null = cmd /c 'icacls' $_.'FullName' '/grant' 'administrators:F' '/t'
    $null = cmd /c 'del' $_.'FullName'
}
