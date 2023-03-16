<#
    .NAME
        User_Delete-WindowsHelloContainer.ps1

    .NOTES
        Resources
        * https://getadmx.com/?Category=Windows_10_2016&Policy=Microsoft.Policies.MicrosoftPassportForWork::MSPassport_UsePassportForWork
        * https://getadmx.com/?Category=Windows_10_2016&Policy=Microsoft.Policies.MicrosoftPassportForWork::MSPassport_UseDeviceUnlock
#>


# Parameters
[OutputType($null)]
Param()


# PowerShell preferences
$ErrorActionPreference = 'Stop'


# Assets
$Success     = [bool] $true
$ScriptName  = [string] 'User_Delete-WindowsHelloContainer.ps1'
$PathFileLog = [string]('{0}\IronstoneIT\Logs\DeviceConfiguration\{1}-{2}-{3}.txt' -f (
    $env:ProgramData,
    $ScriptName.Replace('.ps1',''),
    [string]$(if([System.Environment]::Is64BitProcess){'x64'}else{'x86'}),
    [datetime]::Now.ToString('yyMMdd-HHmmssffff')
))
$PathDirLog  = [string] [System.IO.Directory]::GetParent($PathFileLog).'FullName'


# Start Transcript
if (-not [System.IO.Directory]::Exists($PathDirLog)) {
    $null = [System.IO.Directory]::CreateDirectory($PathDirLog)
}
Start-Transcript -Path $PathFileLog -ErrorAction 'Stop'
Write-Output -InputObject '**********************'


# Delete Windows Hello PIN
Try {
    Write-Output -InputObject 'Delete Windows Hello PIN.'
    $null = Start-Process -FilePath ('{0}\System32\certutil.exe' -f ($env:SystemRoot)) -ArgumentList '/deletehellocontainer' -WindowStyle 'Hidden' -Wait
}
Catch {
    $Success = [bool] $false
    Write-Error -Message $_.'Exception'.'Message' -ErrorAction 'Continue'
}
Finally {
    Write-Output -InputObject ('Success? {0}' -f $Success.ToString())
    Stop-Transcript
}


# Exit
if ($Success) {
    Exit 0
}
else {
    Exit 1
}
