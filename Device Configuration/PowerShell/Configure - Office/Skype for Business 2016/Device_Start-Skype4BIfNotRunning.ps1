#Requires -RunAsAdministrator
<#
.SYNAPSIS
This script will start Skype 4 Business if it's not already running.

.DESCRIPTION
This script will start Skype 4 Business if it's not already running.

.RESOURCES

.NOTES
* It will only keep logs if it fails.
* Use Scheduled Task to set how often it should run.
    
#>

# Variables
[string] $NameScript     = ('Run-Skype4BForcer')
[string] $NameScriptNoun = $NameScript.Split('-')[-1]
[string] $PathDirLog     = ('{0}\IronstoneIT\{1}\Logs' -f ($env:ProgramW6432,$NameScriptNoun))
[string] $PathFileLog    = ('{0}\Log-{1}-{2}.txt' -f ($PathDirLog,$NameScriptNoun,[DateTime]::Now.ToString('yyyyMMdd-HHmmssffff')))

# Logging
if(-not(Test-Path -Path $PathDirLog)){$null = New-Item -Path $PathDirLog -ItemType Directory -Force}
Start-Transcript -Path $PathFileLog



# Try to start Skype for Business if not currently running
Try {
    if (@(Get-Process -Name 'lync' -ErrorAction SilentlyContinue).Count -ne 0) {
        Write-Output -InputObject ('Skype for Business is already running.')
    }
    else {
        Write-Output -InputObject ('Skype for Business is not currently running.')
    
        # Get Skype for Business Path, no matter version (2015,2016..) and architecture (x86/x64)
        [string] $PathFileSkype4B = Get-ChildItem -Path (Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall' | `
            ForEach-Object {Get-ItemProperty $_.PsPath} | Where-Object {$_.DisplayName -like 'Microsoft Office*'} | `
            Sort-Object -Property DisplayName | Select-Object -ExpandProperty InstallLocation -First 1) -Recurse -File -Filter 'lync.exe' | `
            Select-Object -ExpandProperty FullName -First 1
    
        # Exit if lync.exe was not found
        if ([string]::IsNullOrEmpty($PathFileSkype)) {
            Write-Error -Message 'Could not find Skype for Business.'
        }

        # If lync.exe was found, start Skype for Business!
        else {
            Start-Process -FilePath $PathFileSkype
            if ($? -and @(Get-Process -Name 'lync' -ErrorAction SilentlyContinue).Count -ne 0) {
                Write-Output -InputObject ('SUCCESS: Managed to start Skype for Business.')
            }
            else {
                Write-Error -Message ('ERROR: Did not manage to start Skype for Business.')
            }
        }
    } 
}


# Catch Errors
Catch {
    # Construct Message
    [string] $ErrorMessage = ('{0} finished with errors:' -f ($NameScriptFull))
    $ErrorMessage += "`r`n"
    $ErrorMessage += 'Exception: '
    $ErrorMessage += $_.Exception
    $ErrorMessage += "`r`n"
    $ErrorMessage += 'Activity: '
    $ErrorMessage += $_.CategoryInfo.Activity
    $ErrorMessage += "`r`n"
    $ErrorMessage += 'Error Category: '
    $ErrorMessage += $_.CategoryInfo.Category
    $ErrorMessage += "`r`n"
    $ErrorMessage += 'Error Reason: '
    $ErrorMessage += $_.CategoryInfo.Reason
    # Write Error Message
    Write-Error -Message $ErrorMessage
}


# Make sure to Stop Transcript no matter what
Finally {
    # Stop Transcript
    Stop-Transcript
    # Delete log if success
    if (@(Get-Process -Name 'lync' -ErrorAction SilentlyContinue).Count -ne 0) {$null = Remove-Item -Path $PathFileLog -Force}
}