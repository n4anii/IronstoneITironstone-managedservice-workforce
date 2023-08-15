# Will Stop And Disable Services Specified. 
# Detection Script

$Service = 'Virtual Lock Sensor'

$ServiceCheck = Get-Service -Name $Service -ErrorAction SilentlyContinue
if ($null -ne $ServiceCheck) {
    if ((($ServiceCheck).StartType -eq "Disabled") -and ($ServiceCheck.Status -eq "Stopped")) {
        Write-Output "Compliant"
        Exit 0
    }
    else {
        Write-Output "Not Compliant"
        Exit 1
    }
}
else {
    Write-Output "Compliant"
    Exit 0
}