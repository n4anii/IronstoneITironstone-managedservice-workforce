# Help variable
$Success = [bool]$($true)


# v1
## Asset
$Path = [string]$('{0}\Tools' -f ([Environment]::GetFolderPath('Desktop')))
## Remove if exist
if ([System.IO.Directory]::Exists($Path)) {
    [System.IO.Directory]::Delete($Path,$true)
    if (-not $?) {
        $Success = [bool] $false
    }
}


# v2
## Asset
$Path = [string]$('{0}' -f ([Environment]::GetFolderPath('Desktop')))
$Name = [string]$('Koble til ``*´´.lnk')
## Remove if exist
[string[]]$(Get-ChildItem -Path $Path -Filter $Name -Depth 0 -Recurse:$false -File -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'FullName').ForEach{
    $null = [System.IO.File]::Delete($_)
    if (-not $?) {
        $Success = [bool] $false
        break
    }
}


# Exit
if ($Success) {
    Write-Output -InputObject 'Success'
    Exit 0
}
else {
    Write-Error -Message 'Fail.' -ErrorAction 'Continue'
    Exit 1
}
