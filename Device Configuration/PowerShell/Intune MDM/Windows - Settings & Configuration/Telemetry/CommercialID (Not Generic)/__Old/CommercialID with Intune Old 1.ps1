<#
    .SYNOPSIS
    Tests if a registry value exists, if not, add it

    .DESCRIPTION
    Tests if a registry value exists, if not, add it
    Written with PowerShell v5.1 documentation

    .USAGE
    Export values from registry, paste it to $RegFile 

    Sources:
    - https://stackoverflow.com/questions/5648931/test-if-registry-value-exists
    - https://stackoverflow.com/questions/29804234/run-registry-file-remotely-with-powershell
    - https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/out-file?view=powershell-5.1
    - https://docs.microsoft.com/en-us/intune/intune-management-extension
    
#>


#region Variables
# Settings
[bool] $Debug = $true
[bool] $DebugDevelopment = $false
[bool] $Overwrite = $true
if ($Debug) {[String] $global:DebugStr=''}

# Scenario specific information
[String] $WhatToConfig = 'Telemetry CommercialID'
[String] $ValuePath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection\'
[String] $ValueName = 'CommercialID'
[String] $Value = '9c16257a-ee3b-4aec-9427-9a2f48077769'

# Registry file
[String] $RegFile = 'Windows Registry Editor Version 5.00'
[String] $RegFile += ("`r`n" + '
[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\DataCollection]
"CommercialID"="9c16257a-ee3b-4aec-9427-9a2f48077769"
')
#endregion Variables



#region Function Test-RegistryKey
Function Test-RegistryKey {
  param(
    [Parameter(Mandatory=$true)]
    [Bool]$WriteDebug
  )
  
  $Exists = Get-ItemProperty -Path ('{0}' -f $ValuePath) -Name ('{0}' -f $ValueName) -ErrorAction SilentlyContinue
  If (($Exists -ne $null) -and ($Exists.Length -ne 0)) {
    If ($Exists.$ValueName -like $Global:Value) {
        If ($Debug -and $WriteDebug) { $global:DebugStr += ($WhatToConfig + ' present in registry: ' + $ValueName + ' exists, and is equal to new value.' + "`r`n" + '(' + $Exists.$ValueName + ' == ' + $Value + ')' + "`r`n") }
        Return $true        
    }
    Else { 
        If ($Debug -and $WriteDebug) { $global:DebugStr += ($WhatToConfig + ' present in registry: ' + $ValueName + ' exists, but is not equal to new value.' + "`r`n" + '(' + $Exists.$Valuename + ' != ' + $Value + ')' + "`r`n") }
        Return $false
    }
  }
  Else {
    If ($Debug -and $WriteDebug) { $global:DebugStr += ($WhatToConfig + ' not present in registry.' + "`r`n") }
    Return $false
  }
}
#endregion Function Test-RegistryKey



#region Write to registry if Test-RegistryKey returns false
If (!(Test-RegistryKey -WriteDebug $true)) {
    [String] $global:TempRegFile = ('C:\Windows\Temp\' + $WhatToConfig + '.reg')
    Out-File -FilePath $TempRegFile -InputObject $RegFile
    If (!($?)) {
         If ($Debug) {$DebugStr += ('- Could not place temp reg file at ' + $TempRegFile + '. ')}  
         $global:TempRegFile = ($env:TEMP + '\' + $WhatToConfig + '.reg')
         If ($Debug) {$DebugStr += ('Trying ' + $TempRegFile + "`r`n")}
         Out-File -FilePath $TempRegFile -InputObject $RegFile
         If (!($)) {
            If ($Debug) {$DebugStr += ('- Success writing to ' + $TempRegFile + '.'+ "`r`n")}
         } Else {
            If ($Debug) {$DebugStr += ('- Could not place temp reg file to ' + $TempRegFile + "`r`n")}
         }        
    }
    
    If ($Overwrite) {
        If ($Debug) {$DebugStr += ('   $Overwrite is true, attempting to write new value' + "`r`n")}
        $RegStatus = reg.exe import ('{0}' -f $Global:TempRegFile) 2>&1
    
        If (!($RegStatus -Like '*completed successfully*' -or $RegStatus -Like '*operasjonen er utf*rt*')) {
            If ($Debug) {
                $DebugStr += ('Error reg.exe' + "`r`n")  
                $DebugStr += ('Reg.exe output:' + "`r`n" + $RegStatus + "`r`n" + ($Error | Select * ) + "`r`n")
            }     
        }
    
        Else {
            If ($Debug) {
                If (Test-RegistryKey -WriteDebug $false) { $DebugStr += ('      Success, ' + $WhatToConfig + ' was written to registry' + "`r`n") }
                Else { $DebugStr += ('      Error, ' + $WhatToConfig + ' was not written to registry.' + "`r`n") }
            }  
        }
    }
    Else {
        If ($Debug) {$DebugStr += ('   $Overwrite is false, wont attempt to write new registry value' + "`r`n")}
    }
}
#endregion Write to registry if Test-RegistryKey returns false



#region Debug
If ($Debug) {
    If ([String]::IsNullOrEmpty($DebugStr)) {
        $DebugStr = 'Everything failed'
    }

    # Write Output
    $DebugPath = 'C:\Windows\Temp\'
    $DebugFileName = ('Debug Powershell ' + $WhatToConfig + '.txt')

    $DebugStr | Out-File -FilePath ($DebugPath + $DebugFileName) -Encoding 'utf8'
    If (!($?)) {
        $DebugStr | Out-File -FilePath ($env:TEMP + '\' + $DebugFileName) -Encoding 'utf8'
    }
    
    # Debug when developing
    If ($DebugDevelopment) {
        Write-Output -InputObject $DebugStr
    }
}
#endregion Debug