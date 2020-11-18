<#
    .SYNAPSIS
        Creates shortcuts on the desktop to given websites which are to be opened in Internet Explorer.
#>


# Assets - Base
$PathFileIE      = [string]$('%ProgramW6432%\Internet Explorer\iexplore.exe')
$PathsDirDesktop = [string[]]$([string[]]$([string]$([System.Environment]::GetFolderPath('Desktop')),[string]$('{0}\Desktop' -f ($env:USERPROFILE))) | Where-Object -FilterScript {Test-Path -Path $_} | Select-Object -Unique | Sort-Object)


# Assets - Dynamic
$Shortcuts = [PSCustomObject[]]$(
    [PSCustomObject]@{'Name'='KIM'; 'TargetPath'=$PathFileIE; 'Arguments'='"http://kim/kim"'; 'IconLocation'=$PathFileIE}
)


# Create Com Object
$WScriptShell = New-Object -ComObject 'WScript.Shell'


# Create Shortcuts
foreach ($PathDirDesktop in $PathsDirDesktop) {
    foreach ($Shortcut in $Shortcuts) {
        # Asset
        $PathFileShortcut = [string]$('{0}\{1}.lnk' -f ($PathDirDesktop,$Shortcut.'Name'))

        # Remove existing shortcut with same name
        if (Test-Path -Path $PathFileShortcut) {$null = Remove-Item -Path $PathFileShortcut -Force -ErrorAction 'Stop'}
    
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