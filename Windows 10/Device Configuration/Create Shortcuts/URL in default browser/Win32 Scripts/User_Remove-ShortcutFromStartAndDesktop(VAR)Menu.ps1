# Settings
$ErrorActionPreference = 'Continue'



# Assets
## Manual
$ShortcutName = 'Citrix'

## Automatic
$Paths = [string[]]$(
    [string[]](
        [string]('{0}\Desktop' -f ($env:USERPROFILE)),
        [System.Environment]::GetFolderPath('Desktop'),
        [string]('{0}\Microsoft\Windows\Start Menu\Programs' -f ($env:APPDATA))
    ).Where{Test-Path -Path $_} | Sort-Object -Unique
)



# Remove
$Paths.ForEach{
    $Path = [string]('{0}\{1}.lnk' -f ($_,$ShortcutName))
    if (Test-Path -Path $Path) {
        $null = Remove-Item -Path $Path -Force -Confirm:$false
        if (-not$?) {
            Exit 1
        }
    }
}



# Exit
Write-Output -InputObject 'Success'
Exit 1
