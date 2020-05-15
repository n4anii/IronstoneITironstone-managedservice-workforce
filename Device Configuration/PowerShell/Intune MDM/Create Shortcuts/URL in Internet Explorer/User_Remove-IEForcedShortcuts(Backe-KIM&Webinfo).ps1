# Assets
$ShortcutNames    = [string[]]$('KIM.lnk','Webinfo.lnk')
$UserDesktopPaths = [string[]]$([string[]]$([string]$([System.Environment]::GetFolderPath('Desktop')),[string]$('{0}\Desktop' -f ($env:USERPROFILE))) | Where-Object -FilterScript {Test-Path -Path $_} | Select-Object -Unique | Sort-Object)

# Remove Shortcuts if found
foreach ($ShortcutName in $ShortcutNames) {
    foreach ($UserDesktopPath in $UserDesktopPaths) {
        $ShortcutPath = [string]$('{0}\{1}' -f ($UserDesktopPath,$ShortcutName))
        if (Test-Path -Path $ShortcutPath) {
            $null = Remove-Item -Path $ShortcutPath -Force -ErrorAction 'Stop'
        }
    }
}