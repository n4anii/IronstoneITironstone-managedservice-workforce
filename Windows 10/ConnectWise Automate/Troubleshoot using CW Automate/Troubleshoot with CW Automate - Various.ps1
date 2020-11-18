#region    Scheduled Tasks
    # All
    ~(Get-ScheduledTask | Select-Object -Property 'Author','TaskName' | Sort-Object -Property 'TaskName')

    # Author = Ironstone
    ~(Get-ScheduledTask | Where-Object -Property 'Author' -EQ 'Ironstone' | Select-Object -ExpandProperty 'TaskName')
#endregion Scheduled Tasks



#region    Run a full fledged PowerShell Script as Base64
    '"%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy Bypass -NoLogo -NonInteractive -NoProfile -WindowStyle Hidden -EncodedCommand "base64string"'
#endregion Run a full fledged PowerShell Script as Base64



#region    Hardware Info
    # BIOS Info from Registry
    ~Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\HARDWARE\DESCRIPTION\System\BIOS'
#endregion Hardware Info



#region    Intune Management Extension
    # Restart Intune Management Extension
    [bool]$($Service = Get-Service -Name 'IntuneManagementExtension' -ErrorAction 'SilentlyContinue'; if ($?){Stop-Service -Name $Service.'Name'; Start-Sleep -Seconds 2 -ErrorAction 'SilentlyContinue'; Start-Service -InputObject $Service -ErrorAction 'SilentlyContinue'; $?}else{$false})
#endregion Intune Management Extension