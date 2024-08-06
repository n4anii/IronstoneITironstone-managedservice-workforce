# Import PSADT module to allow Autocompletion etc
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

if ($psISE) { $ScriptRoot = split-path -parent $psISE.CurrentFile.Fullpath }
elseif ($PSScriptRoot) { $ScriptRoot = $PSScriptRoot }
else { $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition }

# Uncomment this to load help files. 
# Start-Process PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -file `"$ScriptRoot\..\..\Toolkit\AppDeployToolkit\AppDeployToolkitHelp.ps1`""
Import-Module "$ScriptRoot\..\..\Toolkit\AppDeployToolkit\AppDeployToolkitMain.ps1"
Clear-Host