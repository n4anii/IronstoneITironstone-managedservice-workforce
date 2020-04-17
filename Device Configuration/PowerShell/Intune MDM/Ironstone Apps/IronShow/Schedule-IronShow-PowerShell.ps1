#region    Assets
    # Variables
    $NameScriptNoun     = [string]$('IronShow')
    $PathDirScript      = [string]$('{0}\IronstoneIT\{1}' -f ($env:ProgramW6432,$NameScriptNoun))
    $NameFileScript     = [string]$('Run-{0}.ps1' -f ($NameScriptNoun))

    # Variables - Scheduled Task
    $NameScheduledTask  = [string]$('Run-{0}' -f ($NameScriptNoun))
    $PathFilePowerShell = [string]$('%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe')
    $PathFilePS1        = [string]$('{0}\{1}' -f ($PathDirScript,$NameFileScript))
    
    # Variables - Scheduled Task - Run As
    $PathProfileList    = [string]('Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList')
    $SIDsProfileList    = [string[]]@(Get-ChildItem -Path $PathProfileList -Recurse:$false | Select-Object -ExpandProperty 'Name' | ForEach-Object -Process {$_.Split('\')[-1]} | Where-Object -FilterScript {$_ -like 'S-1-12-*'})
    $RunAsUserSID       = [string]$($SIDsProfileList | Sort-Object -Descending | Select-Object -First 1)
#endregion Assets



#region    Create Scheduled Task running PS1 using PowerShell.exe - Every 15 Minutes
    # Construct Scheduled Task
    $ScheduledTask = New-ScheduledTask `
        -Action    (New-ScheduledTaskAction -Execute ('"{0}"' -f ($PathFilePowerShell)) -Argument ('-ExecutionPolicy Bypass -NoLogo -NonInteractive -NoProfile -WindowStyle Hidden -File "{0}"' -f ($PathFilePS1))) `
        -Principal (New-ScheduledTaskPrincipal -UserId $RunAsUserSID -RunLevel 'Highest') `
        -Trigger   (New-ScheduledTaskTrigger -Once -At ([datetime]::Today) -RepetitionInterval ([timespan]::FromMinutes(30))) `
        -Settings  (New-ScheduledTaskSettingsSet -Hidden -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit ([timespan]::FromMinutes(10)) -Compatibility 4 -StartWhenAvailable)
    $ScheduledTask.'Author'      = 'Ironstone'
    $ScheduledTask.'Description' = ('{0}Runs a PowerShell script. {1}Execute: "{2}". {1}Arguments: "{3}".' -f (
        $(if([string]::IsNullOrEmpty($DescriptionScheduledTask)){''}else{('{0} {1}' -f ($DescriptionScheduledTask,"`r`n"))}),"`r`n",
        [string]($ScheduledTask | Select-Object -ExpandProperty 'Actions' | Select-Object -ExpandProperty 'Execute'),
        [string]($ScheduledTask | Select-Object -ExpandProperty 'Actions' | Select-Object -ExpandProperty 'Arguments')
    ))

    # Register Scheduled Task
    $null = Register-ScheduledTask -TaskName $NameScheduledTask -InputObject $ScheduledTask -Force -Verbose:$false -Debug:$false -ErrorAction 'SilentlyContinue'
                
    # Check if success registering Scheduled Task
    $SuccessCreatingScheduledTask = [bool]$($? -and [bool]$([byte](@(Get-ScheduledTask -TaskName $NameScheduledTask).Count) -eq 1))
    Write-Verbose -Message ('Success creating scheduled task "{0}"? "{1}".' -f ($NameScheduledTask,$SuccessCreatingScheduledTask.ToString()))

    # Run Scheduled Task if Success Creating It
    if ($SuccessCreatingScheduledTask) {$null = Start-ScheduledTask -TaskName $NameScheduledTask}
    else {Write-Error -Message 'ERROR: Failed to create scheduled task.'}
#endregion Create Scheduled Task running PS1 using PowerShell.exe - Every 15 Minutes