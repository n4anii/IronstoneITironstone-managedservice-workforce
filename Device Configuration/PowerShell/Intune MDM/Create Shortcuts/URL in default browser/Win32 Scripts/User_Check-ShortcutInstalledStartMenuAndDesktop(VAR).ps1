# Assets
## Manual
$ShortcutName = ''

## Automatic
$Paths = [string[]]$(
    [string[]](
        [string]('{0}\Desktop' -f ($env:USERPROFILE)),
        [System.Environment]::GetFolderPath('Desktop'),
        [string]('{0}\Microsoft\Windows\Start Menu\Programs' -f ($env:APPDATA))
    ).Where{Test-Path -Path $_} | Sort-Object -Unique
)


# Check
if ([bool[]]($Paths.ForEach{Test-Path -Path ('{0}\{1}.lnk' -f ($_,$ShortcutName))}) -notcontains $false) {
    Write-Output -InputObject 'Installed.'
    Exit 0
}
else {
    Write-Error -Message 'Not installed' -ErrorAction 'Stop'
    Exit 1
}
