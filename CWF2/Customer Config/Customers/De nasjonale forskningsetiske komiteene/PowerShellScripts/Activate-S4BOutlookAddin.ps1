<#
    .NAME
        User_Activate-S4BOutlookAddin.ps1
        Device_Activate-S4BOutlookAddin.ps1

    .SYNOPSIS
        Activates Skype for Business meeting addin in Outlook if the meeting addin exist on the device.
    
    .NOTES
        LoadBehavior
            https://docs.microsoft.com/en-us/visualstudio/vsto/registry-entries-for-vsto-add-ins?view=vs-2017#LoadBehavior
            00 = Unloaded = Do not load automatically
            01 = Loaded   = Do not load automatically
            02 = Unloaded = Load at startup
            03 = Loaded   = Load at startup (Default behavior)
            08 = Unloaded = Load on demand
            09 = Loaded   = Load on demand
            16 = Loaded   = Load first time, then load on demand

        Check if the meeting addin exist using PowerShell
            32-bit
                Test-Path -Path ([string]$('{0}\Microsoft Office\root\Office16\UCADDIN.DLL' -f (${env:ProgramFiles(x86)})))
            64-bit
                Test-Path -Path ([string]$('{0}\Microsoft Office\root\Office16\UCADDIN.DLL' -f ($env:ProgramW6432)))            
#>



# PowerShell preferences
$ErrorActionPreference = 'Stop'



# Settings
$DeviceContext = [bool]$($false)
$LoadBehavior  = [byte]$(3)



# Assets
## Skype for Business meeting plugin path
### Assets
$S4BPluginPathBase = [string]$('Microsoft Office\root\Office16\UCADDIN.DLL')
$S4BPluginPath64   = [string]$('{0}\{1}' -f ($env:ProgramW6432,$S4BPluginPathBase))
$S4BPluginPath32   = [string]$('{0}\{1}' -f (${env:ProgramFiles(x86)},$S4BPluginPathBase))
### Decide actual path or error if not installed
$S4BPluginPath     = [string]$(
    # 64 bit
    if (Test-Path -Path $S4BPluginPath64) {
        $S4BPluginPath64
    }
    # 32 bit
    elseif (Test-Path -Path $S4BPluginPath32) {
        $S4BPluginPath32
    }
    # Not installed
    else {
        Throw 'ERROR: Skype for Business meeting plugin is not installed.'
        Exit 1
    }
)

## Registry path
$Path = [string]('Registry::{0}\Microsoft\Office\Outlook\AddIns\UCAddin.LyncAddin.1' -f ([string]$(if($DeviceContext){'HKEY_LOCAL_MACHINE\SOFTWARE'}else{'HKEY_CURRENT_USER\Software'})))

## Registry values
$RegValues = [PSCustomObject[]]$(
    [PSCustomObject]@{'Path'=$Path;'Type'='String';'Name'='Description'; 'Value'='Skype Meeting Add-in for Microsoft Office'}
    [PSCustomObject]@{'Path'=$Path;'Type'='String';'Name'='FileName';    'Value'=$S4BPluginPath}
    [PSCustomObject]@{'Path'=$Path;'Type'='String';'Name'='FriendlyName';'Value'='Skype Meeting Add-in for Microsoft Office'}
    [PSCustomObject]@{'Path'=$Path;'Type'='DWord'; 'Name'='LoadBehavior';'Value'=$LoadBehavior}
)



# Create registry path if not exist
if (-not(Test-Path -Path $Path)) {
    $null = New-Item -Path $Path -ItemType 'Directory' -Force
}



# Set registry values
foreach ($RegValue in $RegValues) {
    $null = Set-ItemProperty -Path $RegValue.'Path' -Name $RegValue.'Name' -Value $RegValue.'Value' -Type $RegValue.'Type' -Force
}