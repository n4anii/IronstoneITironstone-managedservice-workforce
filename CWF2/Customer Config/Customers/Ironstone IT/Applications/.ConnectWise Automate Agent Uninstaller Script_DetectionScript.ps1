<#
    .SYNOPSIS
        Checks if old password has been removed from registry.
#>



# Input parameters
[OutputType($null)]
Param()



# PowerShell Preferences
$ErrorActionPreference = 'Continue'



# Configured
## Assets
### What to check
$Path = [string] 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\LabTech\Service'
$Name = [string] 'ServerPassword'
### Help variables
$IsConfiguredCorrectly = [bool] $false
$Test  = [byte] 1
$Tests = [byte] 3
## Check
while (-not $IsConfiguredCorrectly -and $Test -le $Tests) {
    # Get value
    $Value = $([string]($(Get-ItemProperty -Path $Path -Name $Name -ErrorAction 'SilentlyContinue').$Name))
    # Check if configured wrong
    $IsConfiguredCorrectly = [bool](
        # No password = Likely install haven't run
        [string]::IsNullOrEmpty($Value) -or 
        # Password length is 32 characters long = Likely wrong server password
        $Value.'Length' -ne 32
    )
    # Wait before trying again
    if (-not $IsConfiguredCorrectly -and $Test -lt $Tests) {
        $null = Start-Sleep -Seconds 50        
    }
    # Increment $Test
    $Test++
}



# Exit
if ($IsConfiguredCorrectly) {
    Write-Output -InputObject 'Success, not configured wrong.'
    Exit 0
}
else {
    Write-Error -Message 'Error, configured wrong.'
    Exit 1
}
