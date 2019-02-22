<#
.SYNOPSIS
    Activates Windows 10 Enterprise using a MAK key provided in the script.


.DESCRIPTION



.OUTPUTS
    Weather it succeeded or not.

#>


# Script Variables
[bool]   $DeviceContext = $true
[string] $NameScript    = 'Activate-Win10EnterpriseMAK(Backe)'

# Settings - PowerShell - Output Preferences
$DebugPreference       = 'SilentlyContinue'
$InformationPreference = 'SilentlyContinue'
$VerbosePreference     = 'Continue'
$WarningPreference     = 'Continue'


#region    Don't Touch This
# Settings - PowerShell - Interaction
$ConfirmPreference     = 'None'
$ProgressPreference    = 'SilentlyContinue'

# Settings - PowerShell - Behaviour
$ErrorActionPreference = 'Continue'

# Dynamic Variables - Process & Environment
[string] $NameScriptFull      = ('{0}_{1}' -f ($(if($DeviceContext){'Device'}else{'User'}),$NameScript))
[string] $NameScriptVerb      = $NameScript.Split('-')[0]
[string] $NameScriptNoun      = $NameScript.Split('-')[-1]
[string] $ProcessArchitecture = $(if([System.Environment]::Is64BitProcess){'64'}else{'32'})
[string] $OSArchitecture      = $(if([System.Environment]::Is64BitOperatingSystem){'64'}else{'32'})

# Dynamic Variables - User
[string] $StrIsAdmin       = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
[string] $StrUserName      = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
[string] $SidCurrentUser   = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
[string] $SidSystemUser    = 'S-1-5-18'
[bool] $CurrentUserCorrect = $(
    if($DeviceContext -and $SIDCurrentUser -eq $SIDSystemUser){$true}
    elseif (-not($DeviceContext) -and $SIDCurrentUser -ne $SIDSystemUser){$true}
    else {$false}
)

