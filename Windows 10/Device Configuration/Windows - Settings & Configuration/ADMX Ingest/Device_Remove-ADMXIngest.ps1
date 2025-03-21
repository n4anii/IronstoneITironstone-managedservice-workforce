﻿#Requires -RunAsAdministrator
<#
    .SYNOPSIS
        Removes ingested ADMX for applications like Mozilla Firefox and Google Chrome, so that new ADMX can be ingested to the same OMA-URI.
#>



# PowerShell preferences
$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'



# Settings
$WriteChanges      = [bool] $true
$ProductsToRemove  = [string[]](
    'Chrome',
    'Firefox',
    'Google'
)



# Assets
$Paths = [string[]](
    'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\PolicyManager\AdmxDefault',
    'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\PolicyManager\Admxinstalled'
)



# Remove ingested ADMX Files
foreach ($Path in $Paths) {
    # Check if path exist
    if (-not (Test-Path -Path $Path)) {
        Continue
    }
    
    # Get name of the random folder inside $Path
    $ChildPath = [string]$('Registry::{0}' -f (Get-ChildItem -Path $Path -Recurse:$false | Select-Object -ExpandProperty 'Name'))
    
    # Verbose
    Write-Information -MessageData $ChildPath

    # For Each Product to Remove
    foreach ($Product in $ProductsToRemove) {
        # Verbose
        Write-Information -MessageData ('{0}{0}{1}' -f ("`t",$Product))

        # Get all related paths
        $PathsToRemove = [string[]](
            $(
                [string[]](
                    $(Get-ChildItem -Path $ChildPath -Recurse:$false).'Name'
                )
            ).Where{
                $_ -like ('*\{0}*' -f ($Product))
            }.ForEach{
                [string]$('Registry::{0}' -f ($_))
            }
        )

        # Remove paths if any found
        if ($PathsToRemove.'Count' -le 0) {
            Write-Information -MessageData ('{0}{0}{0}Found 0 related paths.' -f ("`t"))
        }
        else {
            # Remove paths
            foreach ($Path in $PathsToRemove) {
                Write-Information -MessageData ('{0}{0}{0}{1}' -f ("`t",$Path.Split('\')[-1]))
                if ($WriteChanges) {
                    $null = Remove-Item -Path $Path -Recurse:$true -Force:$true
                    Write-Information -MessageData ('{0}{0}{0}{0}Successfully deleted? {1}.' -f ("`t",$?.ToString()))
                }
                else {
                    Write-Information -MessageData ('{0}{0}{0}{0}WriteChanges is false, did not delete.' -f ("`t"))
                }
            }
        }
    }
}
