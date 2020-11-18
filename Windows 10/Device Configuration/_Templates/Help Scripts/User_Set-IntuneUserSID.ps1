$RegPath   = [string]('Registry::HKEY_CURRENT_USER\Software\IronstoneIT\Intune\UserInfo')
$RegNames  = [string[]]@('IntuneUserSID','IntuneUserName','DateSet')
$RegValues = [string[]]@(([string]([System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value)),([string]([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)),([string]([datetime]::Now.ToString('o'))))


if (-not(Test-Path -Path $RegPath)) {
    $null = New-Item -Path $RegPath -Force -ErrorAction 'Stop'
}


foreach ($x in [byte[]]@(0 .. [byte]($RegNames.Length - 1))) {
    $null = Set-ItemProperty -Path $RegPath -Name $RegNames[$x] -Value $RegValues[$x] -Force -ErrorAction 'Stop'
}