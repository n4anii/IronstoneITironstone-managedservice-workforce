<#
    
    SYNOPSIS
        Set's background picture for the current user. 
        User is allowed to change.
        Needs to run in User Context.

    .NOTES
        FileName:    IST-BackGroundImage.ps1
        Author:      Herman Bergsløkken /Ironstone
        Created:     2024-05-15
        Updated:     2024-05-15
#>

$ScriptVersion = "1.0.1.1"
$CurrentPath = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition)
$Global:LogFile = Join-Path -Path ($env:temp) -ChildPath "IST-BackGroundImage.log"

#region DetermineEnrollment
    $IsOOBEComplete = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE\OOBECompletedForOOBEHealth" -Name "AnyoneReadOOBECompleted" -ErrorAction "SilentlyContinue").AnyoneReadOOBECompleted -eq "1"
    $IsDefaultUserSignedIn = (Get-CimInstance -ClassName Win32_LoggedOnUser -ErrorAction 'SilentlyContinue' | Where-Object { $_.Antecedent -like "*defaultuser*" }) -ne $null

    $IsInEnrollment = -not $IsOOBEComplete -and $IsDefaultUserSignedIn
    #endregion
#region Functions
    function Write-LogEntry {
        param (
            [parameter(Mandatory = $true, HelpMessage = "Value added to the log file.")]
            [ValidateNotNullOrEmpty()]
            [string]$Value,

            [parameter(Mandatory = $true, HelpMessage = "Severity for the log entry. 1 for Informational, 2 for Warning and 3 for Error.")]
            [ValidateNotNullOrEmpty()]
            [ValidateSet("1", "2", "3")]
            [string]$Severity
        )
        # Determine log file location
        $LogFilePath = $Global:LogFile
        
        # Construct time stamp for log entry
        if (-not(Test-Path -Path 'variable:global:TimezoneBias')) {
            [string]$global:TimezoneBias = [System.TimeZoneInfo]::Local.GetUtcOffset((Get-Date)).TotalMinutes
            if ($TimezoneBias -match "^-") {
                $TimezoneBias = $TimezoneBias.Replace('-', '+')
            }
            else {
                $TimezoneBias = '-' + $TimezoneBias
            }
        }
        $Time = -join @((Get-Date -Format "HH:mm:ss.fff"), $TimezoneBias)
        
        # Construct date for log entry
        $Date = (Get-Date -Format "MM-dd-yyyy")
        
        # Construct context for log entry
        $Context = $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)
        
        # Construct final log entry
        $LogText = "<![LOG[$($Value)]LOG]!><time=""$($Time)"" date=""$($Date)"" component=""IST-BackgroudImage"" context=""$($Context)"" type=""$($Severity)"" thread=""$($PID)"" file="""">"
        
        # Add value to log file
        try {
            Out-File -InputObject $LogText -Append -NoClobber -Encoding Default -FilePath $LogFilePath -ErrorAction Stop
        }
        catch [System.Exception] {
            Write-Warning -Message "Unable to append log entry to $($Global:LogFile) file. Error message at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
        }
    }
    #endregion

Write-LogEntry -Value "Running version $ScriptVersion off IST-BackGroundImage.ps1 from: $CurrentPath" -Severity 1
Write-LogEntry -Value "Script is currently running in Autopilot Enrollment: $IsInEnrollment" -Severity 1

if (($IsInEnrollment -eq $true) -or ($IsInEnrollment -eq $false)) {
    
Write-LogEntry -Value "This script can run both during enrollment and after" -Severity 1

$ImageUri = 'https://stingray.fotoware.cloud/fotoweb/embed/2023/04/83e11d9f7ba74fee83d6ce84bb3dd787.jpg'

try {
    Write-LogEntry -Value "Downloading the image from the $ImageUri" -Severity 1
    $WebResponse = Invoke-WebRequest -Uri $ImageUri -ErrorAction Stop
} catch {
    $StatusCode = $_.Exception.Response.StatusCode
    Write-LogEntry -Value "Failed to download the required image from $ImageURI with the following Error code: $StatusCode" -Severity 3
    Write-LogEntry -Value "Script failed to run and cannot continue." -Severity 3
    Throw
}

$Base64String = [Convert]::ToBase64String($WebResponse.Content)
$ImageBytes = [Convert]::FromBase64String($Base64String)

$ImagePath = Join-Path -Path "$env:TEMP" -ChildPath 'LogoDark.jpg'

Write-LogEntry -Value "Saving the image to $ImagePath" -Severity 1
[IO.File]::WriteAllBytes($ImagePath, $ImageBytes)


Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class Params
{ 
    [DllImport("User32.dll", CharSet=CharSet.Unicode)]
    public static extern int SystemParametersInfo (Int32 uAction, 
                                                   Int32 uParam, 
                                                   String lpvParam, 
                                                   Int32 fuWinIni);
}
"@  

$SPI_SETDESKWALLPAPER = 0x0014
$UpdateIniFile = 0x01
$SendChangeEvent = 0x02

$Flags = $UpdateIniFile -bor $SendChangeEvent

Write-LogEntry -Value "Setting the image as the desktop background from $($ImagePath)" -Severity 1
$Result = [Params]::SystemParametersInfo($SPI_SETDESKWALLPAPER, 0, $ImagePath, $Flags)

Write-LogEntry -Value "Attempting to remove the image file" -Severity 1
Remove-Item -Path $ImagePath -ErrorAction SilentlyContinue
}