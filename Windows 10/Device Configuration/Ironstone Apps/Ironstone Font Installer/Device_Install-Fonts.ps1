#Requires -RunAsAdministrator
<#
    .SYNOPSIS
        Installs fonts.
#>



# PowerShell Preferences
$DebugPreference        = 'SilentlyContinue'
$VerbosePreference      = 'SilentlyContinue'
$WarningPreference      = 'Continue'
$ConfirmPreference      = 'None'
$InformationPreference  = 'SilentlyContinue'
$ProgressPreference     = 'SilentlyContinue'
$ErrorActionPreference  = 'Stop'
$WhatIfPreference       = $false



# Assets
$ScriptWorkingDirectory = [string]$(if([string]::IsNullOrEmpty($PSScriptRoot)){[System.IO.Directory]::GetParent($($MyInvocation.'MyCommand'.'Path',$psISE.'CurrentFile'.'FullPath').Where{-not[string]::IsNullOrEmpty($_)}[0]).'FullName'}else{$PSScriptRoot})
$PathInstall = [string]$('{0}\Fonts' -f ($env:windir))
$PathRegDir  = [string]$('Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts')



# Get all fonts
$FontFiles = [array](Get-ChildItem -Path ('{0}\Fonts'-f$ScriptWorkingDirectory) -File | Select-Object -Property 'Name','FullName')
if ($FontFiles.'Count' -le 0 -or [string]::IsNullOrEmpty($FontFiles[0].'FullName')) {
    Throw 'Failed to find any font files to install.'
}



# Copy over font files
Write-Output -InputObject '# Copy over font files'
foreach ($FontFile in $FontFiles) {
    # Write information
    Write-Output -InputObject $FontFile.'Name'
    
    # Generate $ToPath
    $ToPath = [string]('{0}\{1}'-f$PathInstall,$FontFile.'Name')
    
    # Copy over if not already exist
    if ([System.IO.File]::Exists($ToPath)) {
        Write-Output -InputObject ('{0}Already exists.'-f"`t")
    }
    else {
        $null = Copy-Item -Path $FontFile.'FullName' -Destination $ToPath -Force
        Write-Output -InputObject ('{0}Successfully copied over.'-f"`t")
    }
}



# Add registry keys
Write-Output -InputObject ('{0}# Add registry keys'-f[System.Environment]::NewLine)
foreach ($FontFile in $FontFiles) {
    # Write information
    Write-Output -InputObject $FontFile.'Name'

    # Generate name
    $Name = [string] $FontFile.'Name'
    $Name = [string] $Name.Replace(('.{0}'-f$Name.Split('.')[-1]),'')
    $Name = [string] ($Name -csplit '([A-Z][a-z]+)').Where{$_}.Replace('-','').ForEach{$_.Trim()}.Where{$_} -join ' '
    $Name += ' (TrueType)'
    
    # Set Registry Value
    $null = Set-ItemProperty -Path $PathRegDir -Name $Name -Value $FontFile.'Name' -Type 'String' -Force

    # Write information
    Write-Output -InputObject ('{0}Successfully set reg key name "{1}" with value "{2}".' -f ("`t",$Name,$FontFile.'Name'))
}



# Done
Write-Output -InputObject ('{0}# Done.'-f[System.Environment]::NewLine)
