#Requires -Version 5.1
<#
    .SYNOPSIS
        Checks if old password has been removed from registry.
#>



# Input parameters
[OutputType($null)]
Param()



# PowerShell Preferences
$ErrorActionPreference = 'Continue'
$InformationPreference = 'Continue'



# Installed
$IsInstalled = [bool] [System.IO.File]::Exists('{0}\LTSvc\LTSVC.exe'-f$env:windir)



# Configured
## Assets
$Path = [string] 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\LabTech\Service'
$Name = [string] 'ServerPassword'

## Check
$IsConfigured = [bool]$(
    # If not installed, check for traces
    if (-not $IsInstalled) {
        [bool]$(Try{$null=Get-ItemPropertyValue -Path $Path -Name $Name 2>$null;$?}Catch{$false})
    }
    # Else, check
    else {
        # Assets                
        $IsConfigured = [bool] $false
        $Test  = [byte] 1
        $Tests = [byte] 3

        # Check
        while (-not $IsConfigured -and $Test -le $Tests) {
            # Get value
            $Value = [string](Get-ItemPropertyValue -Path $Path -Name $Name -ErrorAction 'SilentlyContinue')
            # Check if configured wrong
            $IsConfigured = [bool](
                # Password exists and length is 32 characters long or more = Likely wrong server password
                $? -and $Value.'Length' -ge 32
            )
            # Wait before trying again
            if (-not $IsConfigured -and $Test -lt $Tests) {
                $null = Start-Sleep -Seconds 50        
            }
            # Increment $Test
            $Test++
        }

        # Return results
        [bool] $IsConfigured
    }
)



# Successfully talking with backend server
## Assets
$Path = [string] 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\LabTech\Service'
$Name = [string] 'LastSuccessStatusFT'

## Get registry value
$LastSuccessStatus = [datetime]$(
    if ([bool]$(Try{$null=Get-ItemPropertyValue -Path $Path -Name $Name 2>$null;$?}Catch{$false})) {
        [datetime]::FromFileTimeUtc((Get-ItemPropertyValue -Path $Path -Name $Name))
    }
    else {
        [datetime]::MinValue
    }
)

## IsAlive
$IsAlive = [bool]($LastSuccessStatus -ge [datetime]::Now.AddDays(-7))



# Write information
Write-Information -MessageData ('$IsInstalled = {0}' -f $IsInstalled.ToString())
Write-Information -MessageData ('$IsConfigured = {0}' -f $IsConfigured.ToString())
Write-Information -MessageData ('$LastSuccessStatus = {0}' -f $LastSuccessStatus.ToString('yyyyMMdd-HHmmss'))
Write-Information -MessageData ('$IsAlive = {0}' -f $IsAlive)



# Exit
if ($IsInstalled) {
    if ($IsConfigured -and $IsAlive) {
        Write-Output -InputObject 'Success, installed and not configured wrong.'
        Exit 0
    }
    else {
        Write-Error -Message 'Error, installed but configured wrong.'
        Exit 1
    }
}
else {
    if ($IsConfigured -or $IsAlive) {
        Write-Error -Message 'Error, not installed but traces are still remaining.'
        Exit 1
    }
    else {
        Write-Output -InputObject 'Success, not installed at all.'
        Exit 0
    }
}