# Dynamic Logging Variables
$Timestamp    = [DateTime]::Now.ToString('yyMMdd-HHmmssffff')
$PathDirLog   = ('{0}\IronstoneIT\Intune\DeviceConfiguration\' -f ($(if($DeviceContext -and $CurrentUserCorrect){$env:ProgramW6432}else{$env:APPDATA})))
$PathFileLog  = ('{0}{1}-{2}bit-{3}.txt' -f ($PathDirLog,$NameScriptFull,$ProcessArchitecture,$Timestamp))

# Start Transcript
if (-not(Test-Path -Path $PathDirLog)) {New-Item -ItemType 'Directory' -Path $PathDirLog -ErrorAction 'Stop'}
Start-Transcript -Path $PathFileLog

# Output User Info, Exit if not $CurrentUserCorrect
Write-Output -InputObject ('Running as user "{0}". Has admin privileges? {1}. $DeviceContext = {2}. Running as correct user? {3}.' -f ($StrUserName,$StrIsAdmin,$DeviceContext.ToString(),$CurrentUserCorrect.ToString()))
if (-not($CurrentUserCorrect)){Throw 'Not running as correct user!'} 

# Output Process and OS Architecture Info
Write-Output -InputObject ('PowerShell is running as a {0} bit process on a {1} bit OS.' -f ($ProcessArchitecture,$OSArchitecture))


# Wrap in Try/Catch, so we can always end the transcript
Try {    
    # If OS is 64 bit, and PowerShell got launched as x86, relaunch as x64
    if ( (-not([System.Environment]::Is64BitProcess))  -and [System.Environment]::Is64BitOperatingSystem) {
        write-Output -InputObject (' * Will restart this PowerShell session as x64.')
        if ($myInvocation.Line) {
            &"$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile $myInvocation.Line
        }
        else {
            &"$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile -File ('{0}' -f ($myInvocation.InvocationName)) $args
        }
        exit $lastexitcode
    }
    
    # End the Initialize Region
    Write-Output -InputObject ('**********************')
#endregion Don't Touch This
################################################
#region    Your Code Here
################################################


    #region    ONLY EDIT THESE VARIABLES
    [string] $EntMAKKey = 'D2DB6-7NFB3-GV9K7-Y9BBD-M7V2F'              # 25 Characters, like 'xXxXx-XxXxX-xXxXx-XxXxX-xXxXx'
    #endregion ONLY EDIT THESE VARIABLES



    #region    Variables
    # Settings
    [bool] $Script:ReadOnly     = $false

    # Script Specific Variables
    [string] $EntKMSClientSetupKey = ('NPPR9-FWDCX-D2C8J-H872K-2YT43')
    [string] $PartialEntClientSetupKey = $EntKMSClientSetupKey.Substring(0,5)
    #endregion Variables



    #region Functions     
        #region Get-ActivationStatus
        function Get-ActivationStatus {
            param(
                [Parameter(Mandatory=$true, Position=0)]
                [string] $HostName
            )
            Try {
                $wpa = Get-WmiObject -Class 'SoftwareLicensingProduct' -ComputerName $HostName `
                -Filter "ApplicationID = '55c92734-d682-4d71-983e-d6ec3f16059f'" `
                -Property 'LicenseStatus' -ErrorAction 'Stop'
            } 
            Catch {
                $status = New-Object -TypeName 'ComponentModel.Win32Exception' -ArgumentList ($_.Exception.ErrorCode)
                $wpa = $null    
            }
            $out = New-Object -TypeName psobject -Property @{
                ComputerName = $HostName
                Status = [string]::Empty
            }
            if ($wpa) {
                :outer foreach($item in $wpa) {
                    switch ($item.LicenseStatus) {
                        0 {$out.Status = 'Unlicensed'}
                        1 {$out.Status = 'Licensed'; break outer}
                        2 {$out.Status = 'Out-Of-Box Grace Period'; break outer}
                        3 {$out.Status = 'Out-Of-Tolerance Grace Period'; break outer}
                        4 {$out.Status = 'Non-Genuine Grace Period'; break outer}
                        5 {$out.Status = 'Notification'; break outer}
                        6 {$out.Status = 'Extended Grace'; break outer}
                        Default {$out.Status = 'Unknown value'}
                    }
                }
            } 
            else {$out.Status = $status.Message}
            $out
        }
        #endregion Get-ActivationStatus
    

        #region Activate-WinWithKey
        function Activate-WinWithKey {
            param(
                [Parameter(Mandatory=$true, Position=0)]
                [string] $Key
            )
            [string] $CompName = $env:COMPUTERNAME
        
            $ActivationService = Get-WmiObject -Query 'select * from SoftwareLicensingService' -ComputerName $CompName
            $null = $ActivationService.InstallProductKey($Key)
            $null = Start-Job -ScriptBlock {$ActivationService.RefreshLicenseStatus()} | Wait-Job
            $Job = Invoke-Command -ComputerName $CompName -ScriptBlock {$ActivationService.RefreshLicenseStatus()} -AsJob
            $ActStatus = Get-ActivationStatus -HostName $CompName
            if ($ActStatus.Status -like 'Licensed') {
                Write-Verbose -Message  ('      Success, Windows is activated!')
            }
            else {
                Write-Verbose -Message  ('      Fail, Windows is not activated!')
            }
        }
        #endregion Activate-WinWithKey


        #region Query-Registry
        function Query-Registry {
            Param ([Parameter(Mandatory=$true)] [String] $Dir)
            $Local:Out = [String]::Empty
            [string] $Local:Key = $Dir.Split('{\}')[-1]
            [string] $Local:Dir = $Dir.Replace($Local:Key,'')
        
            $Local:Exists = Get-ItemProperty -Path ('{0}' -f $Dir) -Name ('{0}' -f $Local:Key) -ErrorAction 'SilentlyContinue'
            if ($Exists) {
                $Local:Out = $Local:Exists.$Local:Key
            }
            return $Local:Out
        }
        #endregion Query-Registry


        #region Get-MachineInfo
        function Get-MachineInfo {
            $Script:ComputerName = $env:COMPUTERNAME
            [string] $Script:ComputerManufacturer = Query-Registry -Dir 'HKLM:\HARDWARE\DESCRIPTION\System\BIOS\SystemManufacturer'
            if (-not([string]::IsNullOrEmpty($Script:ComputerManufacturer))) {
                [string] $Script:ComputerFamily = Query-Registry -Dir 'HKLM:\HARDWARE\DESCRIPTION\System\BIOS\SystemFamily'
                [string] $Script:ComputerProductName = Query-Registry -Dir 'HKLM:\HARDWARE\DESCRIPTION\System\BIOS\SystemProductName'
                [string] $Script:WindowsEdition = Query-Registry -Dir 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProductName'
                [string] $Script:WindowsVersion = Query-Registry -Dir 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ReleaseId'
                [string] $Script:WindowsVersion += (' ({0})' -f (Query-Registry -Dir 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\CurrentBuild'))
            } 
            else {
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




    #region Main    
        Write-Verbose -Message ("`r`n" + '### {0}' -f ($NameScript))
        Get-MachineInfo

        # Get activation status
        $ActStatus = Get-ActivationStatus -HostName $env:COMPUTERNAME
        if ($ActStatus.Status -like 'Licensed') {
            Write-Verbose -Message ('  Activation Status: Licensed')
        } 
        else {
            Write-Verbose -Message ('  Activation Status: Not licensed.')
            if ($WindowsEdition -Like '*enterprise*') {
                if (-not($ReadOnly)) {
                    Write-Verbose -Message  ('    ReadOnly is off, trying to activate.')
                    Activate-WinWithKey -Key $EntMAKKey
                }
                else {
                    Write-Verbose -Message ('    ReadOnly is on, will not attempt to activate')
                }
            }
            else {
                Write-Verbose -Message  ("`n`n" + '    Process stopped: This will only work for Enterprise Edition')
            }
        }
    #endregion Main


################################################
#endregion Your Code Here
################################################   
#region    Don't touch this
}
Catch {
    # Construct Message
    $ErrorMessage = ('{0} finished with errors:' -f ($NameScriptFull))
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
#endregion Don't touch this