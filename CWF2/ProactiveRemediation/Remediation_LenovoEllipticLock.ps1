try {
    $service = Get-Service -Name "LenovoEllipticVirtualLock" -ErrorAction Stop
    $serviceStartType = (Get-WmiObject -Query "Select * From Win32_Service Where Name='LenovoEllipticVirtualLock'").StartMode

    if ($service.Status -eq 'Running') {
        Stop-Service -Name "LenovoEllipticVirtualLock" -Force
        Write-Host "Service stopped"
    }

    if ($serviceStartType -ne 'Disabled') {
        Set-Service -Name "LenovoEllipticVirtualLock" -StartupType Disabled
        Write-Host "Service startup type set to Disabled"
    }
}
catch {
    Write-Host "Service does not exist or failed to modify. Error: $_"
    exit 1
}
