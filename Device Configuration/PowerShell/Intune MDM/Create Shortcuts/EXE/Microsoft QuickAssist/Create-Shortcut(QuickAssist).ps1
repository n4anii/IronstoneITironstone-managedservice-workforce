<#
    .NAME
        Create-Shortcut(QuickAssist).ps1

    .DESCRIPTION
        Install
            "%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy "Bypass" -NoLogo -NonInteractive -NoProfile -WindowStyle "Hidden" -Command "& '.\Create-Shortcut(QuickAssist).ps1'; exit $LASTEXITCODE"

        Uninstall
            "%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy "Bypass" -NoLogo -NonInteractive -NoProfile -WindowStyle "Hidden" -Command "& '.\Remove-Shortcut(QuickAssist).ps1'; exit $LASTEXITCODE"
#>


# Assets
$PathsDirDesktop = [string[]]$([string[]]$([string]$([System.Environment]::GetFolderPath('Desktop')),[string]$('{0}\Desktop' -f ($env:USERPROFILE))) | Where-Object -FilterScript {Test-Path -Path $_} | Sort-Object -Unique)
$PathProgram     = [string]('{0}\quickassist.exe' -f ([System.Environment]::SystemDirectory))


# Assets - Dynamic
$Shortcuts = [PSCustomObject[]]$(
    [PSCustomObject]@{
        'Name'         = 'Hurtighjelp.lnk'
        'TargetPath'   = $PathProgram
        'Arguments'    = ''
        'IconLocation' = $PathProgram
    }
)


# Create Com Object
$WScriptShell = New-Object -ComObject 'WScript.Shell'


# Create Shortcuts
foreach ($PathDirDesktop in $PathsDirDesktop) {
    foreach ($Shortcut in $Shortcuts) {
        # Asset
        $PathFileShortcut = [string]$('{0}\{1}.lnk' -f ($PathDirDesktop,$Shortcut.'Name'))

        # Remove existing shortcut with same name
        if (Test-Path -Path $PathFileShortcut) {
            $null = Remove-Item -Path $PathFileShortcut -Force -ErrorAction 'Stop'
        }
    
        # Create shortcut
        $ShortcutPSObject = $WScriptShell.CreateShortcut($PathFileShortcut)
        $ShortcutPSObject.'TargetPath'   = $Shortcut.'TargetPath'
        $ShortcutPSObject.'Arguments'    = $Shortcut.'Arguments'
        $ShortCutPSObject.'IconLocation' = $Shortcut.'IconLocation'
        $ShortCutPSObject.'WindowStyle'  = 1
        $ShortcutPSObject.Save()
    }
}


# Remove Com Object
$null = Remove-Variable -Name 'WScriptShell' -Force
