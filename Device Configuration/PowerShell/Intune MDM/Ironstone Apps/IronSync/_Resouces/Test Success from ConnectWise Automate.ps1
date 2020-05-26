# Dynamically
## Journal files
### Folder exist
Test-Path -Path ('{0}\IronstoneIT\IronSync(OfficeTemplates_*)\AzCopyJournal' -f ($env:ProgramW6432))

### View
Get-ChildItem -Path ('{0}\IronstoneIT\IronSync(OfficeTemplates_*)\AzCopyJournal' -f ($env:ProgramW6432)) -File


## Logs - Only present if AzCopy failed
Get-ChildItem -Path ('{0}\IronstoneIT\IronSync(OfficeTemplates_*)\Logs' -f ($env:ProgramW6432)) -File


## Task Scheduler
### Office sync only
Get-ScheduledTask -TaskName 'IronSync(OfficeTemplates_*' | Format-Table -AutoSize

### All Ironstone
$(Get-ScheduledTask).Where{$_.'Author' -like 'Ironstone*'} | Format-Table -AutoSize


## Template files
Get-ChildItem -Path ('{0}\Users\Public\OfficeTemplates' -f ($env:SystemDrive)) -File


## Intune Management Extension
### Get
Get-Service -Name 'IntuneManagementExtension'
### Restart if running
Try {
    if ([string](Get-Service -Name 'IntuneManagementExtension' | Select-Object -ExpandProperty 'Status') -eq 'Running') {
        $null = Stop-Service -Name 'IntuneManagementExtension'
        $null = Start-Sleep -Seconds 2
        $null = Start-Service -Name 'IntuneManagementExtension'
    }
    else {
        $null = Start-Service -Name 'IntuneManagementExtension'
    }
    if ($?) {
        Write-Output -InputObject 'Success'
    }
    else {
        Write-Output -InputObject 'Failed'
    }
}
Catch {
    Write-Output -InputObject 'Failed'
}


# Test IronSync Office Templates Edition
    # Customer Name In Script
    $Customer = [string]$('MetierOEC'); $Customer


    # Check File Paths - Public
    ~Get-ChildItem -Path ('{0}\Users\Public' -f ($env:SystemDrive)) -Directory -Recurse:$false -Force


    # Check File Paths - Public\OfficeTemplates - View
    ~Get-ChildItem -Path ('{0}\Users\Public\OfficeTemplates' -f ($env:SystemDrive)) -File -Recurse:$false -Force
    cmd /c 'dir "C:\Users\Public\OfficeTemplates"'


    # Check File Paths - Public\OfficeTemplates - Count
    ~@(Get-ChildItem -Path ('{0}\Users\Public\OfficeTemplates' -f ($env:SystemDrive)) -File -Recurse:$false -Force).Count
    

    # Check Registry Entries - Word
    ~(Get-ItemProperty -Path ('Registry::HKEY_USERS\{0}\Software\Microsoft\Office\16.0\Word\Options' -f ([System.Security.Principal.NTAccount]::new(@(Get-Process -Name 'explorer' -IncludeUserName)[0].'UserName').Translate([System.Security.Principal.SecurityIdentifier]).Value)) -Name 'PersonalTemplates' | Select-Object -ExpandProperty 'PersonalTemplates')


    # Check Registry Entries - PowerPoint
    ~(Get-ItemProperty -Path ('Registry::HKEY_USERS\{0}\Software\Microsoft\Office\16.0\PowerPoint\Options' -f ([System.Security.Principal.NTAccount]::new(@(Get-Process -Name 'explorer' -IncludeUserName)[0].'UserName').Translate([System.Security.Principal.SecurityIdentifier]).Value)) -Name 'PersonalTemplates' | Select-Object -ExpandProperty 'PersonalTemplates')


    # Check Install Log
    ~(Get-Content -Path (Get-ChildItem -Path ('{0}\IronstoneIT\Intune\DeviceConfiguration' -f ($env:ProgramW6432)) -File | Where-Object {$_.Name -like ('Device_Install-IronSync*-64bit*')} | Sort-Object -Property 'LastWriteTime' | Select-Object -Last 1 -ExpandProperty 'FullName') -Raw)


    # Check Sync Error Logs - Any Present
    ~$Result = @(Get-ChildItem -Path ('{0}\IronstoneIT\IronSync(OfficeTemplates_MetierOEC)\Logs' -f ($env:ProgramW6432,$Customer)) -File); if((-not($?)) -or @($Result).'Count' -le 0){'None Where Found'}else{$Result}


    # Check Sync Error Logs - Last Log
    ~(Get-Content -Path (Get-ChildItem -Path ('{0}\IronstoneIT\IronSync(OfficeTemplates_{1})\Logs' -f ($env:ProgramW6432,$Customer)) -File | Sort-Object -Property 'LastWriteTime' | Select-Object -Last 1 -ExpandProperty 'FullName') -Raw)