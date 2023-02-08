$OldTask = Get-ScheduledTask | where {$_.TaskName -like "*ironshow*"} -ErrorAction SilentlyContinue
$NewTaskName = "Switch Wallpaper"

IF ($OldTask)
{
    Unregister-ScheduledTask -TaskName $OldTask.TaskName -TaskPath $OldTask.TaskPath -Confirm:$false -ErrorAction SilentlyContinue
}

IF (Get-ScheduledTask -TaskName $NewTaskName -ErrorAction SilentlyContinue)
{
    Exit 0
}
ELSE
{
    IF (Test-Path $env:ProgramFiles\SATS\WallpaperSwitcher\SwitchWallpaper.xml)
    {
        Register-ScheduledTask -Xml (Get-Content $env:ProgramFiles\SATS\WallpaperSwitcher\SwitchWallpaper.xml | Out-String) -TaskName "Switch Wallpaper" -ErrorAction Stop
        Start-ScheduledTask -TaskName "Switch Wallpaper" -ErrorAction SilentlyContinue
    }
    ELSE
    {
        Write-Error -Message "Could not find Scheduled Task XML file" -Category ObjectNotFound -ErrorId 1618
        Exit 1618
    }
}
