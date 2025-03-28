<#
.SYNOPSIS
    Set volume level to 100% for all Recording Devices using PowerShell Module "AudioDeviceCmdlets"

.DESCRIPTION
    Get Default Recording Device (To reset to this afterwards)
    Loop every Recording Device
    Set each recording volume to 100% by first setting device as default, then set volume
    Restore default recording device afterwards
#>



#region    Settings
    # Settings - PowerShell - Output Preferences
    $DebugPreference       = 'SilentlyContinue'
    $InformationPreference = 'SilentlyContinue'
    $VerbosePreference     = 'SilentlyContinue'
    $WarningPreference     = 'Continue'

    # Settings - PowerShell - Interaction
    $ConfirmPreference     = 'None'
    $ProgressPreference    = 'SilentlyContinue'

    # Settings - PowerShell - Behaviour
    $ErrorActionPreference = 'Continue'

    # Settings - Script
    [bool] $Script:Unmute  = $true
#endregion Settings




#region    Logging
    # Variables - Static
    [bool]   $Script:Success    = $true
    [string] $NameScript        = ('Set-RecordingDeviceVolumeMax')

    # Variables - Environment Info
    [string] $StrUserName = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    [string] $StrIsAdmin  = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    [string] $ProcessArchitecture = $(if([System.Environment]::Is64BitProcess){'64'}Else{'32'})
    [string] $OSArchitecture      = $(if([System.Environment]::Is64BitOperatingSystem){'64'}Else{'32'})

    # Variables - Logging
    [string] $NameScriptNoun    = $NameScript.Split('-')[-1]
    [string] $NameScriptFile    = ('Set-{0}.ps1' -f ($NameScriptNoun))
    [string] $NameScheduledTask = ('Run-{0}' -f ($NameScriptNoun))
    [string] $PathDirLog        = ('{0}\IronstoneIT\{1}\Logs\' -f ($(if($StrIsAdmin -eq 'True'){$env:ProgramW6432}else{$env:APPDATA}),$NameScriptNoun))
    [string] $PathFileLog       = ('{0}{1}-{2}.txt' -f ($PathDirLog,$NameScriptNoun,([DateTime]::Now.ToString('yyMMdd-HHmmssffff'))))
    
    # Start transcript
    if (-not(Test-Path -Path $PathDirLog)){New-Item -Path $PathDirLog -ItemType 'Directory' -Force}
    Start-Transcript -Path $PathFileLog
#endregion Logging




#region    Debug
    Write-Output -InputObject ('**********************')
    Write-Output -InputObject ('PowerShell is running as a {0} bit process on a {1} bit OS.' -f ($ProcessArchitecture,$OSArchitecture))
    Write-Output -InputObject ('Running as user "{0}". Has admin privileges? {1}' -f ($StrUserName,$StrIsAdmin))
    Write-Output -InputObject ('**********************')
#endregion Debug




#region    Main
    Try {
        # Import AudioDeviceCmdlets module manually (Latest Version)
        [string] $PathDirModule       = ('{0}\WindowsPowerShell\Modules\AudioDeviceCmdlets' -f ($env:ProgramW6432))
        [string] $VersionModuleLatest = ([System.Version[]](@(Get-ChildItem -Path $PathDirModule -Directory | Select-Object -ExpandProperty Name)) | Sort-Object)[-1].ToString()
        [string] $PathModuleLatest    = ('{0}\{1}' -f ($PathDirModule,$VersionModuleLatest))
        Get-ChildItem -Path $PathModuleLatest -File | Select-Object -ExpandProperty FullName | ForEach-Object {Import-Module -Name $_}
        
        
        # If modules import failed
        if (@(Get-Module | Where-Object -Property 'Name' -EQ 'AudioDeviceCmdlets').Count -lt 1) {
            Write-Output -InputObject ('Failed to import PowerShell Module "AudioDeviceCmdlets"')
            $Script:Success = $false
        }


        # If modules import succeeded - Loop through recording devices, set Recording Volume to 100%
        else {    
            $RecordingDeviceDefault = Get-AudioDevice -Recording | Select-Object -Property 'Name','ID'
            $RecordingDeviceAll     = @((Get-AudioDevice -List | Where-Object -Property 'Type' -EQ 'Recording') | Select-Object -Property 'Name','ID')
            if ($RecordingDeviceAll.Count -eq 0) {
                Write-Output -InputObject ('Found no recording devices.')
                $Script:Success = $false
            }
            else {
                foreach ($Device in $RecordingDeviceAll) {
                    # Set Default Recording Device
                    $null = Set-AudioDevice $Device.ID
                    [bool] $Local:Success_SetDefaultDevice = $?
                    Write-Output -InputObject ('Setting "{0}" as default recording device. Success? {1}.' -f ($Device.Name,$Local:Success_SetDefaultDevice.ToString()))
                    
                    # Set Volume to 100%
                    $null = Set-AudioDevice -RecordingVolume 100
                    [bool] $Local:Success_SetVolume = $?
                    Write-Output -InputObject ('Setting volume to 100%. Success? "{0}".' -f ($Local:Success_SetVolume.ToString()))

                    # Check if muted, unmute if it is
                    if ([bool](Get-AudioDevice -RecordingMute) -and $Script:Unmute){
                        $null = Set-AudioDevice -RecordingMute $false
                        [bool] $Local:Success_Unmute = $?
                        Write-Output -InputObject ('Unmuting current recording device. Success? "{0}".' -f ($Local:Success_Unmute.ToString()))
                    }
                    else {[bool] $Local:Success_Unmute = $true}
                    
                    # Stats
                    if (-not($Local:Success_SetDefaultDevice -or $Local:Success_SetVolume -or $Local:Success_Unmute)){$Script:Success = $false}
                }
                
                # Set Default Recording Device back to what it was
                $null = Set-AudioDevice $RecordingDeviceDefault.ID
                $Local:Success_RevertDefault = $?
                Write-Output -InputObject ('Reverting "{0}" back as default recording device. Success? {1}.' -f ($RecordingDeviceDefault.Name,$Local:Success_RevertDefault.ToString()))
                if(-not($Local:Success_RevertDefault)){$Script:Success = $Local:Success_RevertDefault}
            }
        }
    }
#endregion Main




#region    Catch and Finally
    Catch {
        $Script:Success = $false
        # Construct Message
        [string] $ErrorMessage = ('{0} finished with errors:' -f ($NameScript))
        $ErrorMessage += ('{0}{0}Exception:{0}' -f ("`r`n"))
        $ErrorMessage += $_.Exception
        $ErrorMessage += ('{0}{0}Activity:{0}' -f ("`r`n"))
        $ErrorMessage += $_.CategoryInfo.Activity
        $ErrorMessage += ('{0}{0}Error Category:{0}' -f ("`r`n"))
        $ErrorMessage += $_.CategoryInfo.Category
        $ErrorMessage += ('{0}{0}Error Reason:{0}' -f ("`r`n"))
        $ErrorMessage += $_.CategoryInfo.Reason
        # Write Error Message
        Write-Error -Message $ErrorMessage
    }
    Finally {
        Stop-Transcript
        if ($Script:Success -and $VerbosePreference -ne 'Continue') {Remove-Item -Path $PathFileLog -Force}
    }
#endregion Catch and Finally