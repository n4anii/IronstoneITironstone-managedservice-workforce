<#
    .SYNOPSIS
    Checks and adds (if wrong or missing) CommercialID.

    .DESCRIPTION
    Checks and adds (if wrong or missing) CommercialID.
    Telemetry level is set by Intune => Device Configuration => Device Restrictions policy

    .USAGE
    - Get Telemetry CommercialID from OMS Workspace 
        - OMS -> Settings -> Connected Sources -> Windows Telemetry -> Commercial ID Key
            - Or 'Upgrade readiness' solution -> Settings
        - Set variable $Value to the value from OMS
    - Set telemetry level (0 = Off, 1 = Security, 2 = enchanced, 3 = Full) 

    .NOTES
    Must be run in device context
    This script is NOT GENERIC: You must change variables accordingly

    Sources:
    - https://stackoverflow.com/questions/5648931/test-if-registry-value-exists
    - https://stackoverflow.com/questions/29804234/run-registry-file-remotely-with-powershell
    - https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/out-file?view=powershell-5.1
    - https://docs.microsoft.com/en-us/intune/intune-management-extension
    - ValueKind: https://msdn.microsoft.com/en-us/library/microsoft.win32.registryvaluekind.aspx
    
#>

<#

.SYNOPSIS


.DESCRIPTION


.NOTES
You need to run this script in the DEVICE context in Intune.

#>


#Change the app name
$AppName = 'Device_Add-Registry-TelemetryCommercialID(Customer)'
$Timestamp = Get-Date -Format 'HHmmssffff'
$LogDirectory = ('{0}\Program Files\IronstoneIT\Intune\DeviceConfiguration' -f $env:SystemDrive)
$Transcriptname = ('{2}\{0}_{1}.txt' -f $AppName, $Timestamp, $LogDirectory)
$ErrorActionPreference = 'continue'

if (!(Test-Path -Path $LogDirectory)) {
    New-Item -ItemType Directory -Path $LogDirectory -ErrorAction Stop
}

