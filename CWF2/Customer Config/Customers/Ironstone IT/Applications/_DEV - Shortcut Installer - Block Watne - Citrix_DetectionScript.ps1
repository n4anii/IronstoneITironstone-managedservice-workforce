# Assets
## Manual
$ShortcutName = 'Citrix'

## Automatic
$Paths = [string[]]$(
    [string[]](
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
