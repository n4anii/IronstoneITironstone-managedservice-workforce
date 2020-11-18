<# 
    SET SID
        Context: User
        Runs:    Once, User_Set-IntuneUserSID.ps1
#>
$RegPath   = [string]('Registry::HKEY_CURRENT_USER\Software\IronstoneIT\Intune\UserInfo')
$RegNames  = [string[]]@('IntuneUserSID','IntuneUserName','DateSet')
$RegValues = [string[]]@(([string]([System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value)),([string]([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)),([string]([datetime]::Now.ToString('o'))))


if (-not(Test-Path -Path $RegPath)) {
    $null = New-Item -Path $RegPath -Force -ErrorAction 'Stop'
}


foreach ($x in [byte[]]@(0 .. [byte]($RegNames.Length - 1))) {
    $null = Set-ItemProperty -Path $RegPath -Name $RegNames[$x] -Value $RegValues[$x] -Force -ErrorAction 'Stop'
}





<# 
    GET SID
        Context: Device / System
        Runs:    Every script if $DeviceContext = $true & running as System user (S-1-5-18)
#>
$IntuneUser = [PSCustomObject]([PSCustomObject[]]@(foreach ($x in [string[]]@(Get-ChildItem -Path 'Registry::HKEY_USERS' -Recurse:$false -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'Name' | ForEach-Object {$_.Split('\')[-1]} | Where-Object {Test-Path -Path ('Registry::HKEY_USERS\{0}\Software\IronstoneIT\Intune\UserInfo' -f ($_))})) {[PSCustomObject]@{
    'IntuneUserSID' =[string](Get-ItemProperty -Path ('Registry::HKEY_USERS\{0}\Software\IronstoneIT\Intune\UserInfo' -f ($x)) -Name 'IntuneUserSID' | Select-Object -ExpandProperty 'IntuneUserSID');
    'IntuneUserName'=[string](Get-ItemProperty -Path ('Registry::HKEY_USERS\{0}\Software\IronstoneIT\Intune\UserInfo' -f ($x)) -Name 'IntuneUserName' | Select-Object -ExpandProperty 'IntuneUserName');
    'DateSet'       =[datetime](Get-ItemProperty -Path ('Registry::HKEY_USERS\{0}\Software\IronstoneIT\Intune\UserInfo' -f ($x)) -Name 'DateSet' | Select-Object -ExpandProperty 'DateSet');
}}) | Sort-Object -Property 'DateSet' -Descending:$false | Select-Object -Last 1)
$IntuneUserSID  = $IntuneUser | Select-Object -ExpandProperty 'IntuneUserSID'
$IntuneUserName = $IntuneUser | Select-Object -ExpandProperty 'IntuneUserName'