Start-Transcript -Path $Transcriptname
#Wrap in a try/catch, so we can always end the transcript
Try {
    # Get the ID and security principal of the current user account
    $myWindowsID = [Security.Principal.WindowsIdentity]::GetCurrent()
    $myWindowsPrincipal = new-object -TypeName System.Security.Principal.WindowsPrincipal -ArgumentList ($myWindowsID)
 
    # Get the security principal for the Administrator role
    $adminRole = [Security.Principal.WindowsBuiltInRole]::Administrator
 
    # Check to see if we are currently running "as Administrator"
    if (!($myWindowsPrincipal.IsInRole($adminRole))) {
        # We are not running "as Administrator" - so relaunch as administrator
   
        # Create a new process object that starts PowerShell
        $newProcess = new-object -TypeName System.Diagnostics.ProcessStartInfo -ArgumentList 'PowerShell'
   
        # Specify the current script path and name as a parameter
        $newProcess.Arguments = $myInvocation.MyCommand.Definition
   
        # Indicate that the process should be elevated
        $newProcess.Verb = 'runas'
   
        # Start the new process
        [Diagnostics.Process]::Start($newProcess)
   
        # Exit from the current, unelevated, process
        Write-Output -InputObject 'Restart in elevated'
        exit
   
    }

    #64-bit invocation
    if ($env:PROCESSOR_ARCHITEW6432 -eq 'AMD64') {
        write-Output -InputObject "Y'arg Matey, we're off to the 64-bit land....."
        if ($myInvocation.Line) {
            &"$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile $myInvocation.Line
        }
        else {
            &"$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile -file ('{0}' -f $myInvocation.InvocationName) $args
        }
        exit $lastexitcode
    }
 
 
 
    ####################################


    #region EDIT THESE VALUES ONLY
    [string] $Script:NameCustomer = 'IronStoneIT'                    # Customer name, no spaces.   EX: 'IronStoneIT'
    [string] $Script:CommercialID = '0214110f-01c5-431f-899b-8bb6e6ed65e9'                    # CommercialID, from OMS.     EX: '0214110f-01c5-431f-899b-8bb6e6ed65e9'
    [byte] $Script:TelemetryLevel = 2                     # Telemetry Level: 0=Security | 1=Basic | 2=Enchanced | 3=Full
    #endregion EDIT THESE VALUES ONLY



    #region Variables
        # Settings - PowerShell
        $VerbosePreference     = 'Continue'
        $WarningPreference     = 'Continue'
        $ErrorActionPreference = 'Continue'
        # Settings - Script
        [bool] $Script:WriteChanges   = $true
        # Dynamic Variables
        [string] $Script:AppName = ('Device_Add-Registry-TelemetryCommercialID({0})' -f ($Script:NameCustomer))
    #endregion Variables



    #region Functions  
        #region    Set-RegistryDir
        Function Set-RegistryDir {
            Param(
                [Parameter(Mandatory=$true, Position=0)]
                [string] $Dir
            )
            if (-not(Test-Path -Path $Dir)) {
                    Write-Verbose -Message '   Reg dir does not exist, trying to create'
                    if ($WriteChanges) {
                        $null = New-Item -ItemType Directory -Force -Path $Dir 2>&1
                        if ($? -and (Test-Path -Path $Dir)) {Write-Verbose -Message '      SUCCESS: Dir was created'}
                        else {Write-Verbose -Message '      ERROR: Dir could not be created'}
                    }
                    else {Write-Verbose -Message '      ReadOnly mode'}
                } 
            else {Write-Verbose -Message '   Reg dir does already exist'} 
        }
        #endregion Set-RegistryDir


        #region    Set-RegistryValue
        Function Set-RegistryValue {
            Param(
                [Parameter(Mandatory=$true)]
                [string] $Dir, 
            
                [Parameter(Mandatory=$true)]
                [string] $Key,
            
                [Parameter(Mandatory=$true)]
                [ValidateSet('REG_BINARY','REG_DWORD','REG_QWORD','REG_SZ','REG_MULTI_SZ','REG_EXPAND_SZ')]
                [string] $ValType,
            
                [Parameter(Mandatory=$true)]
                $Val
            )
            Write-Verbose -Message ('Dir: {0} | Key: {1} | Val: {2} | ValType = {3}' -f ($Dir,$Key,$Val,$ValType))
        
            # Validate input
            if ($ValType -eq 'REG_DWORD') {
                [string] $Local:Type = 'DWord'
                $Val = [int32] $Val
                if (-not($?)) {
                    Write-Verbose -Message 'Error, could not convert value to int32.'
                    return $false
                }       
            }
            elseif ($ValType -eq 'REG_SZ') {
                [string] $Local:Type = 'String'
                $Val = [string] $Val
                if (-not($?)) {
                    Write-Verbose -Message 'Error, could not convert value to string.'
                    return $false
                }
            }
            else {
                Write-Verbose -Message 'Function is only capable of REG_DWORD and REG_STRING for now.'
                return $false
            }      
        
            # Check if path exists, create if doesn't
            Set-RegistryDir $Dir
            # Continue only if Dir exists or gets created successfully
            if (Test-Path -Path $Dir) {
                [bool] $Local:WriteNewValue = $true
            
                # Check if key exists
                $Exists = Get-ItemProperty -Path ('{0}' -f $Dir) -Name ('{0}' -f $Key) -ErrorAction SilentlyContinue
                # If key does not exist
                if (-not($Exists)) {
                    Write-Verbose -Message '   Key does not exist. Creating key and setting value'
                }
                # If key does exist   
                else {
                    # Don't write new value if new key is the same
                    if ($Exists.$Key -eq $Val) {
                        Write-Verbose -Message '   Key does exist, and value is the same as the new one'
                        $Local:WriteNewValue = $false
                    }
                    # Write new key if key is not the same
                    else {
                        Write-Verbose -Message '   Key does exist, but is not equal to the new one. Trying to change it'
                    }
                }
            
                # Write new value if $WriteNewValue and $WriteChanges
                if ($Local:WriteNewValue -and $WriteChanges) {
                    $null = Set-ItemProperty -Path $Dir -Name $Key -Value $Val -Type $Local:Type 2>&1                       
                }


                # Final check
                if (-not($WriteChanges)) {
                    Write-Verbose -Message '      ReadOnly mode, succeeded in checking reg value'
                }
                else {
                    $Exists = Get-ItemProperty -Path ('{0}' -f $Dir) -Name ('{0}' -f $Key) -ErrorAction SilentlyContinue
                    if ($Exists) {
                        if ($Exists.$Key -eq $Val) {
                        Write-Verbose -Message '      SUCCESS: Key is correct'}
                        else {Write-Verbose -Message '      ERROR: Key does exist | Val was not set'}
                    }
                    else {Write-Verbose -Message '      ERROR: Key does not Exist | Val was not set'}
                }
            }
        }
        #endregion Set-RegistryValue
    
    
        #region    Query-Registry
        Function Query-Registry {
            Param ([Parameter(Mandatory=$true)] [String] $Dir)
            $Local:Out = [String]::Empty
            [string] $Local:Key = $Dir.Split('{\}')[-1]
            [string] $Local:Dir = $Dir.Replace($Local:Key,'')
        
            $Local:Exists = Get-ItemProperty -Path ('{0}' -f $Dir) -Name ('{0}' -f $Local:Key) -ErrorAction SilentlyContinue
            if ($Exists) {
                $Local:Out = $Local:Exists.$Local:Key
            }
            return $Local:Out
        }
        #endregion Query-Registry


        #region    Get-MachineInfo
        Function Get-MachineInfo {
            $Script:ComputerName = $env:COMPUTERNAME
            [string] $Script:ComputerManufacturer = Query-Registry -Dir 'HKLM:\HARDWARE\DESCRIPTION\System\BIOS\SystemManufacturer'
            If (-not([string]::IsNullOrEmpty($Script:ComputerManufacturer))) {
                [string] $Script:ComputerFamily = Query-Registry -Dir 'HKLM:\HARDWARE\DESCRIPTION\System\BIOS\SystemFamily'
                [string] $Script:ComputerProductName = Query-Registry -Dir 'HKLM:\HARDWARE\DESCRIPTION\System\BIOS\SystemProductName'
                [string] $Script:WindowsEdition = Query-Registry -Dir 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProductName'
                [string] $Script:WindowsVersion = Query-Registry -Dir 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ReleaseId'
                [string] $Script:WindowsVersion += (' ({0})' -f (Query-Registry -Dir 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\CurrentBuild'))
            } 
            Else {
                $Local:EnvInfo = Get-WmiObject -Class Win32_ComputerSystem | Select-Object -Property Manufacturer,Model,SystemFamily        
                [string] $Script:ComputerManufacturer = $Local:EnvInfo.Manufacturer
                [string] $Script:ComputerFamily = $Local:EnvInfo.SystemFamily
                [string] $Script:ComputerProductName = $Local:EnvInfo.Model
                $Local:OSInfo = Get-WmiObject -Class win32_operatingsystem | Select-Object -Property Caption,Version
                [string] $Script:WindowsEdition = $Local:OSInfo.Caption
                [string] $Script:WindowsVersion = $Local:OSInfo.Version
            }
        }
        #endregion Get-MachineInfo
    #endregion Functions




    #region Initialize
        Get-MachineInfo
        Write-Output -InputObject '### Environment Info'
        Write-Output -InputObject ('Settings - PowerShell: VerbosePreference = "{0}", WarningPreference = "{1}", ErrorActionPreference = "{2}"' -f ($VerbosePreference,$WarningPreference,$ErrorActionPreference))
        Write-Output -InputObject ('Settings - Script:     WriteChanges = "{0}"' -f ($Script:WriteChanges))
        Write-Output -InputObject ('Machine info: Name = "{0}", Manufacturer = "{1}", Family = "{2}", Model = "{3}"' -f ($Script:ComputerName,$Script:ComputerManufacturer,$Script:ComputerFamily,$Script:ComputerProductName))
        Write-Output -InputObject ('Windows info: Edition = "{0}", Version = "{1}"' -f ($Script:WindowsEdition,$Script:WindowsVersion))
    #endregion Initialize




    #region Main
    Write-Output -InputObject ("`r`n" + '### ' + $Script:AppName)
    [string[]] $Local:Dir               = @('HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection\',
                                            'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection')
    [string]   $Local:KeyCommercialID   = 'CommercialID'
    [string[]] $Local:KeyAllowTelemetry = @('AllowTelemetry','AllowTelemetry_PolicyManager')
    foreach ($D in $Local:Dir) {
        Set-RegistryValue -Dir $D -Key $Local:KeyCommercialID -Val $Script:CommercialID -ValType 'REG_SZ'
        foreach ($Key in $Local:KeyAllowTelemetry) {
            Set-RegistryValue  -Dir $D -Key $Key -Val $Script:TelemetryLevel -ValType 'REG_DWORD'
        }  
    }
    #endregion Main



    ####################################
 
 
    
}
Catch {
    # Construct Message
    $ErrorMessage = 'Unable to uninstall all AppxProvisionedPackages.'
    $ErrorMessage += " `n"
    $ErrorMessage += 'Exception: '
    $ErrorMessage += $_.Exception
    $ErrorMessage += " `n"
    $ErrorMessage += 'Activity: '
    $ErrorMessage += $_.CategoryInfo.Activity
    $ErrorMessage += " `n"
    $ErrorMessage += 'Error Category: '
    $ErrorMessage += $_.CategoryInfo.Category
    $ErrorMessage += " `n"
    $ErrorMessage += 'Error Reason: '
    $ErrorMessage += $_.CategoryInfo.Reason
    Write-Error -Message $ErrorMessage
}
Finally {
    Stop-Transcript
}