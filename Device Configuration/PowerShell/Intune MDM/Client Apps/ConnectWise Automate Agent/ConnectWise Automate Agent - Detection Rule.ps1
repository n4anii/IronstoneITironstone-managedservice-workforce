foreach ($ServiceName in [string[]]$('LTService','ScreenConnect Client (*)')) {
    Get-Service -Name $ServiceName

    if ([string]$(Get-Service -Name $ServiceName | Select-Object -ExpandProperty 'Status') -ne 'Running') {
        Start-Service -Name $ServiceName
    }

    if ([string]$(Get-Service -Name $ServiceName | Select-Object -ExpandProperty 'Status') -ne 'Running') {
        Throw ('Service "{0}" is not running.' -f ($ServiceName)) 
    }
}