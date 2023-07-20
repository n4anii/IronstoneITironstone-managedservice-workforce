try {
    $service = Get-Service -Name "Virtual Lock Sensor" -ErrorAction Stop
    $serviceStartType = (Get-WmiObject -Query "Select * From Win32_Service Where Name='Virtual Lock Sensor'").StartMode

    if ($service.Status -eq 'Running') {
        Stop-Service -Name "Virtual Lock Sensor" -Force
        Write-Host "Service stopped"
    }

    if ($serviceStartType -ne 'Disabled') {
        Set-Service -Name "Virtual Lock Sensor" -StartupType Disabled
        Write-Host "Service startup type set to Disabled"
    }
}
catch {
    Write-Host "Service does not exist or failed to modify. Error: $_"
    exit 1
}
