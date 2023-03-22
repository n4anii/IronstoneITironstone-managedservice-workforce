<#	
  .NOTES
  ===========================================================================
   Created with: 	PowerShell
   Created on:   	15-04-2020
   Created by:   	Tristan van Onselen
   Filename:     	Add-CustombackgroundsforTeams.ps1
  ===========================================================================
  .DESCRIPTION
    This script will add custom backgrounds for Teams
#>

$source = "https://metierclientstorage.blob.core.windows.net/teamsbkg/Background.zip"

Start-BitsTransfer -Source $source -Destination $env:temp
$filename =  Split-Path -Path $source -Leaf
if(test-path -Path $env:temp\CustomBackgrounds)
  {
    remove-item $env:temp\CustomBackgrounds -Recurse -Force
  }
Expand-Archive -LiteralPath $env:TEMP\$filename -DestinationPath "$env:temp\CustomBackgrounds" -Force

$AllLocalUsers = (Get-ChildItem -path $env:SystemDrive:\Users).name 
$AllLocalUsers += "Default"
foreach($user in $AllLocalUsers)
  {

    $destination = ("$env:SystemDrive" + "\users\" + "$user" + "\AppData\Roaming\Microsoft\Teams\Backgrounds\Uploads")
    if(!(Test-Path -Path $destination))
      {
        New-Item -Path "$destination" -ItemType Directory | out-null
      } 
    copy-item -path "$env:temp\CustomBackgrounds\*.*" -Destination $destination -Force

  }