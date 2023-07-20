$service = Get-Service -Name "Virtual Lock Sensor" -ErrorAction 
if ($null -ne $service) {
    Write-Host "Service exists"
    $serviceStartType = (Get-WmiObject -Query "Select * From Win32_Service Where Name='Virtual Lock Sensor'").StartMode
    if ($serviceStartType -ne 'Disabled') {
        exit 1
    }
    else {
        Write-Host "Service is disabled"
        exit 0
    }
}
else {
    Write-Host "Service does not exist"
    exit 1
}