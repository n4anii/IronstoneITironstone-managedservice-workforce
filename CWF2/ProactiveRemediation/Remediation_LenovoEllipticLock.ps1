# Will Stop And Disable Services Specified. 
# Remediation Script

$Services = 'Virtual Lock Sensor'
foreach ($Service in $Services) {
    if ((Get-Service -Name $Service).StartType -ne "Disabled") {
        Set-Service -Name $Service -StartupType Disabled

    }
    if ((Get-Service -Name $Service).Status -ne "Stopped") {
        Stop-Service -Name $Service -Force
    }
}