#Requires -Version 5.1
<#
    .SYNOPSIS
        Removes a named shortcut (.lnk) from Desktop and Start Menu for the user who runs this script.

    .PARAMETER ShortcutName
        Name of the shortcut, without the file extension on the end.

    .EXAMPLE
        & .\User_Remove-Shortcut.ps1 -ShortcutName 'Citrix'
#>



# Expected output
[OutputType($null)]



# Input parameters
[CmdletBinding()]
Param (
    [Parameter(Mandatory = $true, HelpMessage = 'Name of the shortcut, do not include file extension')]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({$_ -notlike '*.lnk'})]
    [string] $ShortcutName
)



# PowerShell Preferences
$ErrorActionPreference = 'Continue'



# Assets
## Automatic
$Paths = [string[]]$(
    [string[]](        
        [System.Environment]::GetFolderPath('Desktop'),
        [string]('{0}\Microsoft\Windows\Start Menu\Programs' -f ($env:APPDATA))
    ).Where{Test-Path -Path $_} | Sort-Object -Unique
)
### Check success
if ($Paths.'Count' -eq 0) {
    Write-Error -Message 'FAiled to verify paths for Desktop and Start Menu for current user.' -ErrorAction 'Continue'
    Exit 1
}



# Remove
$Paths.ForEach{
    $Path = [string]('{0}\{1}.lnk' -f ($_,$ShortcutName))
    Write-Output -InputObject $Path
    if (Test-Path -Path $Path) {
        Write-Output -InputObject ('{0}Exists. Deleting..' -f ("`t"))
        $null = Remove-Item -Path $Path -Force -Confirm:$false
        if (-not$?) {
            Write-Error -Message 'Failed to delete.' -ErrorAction 'Continue'
            Exit 1
        }
    }
    else {
        Write-Output -InputObject ('{0}Not found.' -f ("`t"))
    }
}



# Exit
Write-Output -InputObject 'Success'
Exit 1
