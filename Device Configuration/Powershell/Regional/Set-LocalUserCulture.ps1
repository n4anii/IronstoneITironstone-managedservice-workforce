#Version:4
if ($env:PROCESSOR_ARCHITEW6432 -eq "AMD64") {
    #write-error "Y'arg Matey, we're off to the 64-bit land....." -erroraction continue
    if ($myInvocation.Line) {
        &"$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile $myInvocation.Line
    }else{
        &"$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile -file "$($myInvocation.InvocationName)" $args
    }
exit $lastexitcode
}

Import-Module International
$CurrentCulture  = Get-Culture
#Exit if the culture is not English or Norwegian
If ($CurrentCulture.Name -eq "nb-NO" -or $CurrentCulture.Name -eq'en-US')
{
    #If English, set new culture
    if ($CurrentCulture.Name -eq "en-US")
    {
		$RegInstallDate = (get-itemproperty 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion').InstallDate
		$Installdate = [timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($RegInstallDate))
        $CurrentDate = (Get-date )
        $Timespan = New-Timespan -Start $Installdate -End $CurrentDate
        if ($timespan.days -lt 1) {
            Set-Culture 1044
        }
    } 
}