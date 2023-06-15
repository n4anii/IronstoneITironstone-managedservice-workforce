$ErrorActionPreference = 'Stop'
$Path = [string] ('{0}\Tools\Koble til filområder.bat'-f[System.Environment]::GetFolderPath('Desktop'))
$Hash = [string] 'E8E6A23FE32965AA219D8394E20221744B6CB22562D3AD6B4F84232DC895AC5C'
if ((Get-FileHash -Path $Path -Algorithm 'SHA256').'Hash' -eq $Hash) {
    Write-Output -InputObject 'Success.'
    Exit 0
}
else {
    Write-Error -Message 'Fail.' -ErrorAction 'Continue'
    Exit 1
}