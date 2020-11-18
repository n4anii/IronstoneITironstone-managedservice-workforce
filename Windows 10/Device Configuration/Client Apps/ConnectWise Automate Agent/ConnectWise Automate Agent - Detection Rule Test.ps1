foreach ($ServiceName in [string[]]$('LTService','ScreenConnect Client (*)')) {
    Get-Service -Name $ServiceName
    Stop-Service -Name $ServiceName -Force
}