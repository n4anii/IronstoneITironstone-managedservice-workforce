#Requires -RunAsAdministrator
<#
    .SYNOPSIS
        Cleans most common Ironstone scheduled tasks, file paths, and registry paths, both for system/ device context, and user context.
        
    .DESCRIPTION
        Cleans most common Ironstone scheduled tasks, file paths, and registry paths, both for system/ device context, and user context.
          * Must run as administrator.
          * Remember to change $WriteChanges to your liking, will not delete anything if set to $false

        Get content of latest log
            Get-Content -Path $([array](Get-ChildItem -Path ([string]('{0}\Temp\Nuke-BPTW-*.txt' -f ($env:windir))) | Sort-Object -Property 'LastWriteTime' -Descending))[0].'FullName' -Raw
#>



# Input parameters
[OutputType($null)]
Param ()



# Settings
## Script settings
$WriteChanges = [bool] $true

## PowerShell Preferences
$ConfirmPreference = 'None'
$ErrorActionPreference = 'Stop'
$InformationPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'
$WarningPreference = 'Continue'
$WhatIfPreference = $false

## Help variables
$ScriptSuccess = $true



# Tests
## Make sure we're running in 64 bit
if ([System.Environment]::Is64BitOperatingSystem -and -not [System.Environment]::Is64BitProcess) {
    Throw 'ERROR: Not running as 64 bit process on 64 bit operating system.'
    Exit 1
}

## Make sure we're running as administrator
if (-not $([System.Security.Principal.WindowsPrincipal][System.Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Throw 'ERROR: Not running as admin.'
    Exit 1
}


# Logging
$LogPath = [string]('{0}\Temp\Nuke-BPTW-{1}.txt' -f ($env:windir, [datetime]::Now.ToString('yyyyMMdd-HHmmss')))
$null = Start-Transcript -Path $LogPath -Force



#region Try
#######################
#######################
Try {
    #######################
    #######################



    # Scheduled tasks
    ## Introduce
    Write-Output -InputObject '# Scheduled Tasks'

    ## Assets
    $ScheduledTasks = [array](Get-ScheduledTask -TaskName '*' | Where-Object -Property 'Author' -Like 'Ironstone*')

    ## Remove
    foreach ($ScheduledTask in $ScheduledTasks) {
        Write-Output -InputObject ('Found "{0}" by author "{1}"' -f ($ScheduledTask.'TaskName', $ScheduledTask.'Author'))
        if ($WriteChanges) {
            $null = Unregister-ScheduledTask -InputObject $ScheduledTask -Confirm:$false      
            Write-Output -InputObject ('{0}Success? {1}' -f ("`t", $?.ToString()))
        }
        else {
            Write-Output -InputObject ('{0}WriteChanges is $false' -f ("`t"))
        }
    }

    #######################
    #######################
}
#######################
#######################
#endregion Try



Catch {
    # Set script success to false
    $ScriptSuccess = [bool] $false
    
    # Construct error message
    ## Generic content
    $ErrorMessage = [string]$('{0}Catched error:' -f ([System.Environment]::NewLine))    
    ## Last exit code if any
    if (-not[string]::IsNullOrEmpty($LASTEXITCODE)) {
        $ErrorMessage += ('{0}# Last exit code ($LASTEXITCODE):{0}{1}' -f ([System.Environment]::NewLine, $LASTEXITCODE))
    }
    ## Exception
    $ErrorMessage += [string]$('{0}# Exception:{0}{1}' -f ([System.Environment]::NewLine, $_.'Exception'))
    ## Dynamically add info to the error message
    foreach ($ParentProperty in [string[]]$($_.GetType().GetProperties().'Name')) {
        if ($_.$ParentProperty) {
            $ErrorMessage += ('{0}# {1}:' -f ([System.Environment]::NewLine, $ParentProperty))
            foreach ($ChildProperty in [string[]]$($_.$ParentProperty.GetType().GetProperties().'Name')) {
                ### Build ErrorValue
                $ErrorValue = [string]::Empty
                if ($_.$ParentProperty.$ChildProperty -is [System.Collections.IDictionary]) {
                    foreach ($Name in [string[]]$($_.$ParentProperty.$ChildProperty.GetEnumerator().'Name')) {
                        if (-not[string]::IsNullOrEmpty([string]$($_.$ParentProperty.$ChildProperty.$Name))) {
                            $ErrorValue += ('{0} = {1}{2}' -f ($Name, [string]$($_.$ParentProperty.$ChildProperty.$Name), [System.Environment]::NewLine))
                        }
                    }
                }
                else {
                    $ErrorValue = [string]$($_.$ParentProperty.$ChildProperty)
                }
                if (-not[string]::IsNullOrEmpty($ErrorValue)) {
                    $ErrorMessage += ('{0}## {1}\{2}:{0}{3}' -f ([System.Environment]::NewLine, $ParentProperty, $ChildProperty, $ErrorValue.Trim()))
                }
            }
        }
    }
    # Write Error Message
    Write-Error -Message $ErrorMessage -ErrorAction 'Continue'
}



Finally {
    $null = Stop-Transcript
}



# Exit
if ($ScriptSuccess) {    
    Write-Output -InputObject ('{0}# Done' -f ([System.Environment]::NewLine))
    Exit 0
}
else {
    Throw 'Script did not succeed.'
    Exit 1
}
