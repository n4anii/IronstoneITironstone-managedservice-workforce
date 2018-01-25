<#
.SYNOPSIS
Configures powercfg "lid" action to "Do nothing" for DC and AC power.

.DESCRIPTION
Configures powercfg "lid" action to "Do nothing" for DC and AC power.

.NOTES
This configuration must be ran in the User context
#>

powercfg.exe -SETACVALUEINDEX "381b4222-f694-41f0-9685-ff5bb260df2e" "4f971e89-eebd-4455-a8de-9e59040e7347" "5ca83367-6e45-459f-a27b-476b1d01c936" 000
powercfg.exe -SETDCVALUEINDEX "381b4222-f694-41f0-9685-ff5bb260df2e" "4f971e89-eebd-4455-a8de-9e59040e7347" "5ca83367-6e45-459f-a27b-476b1d01c936" 000