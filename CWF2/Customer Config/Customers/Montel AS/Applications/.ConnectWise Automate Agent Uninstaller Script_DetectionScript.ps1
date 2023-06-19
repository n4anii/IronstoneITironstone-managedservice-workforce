<#
    .SYNOPSIS
        Checks if old password has been removed from registry.
#>



# Input parameters
[OutputType($null)]
Param()



# PowerShell Preferences
$ErrorActionPreference = 'Continue'



# Installed
$IsInstalled = [bool] [System.IO.File]::Exists('{0}\LTSvc\LTSVC.exe'-f$env:windir)



# Configured
## Assets
$Path = [string] 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\LabTech\Service'
$Name = [string] 'ServerPassword'

## Check
$IsConfiguredCorrectly = [bool]$(
    # If not installed, check for traces
    if (-not $IsInstalled) {
        [bool]$(Try{$null=Get-ItemPropertyValue -Path $Path -Name $Name 2>$null;$?}Catch{$false})
    }
    # Else, check
    else {
        # Assets                
        $IsConfiguredCorrectly = [bool] $false
        $Test  = [byte] 1
        $Tests = [byte] 3

        # Check
        while (-not $IsConfiguredCorrectly -and $Test -le $Tests) {
            # Get value
            $Value = [string]$(Get-ItemPropertyValue -Path $Path -Name $Name -ErrorAction 'SilentlyContinue')
            # Check if configured wrong
            $IsConfiguredCorrectly = [bool](
                # Password exists and length is 32 characters long or more = Likely wrong server password
                $? -and $Value.'Length' -ge 32
            )
            # Wait before trying again
            if (-not $IsConfiguredCorrectly -and $Test -lt $Tests) {
                $null = Start-Sleep -Seconds 50        
            }
            # Increment $Test
            $Test++
        }

        # Return results
        [bool] $IsConfiguredCorrectly
    }
)



# Successfully talking with backend server
## Assets
$Path = [string] 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\LabTech\Service'
$Name = [string] 'LastSuccessStatus'

## Check
$IsSuccessfullyTalkingWithServer = [bool]$(
    # If not installed, check for traces
    if (-not $IsInstalled) {
        [bool]$(Try{$null=Get-ItemPropertyValue -Path $Path -Name $Name 2>$null;$?}Catch{$false})
    }
    # Else, check
    else {
        # Check
        $LastSuccessStatus = [datetime]$(Get-ItemPropertyValue -Path $Path -Name $Name) 

        # Return results
        [bool] $? -and $LastSuccessStatus -gt [datetime]::Now.AddDays(-5)
    }
)



# Exit
if ($IsInstalled) {
    if ($IsConfiguredCorrectly -and $IsSuccessfullyTalkingWithServer) {
        Write-Output -InputObject 'Success, installed and not configured wrong.'
        Exit 0
    }
    else {
        Write-Error -Message 'Error, installed and configured wrong.'
        Exit 1
    }        
}
else {
    if ($IsConfiguredCorrectly -or $IsSuccessfullyTalkingWithServer) {
        Write-Error -Message 'Error, not installed but traces are still remaining.'
        Exit 1
    }
    else {
        Write-Output -InputObject 'Success, not installed at all.'
        Exit 0
    }
}
