# Assets - Base
$PathFileIE     = [string]$('%ProgramW6432%\Internet Explorer\iexplore.exe')
$PathDirDesktop = [string]$([System.Environment]::GetFolderPath('Desktop'))


# Assets - Dynamic
$Shortcuts = [PSCustomObject[]]$(
    [PSCustomObject]@{'Name'='Kim';    'TargetPath'=$PathFileIE;'Arguments'='"http://kim/kim"';        'IconLocation'=$PathFileIE},
    [PSCustomObject]@{'Name'='Webinfo';'TargetPath'=$PathFileIE;'Arguments'='"http://webinfo/webinfo"';'IconLocation'=$PathFileIE}
)


# Create Com Object
$WScriptShell = New-Object -ComObject 'WScript.Shell'


# Create Shortcuts
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


# Remove Com Object
$null = Remove-Variable -Name 'WScriptShell' -Force