<#
    GPO
        Local Computer Policy \ COmputer Configuration \ Administrative Templates \ System \ Logon \ Always wait for the network at computer startup and logon

    Windows needs your current credentials error on Windows 10
    https://www.thewindowsclub.com/windows-needs-your-current-credentials

    Click here to enter your most recent credentials message in Windows 10
    https://www.thewindowsclub.com/click-here-to-enter-your-most-recent-password

#>


<#
    Registry
        HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\CurrentVersion\Winlogon

    The computer does not wait for the network at computer startup.
    https://www.stigviewer.com/stig/windows_2003_member_server/2014-06-27/finding/V-3342
#>




# Assets
$Path  = [string]$('Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\CurrentVersion\Winlogon')
$Name  = [string]$('SyncForegroundPolicy')
$Value = [byte]  $(0)                  # 1 = Enable, 0 = Disable
$Type  = [string]$('DWord')




#region    Get
    # Get - Short
    Get-ItemProperty -Path $Path -Name $Name | Select-Object -ExpandProperty $Name

    # Get - Long
    Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name 'SyncForegroundPolicy' -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'SyncForegroundPolicy' -ErrorAction 'SilentlyContinue'
#endregion Get




#region    Set
    # Set - Short
    if (-not(Test-Path -Path $Path)) {$null = New-Item -Path $Path -ItemType 'Directory' -Force -ErrorAction 'Stop'}
    $null = Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force -ErrorAction 'Stop'


    # Set - Long
    if (-not(Test-Path -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\CurrentVersion\Winlogon')) {$null = New-Item -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\CurrentVersion\Winlogon' -ItemType 'Directory' -Force -ErrorAction 'Stop'}
    $null = Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name 'SyncForegroundPolicy' -Value 0 -Type 'DWord' -Force -ErrorAction 'Stop'
#endregion Set




#region    Automate
    # Get Registry Hive
    ~(Get-ChildItem -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT' -Recurse:$false -ErrorAction 'SilentlyContinue')
    ~(Get-ChildItem -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\CurrentVersion' -Recurse:$false -ErrorAction 'SilentlyContinue')
    
    # Get
    ~([string]$($x=Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name 'SyncForegroundPolicy' -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'SyncForegroundPolicy' -ErrorAction 'SilentlyContinue';if(-not($?)){'Not found.'}else{$x}))

    # Set
    ~([bool]$($Path='Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\CurrentVersion\Winlogon';if(-not(Test-Path -Path $Path)){$null = New-Item -Path $Path -ItemType 'Directory' -Force -ErrorAction 'Stop'}if($?){$null=Set-ItemProperty -Path $Path -Name 'SyncForegroundPolicy' -Value 0 -Type 'DWord' -Force -ErrorAction 'Stop';$?}else{$false}))

    # Remove
    ~([bool]$($null = Remove-Item -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\CurrentVersion\Winlogon' -Recurse:$true -Force -ErrorAction 'SilentlyContinue';$?))
#endregion Automate