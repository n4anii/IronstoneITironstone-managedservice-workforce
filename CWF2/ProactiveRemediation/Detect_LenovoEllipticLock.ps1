try {
    $service = Get-Service -Name "LenovoEllipticVirtualLock" -ErrorAction Stop
    if ($null -ne $service) {
        Write-Host "Service exists"
        exit 1
    }
}
catch {
    Write-Host "Service does not exist"
    exit 0
}
